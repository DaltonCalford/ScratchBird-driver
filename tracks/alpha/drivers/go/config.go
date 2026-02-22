// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"errors"
	"net/url"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Host                     string
	Port                     int
	FrontDoorMode            string
	Database                 string
	User                     string
	Password                 string
	Schema                   string
	Role                     string
	Protocol                 string
	SSLMode                  string
	SSLRootCert              string
	SSLCert                  string
	SSLKey                   string
	SSLPassword              string
	ConnectTimeout           time.Duration
	SocketTimeout            time.Duration
	Application              string
	BinaryTransfer           bool
	Compression              string
	FetchSize                uint32
	ManagerAuthToken         string
	ManagerUsername          string
	ManagerDatabase          string
	ManagerConnectionProfile string
	ManagerClientIntent      string
	ManagerClientFlags       uint16
	ManagerAuthFastPath      bool
}

func defaultConfig() Config {
	return Config{
		Host:                     "localhost",
		Port:                     3092,
		FrontDoorMode:            "direct",
		Protocol:                 "native",
		SSLMode:                  "require",
		ConnectTimeout:           30 * time.Second,
		SocketTimeout:            0,
		Application:              "scratchbird_go",
		BinaryTransfer:           true,
		Compression:              "off",
		FetchSize:                0,
		ManagerConnectionProfile: "native_v3",
		ManagerClientIntent:      "native_v3",
		ManagerAuthFastPath:      true,
	}
}

func ParseConfig(dsn string) (Config, error) {
	if strings.TrimSpace(dsn) == "" {
		return defaultConfig(), nil
	}
	if strings.Contains(dsn, "://") {
		return parseURI(dsn)
	}
	return parseKeyValue(dsn)
}

func parseURI(dsn string) (Config, error) {
	u, err := url.Parse(dsn)
	if err != nil {
		return Config{}, err
	}
	if !strings.EqualFold(u.Scheme, "scratchbird") {
		return Config{}, errors.New("unsupported DSN scheme")
	}
	cfg := defaultConfig()
	if u.Hostname() != "" {
		cfg.Host = u.Hostname()
	}
	if u.Port() != "" {
		if port, err := strconv.Atoi(u.Port()); err == nil {
			cfg.Port = port
		}
	}
	if u.User != nil {
		cfg.User = u.User.Username()
		if pass, ok := u.User.Password(); ok {
			cfg.Password = pass
		}
	}
	if u.Path != "" && u.Path != "/" {
		cfg.Database = strings.TrimPrefix(u.Path, "/")
	}
	for key, values := range u.Query() {
		if len(values) == 0 {
			continue
		}
		if err := applyParam(&cfg, key, values[0]); err != nil {
			return Config{}, err
		}
	}
	return cfg, nil
}

func parseKeyValue(dsn string) (Config, error) {
	cfg := defaultConfig()
	sep := " "
	if strings.Contains(dsn, ";") {
		sep = ";"
	}
	parts := strings.FieldsFunc(dsn, func(r rune) bool {
		return r == rune(sep[0])
	})
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		idx := strings.Index(part, "=")
		if idx < 0 {
			continue
		}
		key := strings.TrimSpace(part[:idx])
		value := strings.Trim(strings.TrimSpace(part[idx+1:]), "\"")
		if err := applyParam(&cfg, key, value); err != nil {
			return Config{}, err
		}
	}
	return cfg, nil
}

func normalizeNativeProtocol(value string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", "native", "scratchbird", "scratchbird-native", "scratchbird_native":
		return "native", true
	default:
		return "", false
	}
}

func normalizeFrontDoorMode(value string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", "direct":
		return "direct", true
	case "manager_proxy", "manager-proxy", "managed":
		return "manager_proxy", true
	default:
		return "", false
	}
}

func applyParam(cfg *Config, key, value string) error {
	switch strings.ToLower(key) {
	case "host", "server", "data source", "datasource":
		cfg.Host = value
	case "port":
		if port, err := strconv.Atoi(value); err == nil {
			cfg.Port = port
		}
	case "front_door_mode", "frontdoormode", "connection_mode", "ingress_mode":
		normalized, ok := normalizeFrontDoorMode(value)
		if !ok {
			return errors.New("front_door_mode must be direct or manager_proxy")
		}
		cfg.FrontDoorMode = normalized
	case "database", "dbname", "initial catalog":
		cfg.Database = value
	case "user", "username", "user id", "uid":
		cfg.User = value
	case "password", "pwd":
		cfg.Password = value
	case "schema", "search_path", "searchpath", "currentschema":
		cfg.Schema = value
	case "role":
		cfg.Role = value
	case "protocol", "parser", "dialect":
		normalized, ok := normalizeNativeProtocol(value)
		if !ok {
			return errors.New("only protocol=native is supported; connect to the native parser listener/port")
		}
		cfg.Protocol = normalized
	case "sslmode", "ssl mode":
		cfg.SSLMode = value
	case "sslrootcert":
		cfg.SSLRootCert = value
	case "sslcert":
		cfg.SSLCert = value
	case "sslkey":
		cfg.SSLKey = value
	case "sslpassword":
		cfg.SSLPassword = value
	case "connect_timeout", "connecttimeout", "timeout":
		if seconds, err := strconv.Atoi(value); err == nil {
			cfg.ConnectTimeout = time.Duration(seconds) * time.Second
		}
	case "socket_timeout", "sockettimeout":
		if seconds, err := strconv.Atoi(value); err == nil {
			cfg.SocketTimeout = time.Duration(seconds) * time.Second
		}
	case "application_name", "applicationname":
		cfg.Application = value
	case "binary_transfer", "binarytransfer":
		cfg.BinaryTransfer = value == "1" || strings.EqualFold(value, "true")
	case "compression":
		if strings.EqualFold(value, "zstd") {
			cfg.Compression = "zstd"
		} else {
			cfg.Compression = "off"
		}
	case "fetch_size", "fetchsize", "default_fetch_size":
		if rows, err := strconv.Atoi(value); err == nil && rows >= 0 {
			cfg.FetchSize = uint32(rows)
		}
	case "manager_auth_token", "mcp_auth_token":
		cfg.ManagerAuthToken = value
	case "manager_username", "mcp_username":
		cfg.ManagerUsername = value
	case "manager_database", "mcp_database":
		cfg.ManagerDatabase = value
	case "manager_connection_profile", "mcp_connection_profile":
		cfg.ManagerConnectionProfile = value
	case "manager_client_intent", "mcp_client_intent":
		cfg.ManagerClientIntent = value
	case "manager_client_flags", "mcp_client_flags":
		if flags, err := strconv.ParseUint(value, 10, 16); err == nil {
			cfg.ManagerClientFlags = uint16(flags)
		}
	case "manager_auth_fast_path", "mcp_auth_fast_path":
		normalized := strings.ToLower(strings.TrimSpace(value))
		cfg.ManagerAuthFastPath = normalized == "1" ||
			normalized == "true" ||
			normalized == "yes" ||
			normalized == "on"
	}
	return nil
}

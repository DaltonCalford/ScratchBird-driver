package scratchbird

import (
	"errors"
	"net/url"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Host           string
	Port           int
	Database       string
	User           string
	Password       string
	SSLMode        string
	SSLRootCert    string
	SSLCert        string
	SSLKey         string
	ConnectTimeout time.Duration
	SocketTimeout  time.Duration
	Application    string
	BinaryTransfer bool
	Compression    string
}

func defaultConfig() Config {
	return Config{
		Host:           "localhost",
		Port:           3092,
		SSLMode:        "prefer",
		ConnectTimeout: 30 * time.Second,
		SocketTimeout:  0,
		Application:    "scratchbird_go",
		BinaryTransfer: true,
		Compression:    "off",
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
		applyParam(&cfg, key, values[0])
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
		applyParam(&cfg, key, value)
	}
	return cfg, nil
}

func applyParam(cfg *Config, key, value string) {
	switch strings.ToLower(key) {
	case "host", "server", "data source", "datasource":
		cfg.Host = value
	case "port":
		if port, err := strconv.Atoi(value); err == nil {
			cfg.Port = port
		}
	case "database", "dbname", "initial catalog":
		cfg.Database = value
	case "user", "username", "user id", "uid":
		cfg.User = value
	case "password", "pwd":
		cfg.Password = value
	case "sslmode", "ssl mode":
		cfg.SSLMode = value
	case "sslrootcert":
		cfg.SSLRootCert = value
	case "sslcert":
		cfg.SSLCert = value
	case "sslkey":
		cfg.SSLKey = value
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
	}
}

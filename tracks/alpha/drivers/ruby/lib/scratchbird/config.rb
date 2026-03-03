# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "uri"

module Scratchbird
  class Config
    attr_accessor :host, :port, :database, :user, :password, :sslmode,
                  :schema, :role, :sslrootcert, :sslcert, :sslkey, :sslpassword,
                  :connect_timeout_ms, :socket_timeout_ms, :application_name, :protocol,
                  :binary_transfer, :compression, :front_door_mode, :manager_auth_token,
                  :manager_username, :manager_database, :manager_connection_profile,
                  :manager_client_intent, :manager_client_flags, :manager_auth_fast_path,
                  :metadata_expand_schema_parents

    def initialize
      @host = "localhost"
      @port = 3092
      @database = ""
      @user = ""
      @password = ""
      @front_door_mode = "direct"
      @schema = ""
      @role = ""
      @protocol = "native"
      @sslmode = "require"
      @sslrootcert = nil
      @sslcert = nil
      @sslkey = nil
      @sslpassword = nil
      @connect_timeout_ms = 30_000
      @socket_timeout_ms = 0
      @application_name = "scratchbird_ruby"
      @binary_transfer = true
      @compression = "off"
      @manager_auth_token = ""
      @manager_username = ""
      @manager_database = ""
      @manager_connection_profile = "native_v3"
      @manager_client_intent = "native_v3"
      @manager_client_flags = 0
      @manager_auth_fast_path = true
      @metadata_expand_schema_parents = false
    end

    def self.parse(dsn)
      cfg = new
      return cfg if dsn.to_s.strip.empty?
      if dsn.include?("://")
        parse_uri(dsn, cfg)
      else
        parse_key_value(dsn, cfg)
      end
      cfg
    end

    def self.parse_uri(dsn, cfg)
      uri = URI.parse(dsn)
      raise ArgumentError, "Unsupported DSN scheme" unless uri.scheme == "scratchbird"
      cfg.host = uri.host if uri.host
      cfg.port = uri.port if uri.port
      if uri.user
        cfg.user = URI.decode_www_form_component(uri.user)
      end
      if uri.password
        cfg.password = URI.decode_www_form_component(uri.password)
      end
      if uri.path && uri.path != "/"
        cfg.database = uri.path.sub(%r{^/}, "")
      end
      if uri.query
        URI.decode_www_form(uri.query).each do |key, value|
          apply_param(cfg, key, value)
        end
      end
    end

    def self.parse_key_value(dsn, cfg)
      separator = dsn.include?(";") ? ";" : " "
      dsn.split(separator).each do |token|
        token = token.strip
        next if token.empty?
        key, value = token.split("=", 2)
        next unless key && value
        apply_param(cfg, key.strip, value.strip.gsub(/\A"|"\z/, ""))
      end
    end

    def self.normalize_native_protocol(value)
      normalized = value.to_s.strip.downcase
      return "native" if normalized.empty? ||
        normalized == "native" ||
        normalized == "scratchbird" ||
        normalized == "scratchbird-native" ||
        normalized == "scratchbird_native"
      raise ArgumentError, "Only protocol=native is supported; connect to the native parser listener/port."
    end

    def self.normalize_front_door_mode(value)
      normalized = value.to_s.strip.downcase
      return "direct" if normalized.empty? || normalized == "direct"
      return "manager_proxy" if normalized == "manager_proxy" || normalized == "manager-proxy" || normalized == "managed"
      raise ArgumentError, "front_door_mode must be direct or manager_proxy."
    end

    def self.apply_param(cfg, key, value)
      case key.to_s.downcase
      when "host", "server", "data source", "datasource"
        cfg.host = value
      when "port"
        cfg.port = value.to_i
      when "front_door_mode", "frontdoormode", "connection_mode", "ingress_mode"
        cfg.front_door_mode = normalize_front_door_mode(value)
      when "database", "dbname", "initial catalog"
        cfg.database = value
      when "user", "username", "user id", "uid"
        cfg.user = value
      when "password", "pwd"
        cfg.password = value
      when "schema", "search_path", "searchpath", "currentschema"
        cfg.schema = value
      when "metadataexpandschemaparents", "metadata_expand_schema_parents",
           "expandschemaparents", "expand_schema_parents",
           "dbeaverexpandschemaparents", "dbeaver_expand_schema_parents"
        normalized = value.to_s.downcase
        cfg.metadata_expand_schema_parents = normalized == "true" || value.to_s == "1" ||
          normalized == "yes" || normalized == "on"
      when "role"
        cfg.role = value
      when "protocol", "parser", "dialect"
        cfg.protocol = normalize_native_protocol(value)
      when "sslmode", "ssl mode"
        cfg.sslmode = value
      when "sslrootcert"
        cfg.sslrootcert = value
      when "sslcert"
        cfg.sslcert = value
      when "sslkey"
        cfg.sslkey = value
      when "sslpassword"
        cfg.sslpassword = value
      when "connect_timeout", "connecttimeout", "timeout"
        cfg.connect_timeout_ms = value.to_i * 1000
      when "socket_timeout", "sockettimeout"
        cfg.socket_timeout_ms = value.to_i * 1000
      when "application_name", "applicationname"
        cfg.application_name = value
      when "binary_transfer", "binarytransfer"
        cfg.binary_transfer = (value == "1" || value.to_s.downcase == "true")
      when "compression"
        cfg.compression = value.to_s.downcase == "zstd" ? "zstd" : "off"
      when "manager_auth_token", "mcp_auth_token"
        cfg.manager_auth_token = value
      when "manager_username", "mcp_username"
        cfg.manager_username = value
      when "manager_database", "mcp_database"
        cfg.manager_database = value
      when "manager_connection_profile", "mcp_connection_profile"
        cfg.manager_connection_profile = value
      when "manager_client_intent", "mcp_client_intent"
        cfg.manager_client_intent = value
      when "manager_client_flags", "mcp_client_flags"
        cfg.manager_client_flags = value.to_i
      when "manager_auth_fast_path", "mcp_auth_fast_path"
        cfg.manager_auth_fast_path = value.to_s.downcase == "true" || value.to_s == "1" ||
          value.to_s.downcase == "yes" || value.to_s.downcase == "on"
      end
    end
  end
end

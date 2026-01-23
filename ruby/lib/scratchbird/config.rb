require "uri"

module Scratchbird
  class Config
    attr_accessor :host, :port, :database, :user, :password, :sslmode,
                  :sslrootcert, :sslcert, :sslkey, :connect_timeout_ms,
                  :socket_timeout_ms, :application_name, :binary_transfer,
                  :compression

    def initialize
      @host = "localhost"
      @port = 3092
      @database = ""
      @user = ""
      @password = ""
      @sslmode = "require"
      @sslrootcert = nil
      @sslcert = nil
      @sslkey = nil
      @connect_timeout_ms = 30_000
      @socket_timeout_ms = 0
      @application_name = "scratchbird_ruby"
      @binary_transfer = true
      @compression = "off"
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

    def self.apply_param(cfg, key, value)
      case key.to_s.downcase
      when "host", "server", "data source", "datasource"
        cfg.host = value
      when "port"
        cfg.port = value.to_i
      when "database", "dbname", "initial catalog"
        cfg.database = value
      when "user", "username", "user id", "uid"
        cfg.user = value
      when "password", "pwd"
        cfg.password = value
      when "sslmode", "ssl mode"
        cfg.sslmode = value
      when "sslrootcert"
        cfg.sslrootcert = value
      when "sslcert"
        cfg.sslcert = value
      when "sslkey"
        cfg.sslkey = value
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
      end
    end
  end
end

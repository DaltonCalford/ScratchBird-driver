# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "scratchbird/client"
require "scratchbird/config"
require "scratchbird/errors"
require "scratchbird/sql"
require "scratchbird/statement"

module Scratchbird
  class Connection
    attr_reader :config
    attr_accessor :autocommit

    def initialize(options = nil)
      @config = build_config(options)
      @client = Client.new(@config)
      @autocommit = true
      @closed = false
      @client.connect
    end

    def close
      return if @closed
      @client.disconnect
      @closed = true
    end

    def closed?
      @closed
    end

    def begin_transaction
      ensure_open
      @client.begin_transaction
    end

    def commit
      ensure_open
      @client.commit
    end

    def rollback
      ensure_open
      @client.rollback
    end

    def execute(sql, params = nil)
      ensure_open
      begin_transaction unless autocommit
      @client.query(sql, params)
    end

    def query(sql, params = nil)
      execute(sql, params)
    end

    def stream(sql, params = nil)
      ensure_open
      begin_transaction unless autocommit
      @client.stream(sql, params)
    end

    def prepare(sql)
      ensure_open
      Statement.new(self, sql)
    end

    def client
      @client
    end

    private

    def ensure_open
      raise ConnectionError, "connection is closed" if @closed
    end

    def build_config(options)
      case options
      when Config
        options
      when String
        Config.parse(options)
      when Hash
        cfg = Config.new
        options.each do |key, value|
          key_s = key.to_s
          setter = "#{key_s}="
          if cfg.respond_to?(setter)
            cfg.public_send(setter, value)
          else
            Config.apply_param(cfg, key_s, value)
          end
        end
        cfg
      when nil
        Config.new
      else
        raise ArgumentError, "unsupported connection options"
      end
    end
  end
end

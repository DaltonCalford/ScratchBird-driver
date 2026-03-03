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
require "scratchbird/metadata"
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

    def savepoint(name)
      ensure_open
      @client.savepoint(name)
    end

    def rollback_to_savepoint(name)
      ensure_open
      @client.rollback_to_savepoint(name)
    end

    def release_savepoint(name)
      ensure_open
      @client.release_savepoint(name)
    end

    def in_transaction?
      return false unless @client.respond_to?(:in_transaction?)
      @client.in_transaction?
    end

    def execute(sql, params = nil, options = nil)
      ensure_open
      begin_transaction_if_needed
      @client.query(sql, params, options)
    end

    def query(sql, params = nil, options = nil)
      execute(sql, params, options)
    end

    def stream(sql, params = nil, options = nil)
      ensure_open
      begin_transaction_if_needed
      @client.stream(sql, params, options)
    end

    def query_metadata(collection_name = "tables", options = nil)
      ensure_open
      begin_transaction_if_needed
      @client.query_metadata(collection_name, options)
    end

    def get_schema(collection_name = "tables", options = nil, expand_schema_parents: nil)
      ensure_open
      begin_transaction_if_needed
      @client.get_schema(collection_name, options, expand_schema_parents: expand_schema_parents)
    end

    def get_schema_tree(expand_schema_parents: nil, database: nil, default_branch: "default")
      ensure_open
      begin_transaction_if_needed
      rows = get_schema("schemas", nil, expand_schema_parents: expand_schema_parents)
      Metadata.build_database_default_metadata_rows(
        rows,
        database: database || @config.database,
        expand_schema_parents: false,
        default_branch: default_branch
      )
    end

    def prepare(sql)
      ensure_open
      Statement.new(self, sql)
    end

    def execute_prepared(name, params = nil, options = nil)
      ensure_open
      begin_transaction_if_needed
      @client.execute(name, params, options)
    end

    def stream_prepared(name, params = nil, options = nil)
      ensure_open
      begin_transaction_if_needed
      @client.execute_stream(name, params, options)
    end

    def close_prepared(name)
      ensure_open
      @client.deallocate(name)
    end

    def client
      @client
    end

    private

    def ensure_open
      raise ConnectionError, "connection is closed" if @closed
    end

    def begin_transaction_if_needed
      return if autocommit || in_transaction?
      @client.begin_transaction
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

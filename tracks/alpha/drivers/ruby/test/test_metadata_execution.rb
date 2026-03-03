# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestMetadataExecution < Minitest::Test
  FakeMetadataResult = Struct.new(:rows) do
    def each_hash
      return enum_for(:each_hash) unless block_given?
      rows.each { |row| yield row }
    end
  end

  class MetadataClient < Scratchbird::Client
    attr_reader :queries

    def initialize(config, rows)
      super(config)
      @rows = rows
      @queries = []
      @connected = true
    end

    def query(sql, params = nil, options = nil)
      @queries << [sql, params, options]
      FakeMetadataResult.new(@rows.map(&:dup))
    end
  end

  class ConnectionMetadataClient
    attr_reader :calls

    def initialize(schema_rows)
      @schema_rows = schema_rows
      @calls = []
    end

    def in_transaction?
      false
    end

    def get_schema(collection_name, _options = nil, expand_schema_parents: nil)
      @calls << [collection_name, expand_schema_parents]
      @schema_rows.map(&:dup)
    end
  end

  def test_query_metadata_resolves_collection_alias
    client = build_client(rows: [{ "schema_name" => "users" }])
    client.query_metadata("schema")

    assert_equal Scratchbird::Metadata::SCHEMAS_QUERY, client.queries.first[0]
  end

  def test_query_metadata_rejects_unknown_collection
    client = build_client(rows: [])
    err = assert_raises(Scratchbird::NotSupportedError) { client.query_metadata("missing_family") }
    assert_includes err.message, "not supported"
  end

  def test_get_schema_expands_parent_rows_from_config
    cfg = Scratchbird::Config.new
    cfg.metadata_expand_schema_parents = true
    client = build_client(config: cfg, rows: [{ "schema_name" => "users.alice.dev", "schema_id" => 7 }])

    rows = client.get_schema("schemas")
    assert_equal ["users", "users.alice", "users.alice.dev"], rows.map { |row| row["schema_name"] }
    assert_nil rows[0]["schema_id"]
    assert_equal 7, rows[2]["schema_id"]
  end

  def test_get_schema_tree_returns_recursive_nodes
    cfg = Scratchbird::Config.new
    cfg.metadata_expand_schema_parents = true
    client = build_client(
      config: cfg,
      rows: [
        { "schema_name" => "users.alice.dev" },
        { "schema_name" => "users.bob.dev" }
      ]
    )

    roots = client.get_schema_tree
    users = roots.find { |node| node.name == "users" }
    refute_nil users
    assert_equal %w[alice bob], users.children.map(&:name)
  end

  def test_connection_get_schema_tree_shapes_database_default_rows
    cfg = Scratchbird::Config.new
    cfg.database = "main"
    conn = Scratchbird::Connection.allocate
    conn.instance_variable_set(:@config, cfg)
    conn.instance_variable_set(
      :@client,
      ConnectionMetadataClient.new(
        [
          { "schema_name" => "users.alice.dev" },
          { "schema_name" => "users.bob.dev" }
        ]
      )
    )
    conn.instance_variable_set(:@autocommit, true)
    conn.instance_variable_set(:@closed, false)

    rows = conn.get_schema_tree(expand_schema_parents: true)
    assert_equal(
      ["main", "main.default", "main.default.users", "main.default.users.alice", "main.default.users.alice.dev", "main.default.users.bob", "main.default.users.bob.dev"],
      rows.map { |row| row["node_path"] }
    )
  end

  private

  def build_client(rows:, config: Scratchbird::Config.new)
    MetadataClient.new(config, rows)
  end
end

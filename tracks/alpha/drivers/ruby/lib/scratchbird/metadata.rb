# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

module Scratchbird
  module Metadata
    SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
    TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
    COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
    INDEXES_QUERY = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
    INDEX_COLUMNS_QUERY = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
    CONSTRAINTS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
    PROCEDURES_QUERY = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
    FUNCTIONS_QUERY = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
    SCHEMA_FIELD_CANDIDATES = %w[
      schema_name
      table_schem
      table_schema
      schema
      SCHEMA_NAME
      TABLE_SCHEM
      TABLE_SCHEMA
      SCHEMA
    ].freeze

    class SchemaTreeNode
      attr_reader :name, :full_path, :children
      attr_accessor :terminal

      def initialize(name, full_path)
        @name = name
        @full_path = full_path
        @terminal = false
        @children = []
      end
    end

    def self.schemas_query
      SCHEMAS_QUERY
    end

    def self.tables_query
      TABLES_QUERY
    end

    def self.columns_query
      COLUMNS_QUERY
    end

    def self.indexes_query
      INDEXES_QUERY
    end

    def self.index_columns_query
      INDEX_COLUMNS_QUERY
    end

    def self.constraints_query
      CONSTRAINTS_QUERY
    end

    def self.procedures_query
      PROCEDURES_QUERY
    end

    def self.functions_query
      FUNCTIONS_QUERY
    end

    def self.schema_paths_for_navigation(rows_or_names, expand_schema_parents: false)
      base_paths = unique_schema_paths(rows_or_names)
      return base_paths unless expand_schema_parents

      expand_schema_parent_paths(base_paths)
    end

    def self.expand_schema_parent_paths(rows_or_names)
      out = []
      seen = {}

      each_schema_path(rows_or_names) do |schema_path|
        current = +""
        split_schema_path(schema_path).each do |segment|
          current = current.empty? ? segment : "#{current}.#{segment}"
          next if seen[current]

          seen[current] = true
          out << current
        end
      end

      out
    end

    def self.build_schema_tree(schema_paths)
      nodes_by_path = {}
      roots = []

      each_schema_path(schema_paths) do |schema_path|
        parent = nil
        path_parts = []

        split_schema_path(schema_path).each do |segment|
          path_parts << segment
          full_path = path_parts.join(".")

          node = nodes_by_path[full_path]
          unless node
            node = SchemaTreeNode.new(segment, full_path)
            nodes_by_path[full_path] = node
            if parent
              parent.children << node
            else
              roots << node
            end
          end

          parent = node
        end

        parent.terminal = true if parent
      end

      roots
    end

    def self.expand_schema_metadata_rows(rows)
      out = []
      seen = {}

      rows.each do |row|
        schema_path = read_schema_path(row)
        unless schema_path
          out << row
          next
        end

        current = +""
        segments = split_schema_path(schema_path)
        segments.each_with_index do |segment, idx|
          current = current.empty? ? segment : "#{current}.#{segment}"
          next if seen[current]

          seen[current] = true
          if idx == segments.length - 1
            out << row
          else
            out << synthetic_schema_row(row, current)
          end
        end
      end

      out
    end

    def self.build_database_default_metadata_rows(rows_or_names, database:, expand_schema_parents: false, default_branch: "default")
      database_name = database.to_s.strip
      raise ArgumentError, "database is required" if database_name.empty?

      default_name = default_branch.to_s.strip
      raise ArgumentError, "default_branch is required" if default_name.empty?

      schema_paths = schema_paths_for_navigation(rows_or_names, expand_schema_parents: expand_schema_parents)
      roots = build_schema_tree(schema_paths)
      rows = []

      database_path = database_name
      default_path = "#{database_path}.#{default_name}"

      rows << {
        "node_type" => "database",
        "node_name" => database_name,
        "node_path" => database_path,
        "parent_path" => nil,
        "schema_path" => nil,
        "terminal" => false
      }

      rows << {
        "node_type" => "schema",
        "node_name" => default_name,
        "node_path" => default_path,
        "parent_path" => database_path,
        "schema_path" => nil,
        "terminal" => false
      }

      append_tree_metadata_rows(rows, roots, default_path)
      rows
    end

    def self.append_tree_metadata_rows(out_rows, nodes, parent_node_path)
      nodes.each do |node|
        node_path = "#{parent_node_path}.#{node.name}"
        out_rows << {
          "node_type" => "schema",
          "node_name" => node.name,
          "node_path" => node_path,
          "parent_path" => parent_node_path,
          "schema_path" => node.full_path,
          "terminal" => node.terminal
        }
        append_tree_metadata_rows(out_rows, node.children, node_path)
      end
    end
    private_class_method :append_tree_metadata_rows

    def self.unique_schema_paths(rows_or_names)
      out = []
      seen = {}

      each_schema_path(rows_or_names) do |schema_path|
        next if seen[schema_path]

        seen[schema_path] = true
        out << schema_path
      end

      out
    end
    private_class_method :unique_schema_paths

    def self.each_schema_path(rows_or_names)
      return enum_for(:each_schema_path, rows_or_names) unless block_given?
      return if rows_or_names.nil?

      enumerated =
        if rows_or_names.is_a?(String) || rows_or_names.is_a?(Hash)
          [rows_or_names]
        elsif rows_or_names.respond_to?(:each)
          rows_or_names
        else
          [rows_or_names]
        end

      enumerated.each do |row_or_name|
        schema_path = read_schema_path(row_or_name)
        next unless schema_path

        yield schema_path
      end
    end
    private_class_method :each_schema_path

    def self.read_schema_path(row_or_name)
      return normalize_schema_path(row_or_name) if row_or_name.is_a?(String)

      return normalize_schema_path(row_or_name.to_s) if row_or_name.is_a?(Symbol)

      return read_schema_path_from_hash(row_or_name) if row_or_name.is_a?(Hash)

      nil
    end
    private_class_method :read_schema_path

    def self.read_schema_path_from_hash(row)
      SCHEMA_FIELD_CANDIDATES.each do |candidate|
        value = nil
        value = row[candidate] if row.key?(candidate)
        symbol = candidate.to_sym
        value = row[symbol] if value.nil? && row.key?(symbol)
        next unless value.is_a?(String)

        normalized = normalize_schema_path(value)
        return normalized if normalized
      end

      nil
    end
    private_class_method :read_schema_path_from_hash

    def self.normalize_schema_path(value)
      normalized = split_schema_path(value).join(".")
      return nil if normalized.empty?

      normalized
    end
    private_class_method :normalize_schema_path

    def self.split_schema_path(value)
      value.to_s.split(".").map(&:strip).reject(&:empty?)
    end
    private_class_method :split_schema_path

    def self.synthetic_schema_row(sample_row, schema_path)
      synthetic = {}
      sample_row.each_key do |key|
        synthetic[key] = nil
      end
      assign_schema_path(synthetic, schema_path)
      synthetic
    end
    private_class_method :synthetic_schema_row

    def self.assign_schema_path(row, schema_path)
      assigned = false
      SCHEMA_FIELD_CANDIDATES.each do |candidate|
        if row.key?(candidate)
          row[candidate] = schema_path
          assigned = true
        end
        symbol = candidate.to_sym
        if row.key?(symbol)
          row[symbol] = schema_path
          assigned = true
        end
      end
      return if assigned

      target_key = row.keys.any? { |key| key.is_a?(Symbol) } ? :schema_name : "schema_name"
      row[target_key] = schema_path
    end
    private_class_method :assign_schema_path
  end
end

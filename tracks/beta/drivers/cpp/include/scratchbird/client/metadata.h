#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace scratchbird {
namespace client {

struct MetadataSchemaTreeNode {
    std::string name;
    std::string full_path;
    bool terminal{false};
    std::vector<std::unique_ptr<MetadataSchemaTreeNode>> children;
};

struct MetadataSchemaTree {
    std::string database;
    std::vector<std::unique_ptr<MetadataSchemaTreeNode>> schemas;
};

enum class MetadataTreeRowKind : uint8_t {
    DATABASE = 0,
    SCHEMA = 1
};

struct MetadataSchemaTreeRow {
    MetadataTreeRowKind kind{MetadataTreeRowKind::SCHEMA};
    std::string database;
    std::string parent_path;
    std::string path;
    std::string name;
    bool terminal{false};
    bool top_level_branch{false};
};

std::vector<std::string> metadataSchemaPathsForNavigation(
    const std::vector<std::string>& schema_names,
    bool expand_schema_parents);

MetadataSchemaTree buildMetadataSchemaTree(
    const std::vector<std::string>& schema_names,
    const std::string& database,
    bool expand_schema_parents);

std::vector<MetadataSchemaTreeRow> buildMetadataSchemaTreeRows(
    const std::vector<std::string>& schema_names,
    const std::string& database,
    bool expand_schema_parents);

} // namespace client
} // namespace scratchbird

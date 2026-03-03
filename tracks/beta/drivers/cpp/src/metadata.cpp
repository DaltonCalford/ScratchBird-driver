#include "scratchbird/client/metadata.h"

#include <cctype>
#include <string_view>
#include <unordered_map>
#include <unordered_set>

namespace scratchbird {
namespace client {

namespace {

std::string trim(std::string_view value) {
    size_t start = 0;
    while (start < value.size() && std::isspace(static_cast<unsigned char>(value[start])) != 0) {
        ++start;
    }
    size_t end = value.size();
    while (end > start && std::isspace(static_cast<unsigned char>(value[end - 1])) != 0) {
        --end;
    }
    return std::string(value.substr(start, end - start));
}

std::vector<std::string> splitSchemaPath(const std::string& schema_name) {
    std::vector<std::string> segments;
    size_t start = 0;
    while (start <= schema_name.size()) {
        size_t dot = schema_name.find('.', start);
        size_t end = (dot == std::string::npos) ? schema_name.size() : dot;
        std::string segment = trim(std::string_view(schema_name).substr(start, end - start));
        if (!segment.empty()) {
            segments.push_back(segment);
        }
        if (dot == std::string::npos) {
            break;
        }
        start = dot + 1;
    }
    return segments;
}

std::string normalizeSchemaPath(const std::string& schema_name) {
    std::vector<std::string> parts = splitSchemaPath(schema_name);
    std::string normalized;
    for (size_t i = 0; i < parts.size(); ++i) {
        if (i > 0) {
            normalized.push_back('.');
        }
        normalized.append(parts[i]);
    }
    return normalized;
}

void appendRowsDepthFirst(const MetadataSchemaTreeNode& node,
                          const std::string& database_name,
                          const std::string& parent_path,
                          bool top_level,
                          std::vector<MetadataSchemaTreeRow>* rows) {
    if (!rows) {
        return;
    }

    rows->push_back(MetadataSchemaTreeRow{
        MetadataTreeRowKind::SCHEMA,
        database_name,
        parent_path,
        node.full_path,
        node.name,
        node.terminal,
        top_level});

    for (const auto& child : node.children) {
        if (!child) {
            continue;
        }
        appendRowsDepthFirst(*child, database_name, node.full_path, false, rows);
    }
}

} // namespace

std::vector<std::string> metadataSchemaPathsForNavigation(
    const std::vector<std::string>& schema_names,
    bool expand_schema_parents) {
    std::vector<std::string> out;
    std::unordered_set<std::string> seen;

    for (const std::string& raw : schema_names) {
        std::string normalized = normalizeSchemaPath(raw);
        if (normalized.empty()) {
            continue;
        }

        if (!expand_schema_parents) {
            if (seen.insert(normalized).second) {
                out.push_back(normalized);
            }
            continue;
        }

        std::string current;
        std::vector<std::string> parts = splitSchemaPath(normalized);
        for (size_t i = 0; i < parts.size(); ++i) {
            if (!current.empty()) {
                current.push_back('.');
            }
            current.append(parts[i]);
            if (seen.insert(current).second) {
                out.push_back(current);
            }
        }
    }

    return out;
}

MetadataSchemaTree buildMetadataSchemaTree(
    const std::vector<std::string>& schema_names,
    const std::string& database,
    bool expand_schema_parents) {
    MetadataSchemaTree tree;
    tree.database = trim(database);

    std::vector<std::string> schema_paths =
        metadataSchemaPathsForNavigation(schema_names, expand_schema_parents);
    std::unordered_set<std::string> terminal_paths(schema_paths.begin(), schema_paths.end());
    std::unordered_map<std::string, MetadataSchemaTreeNode*> nodes_by_path;

    for (const std::string& schema_path : schema_paths) {
        std::vector<std::string> parts = splitSchemaPath(schema_path);
        if (parts.empty()) {
            continue;
        }

        MetadataSchemaTreeNode* parent = nullptr;
        std::string current_path;
        for (size_t i = 0; i < parts.size(); ++i) {
            if (!current_path.empty()) {
                current_path.push_back('.');
            }
            current_path.append(parts[i]);

            MetadataSchemaTreeNode* node = nullptr;
            auto existing = nodes_by_path.find(current_path);
            if (existing == nodes_by_path.end()) {
                auto created = std::make_unique<MetadataSchemaTreeNode>();
                created->name = parts[i];
                created->full_path = current_path;
                node = created.get();
                nodes_by_path[current_path] = node;

                if (parent == nullptr) {
                    tree.schemas.push_back(std::move(created));
                } else {
                    parent->children.push_back(std::move(created));
                }
            } else {
                node = existing->second;
            }

            if (terminal_paths.find(current_path) != terminal_paths.end()) {
                node->terminal = true;
            }
            parent = node;
        }
    }

    return tree;
}

std::vector<MetadataSchemaTreeRow> buildMetadataSchemaTreeRows(
    const std::vector<std::string>& schema_names,
    const std::string& database,
    bool expand_schema_parents) {
    MetadataSchemaTree tree = buildMetadataSchemaTree(schema_names, database, expand_schema_parents);

    std::string database_name = tree.database.empty() ? std::string("default") : tree.database;
    std::vector<MetadataSchemaTreeRow> rows;
    rows.push_back(MetadataSchemaTreeRow{
        MetadataTreeRowKind::DATABASE,
        database_name,
        std::string(),
        database_name,
        database_name,
        false,
        false});

    for (const auto& root : tree.schemas) {
        if (!root) {
            continue;
        }
        appendRowsDepthFirst(*root, database_name, database_name, true, &rows);
    }

    return rows;
}

} // namespace client
} // namespace scratchbird

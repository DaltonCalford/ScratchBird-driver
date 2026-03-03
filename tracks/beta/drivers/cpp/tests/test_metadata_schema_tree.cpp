#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include "scratchbird/client/metadata.h"

namespace {

const scratchbird::client::MetadataSchemaTreeRow* findRowByPath(
    const std::vector<scratchbird::client::MetadataSchemaTreeRow>& rows,
    const std::string& path) {
    for (const auto& row : rows) {
        if (row.path == path) {
            return &row;
        }
    }
    return nullptr;
}

const scratchbird::client::MetadataSchemaTreeNode* findNodeByPath(
    const std::vector<std::unique_ptr<scratchbird::client::MetadataSchemaTreeNode>>& nodes,
    const std::string& path) {
    for (const auto& node : nodes) {
        if (!node) {
            continue;
        }
        if (node->full_path == path) {
            return node.get();
        }
        const auto* nested = findNodeByPath(node->children, path);
        if (nested != nullptr) {
            return nested;
        }
    }
    return nullptr;
}

} // namespace

TEST(MetadataSchemaTreeTest, TreeRowsStartAtDatabaseAndExposeTopBranches) {
    std::vector<scratchbird::client::MetadataSchemaTreeRow> rows =
        scratchbird::client::buildMetadataSchemaTreeRows(
            {"sys", "users.alice.dev", "users.bob.dev", "analytics.prod"},
            "main",
            false);

    ASSERT_FALSE(rows.empty());
    EXPECT_EQ(rows[0].kind, scratchbird::client::MetadataTreeRowKind::DATABASE);
    EXPECT_EQ(rows[0].path, "main");

    std::vector<std::string> top_branches;
    for (const auto& row : rows) {
        if (row.kind == scratchbird::client::MetadataTreeRowKind::SCHEMA &&
            row.top_level_branch) {
            top_branches.push_back(row.path);
        }
    }

    EXPECT_EQ(top_branches, (std::vector<std::string>{"sys", "users", "analytics"}));
}

TEST(MetadataSchemaTreeTest, ParentExpansionAddsDottedSchemaAncestors) {
    std::vector<std::string> expanded = scratchbird::client::metadataSchemaPathsForNavigation(
        {"users.alice.dev", "users.bob.dev", "users.bob.dev"},
        true);

    EXPECT_EQ(
        expanded,
        (std::vector<std::string>{"users", "users.alice", "users.alice.dev", "users.bob", "users.bob.dev"}));
}

TEST(MetadataSchemaTreeTest, ParentDoesNotAllowDuplicateChildNames) {
    scratchbird::client::MetadataSchemaTree tree = scratchbird::client::buildMetadataSchemaTree(
        {"users.bob.dev", "users.bob.dev"},
        "main",
        false);

    const auto* bob = findNodeByPath(tree.schemas, "users.bob");
    ASSERT_NE(bob, nullptr);
    ASSERT_EQ(bob->children.size(), 1U);
    EXPECT_EQ(bob->children.front()->name, "dev");
    EXPECT_EQ(bob->children.front()->full_path, "users.bob.dev");
}

TEST(MetadataSchemaTreeTest, SameLeafNameUnderDifferentParentsIsPreserved) {
    std::vector<scratchbird::client::MetadataSchemaTreeRow> rows =
        scratchbird::client::buildMetadataSchemaTreeRows(
            {"users.alice.orders", "users.bob.orders"},
            "main",
            false);

    const auto* alice_orders = findRowByPath(rows, "users.alice.orders");
    const auto* bob_orders = findRowByPath(rows, "users.bob.orders");
    ASSERT_NE(alice_orders, nullptr);
    ASSERT_NE(bob_orders, nullptr);
    EXPECT_EQ(alice_orders->name, "orders");
    EXPECT_EQ(bob_orders->name, "orders");
    EXPECT_NE(alice_orders->parent_path, bob_orders->parent_path);
}

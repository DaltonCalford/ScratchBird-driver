// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import XCTest
@testable import ScratchBird

final class MetadataRecursiveSchemaTests: XCTestCase {
    func testTreeRowsStartAtDefaultDatabaseAndExposeTopBranches() {
        let rows = buildMetadataSchemaTreeRows(
            ["sys", "users.alice.dev", "users.bob.dev", "analytics.prod"],
            database: "",
            expandSchemaParents: false
        )

        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(rows[0].kind, .database)
        XCTAssertEqual(rows[0].path, "default")

        let topBranches = rows
            .filter { $0.kind == .schema && $0.topLevelBranch }
            .map { $0.path }
        XCTAssertEqual(topBranches, ["sys", "users", "analytics"])
    }

    func testParentExpansionAddsDottedSchemaAncestors() {
        let expanded = metadataSchemaPathsForNavigation(
            ["users.alice.dev", "users.bob.dev", "users.bob.dev"],
            expandSchemaParents: true
        )

        XCTAssertEqual(
            expanded,
            ["users", "users.alice", "users.alice.dev", "users.bob", "users.bob.dev"]
        )
    }

    func testParentDoesNotAllowDuplicateChildNames() {
        let tree = buildMetadataSchemaTree(
            ["users.bob.dev", "users.bob.dev"],
            database: "main",
            expandSchemaParents: false
        )

        let bob = findNodeByPath(tree.schemas, "users.bob")
        XCTAssertNotNil(bob)
        XCTAssertEqual(bob?.children.count, 1)
        XCTAssertEqual(bob?.children.first?.name, "dev")
        XCTAssertEqual(bob?.children.first?.path, "users.bob.dev")
    }

    func testSameLeafNameUnderDifferentParentsIsPreserved() {
        let rows = buildMetadataSchemaTreeRows(
            ["users.alice.orders", "users.bob.orders"],
            database: "main",
            expandSchemaParents: false
        )

        let aliceOrders = findRowByPath(rows, "users.alice.orders")
        let bobOrders = findRowByPath(rows, "users.bob.orders")
        XCTAssertNotNil(aliceOrders)
        XCTAssertNotNil(bobOrders)
        XCTAssertEqual(aliceOrders?.name, "orders")
        XCTAssertEqual(bobOrders?.name, "orders")
        XCTAssertNotEqual(aliceOrders?.parentPath, bobOrders?.parentPath)
    }

    private func findRowByPath(_ rows: [ScratchBirdMetadataSchemaTreeRow], _ path: String) -> ScratchBirdMetadataSchemaTreeRow? {
        for row in rows where row.path == path {
            return row
        }
        return nil
    }

    private func findNodeByPath(_ nodes: [ScratchBirdMetadataSchemaTreeNode], _ path: String) -> ScratchBirdMetadataSchemaTreeNode? {
        for node in nodes {
            if node.path == path {
                return node
            }
            if let nested = findNodeByPath(node.children, path) {
                return nested
            }
        }
        return nil
    }
}

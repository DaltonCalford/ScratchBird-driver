// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import XCTest
@testable import ScratchBird

final class IntegrationTests: XCTestCase {
    func testIntegrationConnectAndBasicQuery() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            let result = try await conn.query("SELECT 1")
            XCTAssertFalse(result.rows.isEmpty)
            XCTAssertFalse(result.rows[0].isEmpty)
            XCTAssertEqual(asInt(result.rows[0][0]), 1)
        }
    }

    func testIntegrationManagerProxyConnectAndBasicQuery() async throws {
        let config = try managerIntegrationConfig()
        try await withConnection(config) { conn in
            let result = try await conn.query("SELECT 1")
            XCTAssertFalse(result.rows.isEmpty)
            XCTAssertFalse(result.rows[0].isEmpty)
            XCTAssertEqual(asInt(result.rows[0][0]), 1)
        }
    }

    func testIntegrationParameterizedQueryAndTypeRoundTrip() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            let result = try await conn.query(
                "SELECT ?::INTEGER, ?::DOUBLE, ?::VARCHAR, ?::BOOLEAN",
                [42, 3.5, "scratchbird-swift", true]
            )
            XCTAssertFalse(result.rows.isEmpty)
            XCTAssertEqual(asInt(result.rows[0][0]), 42)
            guard let doubleValue = result.rows[0][1] as? Double else {
                XCTFail("Expected second column to decode as Double")
                return
            }
            XCTAssertEqual(doubleValue, 3.5, accuracy: 0.000001)
            XCTAssertEqual(result.rows[0][2] as? String, "scratchbird-swift")
            XCTAssertEqual(result.rows[0][3] as? Bool, true)
        }
    }

    func testIntegrationTransactionAndSavepointLifecycle() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            try await conn.begin()
            try await conn.savepoint("sp_swift_live")
            try await conn.rollbackToSavepoint("sp_swift_live")
            try await conn.releaseSavepoint("sp_swift_live")
            try await conn.commit()

            try await conn.begin()
            try await conn.rollback()
        }
    }

    func testIntegrationMetadataWrappersAndSchemaTree() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            let schemas = try await conn.metadataSchemas()
            XCTAssertFalse(schemas.columns.isEmpty)

            let tables = try await conn.metadataTables()
            XCTAssertFalse(tables.columns.isEmpty)

            let treeRows = try await conn.metadataSchemaTreeRows(expandSchemaParents: true)
            XCTAssertFalse(treeRows.isEmpty)
            XCTAssertEqual(treeRows[0].kind, .database)
            XCTAssertEqual(treeRows[0].path, expectedDatabaseName(config.database))
        }
    }

    func testIntegrationTypedSqlStateErrorMapping() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            do {
                _ = try await conn.query("SELECT FROM")
                XCTFail("Expected syntax failure")
            } catch let error as ScratchBirdProgrammingException {
                XCTAssertEqual(error.sqlState?.prefix(2), "42")
            } catch {
                XCTFail("Expected ScratchBirdProgrammingException, got \(error)")
            }

            do {
                _ = try await conn.query("SELECT ?::INTEGER", ["not-an-int"])
                XCTFail("Expected data conversion failure")
            } catch let error as ScratchBirdDataException {
                XCTAssertEqual(error.sqlState?.prefix(2), "22")
            } catch {
                XCTFail("Expected ScratchBirdDataException, got \(error)")
            }
        }
    }

    func testIntegrationConnectionRemainsUsableAfterServerError() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            do {
                _ = try await conn.query("SELECT FROM")
                XCTFail("Expected syntax failure")
            } catch {
                // expected
            }

            let result = try await conn.query("SELECT 7")
            XCTAssertFalse(result.rows.isEmpty)
            XCTAssertEqual(asInt(result.rows[0][0]), 7)
        }
    }

    func testIntegrationPingRoundTrip() async throws {
        let config = try integrationConfig()
        try await withConnection(config) { conn in
            try await conn.ping()
            let result = try await conn.query("SELECT 2")
            XCTAssertFalse(result.rows.isEmpty)
            XCTAssertEqual(asInt(result.rows[0][0]), 2)
        }
    }

    func testIntegrationKeepaliveValidationRunsForIdleConnection() async throws {
        var config = try integrationConfig()
        config.keepaliveIntervalMs = 20
        config.keepaliveMaxIdleBeforeCheckMs = 0
        config.keepaliveValidationTimeoutMs = 250

        try await withConnection(config) { conn in
            try await Task.sleep(nanoseconds: 180_000_000)
            let stats = conn.debugResilienceStats()
            XCTAssertGreaterThanOrEqual(stats.keepaliveValidationAttempts, 1)
            XCTAssertGreaterThanOrEqual(stats.keepaliveValidationSuccesses, 1)
            XCTAssertEqual(stats.keepaliveRegisteredConnections, 1)
        }
    }

    func testIntegrationLeakDetectorReportsLongHeldConnection() async throws {
        var config = try integrationConfig()
        config.leakDetectionThresholdMs = 20
        config.leakDetectionCheckIntervalMs = 10

        try await withConnection(config) { conn in
            try await Task.sleep(nanoseconds: 140_000_000)
            let stats = conn.debugResilienceStats()
            XCTAssertGreaterThanOrEqual(stats.activeLeakCheckouts, 1)
            XCTAssertGreaterThanOrEqual(stats.detectedLeaks, 1)
        }
    }

    func testIntegrationResilienceAcrossMultipleConnections() async throws {
        var config = try integrationConfig()
        config.keepaliveIntervalMs = 20
        config.keepaliveMaxIdleBeforeCheckMs = 0
        config.keepaliveValidationTimeoutMs = 250
        config.leakDetectionThresholdMs = 20
        config.leakDetectionCheckIntervalMs = 10

        var connections: [ScratchBirdConnection] = []
        do {
            for _ in 0..<3 {
                connections.append(try await ScratchBirdConnection.connect(config))
            }

            try await Task.sleep(nanoseconds: 180_000_000)

            for conn in connections {
                let stats = conn.debugResilienceStats()
                XCTAssertGreaterThanOrEqual(stats.keepaliveValidationAttempts, 1)
                XCTAssertGreaterThanOrEqual(stats.keepaliveValidationSuccesses, 1)
                XCTAssertGreaterThanOrEqual(stats.detectedLeaks, 1)
                let result = try await conn.query("SELECT 11")
                XCTAssertFalse(result.rows.isEmpty)
                XCTAssertEqual(asInt(result.rows[0][0]), 11)
            }
        } catch {
            for conn in connections {
                try? await conn.close()
            }
            throw error
        }

        for conn in connections {
            try? await conn.close()
        }
    }

    func testIntegrationAuthFailureMapsTypedAuthorizationException() async throws {
        let config = try badAuthIntegrationConfig()
        do {
            _ = try await ScratchBirdConnection.connect(config)
            XCTFail("Expected authentication failure")
        } catch let error as ScratchBirdAuthorizationException {
            XCTAssertEqual(error.sqlState?.prefix(2), "28")
        }
    }

    func testIntegrationPoolCheckoutChurnAndReuse() async throws {
        var config = try integrationConfig()
        config.keepaliveIntervalMs = 20
        config.keepaliveMaxIdleBeforeCheckMs = 0
        config.leakDetectionThresholdMs = 20
        config.leakDetectionCheckIntervalMs = 10

        let pool = ScratchBirdConnectionPool(config: config, maxSize: 2)

        do {
            for i in 0..<8 {
                let value = i
                let result = try await pool.withConnection { conn in
                    try await conn.query("SELECT ?::INTEGER", [value])
                }
                XCTAssertFalse(result.rows.isEmpty)
                XCTAssertEqual(asInt(result.rows[0][0]), value)
            }

            let stats = pool.debugStats()
            XCTAssertEqual(stats.maxSize, 2)
            XCTAssertLessThanOrEqual(stats.createdConnections, 2)
            XCTAssertLessThanOrEqual(stats.idleConnections, 2)
            await pool.close()
        } catch {
            await pool.close()
            throw error
        }
    }

    func testIntegrationPoolExhaustionRaisesOperationalException() async throws {
        let config = try integrationConfig()
        let pool = ScratchBirdConnectionPool(config: config, maxSize: 1)

        do {
            let first = try await pool.acquire()
            do {
                _ = try await pool.acquire()
                XCTFail("Expected pool exhaustion error")
            } catch let error as ScratchBirdOperationalException {
                XCTAssertTrue(error.message.contains("exhausted"))
            }
            await pool.release(first)
            await pool.close()
        } catch {
            await pool.close()
            throw error
        }
    }

    private func integrationConfig() throws -> ScratchBirdConfig {
        let env = ProcessInfo.processInfo.environment
        let dsn = env["SCRATCHBIRD_TEST_DSN"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        try XCTSkipIf(dsn.isEmpty, "SCRATCHBIRD_TEST_DSN not set")
        return ScratchBirdConfig(dsn: dsn)
    }

    private func managerIntegrationConfig() throws -> ScratchBirdConfig {
        let env = ProcessInfo.processInfo.environment
        let dsn = env["SCRATCHBIRD_TEST_MANAGER_DSN"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        try XCTSkipIf(dsn.isEmpty, "SCRATCHBIRD_TEST_MANAGER_DSN not set")
        let config = ScratchBirdConfig(dsn: dsn)
        try XCTSkipIf(
            config.frontDoorMode != "manager_proxy",
            "SCRATCHBIRD_TEST_MANAGER_DSN must include front_door_mode=manager_proxy"
        )
        return config
    }

    private func badAuthIntegrationConfig() throws -> ScratchBirdConfig {
        let env = ProcessInfo.processInfo.environment
        let dsn = env["SCRATCHBIRD_TEST_BAD_AUTH_DSN"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        try XCTSkipIf(dsn.isEmpty, "SCRATCHBIRD_TEST_BAD_AUTH_DSN not set")
        return ScratchBirdConfig(dsn: dsn)
    }

    private func withConnection(
        _ config: ScratchBirdConfig,
        body: (ScratchBirdConnection) async throws -> Void
    ) async throws {
        let conn = try await ScratchBirdConnection.connect(config)
        do {
            try await body(conn)
            try await conn.close()
        } catch {
            try? await conn.close()
            throw error
        }
    }

    private func asInt(_ value: Any?) -> Int {
        if let value = value as? Int { return value }
        if let value = value as? Int16 { return Int(value) }
        if let value = value as? Int32 { return Int(value) }
        if let value = value as? Int64 { return Int(value) }
        if let value = value as? UInt8 { return Int(value) }
        XCTFail("Expected integer value, got \(String(describing: value))")
        return -1
    }

    private func expectedDatabaseName(_ configuredDatabase: String) -> String {
        let trimmed = configuredDatabase.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "default" : trimmed
    }
}

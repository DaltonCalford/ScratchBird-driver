// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import XCTest
@testable import ScratchBird

final class ConfigTests: XCTestCase {
    func testParseDsn() throws {
        let cfg = ScratchBirdConfig(dsn: "scratchbird://user:pass@localhost:3092/db")
        XCTAssertEqual(cfg.user, "user")
        XCTAssertEqual(cfg.password, "pass")
        XCTAssertEqual(cfg.database, "db")
    }

    func testParseManagerProxyParams() throws {
        let cfg = ScratchBirdConfig(
            dsn: "scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7"
        )
        XCTAssertEqual(cfg.frontDoorMode, "manager_proxy")
        XCTAssertEqual(cfg.managerAuthToken, "token")
        XCTAssertEqual(cfg.managerClientFlags, 7)
    }

    func testNormalizeFrontDoorModeRejectsInvalid() throws {
        XCTAssertThrowsError(try normalizeFrontDoorMode("invalid"))
    }

    func testParseTlsOptions() throws {
        let cfg = ScratchBirdConfig(
            dsn: "scratchbird://user:pass@localhost:3092/db?sslmode=verify-full&sslrootcert=/tmp/ca.pem&sslcert=/tmp/client.pem&sslkey=/tmp/client.key&sslpassword=secret"
        )
        XCTAssertEqual(cfg.sslmode, "verify-full")
        XCTAssertEqual(cfg.sslrootcert, "/tmp/ca.pem")
        XCTAssertEqual(cfg.sslcert, "/tmp/client.pem")
        XCTAssertEqual(cfg.sslkey, "/tmp/client.key")
        XCTAssertEqual(cfg.sslpassword, "secret")
    }

    func testNormalizeSslMode() throws {
        XCTAssertEqual(try normalizeSslMode("verify_ca"), "verify-ca")
        XCTAssertEqual(try normalizeSslMode("verify-full"), "verify-full")
        XCTAssertEqual(try normalizeSslMode("require"), "require")
        XCTAssertThrowsError(try normalizeSslMode("invalid"))
    }

    func testConnectRejectsDisableSslMode() async {
        let config = ScratchBirdConfig(
            database: "mydb",
            user: "user",
            sslmode: "disable"
        )

        do {
            _ = try await ScratchBirdConnection.connect(config)
            XCTFail("Expected connect to reject sslmode=disable")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "ScratchBird")
            XCTAssertTrue(nsError.localizedDescription.contains("TLS is required"))
        }
    }

    func testConnectRejectsBinaryTransferDisabled() async {
        let config = ScratchBirdConfig(
            database: "mydb",
            user: "user",
            binaryTransfer: false
        )

        do {
            _ = try await ScratchBirdConnection.connect(config)
            XCTFail("Expected connect to reject binary_transfer=false")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "ScratchBird")
            XCTAssertTrue(nsError.localizedDescription.contains("binary_transfer=false"))
        }
    }

    func testConnectRejectsUnsupportedCompression() async {
        let config = ScratchBirdConfig(
            database: "mydb",
            user: "user",
            compression: "zstd"
        )

        do {
            _ = try await ScratchBirdConnection.connect(config)
            XCTFail("Expected connect to reject compression=zstd")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "ScratchBird")
            XCTAssertTrue(nsError.localizedDescription.contains("compression=zstd"))
        }
    }
}

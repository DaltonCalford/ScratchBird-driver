// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import XCTest
@testable import ScratchBird

final class TxnExecParityTests: XCTestCase {
    func testValidateTxnBeginOptionsAcceptsSupportedValues() throws {
        XCTAssertNoThrow(try validateTxnBeginOptions(
            isolationLevel: isolationSerializable,
            accessMode: 1,
            autocommitMode: 1
        ))
    }

    func testValidateTxnBeginOptionsRejectsUnsupportedIsolation() throws {
        XCTAssertThrowsError(try validateTxnBeginOptions(
            isolationLevel: isolationSerializable + 1,
            accessMode: nil,
            autocommitMode: nil
        ))
    }

    func testValidateTxnBeginOptionsRejectsUnsupportedAccessMode() throws {
        XCTAssertThrowsError(try validateTxnBeginOptions(
            isolationLevel: nil,
            accessMode: 2,
            autocommitMode: nil
        ))
    }

    func testValidateTxnBeginOptionsRejectsUnsupportedAutocommitMode() throws {
        XCTAssertThrowsError(try validateTxnBeginOptions(
            isolationLevel: nil,
            accessMode: nil,
            autocommitMode: 2
        ))
    }

    func testNormalizeSavepointNameTrimsAndRejectsBlank() throws {
        XCTAssertEqual(try normalizeSavepointName("  sp_main\t"), "sp_main")
        XCTAssertThrowsError(try normalizeSavepointName("   \n"))
    }

    func testRequireCancelableSequenceRejectsZero() throws {
        XCTAssertEqual(try requireCancelableSequence(17), 17)
        XCTAssertThrowsError(try requireCancelableSequence(0))
    }

    func testNormalizePortalResumeMaxRowsClampsValues() throws {
        XCTAssertEqual(normalizePortalResumeMaxRows(fetchSize: -3), 0)
        XCTAssertEqual(normalizePortalResumeMaxRows(fetchSize: 0), 0)
        XCTAssertEqual(normalizePortalResumeMaxRows(fetchSize: 128), 128)
        XCTAssertEqual(normalizePortalResumeMaxRows(fetchSize: Int(UInt32.max) + 17), UInt32.max)
    }

    func testBuildTxnBeginPayloadEncodesFlagsAndOptions() throws {
        let flags = txnFlagHasIsolation | txnFlagHasAccess | txnFlagHasDeferrable | txnFlagHasWait | txnFlagHasTimeout | txnFlagHasAutocommit
        let payload = buildTxnBeginPayload(
            flags: flags,
            conflictAction: 2,
            autocommitMode: 1,
            isolationLevel: isolationRepeatableRead,
            accessMode: 1,
            deferrable: 1,
            waitMode: 1,
            timeoutMs: 9000
        )

        XCTAssertEqual(payload.count, 12)
        XCTAssertEqual(readUInt16LE(payload, 0), flags)
        XCTAssertEqual(payload[2], 2)
        XCTAssertEqual(payload[3], 1)
        XCTAssertEqual(payload[4], isolationRepeatableRead)
        XCTAssertEqual(payload[5], 1)
        XCTAssertEqual(payload[6], 1)
        XCTAssertEqual(payload[7], 1)
        XCTAssertEqual(readUInt32LE(payload, 8), 9000)
    }

    func testBuildTxnCommitRollbackAndSavepointPayloads() throws {
        XCTAssertEqual(buildTxnCommitPayload(flags: 3), Data([3, 0, 0, 0]))
        XCTAssertEqual(buildTxnRollbackPayload(flags: 4), Data([4, 0, 0, 0]))

        let savepoint = buildTxnSavepointPayload(name: "sp1")
        XCTAssertEqual(readUInt32LE(savepoint, 0), 3)
        XCTAssertEqual(String(data: savepoint.subdata(in: 4..<7), encoding: .utf8), "sp1")
    }

    func testBuildExecuteAndCancelPayloads() throws {
        let execute = buildExecutePayload(portal: "p1", maxRows: 42)
        XCTAssertEqual(readUInt32LE(execute, 0), 2)
        XCTAssertEqual(String(data: execute.subdata(in: 4..<6), encoding: .utf8), "p1")
        XCTAssertEqual(readUInt32LE(execute, 6), 42)

        let cancel = buildCancelPayload(cancelType: 0, targetSequence: 77)
        XCTAssertEqual(readUInt32LE(cancel, 0), 0)
        XCTAssertEqual(readUInt32LE(cancel, 4), 77)
    }

    private func readUInt16LE(_ data: Data, _ offset: Int) -> UInt16 {
        UInt16(littleEndian: data.subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt16.self) })
    }

    private func readUInt32LE(_ data: Data, _ offset: Int) -> UInt32 {
        UInt32(littleEndian: data.subdata(in: offset..<(offset + 4)).withUnsafeBytes { $0.load(as: UInt32.self) })
    }
}

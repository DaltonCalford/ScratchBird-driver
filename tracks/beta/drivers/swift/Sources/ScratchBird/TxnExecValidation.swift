// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

func validateTxnBeginOptions(
    isolationLevel: UInt8?,
    accessMode: UInt8?,
    autocommitMode: UInt8?
) throws {
    if let isolationLevel, isolationLevel > isolationSerializable {
        throw NSError(
            domain: "ScratchBird",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "isolation level \(isolationLevel) is not supported"]
        )
    }
    if let accessMode, accessMode > 1 {
        throw NSError(
            domain: "ScratchBird",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "access mode \(accessMode) is not supported"]
        )
    }
    if let autocommitMode, autocommitMode > 1 {
        throw NSError(
            domain: "ScratchBird",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "autocommit mode \(autocommitMode) is not supported"]
        )
    }
}

func normalizeSavepointName(_ name: String) throws -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        throw NSError(
            domain: "ScratchBird",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "savepoint name is required"]
        )
    }
    return trimmed
}

func requireCancelableSequence(_ sequence: UInt32) throws -> UInt32 {
    if sequence == 0 {
        throw NSError(
            domain: "ScratchBird",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "No active query to cancel"]
        )
    }
    return sequence
}

func normalizePortalResumeMaxRows(fetchSize: Int) -> UInt32 {
    if fetchSize <= 0 {
        return 0
    }
    if fetchSize >= Int(UInt32.max) {
        return UInt32.max
    }
    return UInt32(fetchSize)
}

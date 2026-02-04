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
}

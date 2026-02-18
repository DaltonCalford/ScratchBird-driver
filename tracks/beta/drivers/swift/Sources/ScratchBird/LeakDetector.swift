// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

final class LeakDetector {
    struct Config {
        var thresholdMs: Int = 30_000
        var captureStackTrace: Bool = false
        var checkIntervalMs: Int = 10_000
    }

    final class CheckoutInfo {
        let checkoutTime = Date()
        let stackTrace: String?
        let metadata: [String: String]

        init(metadata: [String: String], captureStackTrace: Bool) {
            self.metadata = metadata
            self.stackTrace = captureStackTrace ? Thread.callStackSymbols.joined(separator: "\n") : nil
        }

        func heldDurationMs() -> Int {
            return Int(Date().timeIntervalSince(checkoutTime) * 1000)
        }
    }

    final class Guard {
        private var released = false
        private let detector: LeakDetector
        private let connectionId: String

        init(detector: LeakDetector, connectionId: String) {
            self.detector = detector
            self.connectionId = connectionId
        }

        func release() {
            if released { return }
            released = true
            detector.checkin(connectionId: connectionId)
        }
    }

    private let config: Config
    private let queue = DispatchQueue(label: "scratchbird.leakdetector")
    private var checkouts: [String: CheckoutInfo] = [:]
    private var timer: DispatchSourceTimer?

    init(config: Config = Config()) {
        self.config = config
    }

    func start() {
        if timer != nil { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(config.checkIntervalMs), repeating: .milliseconds(config.checkIntervalMs))
        timer.setEventHandler { [weak self] in
            self?.checkLeaks()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func checkout(connectionId: String, metadata: [String: String]) -> Guard {
        let info = CheckoutInfo(metadata: metadata, captureStackTrace: config.captureStackTrace)
        queue.sync {
            checkouts[connectionId] = info
        }
        return Guard(detector: self, connectionId: connectionId)
    }

    func checkin(connectionId: String) {
        queue.sync {
            checkouts.removeValue(forKey: connectionId)
        }
    }

    private func checkLeaks() {
        for (connId, info) in checkouts {
            if info.heldDurationMs() > config.thresholdMs {
                print("POSSIBLE CONNECTION LEAK: conn=\(connId) held=\(info.heldDurationMs())ms")
            }
        }
    }
}

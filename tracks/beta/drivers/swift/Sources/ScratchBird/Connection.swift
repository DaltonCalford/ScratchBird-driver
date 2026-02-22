// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

public struct ScratchBirdColumn {
    public let name: String
    public let typeOid: UInt32
    public let format: UInt16
}

public struct ScratchBirdResult {
    public let rows: [[Any?]]
    public let columns: [ScratchBirdColumn]
}

public struct NotificationMessage {
    public let processId: UInt32
    public let channel: String
    public let payload: Data
    public let changeType: String?
    public let rowId: UInt64?
}

public struct QueryPlanMessage {
    public let format: UInt32
    public let planningTimeUs: UInt64
    public let estimatedRows: UInt64
    public let estimatedCost: UInt64
    public let plan: Data
}

public struct SblrCompiledMessage {
    public let hash: UInt64
    public let version: UInt32
    public let bytecode: Data
}

private let managerProtocolMagic: UInt32 = 0x42444253 // SBDB
private let managerProtocolVersion: UInt16 = 0x0101
private let managerHeaderSize = 12
private let managerMaxPayloadSize: UInt32 = 16 * 1024 * 1024
private let mcpProtocolVersion: UInt16 = 0x0100

private let mcpMsgConnectResponse: UInt8 = 0x02
private let mcpMsgAuthChallenge: UInt8 = 0x12
private let mcpMsgAuthResponse: UInt8 = 0x11
private let mcpMsgStatusResponse: UInt8 = 0x64
private let mcpMsgHello: UInt8 = 0x65
private let mcpMsgAuthStart: UInt8 = 0x66
private let mcpMsgAuthContinue: UInt8 = 0x67
private let mcpMsgDbConnect: UInt8 = 0x69
private let mcpAuthMethodToken: UInt8 = 4

public final class ScratchBirdConnection {
    private let config: ScratchBirdConfig
    private let socket: ScratchBirdSocket
    private var sequence: UInt32 = 0
    private var lastQuerySequence: UInt32 = 0
    private var attachmentId = Data(repeating: 0, count: 16)
    private var txnId: UInt64 = 0
    private var parameters: [String: String] = [:]
    private var notificationHandlers: [(NotificationMessage) -> Void] = []
    private var lastPlan: QueryPlanMessage?
    private var lastSblr: SblrCompiledMessage?
    private let connectionId = UUID().uuidString
    private let circuitBreaker = CircuitBreaker()
    private let telemetry = TelemetryCollector()
    private let keepaliveManager = KeepaliveManager()
    private var keepaliveTracker: KeepaliveTracker?
    private let leakDetector = LeakDetector()
    private var leakGuard: LeakDetector.Guard?

    private init(config: ScratchBirdConfig, socket: ScratchBirdSocket) {
        self.config = config
        self.socket = socket
    }

    public static func connect(_ config: ScratchBirdConfig) async throws -> ScratchBirdConnection {
        return try await Task.detached { () -> ScratchBirdConnection in
            var normalizedConfig = config
            normalizedConfig.protocolName = try normalizeNativeProtocol(config.protocolName)
            normalizedConfig.frontDoorMode = try normalizeFrontDoorMode(config.frontDoorMode)
            let sslmode = try normalizeSslMode(normalizedConfig.sslmode)
            normalizedConfig.sslmode = sslmode
            if sslmode == "disable" {
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "TLS is required for ScratchBird connections"])
            }
            if !normalizedConfig.binaryTransfer {
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "binary_transfer=false is not supported"])
            }
            if normalizedConfig.compression.lowercased() == "zstd" {
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "compression=zstd is not supported"])
            }
            let socket = ScratchBirdSocket()
            try socket.connect(
                host: normalizedConfig.host,
                port: normalizedConfig.port,
                tlsConfig: ScratchBirdTlsConfig(
                    sslmode: sslmode,
                    sslrootcert: normalizedConfig.sslrootcert,
                    sslcert: normalizedConfig.sslcert,
                    sslkey: normalizedConfig.sslkey,
                    sslpassword: normalizedConfig.sslpassword
                )
            )
            let conn = ScratchBirdConnection(config: normalizedConfig, socket: socket)
            if normalizedConfig.frontDoorMode == "manager_proxy" {
                try conn.performManagerConnect()
            }
            try conn.handshake()
            conn.startResilience()
            return conn
        }.value
    }

    public func close() async throws {
        socket.close()
        stopResilience()
    }

    public func query(_ sql: String, _ params: [Any?] = []) async throws -> ScratchBirdResult {
        return try await Task.detached { () -> ScratchBirdResult in
            return try await self.withResilience(operation: "query", sql: sql) {
                if params.isEmpty {
                    try self.sendSimpleQuery(sql, maxRows: 0, timeoutMs: 0)
                } else {
                    try self.sendExtendedQuery(sql, params: params, maxRows: 0)
                }
                return try self.collectResults()
            }
        }.value
    }

    public func onNotification(_ handler: @escaping (NotificationMessage) -> Void) {
        notificationHandlers.append(handler)
    }

    public func lastQueryPlan() -> QueryPlanMessage? {
        return lastPlan
    }

    public func lastSblrCompiled() -> SblrCompiledMessage? {
        return lastSblr
    }

    public func begin(
        isolationLevel: UInt8? = nil,
        accessMode: UInt8? = nil,
        deferrable: Bool? = nil,
        wait: Bool? = nil,
        timeoutMs: UInt32? = nil,
        autocommitMode: UInt8? = nil,
        conflictAction: UInt8 = 0
    ) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "txn_begin") {
                var flags: UInt16 = 0
                let isolation = isolationLevel ?? isolationReadCommitted
                if isolationLevel != nil { flags |= txnFlagHasIsolation }
                if accessMode != nil { flags |= txnFlagHasAccess }
                if deferrable != nil { flags |= txnFlagHasDeferrable }
                if wait != nil { flags |= txnFlagHasWait }
                if timeoutMs != nil { flags |= txnFlagHasTimeout }
                if autocommitMode != nil { flags |= txnFlagHasAutocommit }
                let payload = buildTxnBeginPayload(
                    flags: flags,
                    conflictAction: conflictAction,
                    autocommitMode: autocommitMode ?? 0,
                    isolationLevel: isolation,
                    accessMode: accessMode ?? 0,
                    deferrable: deferrable == true ? 1 : 0,
                    waitMode: wait == true ? 1 : 0,
                    timeoutMs: timeoutMs ?? 0
                )
                _ = try self.sendMessage(type: .txnBegin, payload: payload)
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func commit(flags: UInt8 = 0) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "txn_commit") {
                _ = try self.sendMessage(type: .txnCommit, payload: buildTxnCommitPayload(flags: flags))
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func rollback(flags: UInt8 = 0) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "txn_rollback") {
                _ = try self.sendMessage(type: .txnRollback, payload: buildTxnRollbackPayload(flags: flags))
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func savepoint(_ name: String) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "txn_savepoint") {
                _ = try self.sendMessage(type: .txnSavepoint, payload: buildTxnSavepointPayload(name: name))
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func releaseSavepoint(_ name: String) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "txn_release") {
                _ = try self.sendMessage(type: .txnRelease, payload: buildTxnReleasePayload(name: name))
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func rollbackToSavepoint(_ name: String) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "txn_rollback_to") {
                _ = try self.sendMessage(type: .txnRollbackTo, payload: buildTxnRollbackToPayload(name: name))
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func setOption(_ name: String, value: String) async throws {
        try await Task.detached {
            try await self.withResilience(operation: "set_option") {
                _ = try self.sendMessage(type: .setOption, payload: buildSetOptionPayload(name: name, value: value))
                _ = try self.drainUntilReady()
            }
        }.value
    }

    public func ping() async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .ping, payload: Data())
            while true {
                let msg = try self.recvMessage()
                if self.handleAsyncMessage(msg) {
                    continue
                }
                if msg.header.type == .pong {
                    return
                }
                if msg.header.type == .ready {
                    self.txnId = self.readUInt64LE(msg.payload, 4)
                    return
                }
                if msg.header.type == .error {
                    throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ping failed"])
                }
            }
        }.value
    }

    public func terminate() async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .terminate, payload: Data())
            self.socket.close()
        }.value
    }

    public func subscribe(_ channel: String, subscribeType: UInt8 = 0, filterExpr: String = "") async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .subscribe, payload: buildSubscribePayload(subscribeType: subscribeType, channel: channel, filterExpr: filterExpr))
            _ = try self.drainUntilReady()
        }.value
    }

    public func unsubscribe(_ channel: String) async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .unsubscribe, payload: buildUnsubscribePayload(channel: channel))
            _ = try self.drainUntilReady()
        }.value
    }

    public func executeSblr(_ sblrHash: UInt64, bytecode: Data, params: [Any?] = []) async throws -> ScratchBirdResult {
        return try await Task.detached { () -> ScratchBirdResult in
            let encoded = try params.map { try encodeParam($0) }
            let paramValues = encoded.map { $0.param }
            let payload = buildSblrExecutePayload(sblrHash: sblrHash, sblrBytecode: bytecode, params: paramValues)
            self.lastPlan = nil
            self.lastSblr = nil
            self.lastQuerySequence = try self.sendMessage(type: .sblrExecute, payload: payload)
            _ = try self.sendMessage(type: .sync, payload: Data())
            return try self.collectResults()
        }.value
    }

    public func streamControl(controlType: UInt8, windowSize: UInt32 = 0, timeoutMs: UInt32 = 0) async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .streamControl, payload: buildStreamControlPayload(controlType: controlType, windowSize: windowSize, timeoutMs: timeoutMs))
        }.value
    }

    public func attachCreate(emulationMode: String, dbName: String) async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .attachCreate, payload: buildAttachCreatePayload(emulationMode: emulationMode, dbName: dbName))
            _ = try self.drainUntilReady()
        }.value
    }

    public func attachDetach() async throws {
        try await Task.detached {
            _ = try self.sendMessage(type: .attachDetach, payload: Data())
            _ = try self.drainUntilReady()
        }.value
    }

    public func attachList() async throws -> ScratchBirdResult {
        return try await Task.detached { () -> ScratchBirdResult in
            _ = try self.sendMessage(type: .attachList, payload: Data())
            _ = try self.sendMessage(type: .sync, payload: Data())
            return try self.collectResults()
        }.value
    }

    public func cancel() async throws {
        try await Task.detached {
            let payload = buildCancelPayload(cancelType: 0, targetSequence: self.lastQuerySequence)
            _ = try self.sendMessage(type: .cancel, payload: payload, flags: messageFlagUrgent)
        }.value
    }

    private func handshake() throws {
        var params: [String: String] = [
            "database": config.database,
            "user": config.user
        ]
        if let role = config.role { params["role"] = role }
        if let app = config.applicationName { params["application_name"] = app }
        let features: UInt64 = config.binaryTransfer ? (1 << 1) : 0
        _ = try sendMessage(type: .startup, payload: buildStartupPayload(features: features, params: params), forceZero: true)

        var scram: ScramClient? = nil
        while true {
            let msg = try recvMessage()
            switch msg.header.type {
            case .negotiateVersion:
                continue
            case .authRequest:
                let method = msg.payload.first ?? 0
                if method == 1 {
                    let password = config.password ?? ""
                    _ = try sendMessage(type: .authResponse, payload: Data(password.utf8), forceZero: true)
                } else if method == 3 {
                    scram = scram ?? ScramClient(username: config.user)
                    let first = scram!.clientFirstMessage()
                    _ = try sendMessage(type: .authResponse, payload: Data(first.utf8), forceZero: true)
                }
            case .authContinue:
                let method = msg.payload.first ?? 0
                if method == 3, let scram = scram {
                    let len = msg.payload.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
                    let start = 8
                    let data = msg.payload.subdata(in: start..<(start + Int(len)))
                    let serverFirst = String(data: data, encoding: .utf8) ?? ""
                    let final = try scram.handleServerFirst(password: config.password ?? "", serverFirst: serverFirst)
                    _ = try sendMessage(type: .authResponse, payload: Data(final.utf8), forceZero: true)
                }
            case .authOk:
                attachmentId = msg.header.attachmentId
                txnId = msg.header.txnId
            case .parameterStatus:
                handleParameterStatus(msg.payload)
            case .ready:
                return
            case .error:
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
            default:
                continue
            }
        }
    }

    private func collectResults() throws -> ScratchBirdResult {
        var columns: [ScratchBirdColumn] = []
        var rows: [[Any?]] = []
        while true {
            let msg = try recvMessage()
            if handleAsyncMessage(msg) {
                continue
            }
            switch msg.header.type {
            case .rowDescription:
                columns = parseRowDescription(msg.payload)
            case .dataRow:
                let values = parseDataRow(msg.payload)
                let decoded = values.enumerated().map { idx, value -> Any? in
                    guard let value = value else { return nil }
                    return decodeValue(oid: columns[idx].typeOid, data: value, format: columns[idx].format)
                }
                rows.append(decoded)
            case .ready:
                return ScratchBirdResult(rows: rows, columns: columns)
            case .error:
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Query failed"])
            case .portalSuspended:
                try sendMessage(type: .execute, payload: buildExecutePayload(portal: "", maxRows: UInt32(config.fetchSize)))
                try sendMessage(type: .sync, payload: Data())
            default:
                continue
            }
        }
    }

    private func sendSimpleQuery(_ sql: String, maxRows: UInt32, timeoutMs: UInt32) throws {
        let flags: UInt32 = config.binaryTransfer ? queryFlagBinaryResult : 0
        lastPlan = nil
        lastSblr = nil
        lastQuerySequence = try sendMessage(
            type: .query,
            payload: buildQueryPayload(sql: sql, flags: flags, maxRows: maxRows, timeoutMs: timeoutMs)
        )
    }

    private func sendExtendedQuery(_ sql: String, params: [Any?], maxRows: UInt32) throws {
        let encoded = try params.map { try encodeParam($0) }
        let paramValues = encoded.map { $0.param }
        let paramTypes = encoded.map { $0.oid }
        _ = try sendMessage(type: .parse, payload: buildParsePayload(statement: "", sql: sql, paramTypes: paramTypes))
        _ = try sendMessage(type: .describe, payload: buildDescribePayload(kind: "S".utf8.first ?? 83, name: ""))
        _ = try sendMessage(type: .sync, payload: Data())
        _ = try drainUntilReady()
        _ = try sendMessage(type: .bind, payload: buildBindPayload(portal: "", statement: "", params: paramValues, resultFormats: [1]))
        lastPlan = nil
        lastSblr = nil
        lastQuerySequence = try sendMessage(type: .execute, payload: buildExecutePayload(portal: "", maxRows: maxRows))
        _ = try sendMessage(type: .sync, payload: Data())
    }

    private func handleAsyncMessage(_ msg: ProtocolMessage) -> Bool {
        switch msg.header.type {
        case .parameterStatus:
            handleParameterStatus(msg.payload)
            return true
        case .notification:
            if let notice = parseNotification(msg.payload) {
                for handler in notificationHandlers {
                    handler(notice)
                }
            }
            return true
        case .queryPlan:
            if let plan = parseQueryPlan(msg.payload) {
                lastPlan = plan
            }
            return true
        case .sblrCompiled:
            if let compiled = parseSblrCompiled(msg.payload) {
                lastSblr = compiled
            }
            return true
        default:
            return false
        }
    }

    private func startResilience() {
        keepaliveManager.start()
        keepaliveTracker = keepaliveManager.register(connectionId: connectionId) { [weak self] in
            guard let self else { return false }
            do {
                try await self.ping()
                return true
            } catch {
                return false
            }
        }
        leakDetector.start()
        leakGuard = leakDetector.checkout(connectionId: connectionId, metadata: ["driver": "swift"])
    }

    private func stopResilience() {
        if let _ = keepaliveTracker {
            keepaliveManager.unregister(connectionId: connectionId)
            keepaliveTracker = nil
        }
        keepaliveManager.stop()
        if let leakGuard {
            leakGuard.release()
            self.leakGuard = nil
        }
        leakDetector.stop()
    }

    private func validateIfIdle() async throws {
        if let keepaliveTracker, keepaliveTracker.needsValidation() {
            try await ping()
            keepaliveTracker.markActive()
        }
    }

    private func withResilience<T>(operation: String, sql: String? = nil, _ body: () async throws -> T) async throws -> T {
        if !circuitBreaker.allowRequest() {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Circuit breaker is OPEN"])
        }
        try await validateIfIdle()
        let span = telemetry.startSpan(operation)
        if let span, let sql {
            span.withAttribute("db.statement", TelemetryCollector.sanitizeQuery(sql))
        }
        do {
            let result = try await body()
            finishOperation(span: span, success: true)
            return result
        } catch {
            finishOperation(span: span, success: false)
            throw error
        }
    }

    private func finishOperation(span: SpanContext?, success: Bool) {
        if success {
            circuitBreaker.recordSuccess()
            keepaliveTracker?.markActive()
        } else {
            circuitBreaker.recordFailure()
        }
        telemetry.endSpan(span, success: success)
    }

    private func handleParameterStatus(_ payload: Data) {
        if payload.count < 8 { return }
        let nameLen = Int(readUInt32LE(payload, 0))
        if 4 + nameLen + 4 > payload.count { return }
        let name = String(data: payload.subdata(in: 4..<(4 + nameLen)), encoding: .utf8) ?? ""
        let valueLen = Int(readUInt32LE(payload, 4 + nameLen))
        let valueStart = 8 + nameLen
        if valueStart + valueLen > payload.count { return }
        let value = String(data: payload.subdata(in: valueStart..<(valueStart + valueLen)), encoding: .utf8) ?? ""
        parameters[name] = value
        if name == "attachment_id", let parsed = parseUuidBytes(value) {
            attachmentId = parsed
        }
        if name == "current_txn_id", let parsed = UInt64(value.trimmingCharacters(in: .whitespaces)) {
            txnId = parsed
        }
    }

    private func parseNotification(_ payload: Data) -> NotificationMessage? {
        if payload.count < 12 { return nil }
        var offset = 0
        let processId = readUInt32LE(payload, offset)
        offset += 4
        let channelLen = Int(readUInt32LE(payload, offset))
        offset += 4
        if offset + channelLen + 4 > payload.count { return nil }
        let channel = String(data: payload.subdata(in: offset..<(offset + channelLen)), encoding: .utf8) ?? ""
        offset += channelLen
        let payloadLen = Int(readUInt32LE(payload, offset))
        offset += 4
        if offset + payloadLen > payload.count { return nil }
        let data = payload.subdata(in: offset..<(offset + payloadLen))
        offset += payloadLen
        var changeType: String?
        var rowId: UInt64?
        if offset < payload.count {
            changeType = String(bytes: [payload[offset]], encoding: .utf8)
            offset += 1
            if offset + 8 <= payload.count {
                rowId = readUInt64LE(payload, offset)
            }
        }
        return NotificationMessage(processId: processId, channel: channel, payload: data, changeType: changeType, rowId: rowId)
    }

    private func parseQueryPlan(_ payload: Data) -> QueryPlanMessage? {
        if payload.count < 32 { return nil }
        let format = readUInt32LE(payload, 0)
        let planLen = Int(readUInt32LE(payload, 4))
        let planningTimeUs = readUInt64LE(payload, 8)
        let estimatedRows = readUInt64LE(payload, 16)
        let estimatedCost = readUInt64LE(payload, 24)
        if 32 + planLen > payload.count { return nil }
        let plan = payload.subdata(in: 32..<(32 + planLen))
        return QueryPlanMessage(
            format: format,
            planningTimeUs: planningTimeUs,
            estimatedRows: estimatedRows,
            estimatedCost: estimatedCost,
            plan: plan
        )
    }

    private func parseSblrCompiled(_ payload: Data) -> SblrCompiledMessage? {
        if payload.count < 16 { return nil }
        let hash = readUInt64LE(payload, 0)
        let version = readUInt32LE(payload, 8)
        let length = Int(readUInt32LE(payload, 12))
        if 16 + length > payload.count { return nil }
        let bytecode = payload.subdata(in: 16..<(16 + length))
        return SblrCompiledMessage(hash: hash, version: version, bytecode: bytecode)
    }

    private func parseUuidBytes(_ value: String) -> Data? {
        let hex = value.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[0-9A-Fa-f]{32}$"
        if hex.range(of: pattern, options: .regularExpression) == nil {
            return nil
        }
        var data = Data()
        var index = hex.startIndex
        for _ in 0..<16 {
            let next = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<next])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            index = next
        }
        return data
    }

    private func readUInt32LE(_ data: Data, _ offset: Int) -> UInt32 {
        let slice = data.subdata(in: offset..<(offset + 4))
        return UInt32(littleEndian: slice.withUnsafeBytes { $0.load(as: UInt32.self) })
    }

    private func readUInt64LE(_ data: Data, _ offset: Int) -> UInt64 {
        let slice = data.subdata(in: offset..<(offset + 8))
        return UInt64(littleEndian: slice.withUnsafeBytes { $0.load(as: UInt64.self) })
    }

    private func buildLengthPrefixedString(_ value: String) -> Data {
        let bytes = Data(value.utf8)
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: UInt32(bytes.count).littleEndian, Array.init))
        data.append(bytes)
        return data
    }

    private func sendManagerFrame(type: UInt8, payload: Data) throws {
        var frame = Data()
        frame.append(contentsOf: withUnsafeBytes(of: managerProtocolMagic.littleEndian, Array.init))
        frame.append(contentsOf: withUnsafeBytes(of: managerProtocolVersion.littleEndian, Array.init))
        frame.append(type)
        frame.append(0)
        frame.append(contentsOf: withUnsafeBytes(of: UInt32(payload.count).littleEndian, Array.init))
        frame.append(payload)
        try socket.write(frame)
    }

    private func recvManagerFrame() throws -> (UInt8, Data) {
        let header = try socket.readExact(managerHeaderSize)
        let magic = readUInt32LE(header, 0)
        if magic != managerProtocolMagic {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager frame magic mismatch"])
        }
        let version = UInt16(littleEndian: header.subdata(in: 4..<6).withUnsafeBytes { $0.load(as: UInt16.self) })
        if version != managerProtocolVersion {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager frame version mismatch"])
        }
        let type = header[6]
        let length = readUInt32LE(header, 8)
        if length > managerMaxPayloadSize {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager payload too large"])
        }
        let payload = length > 0 ? try socket.readExact(Int(length)) : Data()
        return (type, payload)
    }

    private func performManagerConnect() throws {
        let token = config.managerAuthToken ?? ""
        if token.isEmpty {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "manager_proxy mode requires manager_auth_token"])
        }
        let managerUser: String
        if let configured = config.managerUsername, !configured.isEmpty {
            managerUser = configured
        } else if !config.user.isEmpty {
            managerUser = config.user
        } else {
            managerUser = "admin"
        }
        let managerDatabase =
            (config.managerDatabase?.isEmpty == false) ? config.managerDatabase! : config.database
        let managerProfile = config.managerConnectionProfile.isEmpty ? "native_v3" : config.managerConnectionProfile
        let managerIntent = config.managerClientIntent.isEmpty ? "native_v3" : config.managerClientIntent

        var hello = Data()
        hello.append(contentsOf: withUnsafeBytes(of: mcpProtocolVersion.littleEndian, Array.init))
        hello.append(contentsOf: withUnsafeBytes(of: UInt16(config.managerClientFlags & 0xFFFF).littleEndian, Array.init))
        try sendManagerFrame(type: mcpMsgHello, payload: hello)
        var frame = try recvManagerFrame()
        if frame.0 != mcpMsgStatusResponse {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected MCP hello status response"])
        }

        var authStart = Data()
        authStart.append(buildLengthPrefixedString(managerUser))
        authStart.append(mcpAuthMethodToken)
        if config.managerAuthFastPath {
            let tokenBytes = Data(token.utf8)
            authStart.append(contentsOf: withUnsafeBytes(of: UInt32(tokenBytes.count).littleEndian, Array.init))
            authStart.append(tokenBytes)
        } else {
            authStart.append(contentsOf: [0, 0, 0, 0])
        }
        try sendManagerFrame(type: mcpMsgAuthStart, payload: authStart)
        frame = try recvManagerFrame()
        if frame.0 == mcpMsgAuthChallenge {
            let tokenBytes = Data(token.utf8)
            var authContinue = Data()
            authContinue.append(contentsOf: withUnsafeBytes(of: UInt32(tokenBytes.count).littleEndian, Array.init))
            authContinue.append(tokenBytes)
            try sendManagerFrame(type: mcpMsgAuthContinue, payload: authContinue)
            frame = try recvManagerFrame()
        }
        if frame.0 != mcpMsgAuthResponse {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected MCP auth response"])
        }
        if frame.1.count < 1 + 4 + 256 {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Truncated MCP auth response"])
        }
        if frame.1[0] != 0 {
            let errSlice = frame.1.subdata(in: 5..<261)
            let err = String(data: errSlice, encoding: .utf8)?
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? ""
            throw NSError(
                domain: "ScratchBird",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: err.isEmpty ? "MCP authentication failed" : err]
            )
        }

        var dbConnect = Data("MCP1".utf8)
        dbConnect.append(buildLengthPrefixedString(managerDatabase))
        dbConnect.append(buildLengthPrefixedString(managerProfile))
        dbConnect.append(buildLengthPrefixedString(managerIntent))
        let nonce = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        dbConnect.append(contentsOf: withUnsafeBytes(of: UInt16(nonce.count).littleEndian, Array.init))
        dbConnect.append(nonce)
        try sendManagerFrame(type: mcpMsgDbConnect, payload: dbConnect)
        frame = try recvManagerFrame()
        if frame.0 != mcpMsgConnectResponse {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected MCP connect response"])
        }
        if frame.1.count < 1 + 2 + 2 + 16 + 64 + 32 {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Truncated MCP connect response"])
        }
        if frame.1[0] != 0 {
            var message = "MCP database connect failed"
            let errOffset = 1 + 2 + 2 + 16 + 64 + 32
            if frame.1.count >= errOffset + 4 {
                let errLen = Int(readUInt32LE(frame.1, errOffset))
                if frame.1.count >= errOffset + 4 + errLen {
                    let errData = frame.1.subdata(in: (errOffset + 4)..<(errOffset + 4 + errLen))
                    if let decoded = String(data: errData, encoding: .utf8), !decoded.isEmpty {
                        message = decoded
                    }
                }
            }
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func drainUntilReady() throws -> Bool {
        while true {
            let msg = try recvMessage()
            if handleAsyncMessage(msg) {
                continue
            }
            if msg.header.type == .ready {
                txnId = readUInt64LE(msg.payload, 4)
                return true
            }
            if msg.header.type == .error {
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request failed"])
            }
        }
    }

    @discardableResult
    private func sendMessage(type: MessageType, payload: Data, flags: UInt8 = 0, forceZero: Bool = false) throws -> UInt32 {
        let currentSequence = sequence
        let attachment = forceZero ? Data(repeating: 0, count: 16) : attachmentId
        let txn = forceZero ? 0 : txnId
        let header = MessageHeader(type: type, flags: flags, length: UInt32(payload.count), sequence: currentSequence, attachmentId: attachment, txnId: txn)
        sequence += 1
        let data = encodeMessage(header: header, payload: payload)
        try socket.write(data)
        return currentSequence
    }

    private func recvMessage() throws -> ProtocolMessage {
        let headerBytes = try socket.readExact(headerSize)
        let header = try decodeHeader(headerBytes)
        let payload = header.length > 0 ? try socket.readExact(Int(header.length)) : Data()
        return ProtocolMessage(header: header, payload: payload)
    }

    private func parseRowDescription(_ payload: Data) -> [ScratchBirdColumn] {
        if payload.count < 2 { return [] }
        let count = UInt16(littleEndian: payload.withUnsafeBytes { $0.load(as: UInt16.self) })
        var offset = 2
        var columns: [ScratchBirdColumn] = []
        for _ in 0..<count {
            let (name, next) = readCString(payload, offset)
            offset = next
            offset += 4 // table oid
            offset += 2 // column index
            let typeOid = UInt32(littleEndian: payload.subdata(in: offset..<(offset + 4)).withUnsafeBytes { $0.load(as: UInt32.self) })
            offset += 4
            offset += 2 // type size
            offset += 4 // modifier
            let format = UInt16(payload[offset])
            offset += 2
            columns.append(ScratchBirdColumn(name: name, typeOid: typeOid, format: format))
        }
        return columns
    }

    private func parseDataRow(_ payload: Data) -> [Data?] {
        if payload.count < 2 { return [] }
        let count = UInt16(littleEndian: payload.withUnsafeBytes { $0.load(as: UInt16.self) })
        var offset = 2
        var out: [Data?] = []
        for _ in 0..<count {
            let len = Int32(littleEndian: payload.subdata(in: offset..<(offset + 4)).withUnsafeBytes { $0.load(as: Int32.self) })
            offset += 4
            if len < 0 {
                out.append(nil)
            } else {
                out.append(payload.subdata(in: offset..<(offset + Int(len))))
                offset += Int(len)
            }
        }
        return out
    }

    private func readCString(_ data: Data, _ offset: Int) -> (String, Int) {
        var idx = offset
        while idx < data.count && data[idx] != 0 { idx += 1 }
        let name = String(data: data.subdata(in: offset..<idx), encoding: .utf8) ?? ""
        return (name, idx + 1)
    }
}

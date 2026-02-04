// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

enum ProtocolError: Error {
    case invalidHeader
    case unsupportedVersion
    case payloadTooLarge
}

enum MessageType: UInt8 {
    case startup = 0x01
    case authResponse = 0x02
    case query = 0x03
    case parse = 0x04
    case bind = 0x05
    case describe = 0x06
    case execute = 0x07
    case close = 0x08
    case sync = 0x09
    case flush = 0x0a
    case cancel = 0x0b
    case terminate = 0x0c
    case copyData = 0x0d
    case copyDone = 0x0e
    case copyFail = 0x0f
    case sblrExecute = 0x10
    case subscribe = 0x11
    case unsubscribe = 0x12
    case federatedQuery = 0x13
    case streamControl = 0x14
    case txnBegin = 0x15
    case txnCommit = 0x16
    case txnRollback = 0x17
    case txnSavepoint = 0x18
    case txnRelease = 0x19
    case txnRollbackTo = 0x1a
    case ping = 0x1b
    case setOption = 0x1c
    case clusterAuth = 0x1d
    case attachCreate = 0x1e
    case attachDetach = 0x1f
    case attachList = 0x20

    case authRequest = 0x40
    case authOk = 0x41
    case authContinue = 0x42
    case ready = 0x43
    case rowDescription = 0x44
    case dataRow = 0x45
    case commandComplete = 0x46
    case emptyQuery = 0x47
    case error = 0x48
    case notice = 0x49
    case parseComplete = 0x4a
    case bindComplete = 0x4b
    case closeComplete = 0x4c
    case portalSuspended = 0x4d
    case noData = 0x4e
    case parameterStatus = 0x4f
    case parameterDescription = 0x50
    case copyInResponse = 0x51
    case copyOutResponse = 0x52
    case copyBothResponse = 0x53
    case notification = 0x54
    case functionResult = 0x55
    case negotiateVersion = 0x56
    case sblrCompiled = 0x57
    case queryPlan = 0x58
    case streamReady = 0x59
    case streamData = 0x5a
    case streamEnd = 0x5b
    case txnStatus = 0x5c
    case pong = 0x5d
    case clusterAuthOk = 0x5e
    case federatedResult = 0x5f
    case heartbeat = 0x80
    case `extension` = 0x81
}

struct MessageHeader {
    var type: MessageType
    var flags: UInt8
    var length: UInt32
    var sequence: UInt32
    var attachmentId: Data
    var txnId: UInt64
}

struct ProtocolMessage {
    var header: MessageHeader
    var payload: Data
}

let protocolMagic: UInt32 = 0x50574253
let protocolMajor: UInt8 = 1
let protocolMinor: UInt8 = 1
let headerSize = 40
let maxMessageSize: UInt32 = 1024 * 1024 * 1024

let messageFlagUrgent: UInt8 = 0x08

let queryFlagDescribeOnly: UInt32 = 0x01
let queryFlagNoPortal: UInt32 = 0x02
let queryFlagBinaryResult: UInt32 = 0x04
let queryFlagIncludePlan: UInt32 = 0x08
let queryFlagReturnSblr: UInt32 = 0x10
let queryFlagNoCache: UInt32 = 0x20

let isolationReadUncommitted: UInt8 = 0
let isolationReadCommitted: UInt8 = 1
let isolationRepeatableRead: UInt8 = 2
let isolationSerializable: UInt8 = 3

let txnFlagHasIsolation: UInt16 = 0x0001
let txnFlagHasAccess: UInt16 = 0x0002
let txnFlagHasDeferrable: UInt16 = 0x0004
let txnFlagHasWait: UInt16 = 0x0008
let txnFlagHasTimeout: UInt16 = 0x0010
let txnFlagHasAutocommit: UInt16 = 0x0020

let streamStart: UInt8 = 0
let streamPause: UInt8 = 1
let streamResume: UInt8 = 2
let streamCancel: UInt8 = 3
let streamAck: UInt8 = 4

let subscribeTypeChannel: UInt8 = 0
let subscribeTypeTable: UInt8 = 1
let subscribeTypeQuery: UInt8 = 2
let subscribeTypeEvent: UInt8 = 3

func encodeMessage(header: MessageHeader, payload: Data) -> Data {
    var data = Data(count: headerSize + payload.count)
    data.withUnsafeMutableBytes { ptr in
        var offset = 0
        ptr.storeBytes(of: protocolMagic.littleEndian, toByteOffset: offset, as: UInt32.self)
        offset += 4
        ptr.storeBytes(of: protocolMajor, toByteOffset: offset, as: UInt8.self)
        offset += 1
        ptr.storeBytes(of: protocolMinor, toByteOffset: offset, as: UInt8.self)
        offset += 1
        ptr.storeBytes(of: header.type.rawValue, toByteOffset: offset, as: UInt8.self)
        offset += 1
        ptr.storeBytes(of: header.flags, toByteOffset: offset, as: UInt8.self)
        offset += 1
        ptr.storeBytes(of: UInt32(payload.count).littleEndian, toByteOffset: offset, as: UInt32.self)
        offset += 4
        ptr.storeBytes(of: header.sequence.littleEndian, toByteOffset: offset, as: UInt32.self)
        offset += 4
        header.attachmentId.copyBytes(to: ptr.baseAddress!.advanced(by: offset).assumingMemoryBound(to: UInt8.self), count: 16)
        offset += 16
        ptr.storeBytes(of: header.txnId.littleEndian, toByteOffset: offset, as: UInt64.self)
        offset += 8
        payload.copyBytes(to: ptr.baseAddress!.advanced(by: offset).assumingMemoryBound(to: UInt8.self), count: payload.count)
    }
    return data
}

func decodeHeader(_ data: Data) throws -> MessageHeader {
    if data.count != headerSize { throw ProtocolError.invalidHeader }
    let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
    if magic != protocolMagic { throw ProtocolError.invalidHeader }
    let major = data[4]
    let minor = data[5]
    if major != protocolMajor || minor != protocolMinor { throw ProtocolError.unsupportedVersion }
    let length = data.subdata(in: 8..<12).withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
    if length > maxMessageSize { throw ProtocolError.payloadTooLarge }
    let type = MessageType(rawValue: data[6]) ?? .error
    let flags = data[7]
    let sequence = data.subdata(in: 12..<16).withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
    let attachment = data.subdata(in: 16..<32)
    let txnId = data.subdata(in: 32..<40).withUnsafeBytes { $0.load(as: UInt64.self) }.littleEndian
    return MessageHeader(type: type, flags: flags, length: length, sequence: sequence, attachmentId: attachment, txnId: txnId)
}

func buildStartupPayload(features: UInt64, params: [String: String]) -> Data {
    let paramBytes = buildParamList(params)
    var data = Data()
    data.append(protocolMajor)
    data.append(protocolMinor)
    data.append(contentsOf: [0, 0])
    data.append(contentsOf: withUnsafeBytes(of: features.littleEndian, Array.init))
    data.append(paramBytes)
    return data
}

func buildQueryPayload(sql: String, flags: UInt32, maxRows: UInt32, timeoutMs: UInt32) -> Data {
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: flags.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: maxRows.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: timeoutMs.littleEndian, Array.init))
    data.append(sql.data(using: .utf8) ?? Data())
    data.append(0)
    return data
}

func buildParsePayload(statement: String, sql: String, paramTypes: [UInt32]) -> Data {
    var data = Data()
    let nameBytes = statement.data(using: .utf8) ?? Data()
    let sqlBytes = sql.data(using: .utf8) ?? Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(nameBytes.count).littleEndian, Array.init))
    data.append(nameBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt32(sqlBytes.count).littleEndian, Array.init))
    data.append(sqlBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt16(paramTypes.count).littleEndian, Array.init))
    data.append(contentsOf: [0, 0])
    for oid in paramTypes {
        data.append(contentsOf: withUnsafeBytes(of: oid.littleEndian, Array.init))
    }
    return data
}

struct ParamValue {
    let format: UInt16
    let data: Data?
    let isNull: Bool
}

func buildBindPayload(portal: String, statement: String, params: [ParamValue], resultFormats: [UInt16]) -> Data {
    var data = Data()
    let portalBytes = portal.data(using: .utf8) ?? Data()
    let stmtBytes = statement.data(using: .utf8) ?? Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(portalBytes.count).littleEndian, Array.init))
    data.append(portalBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt32(stmtBytes.count).littleEndian, Array.init))
    data.append(stmtBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt16(params.count).littleEndian, Array.init))
    for param in params {
        data.append(contentsOf: withUnsafeBytes(of: param.format.littleEndian, Array.init))
    }
    data.append(contentsOf: withUnsafeBytes(of: UInt16(params.count).littleEndian, Array.init))
    data.append(contentsOf: [0, 0])
    for param in params {
        if param.isNull {
            data.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF])
        } else {
            let payload = param.data ?? Data()
            data.append(contentsOf: withUnsafeBytes(of: UInt32(payload.count).littleEndian, Array.init))
            data.append(payload)
        }
    }
    data.append(contentsOf: withUnsafeBytes(of: UInt16(resultFormats.count).littleEndian, Array.init))
    for fmt in resultFormats {
        data.append(contentsOf: withUnsafeBytes(of: fmt.littleEndian, Array.init))
    }
    return data
}

func buildDescribePayload(kind: UInt8, name: String) -> Data {
    var data = Data()
    data.append(kind)
    data.append(contentsOf: [0, 0, 0])
    let nameBytes = name.data(using: .utf8) ?? Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(nameBytes.count).littleEndian, Array.init))
    data.append(nameBytes)
    return data
}

func buildExecutePayload(portal: String, maxRows: UInt32) -> Data {
    var data = Data()
    let portalBytes = portal.data(using: .utf8) ?? Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(portalBytes.count).littleEndian, Array.init))
    data.append(portalBytes)
    data.append(contentsOf: withUnsafeBytes(of: maxRows.littleEndian, Array.init))
    return data
}

func buildCancelPayload(cancelType: UInt32, targetSequence: UInt32) -> Data {
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: cancelType.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: targetSequence.littleEndian, Array.init))
    return data
}

func buildSblrExecutePayload(sblrHash: UInt64, sblrBytecode: Data?, params: [ParamValue]) -> Data {
    var data = Data()
    let bytecode = sblrBytecode ?? Data()
    data.append(contentsOf: withUnsafeBytes(of: sblrHash.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: UInt32(bytecode.count).littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: UInt16(params.count).littleEndian, Array.init))
    data.append(contentsOf: [0, 0])
    if !bytecode.isEmpty {
        data.append(bytecode)
    }
    for param in params {
        if param.isNull {
            data.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF])
        } else {
            let payload = param.data ?? Data()
            data.append(contentsOf: withUnsafeBytes(of: UInt32(payload.count).littleEndian, Array.init))
            data.append(payload)
        }
    }
    return data
}

func buildSubscribePayload(subscribeType: UInt8, channel: String, filterExpr: String = "") -> Data {
    var data = Data()
    data.append(subscribeType)
    data.append(contentsOf: [0, 0, 0])
    let channelBytes = channel.data(using: .utf8) ?? Data()
    let filterBytes = filterExpr.data(using: .utf8) ?? Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(channelBytes.count).littleEndian, Array.init))
    data.append(channelBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt32(filterBytes.count).littleEndian, Array.init))
    data.append(filterBytes)
    return data
}

func buildUnsubscribePayload(channel: String) -> Data {
    let channelBytes = channel.data(using: .utf8) ?? Data()
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(channelBytes.count).littleEndian, Array.init))
    data.append(channelBytes)
    return data
}

func buildTxnBeginPayload(
    flags: UInt16,
    conflictAction: UInt8,
    autocommitMode: UInt8,
    isolationLevel: UInt8,
    accessMode: UInt8,
    deferrable: UInt8,
    waitMode: UInt8,
    timeoutMs: UInt32
) -> Data {
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: flags.littleEndian, Array.init))
    data.append(conflictAction)
    data.append(autocommitMode)
    data.append(isolationLevel)
    data.append(accessMode)
    data.append(deferrable)
    data.append(waitMode)
    data.append(contentsOf: withUnsafeBytes(of: timeoutMs.littleEndian, Array.init))
    return data
}

func buildTxnCommitPayload(flags: UInt8) -> Data {
    return Data([flags, 0, 0, 0])
}

func buildTxnRollbackPayload(flags: UInt8) -> Data {
    return Data([flags, 0, 0, 0])
}

func buildTxnSavepointPayload(name: String) -> Data {
    let nameBytes = name.data(using: .utf8) ?? Data()
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(nameBytes.count).littleEndian, Array.init))
    data.append(nameBytes)
    return data
}

func buildTxnReleasePayload(name: String) -> Data {
    return buildTxnSavepointPayload(name: name)
}

func buildTxnRollbackToPayload(name: String) -> Data {
    return buildTxnSavepointPayload(name: name)
}

func buildSetOptionPayload(name: String, value: String) -> Data {
    let nameBytes = name.data(using: .utf8) ?? Data()
    let valueBytes = value.data(using: .utf8) ?? Data()
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(nameBytes.count).littleEndian, Array.init))
    data.append(nameBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt32(valueBytes.count).littleEndian, Array.init))
    data.append(valueBytes)
    return data
}

func buildStreamControlPayload(controlType: UInt8, windowSize: UInt32, timeoutMs: UInt32) -> Data {
    var data = Data()
    data.append(controlType)
    data.append(contentsOf: [0, 0, 0])
    data.append(contentsOf: withUnsafeBytes(of: windowSize.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: timeoutMs.littleEndian, Array.init))
    return data
}

func buildAttachCreatePayload(emulationMode: String, dbName: String) -> Data {
    let modeBytes = emulationMode.data(using: .utf8) ?? Data()
    let dbBytes = dbName.data(using: .utf8) ?? Data()
    var data = Data()
    data.append(contentsOf: withUnsafeBytes(of: UInt32(modeBytes.count).littleEndian, Array.init))
    data.append(modeBytes)
    data.append(contentsOf: withUnsafeBytes(of: UInt32(dbBytes.count).littleEndian, Array.init))
    data.append(dbBytes)
    return data
}

func buildParamList(_ params: [String: String]) -> Data {
    var data = Data()
    for (key, value) in params {
        data.append(key.data(using: .utf8) ?? Data())
        data.append(0)
        data.append(value.data(using: .utf8) ?? Data())
        data.append(0)
    }
    data.append(0)
    return data
}

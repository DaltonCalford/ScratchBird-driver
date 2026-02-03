// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

enum TypeOid {
    static let bool: UInt32 = 16
    static let bytea: UInt32 = 17
    static let char: UInt32 = 18
    static let int8: UInt32 = 20
    static let int2: UInt32 = 21
    static let int4: UInt32 = 23
    static let text: UInt32 = 25
    static let json: UInt32 = 114
    static let xml: UInt32 = 142
    static let point: UInt32 = 600
    static let float4: UInt32 = 700
    static let float8: UInt32 = 701
    static let money: UInt32 = 790
    static let cidr: UInt32 = 650
    static let inet: UInt32 = 869
    static let macaddr: UInt32 = 829
    static let bpchar: UInt32 = 1042
    static let varchar: UInt32 = 1043
    static let date: UInt32 = 1082
    static let time: UInt32 = 1083
    static let timestamp: UInt32 = 1114
    static let timestamptz: UInt32 = 1184
    static let interval: UInt32 = 1186
    static let numeric: UInt32 = 1700
    static let uuid: UInt32 = 2950
    static let jsonb: UInt32 = 3802
    static let record: UInt32 = 2249
    static let int4range: UInt32 = 3904
    static let numrange: UInt32 = 3906
    static let tsrange: UInt32 = 3908
    static let tstzrange: UInt32 = 3910
    static let daterange: UInt32 = 3912
    static let int8range: UInt32 = 3926
    static let tsvector: UInt32 = 3614
    static let tsquery: UInt32 = 3615
    static let sbVector: UInt32 = 16386
}

struct Jsonb { let raw: Data }
struct Json { let raw: Data }
struct Geometry { let wkb: Data }
struct Interval { let micros: Int64; let days: Int32; let months: Int32 }
struct RawValue { let oid: UInt32; let data: Data }

struct ParamEncoding {
    let param: ParamValue
    let oid: UInt32
}

func encodeParam(_ value: Any?) throws -> ParamEncoding {
    guard let value = value else {
        return ParamEncoding(param: ParamValue(format: 1, data: nil, isNull: true), oid: 0)
    }
    if let raw = value as? RawValue {
        return ParamEncoding(param: ParamValue(format: 1, data: raw.data, isNull: false), oid: raw.oid)
    }
    if let jsonb = value as? Jsonb {
        return ParamEncoding(param: ParamValue(format: 1, data: lengthPrefixed(jsonb.raw), isNull: false), oid: TypeOid.jsonb)
    }
    if let json = value as? Json {
        return ParamEncoding(param: ParamValue(format: 1, data: lengthPrefixed(json.raw), isNull: false), oid: TypeOid.json)
    }
    if let geom = value as? Geometry {
        return ParamEncoding(param: ParamValue(format: 1, data: lengthPrefixed(geom.wkb), isNull: false), oid: TypeOid.point)
    }
    if let interval = value as? Interval {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: interval.micros.littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: interval.days.littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: interval.months.littleEndian, Array.init))
        return ParamEncoding(param: ParamValue(format: 1, data: data, isNull: false), oid: TypeOid.interval)
    }
    if let boolVal = value as? Bool {
        return ParamEncoding(param: ParamValue(format: 1, data: Data([boolVal ? 1 : 0]), isNull: false), oid: TypeOid.bool)
    }
    if let intVal = value as? Int {
        if intVal >= -32768 && intVal <= 32767 {
            var v = Int16(intVal).littleEndian
            return ParamEncoding(param: ParamValue(format: 1, data: Data(bytes: &v, count: 2), isNull: false), oid: TypeOid.int2)
        }
        if intVal >= Int(Int32.min) && intVal <= Int(Int32.max) {
            var v = Int32(intVal).littleEndian
            return ParamEncoding(param: ParamValue(format: 1, data: Data(bytes: &v, count: 4), isNull: false), oid: TypeOid.int4)
        }
        var v = Int64(intVal).littleEndian
        return ParamEncoding(param: ParamValue(format: 1, data: Data(bytes: &v, count: 8), isNull: false), oid: TypeOid.int8)
    }
    if let doubleVal = value as? Double {
        var v = doubleVal.bitPattern.littleEndian
        return ParamEncoding(param: ParamValue(format: 1, data: Data(bytes: &v, count: 8), isNull: false), oid: TypeOid.float8)
    }
    if let dateVal = value as? Date {
        let base = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(secondsFromGMT: 0), year: 2000, month: 1, day: 1).date!
        let micros = Int64(dateVal.timeIntervalSince(base) * 1_000_000)
        var v = micros.littleEndian
        return ParamEncoding(param: ParamValue(format: 1, data: Data(bytes: &v, count: 8), isNull: false), oid: TypeOid.timestamptz)
    }
    if let dataVal = value as? Data {
        return ParamEncoding(param: ParamValue(format: 1, data: lengthPrefixed(dataVal), isNull: false), oid: TypeOid.bytea)
    }
    if let strVal = value as? String {
        if let uuidBytes = uuidToBytes(strVal) {
            return ParamEncoding(param: ParamValue(format: 1, data: uuidBytes, isNull: false), oid: TypeOid.uuid)
        }
        return ParamEncoding(param: ParamValue(format: 1, data: lengthPrefixed(Data(strVal.utf8)), isNull: false), oid: TypeOid.text)
    }
    if let obj = value as? [String: Any] {
        let data = try JSONSerialization.data(withJSONObject: obj)
        return ParamEncoding(param: ParamValue(format: 1, data: lengthPrefixed(data), isNull: false), oid: TypeOid.json)
    }
    throw NSError(domain: "ScratchBird", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported parameter type"])
}

func decodeValue(oid: UInt32, data: Data, format: UInt16) -> Any {
    if format == 0 {
        return String(data: data, encoding: .utf8) ?? ""
    }
    switch oid {
    case TypeOid.bool:
        return data.first == 1
    case TypeOid.int2:
        return Int16(littleEndian: data.withUnsafeBytes { $0.load(as: Int16.self) })
    case TypeOid.int4:
        return Int32(littleEndian: data.withUnsafeBytes { $0.load(as: Int32.self) })
    case TypeOid.int8:
        return Int64(littleEndian: data.withUnsafeBytes { $0.load(as: Int64.self) })
    case TypeOid.float4:
        let bits = UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
        return Float(bitPattern: bits)
    case TypeOid.float8:
        let bits = UInt64(littleEndian: data.withUnsafeBytes { $0.load(as: UInt64.self) })
        return Double(bitPattern: bits)
    case TypeOid.numeric:
        return String(data: stripLengthPrefix(data), encoding: .utf8) ?? ""
    case TypeOid.text, TypeOid.varchar, TypeOid.char, TypeOid.bpchar, TypeOid.json, TypeOid.xml, TypeOid.tsvector, TypeOid.tsquery:
        return String(data: stripLengthPrefix(data), encoding: .utf8) ?? ""
    case TypeOid.jsonb:
        return Jsonb(raw: stripLengthPrefix(data))
    case TypeOid.uuid:
        return uuidFromBytes(data)
    case TypeOid.date:
        let days = Int32(littleEndian: data.withUnsafeBytes { $0.load(as: Int32.self) })
        let base = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2000, month: 1, day: 1))!
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: Int(days), to: base) ?? base
    case TypeOid.time:
        return Int64(littleEndian: data.withUnsafeBytes { $0.load(as: Int64.self) })
    case TypeOid.timestamp, TypeOid.timestamptz:
        let micros = Int64(littleEndian: data.withUnsafeBytes { $0.load(as: Int64.self) })
        let base = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2000, month: 1, day: 1))!
        return base.addingTimeInterval(Double(micros) / 1_000_000)
    case TypeOid.interval:
        let micros = Int64(littleEndian: data.withUnsafeBytes { $0.load(as: Int64.self) })
        let days = Int32(littleEndian: data.subdata(in: 8..<12).withUnsafeBytes { $0.load(as: Int32.self) })
        let months = Int32(littleEndian: data.subdata(in: 12..<16).withUnsafeBytes { $0.load(as: Int32.self) })
        return Interval(micros: micros, days: days, months: months)
    case TypeOid.point:
        return Geometry(wkb: stripLengthPrefix(data))
    default:
        return RawValue(oid: oid, data: data)
    }
}

func lengthPrefixed(_ data: Data) -> Data {
    var out = Data()
    var len = UInt32(data.count).littleEndian
    out.append(Data(bytes: &len, count: 4))
    out.append(data)
    return out
}

func stripLengthPrefix(_ data: Data) -> Data {
    if data.count < 4 { return data }
    let len = UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
    if data.count < 4 + Int(len) { return data }
    return data.subdata(in: 4..<(4 + Int(len)))
}

func uuidToBytes(_ value: String) -> Data? {
    let regex = try? NSRegularExpression(pattern: "^[0-9a-fA-F-]{36}$")
    if regex?.firstMatch(in: value, range: NSRange(location: 0, length: value.count)) == nil {
        return nil
    }
    let hex = value.replacingOccurrences(of: "-", with: "")
    var data = Data(capacity: 16)
    var index = hex.startIndex
    while index < hex.endIndex {
        let next = hex.index(index, offsetBy: 2)
        let byte = UInt8(hex[index..<next], radix: 16) ?? 0
        data.append(byte)
        index = next
    }
    return data
}

func uuidFromBytes(_ data: Data) -> String {
    let hex = data.map { String(format: "%02x", $0) }.joined()
    let p1 = hex.prefix(8)
    let p2 = hex.dropFirst(8).prefix(4)
    let p3 = hex.dropFirst(12).prefix(4)
    let p4 = hex.dropFirst(16).prefix(4)
    let p5 = hex.dropFirst(20)
    return "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
}

// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'dart:typed_data';
import 'dart:convert';

import 'protocol.dart';

const int oidBool = 16;
const int oidBytea = 17;
const int oidChar = 18;
const int oidInt8 = 20;
const int oidInt2 = 21;
const int oidInt4 = 23;
const int oidText = 25;
const int oidJson = 114;
const int oidXml = 142;
const int oidPoint = 600;
const int oidFloat4 = 700;
const int oidFloat8 = 701;
const int oidMoney = 790;
const int oidMacaddr = 829;
const int oidCidr = 650;
const int oidInet = 869;
const int oidBpchar = 1042;
const int oidVarchar = 1043;
const int oidDate = 1082;
const int oidTime = 1083;
const int oidTimestamp = 1114;
const int oidTimestamptz = 1184;
const int oidInterval = 1186;
const int oidNumeric = 1700;
const int oidUuid = 2950;
const int oidJsonb = 3802;
const int oidRecord = 2249;
const int oidInt4Range = 3904;
const int oidNumRange = 3906;
const int oidTsRange = 3908;
const int oidTstzRange = 3910;
const int oidDateRange = 3912;
const int oidInt8Range = 3926;
const int oidTsVector = 3614;
const int oidTsQuery = 3615;
const int oidVector = 16386;

const int rangeEmpty = 0x01;
const int rangeLbInc = 0x02;
const int rangeUbInc = 0x04;
const int rangeLbInf = 0x08;
const int rangeUbInf = 0x10;

class ScratchBirdJsonb {
  final Uint8List raw;
  ScratchBirdJsonb(this.raw);
}

class ScratchBirdJson {
  final Uint8List raw;
  ScratchBirdJson(this.raw);
}

class ScratchBirdGeometry {
  final Uint8List wkb;
  ScratchBirdGeometry(this.wkb);
}

class ScratchBirdRange<T> {
  final T? lower;
  final T? upper;
  final bool lowerInclusive;
  final bool upperInclusive;
  final bool lowerInfinite;
  final bool upperInfinite;
  final bool empty;
  final int rangeOid;

  ScratchBirdRange({
    this.lower,
    this.upper,
    this.lowerInclusive = false,
    this.upperInclusive = false,
    this.lowerInfinite = false,
    this.upperInfinite = false,
    this.empty = false,
    required this.rangeOid,
  });
}

class ScratchBirdInterval {
  final int micros;
  final int days;
  final int months;
  ScratchBirdInterval(this.micros, this.days, this.months);
}

class RawValue {
  final int oid;
  final Uint8List data;
  RawValue(this.oid, this.data);
}

class ParamEncoding {
  final ParamValue param;
  final int oid;
  ParamEncoding(this.param, this.oid);
}

ParamEncoding encodeParam(dynamic value) {
  if (value == null) {
    return ParamEncoding(ParamValue(format: 1, isNull: true), 0);
  }
  if (value is RawValue) {
    return ParamEncoding(ParamValue(format: 1, data: value.data), value.oid);
  }
  if (value is ScratchBirdJsonb) {
    return ParamEncoding(ParamValue(format: 1, data: _lengthPrefixed(value.raw)), oidJsonb);
  }
  if (value is ScratchBirdJson) {
    return ParamEncoding(ParamValue(format: 1, data: _lengthPrefixed(value.raw)), oidJson);
  }
  if (value is ScratchBirdGeometry) {
    return ParamEncoding(ParamValue(format: 1, data: _lengthPrefixed(value.wkb)), oidPoint);
  }
  if (value is ScratchBirdInterval) {
    final buf = ByteData(16);
    buf.setInt64(0, value.micros, Endian.little);
    buf.setInt32(8, value.days, Endian.little);
    buf.setInt32(12, value.months, Endian.little);
    return ParamEncoding(ParamValue(format: 1, data: buf.buffer.asUint8List()), oidInterval);
  }
  if (value is bool) {
    return ParamEncoding(ParamValue(format: 1, data: Uint8List.fromList([value ? 1 : 0])), oidBool);
  }
  if (value is int) {
    if (value >= -32768 && value <= 32767) {
      final buf = ByteData(2);
      buf.setInt16(0, value, Endian.little);
      return ParamEncoding(ParamValue(format: 1, data: buf.buffer.asUint8List()), oidInt2);
    }
    if (value >= -2147483648 && value <= 2147483647) {
      final buf = ByteData(4);
      buf.setInt32(0, value, Endian.little);
      return ParamEncoding(ParamValue(format: 1, data: buf.buffer.asUint8List()), oidInt4);
    }
    final buf = ByteData(8);
    buf.setInt64(0, value, Endian.little);
    return ParamEncoding(ParamValue(format: 1, data: buf.buffer.asUint8List()), oidInt8);
  }
  if (value is double) {
    final buf = ByteData(8);
    buf.setFloat64(0, value, Endian.little);
    return ParamEncoding(ParamValue(format: 1, data: buf.buffer.asUint8List()), oidFloat8);
  }
  if (value is DateTime) {
    final base = DateTime.utc(2000, 1, 1);
    final micros = value.toUtc().difference(base).inMicroseconds;
    final buf = ByteData(8);
    buf.setInt64(0, micros, Endian.little);
    return ParamEncoding(ParamValue(format: 1, data: buf.buffer.asUint8List()), oidTimestamptz);
  }
  if (value is Uint8List) {
    return ParamEncoding(ParamValue(format: 1, data: _lengthPrefixed(value)), oidBytea);
  }
  if (value is String) {
    final uuid = _uuidToBytes(value);
    if (uuid != null) {
      return ParamEncoding(ParamValue(format: 1, data: uuid), oidUuid);
    }
    return ParamEncoding(ParamValue(format: 1, data: _lengthPrefixed(Uint8List.fromList(utf8.encode(value)))), oidText);
  }
  if (value is Map || value is List) {
    final json = jsonEncode(value);
    return ParamEncoding(ParamValue(format: 1, data: _lengthPrefixed(Uint8List.fromList(utf8.encode(json)))), oidJson);
  }
  throw Exception('Unsupported parameter type');
}

dynamic decodeValue(int typeOid, Uint8List data, int format) {
  if (format == 0) {
    return utf8.decode(data);
  }
  switch (typeOid) {
    case oidBool:
      return data.isNotEmpty && data[0] == 1;
    case oidInt2:
      return ByteData.sublistView(data).getInt16(0, Endian.little);
    case oidInt4:
      return ByteData.sublistView(data).getInt32(0, Endian.little);
    case oidInt8:
      return ByteData.sublistView(data).getInt64(0, Endian.little);
    case oidFloat4:
      return ByteData.sublistView(data).getFloat32(0, Endian.little);
    case oidFloat8:
      return ByteData.sublistView(data).getFloat64(0, Endian.little);
    case oidNumeric:
      return utf8.decode(_stripLength(data));
    case oidMoney:
      return ByteData.sublistView(data).getInt64(0, Endian.little);
    case oidText:
    case oidVarchar:
    case oidChar:
    case oidBpchar:
    case oidJson:
    case oidXml:
    case oidTsVector:
    case oidTsQuery:
      return utf8.decode(_stripLength(data));
    case oidJsonb:
      return ScratchBirdJsonb(_stripLength(data));
    case oidUuid:
      return _uuidFromBytes(data);
    case oidDate:
      final days = ByteData.sublistView(data).getInt32(0, Endian.little);
      return DateTime.utc(2000, 1, 1).add(Duration(days: days));
    case oidTime:
      return ByteData.sublistView(data).getInt64(0, Endian.little);
    case oidTimestamp:
    case oidTimestamptz:
      final micros = ByteData.sublistView(data).getInt64(0, Endian.little);
      return DateTime.utc(2000, 1, 1).add(Duration(microseconds: micros));
    case oidInterval:
      final bd = ByteData.sublistView(data);
      return ScratchBirdInterval(bd.getInt64(0, Endian.little), bd.getInt32(8, Endian.little), bd.getInt32(12, Endian.little));
    case oidInt4Range:
    case oidInt8Range:
    case oidNumRange:
    case oidTsRange:
    case oidTstzRange:
    case oidDateRange:
      return _decodeRange(typeOid, data);
    case oidPoint:
      return ScratchBirdGeometry(_stripLength(data));
    default:
      return RawValue(typeOid, data);
  }
}

Uint8List _lengthPrefixed(Uint8List data) {
  final buf = ByteData(4 + data.length);
  buf.setUint32(0, data.length, Endian.little);
  buf.buffer.asUint8List().setAll(4, data);
  return buf.buffer.asUint8List();
}

Uint8List _stripLength(Uint8List data) {
  if (data.length < 4) return data;
  final len = ByteData.sublistView(data).getUint32(0, Endian.little);
  return data.sublist(4, 4 + len);
}

Uint8List? _uuidToBytes(String value) {
  final regex = RegExp(r'^[0-9a-fA-F-]{36}$');
  if (!regex.hasMatch(value)) return null;
  final hex = value.replaceAll('-', '');
  return Uint8List.fromList(hexToBytes(hex));
}

String _uuidFromBytes(Uint8List bytes) {
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

List<int> hexToBytes(String hex) {
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    out.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return out;
}

ScratchBirdRange _decodeRange(int rangeOid, Uint8List data) {
  final flags = data[0];
  var offset = 1;

  ScratchBirdRange range = ScratchBirdRange(
    rangeOid: rangeOid,
    empty: (flags & rangeEmpty) != 0,
    lowerInclusive: (flags & rangeLbInc) != 0,
    upperInclusive: (flags & rangeUbInc) != 0,
    lowerInfinite: (flags & rangeLbInf) != 0,
    upperInfinite: (flags & rangeUbInf) != 0,
  );

  dynamic lower;
  dynamic upper;
  if ((flags & rangeLbInf) == 0) {
    final len = ByteData.sublistView(data, offset, offset + 4).getUint32(0, Endian.little);
    offset += 4;
    lower = _decodeRangeBound(rangeOid, data.sublist(offset, offset + len));
    offset += len;
  }
  if ((flags & rangeUbInf) == 0) {
    final len = ByteData.sublistView(data, offset, offset + 4).getUint32(0, Endian.little);
    offset += 4;
    upper = _decodeRangeBound(rangeOid, data.sublist(offset, offset + len));
  }

  return ScratchBirdRange(
    rangeOid: rangeOid,
    lower: lower,
    upper: upper,
    empty: range.empty,
    lowerInclusive: range.lowerInclusive,
    upperInclusive: range.upperInclusive,
    lowerInfinite: range.lowerInfinite,
    upperInfinite: range.upperInfinite,
  );
}

dynamic _decodeRangeBound(int rangeOid, Uint8List data) {
  switch (rangeOid) {
    case oidInt4Range:
      return ByteData.sublistView(data).getInt32(0, Endian.little);
    case oidInt8Range:
      return ByteData.sublistView(data).getInt64(0, Endian.little);
    case oidNumRange:
      return utf8.decode(_stripLength(data));
    case oidDateRange:
      final days = ByteData.sublistView(data).getInt32(0, Endian.little);
      return DateTime.utc(2000, 1, 1).add(Duration(days: days));
    case oidTsRange:
    case oidTstzRange:
      final micros = ByteData.sublistView(data).getInt64(0, Endian.little);
      return DateTime.utc(2000, 1, 1).add(Duration(microseconds: micros));
    default:
      return data;
  }
}

// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'config.dart';
import 'protocol.dart';
import 'scram.dart';
import 'types.dart';

class ScratchBirdColumn {
  final String name;
  final int typeOid;
  final int format;

  ScratchBirdColumn(this.name, this.typeOid, this.format);
}

class ScratchBirdResult {
  final List<List<dynamic>> rows;
  final List<ScratchBirdColumn> columns;

  ScratchBirdResult(this.rows, this.columns);
}

class NotificationMessage {
  final int processId;
  final String channel;
  final Uint8List payload;
  final String? changeType;
  final int? rowId;

  NotificationMessage(this.processId, this.channel, this.payload, this.changeType, this.rowId);
}

class QueryPlanMessage {
  final int format;
  final int planningTimeUs;
  final int estimatedRows;
  final int estimatedCost;
  final Uint8List plan;

  QueryPlanMessage(this.format, this.planningTimeUs, this.estimatedRows, this.estimatedCost, this.plan);
}

class SblrCompiledMessage {
  final int hash;
  final int version;
  final Uint8List bytecode;

  SblrCompiledMessage(this.hash, this.version, this.bytecode);
}

class ScratchBirdClient {
  final ScratchBirdConfig config;
  late final StreamIterator<Uint8List> _iter;
  late final _SocketReader _reader;
  Socket? _socket;
  int _sequence = 0;
  int _lastQuerySequence = 0;
  Uint8List _attachmentId = Uint8List(16);
  int _txnId = 0;
  final Map<String, String> _parameters = {};
  final List<void Function(NotificationMessage)> _notificationHandlers = [];
  QueryPlanMessage? _lastPlan;
  SblrCompiledMessage? _lastSblr;

  ScratchBirdClient(this.config);

  static Future<ScratchBirdClient> connect(ScratchBirdConfig config) async {
    final client = ScratchBirdClient(config);
    await client._connect();
    return client;
  }

  Future<void> _connect() async {
    final host = config.host;
    final port = config.port;
    final sslmode = config.sslmode.toLowerCase();
    if (sslmode == 'disable') {
      throw Exception('TLS is required for ScratchBird connections');
    }
    if (!config.binaryTransfer) {
      throw Exception('binary_transfer=false is not supported');
    }
    if (config.compression.toLowerCase() == 'zstd') {
      throw Exception('compression=zstd is not supported');
    }
    final useTls = true;

    _socket = await SecureSocket.connect(host, port,
        supportedProtocols: ['tlsv1.3'],
        onBadCertificate: (_) => true);
    _iter = StreamIterator(_socket!);
    _reader = _SocketReader(_iter);
    await _handshake();
  }

  Future<void> close() async {
    await _socket?.close();
  }

  Future<ScratchBirdResult> query(String sql, [List<dynamic> params = const []]) async {
    if (params.isEmpty) {
      await _sendSimpleQuery(sql, 0, 0);
      return _collectResults();
    }
    await _sendExtendedQuery(sql, params, 0);
    return _collectResults();
  }

  void onNotification(void Function(NotificationMessage) handler) {
    _notificationHandlers.add(handler);
  }

  QueryPlanMessage? get lastQueryPlan => _lastPlan;
  SblrCompiledMessage? get lastSblrCompiled => _lastSblr;

  Future<void> begin({
    int? isolationLevel,
    int? accessMode,
    bool? deferrable,
    bool? wait,
    int? timeoutMs,
    int? autocommitMode,
    int conflictAction = 0,
  }) async {
    var flags = 0;
    final isolation = isolationLevel ?? isolationReadCommitted;
    if (isolationLevel != null) flags |= txnFlagHasIsolation;
    if (accessMode != null) flags |= txnFlagHasAccess;
    if (deferrable != null) flags |= txnFlagHasDeferrable;
    if (wait != null) flags |= txnFlagHasWait;
    if (timeoutMs != null) flags |= txnFlagHasTimeout;
    if (autocommitMode != null) flags |= txnFlagHasAutocommit;
    final payload = buildTxnBeginPayload(
      flags,
      conflictAction,
      autocommitMode ?? 0,
      isolation,
      accessMode ?? 0,
      deferrable == true ? 1 : 0,
      wait == true ? 1 : 0,
      timeoutMs ?? 0,
    );
    await _sendMessage(MessageType.txnBegin, payload);
    await _drainUntilReady();
  }

  Future<void> commit([int flags = 0]) async {
    await _sendMessage(MessageType.txnCommit, buildTxnCommitPayload(flags));
    await _drainUntilReady();
  }

  Future<void> rollback([int flags = 0]) async {
    await _sendMessage(MessageType.txnRollback, buildTxnRollbackPayload(flags));
    await _drainUntilReady();
  }

  Future<void> savepoint(String name) async {
    await _sendMessage(MessageType.txnSavepoint, buildTxnSavepointPayload(name));
    await _drainUntilReady();
  }

  Future<void> releaseSavepoint(String name) async {
    await _sendMessage(MessageType.txnRelease, buildTxnReleasePayload(name));
    await _drainUntilReady();
  }

  Future<void> rollbackToSavepoint(String name) async {
    await _sendMessage(MessageType.txnRollbackTo, buildTxnRollbackToPayload(name));
    await _drainUntilReady();
  }

  Future<void> setOption(String name, String value) async {
    await _sendMessage(MessageType.setOption, buildSetOptionPayload(name, value));
    await _drainUntilReady();
  }

  Future<void> ping() async {
    await _sendMessage(MessageType.ping, Uint8List(0));
    while (true) {
      final msg = await _recvMessage();
      if (_handleAsyncMessage(msg)) {
        continue;
      }
      if (msg.header.type == MessageType.pong) {
        return;
      }
      if (msg.header.type == MessageType.ready) {
        _txnId = ByteData.sublistView(msg.payload, 4, 12).getUint64(0, Endian.little);
        return;
      }
      if (msg.header.type == MessageType.error) {
        throw Exception('Ping failed');
      }
    }
  }

  Future<void> terminate() async {
    if (_socket == null) return;
    await _sendMessage(MessageType.terminate, Uint8List(0));
    await close();
  }

  Future<void> subscribe(String channel, {int subscribeType = subscribeTypeChannel, String filterExpr = ''}) async {
    await _sendMessage(MessageType.subscribe, buildSubscribePayload(subscribeType, channel, filterExpr));
    await _drainUntilReady();
  }

  Future<void> unsubscribe(String channel) async {
    await _sendMessage(MessageType.unsubscribe, buildUnsubscribePayload(channel));
    await _drainUntilReady();
  }

  Future<ScratchBirdResult> executeSblr(int sblrHash, Uint8List? bytecode, [List<dynamic> params = const []]) async {
    final encoded = params.map(encodeParam).toList();
    final payload = buildSblrExecutePayload(sblrHash, bytecode, encoded.map((e) => e.param).toList());
    _lastPlan = null;
    _lastSblr = null;
    _lastQuerySequence = await _sendMessage(MessageType.sblrExecute, payload);
    await _sendMessage(MessageType.sync, Uint8List(0));
    return _collectResults();
  }

  Future<void> streamControl(int controlType, {int windowSize = 0, int timeoutMs = 0}) async {
    await _sendMessage(MessageType.streamControl, buildStreamControlPayload(controlType, windowSize, timeoutMs));
  }

  Future<void> attachCreate(String emulationMode, String dbName) async {
    await _sendMessage(MessageType.attachCreate, buildAttachCreatePayload(emulationMode, dbName));
    await _drainUntilReady();
  }

  Future<void> attachDetach() async {
    await _sendMessage(MessageType.attachDetach, Uint8List(0));
    await _drainUntilReady();
  }

  Future<ScratchBirdResult> attachList() async {
    await _sendMessage(MessageType.attachList, Uint8List(0));
    await _sendMessage(MessageType.sync, Uint8List(0));
    return _collectResults();
  }

  Future<void> cancel() async {
    final payload = buildCancelPayload(0, _lastQuerySequence);
    await _sendMessage(MessageType.cancel, payload, flags: 0x08);
  }

  Future<void> _handshake() async {
    final params = <String, String>{
      'database': config.database,
      'user': config.user,
    };
    if (config.role != null) params['role'] = config.role!;
    if (config.applicationName != null) params['application_name'] = config.applicationName!;

    final features = config.binaryTransfer ? (1 << 1) : 0;
    await _sendMessage(MessageType.startup, buildStartupPayload(features, params), forceZero: true);

    ScramClient? scram;
    while (true) {
      final msg = await _recvMessage();
      switch (msg.header.type) {
        case MessageType.negotiateVersion:
          continue;
        case MessageType.authRequest:
          final method = msg.payload[0];
          if (method == 1) {
            await _sendMessage(
              MessageType.authResponse,
              Uint8List.fromList(utf8.encode(config.password ?? '')),
              forceZero: true,
            );
          } else if (method == 3) {
            scram ??= ScramClient(config.user);
            final clientFirst = scram.clientFirstMessage();
            await _sendMessage(
              MessageType.authResponse,
              Uint8List.fromList(utf8.encode(clientFirst)),
              forceZero: true,
            );
          }
          break;
        case MessageType.authContinue:
          final method = msg.payload[0];
          if (method == 3 && scram != null) {
            final dataLen = ByteData.sublistView(msg.payload, 4).getUint32(0, Endian.little);
            final data = utf8.decode(msg.payload.sublist(8, 8 + dataLen));
            final clientFinal = scram.handleServerFirst(config.password ?? '', data);
            await _sendMessage(
              MessageType.authResponse,
              Uint8List.fromList(utf8.encode(clientFinal)),
              forceZero: true,
            );
          }
          break;
        case MessageType.authOk:
          _attachmentId = msg.header.attachmentId;
          _txnId = msg.header.txnId;
          break;
        case MessageType.parameterStatus:
          _handleParameterStatus(msg.payload);
          continue;
        case MessageType.ready:
          _txnId = ByteData.sublistView(msg.payload, 4, 12).getUint64(0, Endian.little);
          return;
        case MessageType.error:
          throw Exception('Authentication failed');
      }
    }
  }

  Future<ScratchBirdResult> _collectResults() async {
    List<ScratchBirdColumn> columns = [];
    final rows = <List<dynamic>>[];
    while (true) {
      final msg = await _recvMessage();
      if (_handleAsyncMessage(msg)) {
        continue;
      }
      switch (msg.header.type) {
        case MessageType.rowDescription:
          columns = _parseRowDescription(msg.payload);
          break;
        case MessageType.dataRow:
          final values = _parseDataRow(msg.payload);
          final decoded = <dynamic>[];
          for (var i = 0; i < values.length; i++) {
            final value = values[i];
            if (value == null) {
              decoded.add(null);
            } else {
              decoded.add(decodeValue(columns[i].typeOid, value, columns[i].format));
            }
          }
          rows.add(decoded);
          break;
        case MessageType.portalSuspended:
          await _sendMessage(MessageType.execute, buildExecutePayload('', config.fetchSize));
          await _sendMessage(MessageType.sync, Uint8List(0));
          break;
        case MessageType.ready:
          _txnId = ByteData.sublistView(msg.payload, 4, 12).getUint64(0, Endian.little);
          return ScratchBirdResult(rows, columns);
        case MessageType.error:
          throw Exception('Query failed');
      }
    }
  }

  Future<void> _sendSimpleQuery(String sql, int maxRows, int timeoutMs) async {
    final flags = config.binaryTransfer ? queryFlagBinaryResult : 0;
    _lastPlan = null;
    _lastSblr = null;
    _lastQuerySequence = await _sendMessage(MessageType.query, buildQueryPayload(sql, flags, maxRows, timeoutMs));
  }

  Future<void> _sendExtendedQuery(String sql, List<dynamic> params, int maxRows) async {
    final enc = params.map(encodeParam).toList();
    final paramValues = enc.map((e) => e.param).toList();
    final paramTypes = enc.map((e) => e.oid).toList();
    await _sendMessage(MessageType.parse, buildParsePayload('', sql, paramTypes));
    await _sendMessage(MessageType.describe, buildDescribePayload('S'.codeUnitAt(0), ''));
    await _sendMessage(MessageType.sync, Uint8List(0));
    await _drainUntilReady();
    await _sendMessage(MessageType.bind, buildBindPayload('', '', paramValues, [1]));
    _lastPlan = null;
    _lastSblr = null;
    _lastQuerySequence = await _sendMessage(MessageType.execute, buildExecutePayload('', maxRows));
    await _sendMessage(MessageType.sync, Uint8List(0));
  }

  bool _handleAsyncMessage(ScratchBirdMessage msg) {
    switch (msg.header.type) {
      case MessageType.parameterStatus:
        _handleParameterStatus(msg.payload);
        return true;
      case MessageType.notification:
        final notice = _parseNotification(msg.payload);
        for (final handler in _notificationHandlers) {
          handler(notice);
        }
        return true;
      case MessageType.queryPlan:
        _lastPlan = _parseQueryPlan(msg.payload);
        return true;
      case MessageType.sblrCompiled:
        _lastSblr = _parseSblrCompiled(msg.payload);
        return true;
      default:
        return false;
    }
  }

  void _handleParameterStatus(Uint8List payload) {
    if (payload.length < 8) return;
    final data = ByteData.sublistView(payload);
    final nameLen = data.getUint32(0, Endian.little);
    if (4 + nameLen + 4 > payload.length) return;
    final name = utf8.decode(payload.sublist(4, 4 + nameLen));
    final valueLen = data.getUint32(4 + nameLen, Endian.little);
    final valueStart = 8 + nameLen;
    if (valueStart + valueLen > payload.length) return;
    final value = utf8.decode(payload.sublist(valueStart, valueStart + valueLen));
    _parameters[name] = value;
    if (name == 'attachment_id') {
      final parsed = _parseUuidBytes(value);
      if (parsed != null) _attachmentId = parsed;
    }
    if (name == 'current_txn_id') {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) _txnId = parsed;
    }
  }

  NotificationMessage _parseNotification(Uint8List payload) {
    if (payload.length < 12) {
      throw Exception('Notification truncated');
    }
    var offset = 0;
    final data = ByteData.sublistView(payload);
    final processId = data.getUint32(offset, Endian.little);
    offset += 4;
    final channelLen = data.getUint32(offset, Endian.little);
    offset += 4;
    if (offset + channelLen + 4 > payload.length) {
      throw Exception('Notification truncated');
    }
    final channel = utf8.decode(payload.sublist(offset, offset + channelLen));
    offset += channelLen;
    final payloadLen = data.getUint32(offset, Endian.little);
    offset += 4;
    if (offset + payloadLen > payload.length) {
      throw Exception('Notification truncated');
    }
    final noticePayload = payload.sublist(offset, offset + payloadLen);
    offset += payloadLen;
    String? changeType;
    int? rowId;
    if (offset < payload.length) {
      changeType = String.fromCharCode(payload[offset]);
      offset += 1;
      if (offset + 8 <= payload.length) {
        rowId = data.getUint64(offset, Endian.little);
      }
    }
    return NotificationMessage(processId, channel, noticePayload, changeType, rowId);
  }

  QueryPlanMessage _parseQueryPlan(Uint8List payload) {
    if (payload.length < 32) {
      throw Exception('Query plan truncated');
    }
    final data = ByteData.sublistView(payload);
    final format = data.getUint32(0, Endian.little);
    final planLen = data.getUint32(4, Endian.little);
    final planningTimeUs = data.getUint64(8, Endian.little);
    final estimatedRows = data.getUint64(16, Endian.little);
    final estimatedCost = data.getUint64(24, Endian.little);
    if (32 + planLen > payload.length) {
      throw Exception('Query plan truncated');
    }
    final plan = payload.sublist(32, 32 + planLen);
    return QueryPlanMessage(format, planningTimeUs, estimatedRows, estimatedCost, plan);
  }

  SblrCompiledMessage _parseSblrCompiled(Uint8List payload) {
    if (payload.length < 16) {
      throw Exception('SBLR compiled truncated');
    }
    final data = ByteData.sublistView(payload);
    final hash = data.getUint64(0, Endian.little);
    final version = data.getUint32(8, Endian.little);
    final length = data.getUint32(12, Endian.little);
    if (16 + length > payload.length) {
      throw Exception('SBLR compiled truncated');
    }
    final bytecode = payload.sublist(16, 16 + length);
    return SblrCompiledMessage(hash, version, bytecode);
  }

  Uint8List? _parseUuidBytes(String value) {
    final hex = value.replaceAll('-', '').trim();
    if (!RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(hex)) {
      return null;
    }
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      final part = hex.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(part, radix: 16);
    }
    return bytes;
  }

  Future<void> _drainUntilReady() async {
    while (true) {
      final msg = await _recvMessage();
      if (_handleAsyncMessage(msg)) {
        continue;
      }
      if (msg.header.type == MessageType.ready) {
        _txnId = ByteData.sublistView(msg.payload, 4, 12).getUint64(0, Endian.little);
        return;
      }
      if (msg.header.type == MessageType.error) {
        throw Exception('Describe failed');
      }
    }
  }

  Future<int> _sendMessage(int type, Uint8List payload, {int flags = 0, bool forceZero = false}) async {
    final sequence = _sequence;
    final header = MessageHeader(
      type: type,
      flags: flags,
      length: payload.length,
      sequence: sequence,
      attachmentId: forceZero ? Uint8List(16) : _attachmentId,
      txnId: forceZero ? 0 : _txnId,
    );
    _sequence += 1;
    final data = encodeMessage(header, payload);
    _socket!.add(data);
    await _socket!.flush();
    return sequence;
  }

  Future<ScratchBirdMessage> _recvMessage() async {
    final headerBytes = await _reader.readExact(headerSize);
    final header = decodeHeader(headerBytes);
    final payload = header.length == 0 ? Uint8List(0) : await _reader.readExact(header.length);
    return ScratchBirdMessage(header, payload);
  }

  List<ScratchBirdColumn> _parseRowDescription(Uint8List payload) {
    final count = ByteData.sublistView(payload, 0, 2).getUint16(0, Endian.little);
    var offset = 2;
    final cols = <ScratchBirdColumn>[];
    for (var i = 0; i < count; i++) {
      final nameResult = _readCString(payload, offset);
      final name = nameResult.item1;
      offset = nameResult.item2;
      final tableOid = ByteData.sublistView(payload, offset, offset + 4).getUint32(0, Endian.little);
      offset += 4;
      offset += 2; // column index
      final typeOid = ByteData.sublistView(payload, offset, offset + 4).getUint32(0, Endian.little);
      offset += 4;
      offset += 2; // type size
      offset += 4; // type modifier
      final format = payload[offset];
      offset += 2; // format + nullable
      cols.add(ScratchBirdColumn(name, typeOid, format));
      // tableOid unused in client metadata
    }
    return cols;
  }

  List<Uint8List?> _parseDataRow(Uint8List payload) {
    final count = ByteData.sublistView(payload, 0, 2).getUint16(0, Endian.little);
    var offset = 2;
    final out = <Uint8List?>[];
    for (var i = 0; i < count; i++) {
      final len = ByteData.sublistView(payload, offset, offset + 4).getInt32(0, Endian.little);
      offset += 4;
      if (len < 0) {
        out.add(null);
      } else {
        out.add(payload.sublist(offset, offset + len));
        offset += len;
      }
    }
    return out;
  }

  _CStringResult _readCString(Uint8List buffer, int offset) {
    var idx = offset;
    while (idx < buffer.length && buffer[idx] != 0) {
      idx += 1;
    }
    final name = utf8.decode(buffer.sublist(offset, idx));
    return _CStringResult(name, idx + 1);
  }
}

class _CStringResult {
  final String item1;
  final int item2;
  _CStringResult(this.item1, this.item2);
}

class _SocketReader {
  final StreamIterator<Uint8List> iterator;
  final BytesBuilder _buffer = BytesBuilder();

  _SocketReader(this.iterator);

  Future<Uint8List> readExact(int length) async {
    while (_buffer.length < length) {
      if (!await iterator.moveNext()) {
        throw Exception('Socket closed');
      }
      _buffer.add(iterator.current);
    }
    final data = _buffer.takeBytes();
    final result = data.sublist(0, length);
    final rest = data.sublist(length);
    _buffer.add(rest);
    return result;
  }
}

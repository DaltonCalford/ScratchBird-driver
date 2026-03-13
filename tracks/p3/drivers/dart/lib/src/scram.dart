// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'errors.dart';

class ScramClient {
  final String username;
  late String clientNonce;
  String? clientFirstBare;
  Uint8List? serverSignature;

  ScramClient(this.username) {
    final rand = Random.secure();
    final bytes = List<int>.generate(18, (_) => rand.nextInt(256));
    clientNonce = base64.encode(bytes);
  }

  String clientFirstMessage() {
    clientFirstBare = 'n=${_escape(username)},r=$clientNonce';
    return 'n,,' + clientFirstBare!;
  }

  String handleServerFirst(String password, String serverFirst) {
    final attrs = _parseAttrs(serverFirst);
    final nonce = attrs['r'] ?? '';
    final saltB64 = attrs['s'] ?? '';
    final iterStr = attrs['i'] ?? '0';
    if (!nonce.startsWith(clientNonce)) {
      throw const ScratchBirdAuthException('SCRAM server nonce mismatch');
    }
    final iterations = int.parse(iterStr);
    final salt = base64.decode(saltB64);
    final salted = _pbkdf2Sha256(utf8.encode(password), salt, iterations, 32);
    final clientKey = _hmacSha256(salted, utf8.encode('Client Key'));
    final storedKey = sha256.convert(clientKey).bytes;
    final clientFinalWithoutProof = 'c=biws,r=$nonce';
    final authMessage =
        '${clientFirstBare!},$serverFirst,$clientFinalWithoutProof';
    final clientSignature = _hmacSha256(storedKey, utf8.encode(authMessage));
    final clientProof = _xor(clientKey, clientSignature);
    final serverKey = _hmacSha256(salted, utf8.encode('Server Key'));
    serverSignature = _hmacSha256(serverKey, utf8.encode(authMessage));
    return '$clientFinalWithoutProof,p=${base64.encode(clientProof)}';
  }

  void verifyServerFinal(String serverFinal) {
    final attrs = _parseAttrs(serverFinal);
    final verifier = attrs['v'] ?? '';
    final expected = base64.encode(serverSignature ?? Uint8List(0));
    if (verifier != expected) {
      throw const ScratchBirdAuthException('SCRAM server signature mismatch');
    }
  }

  String _escape(String input) =>
      input.replaceAll('=', '=3D').replaceAll(',', '=2C');

  Map<String, String> _parseAttrs(String message) {
    final out = <String, String>{};
    for (final part in message.split(',')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        out[part.substring(0, idx)] = part.substring(idx + 1);
      }
    }
    return out;
  }

  Uint8List _hmacSha256(List<int> key, List<int> data) {
    final hmacSha = Hmac(sha256, key);
    return Uint8List.fromList(hmacSha.convert(data).bytes);
  }

  Uint8List _xor(List<int> left, List<int> right) {
    final out = Uint8List(left.length);
    for (var i = 0; i < left.length; i++) {
      out[i] = left[i] ^ right[i];
    }
    return out;
  }

  Uint8List _pbkdf2Sha256(
      List<int> password, List<int> salt, int iterations, int keyLen) {
    final blocks = (keyLen / 32).ceil();
    final out = BytesBuilder();
    for (var i = 1; i <= blocks; i++) {
      out.add(_pbkdf2F(password, salt, iterations, i));
    }
    final bytes = out.toBytes();
    return Uint8List.sublistView(bytes, 0, keyLen);
  }

  List<int> _pbkdf2F(
      List<int> password, List<int> salt, int iterations, int blockIndex) {
    final block = Uint8List(salt.length + 4);
    block.setAll(0, salt);
    block[block.length - 4] = (blockIndex >> 24) & 0xff;
    block[block.length - 3] = (blockIndex >> 16) & 0xff;
    block[block.length - 2] = (blockIndex >> 8) & 0xff;
    block[block.length - 1] = blockIndex & 0xff;
    var u = _hmacSha256(password, block);
    final out = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = _hmacSha256(password, u);
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }
}

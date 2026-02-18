// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

class ScratchBirdConfig {
  final String host;
  final int port;
  final String protocol;
  final String database;
  final String user;
  final String? password;
  final String sslmode;
  final String? sslrootcert;
  final String? sslcert;
  final String? sslkey;
  final String? sslpassword;
  final int connectTimeoutMs;
  final int socketTimeoutMs;
  final String? applicationName;
  final String? searchPath;
  final String? role;
  final bool binaryTransfer;
  final String compression;
  final int fetchSize;

  const ScratchBirdConfig({
    required this.host,
    required this.port,
    this.protocol = 'native',
    required this.database,
    required this.user,
    this.password,
    this.sslmode = 'require',
    this.sslrootcert,
    this.sslcert,
    this.sslkey,
    this.sslpassword,
    this.connectTimeoutMs = 5000,
    this.socketTimeoutMs = 0,
    this.applicationName,
    this.searchPath,
    this.role,
    this.binaryTransfer = true,
    this.compression = 'off',
    this.fetchSize = 0,
  });

  factory ScratchBirdConfig.fromDsn(String dsn) {
    if (dsn.contains('://')) {
      return _fromUri(Uri.parse(dsn));
    }
    return _fromKv(dsn);
  }

  ScratchBirdConfig copyWith({
    String? host,
    int? port,
    String? protocol,
    String? database,
    String? user,
    String? password,
    String? sslmode,
    String? applicationName,
    String? role,
    bool? binaryTransfer,
  }) {
    return ScratchBirdConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      database: database ?? this.database,
      user: user ?? this.user,
      password: password ?? this.password,
      sslmode: sslmode ?? this.sslmode,
      sslrootcert: sslrootcert,
      sslcert: sslcert,
      sslkey: sslkey,
      sslpassword: sslpassword,
      connectTimeoutMs: connectTimeoutMs,
      socketTimeoutMs: socketTimeoutMs,
      applicationName: applicationName ?? this.applicationName,
      searchPath: searchPath,
      role: role ?? this.role,
      binaryTransfer: binaryTransfer ?? this.binaryTransfer,
      compression: compression,
      fetchSize: fetchSize,
    );
  }
}

ScratchBirdConfig _fromUri(Uri uri) {
  final userInfo = uri.userInfo.split(':');
  final user = userInfo.isNotEmpty ? Uri.decodeComponent(userInfo[0]) : '';
  final password = userInfo.length > 1 ? Uri.decodeComponent(userInfo[1]) : null;
  final params = _normalizeParams(uri.queryParameters);
  return ScratchBirdConfig(
    host: uri.host,
    port: uri.port == 0 ? 3092 : uri.port,
    protocol: normalizeNativeProtocol(params['protocol'] ?? params['parser'] ?? params['dialect']),
    database: uri.path.replaceFirst('/', ''),
    user: params['user'] ?? user,
    password: params['password'] ?? password,
    sslmode: params['sslmode'] ?? 'require',
    applicationName: params['application_name'],
    role: params['role'],
    binaryTransfer: params['binary_transfer'] != 'false',
    compression: params['compression'] ?? 'off',
  );
}

ScratchBirdConfig _fromKv(String dsn) {
  final parts = dsn.split(RegExp(r'\s+'));
  final params = <String, String>{};
  for (final part in parts) {
    final idx = part.indexOf('=');
    if (idx <= 0) continue;
    params[part.substring(0, idx)] = part.substring(idx + 1);
  }
  final normalized = _normalizeParams(params);
  return ScratchBirdConfig(
    host: normalized['host'] ?? 'localhost',
    port: int.tryParse(normalized['port'] ?? '3092') ?? 3092,
    protocol: normalizeNativeProtocol(normalized['protocol'] ?? normalized['parser'] ?? normalized['dialect']),
    database: normalized['database'] ?? normalized['dbname'] ?? '',
    user: normalized['user'] ?? '',
    password: normalized['password'],
    sslmode: normalized['sslmode'] ?? 'require',
    applicationName: normalized['application_name'],
    role: normalized['role'],
    binaryTransfer: normalized['binary_transfer'] != 'false',
    compression: normalized['compression'] ?? 'off',
  );
}

String normalizeNativeProtocol(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  switch (normalized) {
    case '':
    case 'native':
    case 'scratchbird':
    case 'scratchbird-native':
    case 'scratchbird_native':
      return 'native';
    default:
      throw ArgumentError(
          'Only protocol=native is supported; connect to the native parser listener/port.');
  }
}

Map<String, String> _normalizeParams(Map<String, String> params) {
  final out = <String, String>{};
  params.forEach((key, value) {
    final lower = key.toLowerCase();
    switch (lower) {
      case 'dbname':
        out['database'] = value;
        break;
      case 'username':
        out['user'] = value;
        break;
      case 'applicationname':
        out['application_name'] = value;
        break;
      case 'searchpath':
        out['search_path'] = value;
        break;
      case 'binarytransfer':
        out['binary_transfer'] = value;
        break;
      default:
        out[lower] = value;
    }
  });
  return out;
}

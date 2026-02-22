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
  final String frontDoorMode;
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
  final String? managerAuthToken;
  final String? managerUsername;
  final String? managerDatabase;
  final String? managerConnectionProfile;
  final String? managerClientIntent;
  final int managerClientFlags;
  final bool managerAuthFastPath;

  const ScratchBirdConfig({
    required this.host,
    required this.port,
    this.protocol = 'native',
    this.frontDoorMode = 'direct',
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
    this.managerAuthToken,
    this.managerUsername,
    this.managerDatabase,
    this.managerConnectionProfile = 'native_v3',
    this.managerClientIntent = 'native_v3',
    this.managerClientFlags = 0,
    this.managerAuthFastPath = true,
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
    String? frontDoorMode,
    String? database,
    String? user,
    String? password,
    String? sslmode,
    String? applicationName,
    String? role,
    bool? binaryTransfer,
    String? managerAuthToken,
    String? managerUsername,
    String? managerDatabase,
    String? managerConnectionProfile,
    String? managerClientIntent,
    int? managerClientFlags,
    bool? managerAuthFastPath,
  }) {
    return ScratchBirdConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      frontDoorMode: frontDoorMode ?? this.frontDoorMode,
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
      managerAuthToken: managerAuthToken ?? this.managerAuthToken,
      managerUsername: managerUsername ?? this.managerUsername,
      managerDatabase: managerDatabase ?? this.managerDatabase,
      managerConnectionProfile:
          managerConnectionProfile ?? this.managerConnectionProfile,
      managerClientIntent: managerClientIntent ?? this.managerClientIntent,
      managerClientFlags: managerClientFlags ?? this.managerClientFlags,
      managerAuthFastPath: managerAuthFastPath ?? this.managerAuthFastPath,
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
    frontDoorMode: normalizeFrontDoorMode(params['front_door_mode']),
    database: uri.path.replaceFirst('/', ''),
    user: params['user'] ?? user,
    password: params['password'] ?? password,
    sslmode: params['sslmode'] ?? 'require',
    applicationName: params['application_name'],
    role: params['role'],
    binaryTransfer: _parseBool(params['binary_transfer'], true),
    compression: params['compression'] ?? 'off',
    fetchSize: _parseInt(params['fetch_size'], 0),
    managerAuthToken: params['manager_auth_token'],
    managerUsername: params['manager_username'],
    managerDatabase: params['manager_database'],
    managerConnectionProfile:
        params['manager_connection_profile'] ?? 'native_v3',
    managerClientIntent: params['manager_client_intent'] ?? 'native_v3',
    managerClientFlags: _parseInt(params['manager_client_flags'], 0),
    managerAuthFastPath: _parseBool(params['manager_auth_fast_path'], true),
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
    frontDoorMode: normalizeFrontDoorMode(normalized['front_door_mode']),
    database: normalized['database'] ?? normalized['dbname'] ?? '',
    user: normalized['user'] ?? '',
    password: normalized['password'],
    sslmode: normalized['sslmode'] ?? 'require',
    applicationName: normalized['application_name'],
    role: normalized['role'],
    binaryTransfer: _parseBool(normalized['binary_transfer'], true),
    compression: normalized['compression'] ?? 'off',
    fetchSize: _parseInt(normalized['fetch_size'], 0),
    managerAuthToken: normalized['manager_auth_token'],
    managerUsername: normalized['manager_username'],
    managerDatabase: normalized['manager_database'],
    managerConnectionProfile:
        normalized['manager_connection_profile'] ?? 'native_v3',
    managerClientIntent: normalized['manager_client_intent'] ?? 'native_v3',
    managerClientFlags: _parseInt(normalized['manager_client_flags'], 0),
    managerAuthFastPath:
        _parseBool(normalized['manager_auth_fast_path'], true),
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

String normalizeFrontDoorMode(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  switch (normalized) {
    case '':
    case 'direct':
      return 'direct';
    case 'manager_proxy':
    case 'manager-proxy':
    case 'managed':
      return 'manager_proxy';
    default:
      throw ArgumentError('front_door_mode must be direct or manager_proxy.');
  }
}

bool _parseBool(String? value, bool defaultValue) {
  if (value == null || value.isEmpty) {
    return defaultValue;
  }
  final normalized = value.toLowerCase();
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'on';
}

int _parseInt(String? value, int defaultValue) {
  if (value == null || value.isEmpty) {
    return defaultValue;
  }
  return int.tryParse(value) ?? defaultValue;
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
      case 'frontdoormode':
      case 'connection_mode':
      case 'ingress_mode':
        out['front_door_mode'] = value;
        break;
      case 'mcp_auth_token':
        out['manager_auth_token'] = value;
        break;
      case 'mcp_username':
        out['manager_username'] = value;
        break;
      case 'mcp_database':
        out['manager_database'] = value;
        break;
      case 'mcp_connection_profile':
        out['manager_connection_profile'] = value;
        break;
      case 'mcp_client_intent':
        out['manager_client_intent'] = value;
        break;
      case 'mcp_client_flags':
        out['manager_client_flags'] = value;
        break;
      case 'mcp_auth_fast_path':
        out['manager_auth_fast_path'] = value;
        break;
      default:
        out[lower] = value;
    }
  });
  return out;
}

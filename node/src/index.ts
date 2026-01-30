// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
export { Client, Pool } from "./client";
export type { ClientConfig, FieldDef, QueryResult, ParamValue } from "./types";
export {
  FORMAT_TEXT,
  FORMAT_BINARY,
  OID_BOOL,
  OID_BYTEA,
  OID_CHAR,
  OID_INT8,
  OID_INT2,
  OID_INT4,
  OID_TEXT,
  OID_JSON,
  OID_XML,
  OID_FLOAT4,
  OID_FLOAT8,
  OID_MONEY,
  OID_MACADDR,
  OID_CIDR,
  OID_INET,
  OID_VARCHAR,
  OID_DATE,
  OID_TIME,
  OID_TIMESTAMP,
  OID_TIMESTAMPTZ,
  OID_INTERVAL,
  OID_NUMERIC,
  OID_UUID,
  OID_JSONB,
  OID_INT4RANGE,
  OID_NUMRANGE,
  OID_TSRANGE,
  OID_TSTZRANGE,
  OID_DATERANGE,
  OID_INT8RANGE,
  OID_TSVECTOR,
  OID_TSQUERY,
  OID_SB_VECTOR,
  ScratchbirdJsonb,
  ScratchbirdJson,
  ScratchbirdGeometry,
  ScratchbirdRange,
  ScratchbirdInterval,
  ScratchbirdDate,
  ScratchbirdTime,
  ScratchbirdTimestamp,
  ScratchbirdTimestampTZ,
  ScratchbirdDecimal,
  ScratchbirdMoney,
  ScratchbirdRaw,
  encodeParam,
  decodeValue,
  oidToString,
} from "./types";
export { parseDsn } from "./dsn";
export { normalizeQuery } from "./sql";
export * from "./errors";

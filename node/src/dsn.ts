import { ClientConfig } from "./types";

export function parseDsn(dsn?: string): Partial<ClientConfig> {
  if (!dsn) {
    return {};
  }
  if (dsn.includes("://")) {
    return parseUri(dsn);
  }
  return parseKv(dsn);
}

function parseUri(dsn: string): Partial<ClientConfig> {
  const url = new URL(dsn);
  if (url.protocol !== "scratchbird:") {
    throw new Error(`Unsupported DSN scheme: ${url.protocol}`);
  }
  const params: Partial<ClientConfig> = {};
  if (url.hostname) params.host = url.hostname;
  if (url.port) params.port = Number(url.port);
  if (url.username) params.user = decodeURIComponent(url.username);
  if (url.password) params.password = decodeURIComponent(url.password);
  if (url.pathname && url.pathname !== "/") {
    params.database = url.pathname.replace(/^\//, "");
  }
  url.searchParams.forEach((value, key) => {
    setConfigParam(params, key, value);
  });
  return params;
}

function parseKv(dsn: string): Partial<ClientConfig> {
  const params: Partial<ClientConfig> = {};
  const tokens = dsn.split(/\s+/);
  for (const token of tokens) {
    const idx = token.indexOf("=");
    if (idx <= 0) continue;
    const key = token.slice(0, idx).trim();
    const value = token.slice(idx + 1).trim();
    setConfigParam(params, key, value);
  }
  return params;
}

function setConfigParam(config: Partial<ClientConfig>, key: string, value: string) {
  switch (key.toLowerCase()) {
    case "host":
      config.host = value;
      break;
    case "port":
      config.port = Number(value);
      break;
    case "database":
    case "dbname":
      config.database = value;
      break;
    case "user":
      config.user = value;
      break;
    case "password":
      config.password = value;
      break;
    case "schema":
    case "search_path":
    case "searchpath":
    case "currentschema":
      config.schema = value;
      break;
    case "sslmode":
      config.sslmode = value;
      break;
    case "sslrootcert":
      config.sslrootcert = value;
      break;
    case "sslcert":
      config.sslcert = value;
      break;
    case "sslkey":
      config.sslkey = value;
      break;
    case "connect_timeout":
    case "connecttimeout":
      config.connectTimeoutMs = Number(value) * 1000;
      break;
    case "socket_timeout":
    case "sockettimeout":
      config.socketTimeoutMs = Number(value) * 1000;
      break;
    case "application_name":
    case "applicationname":
      config.applicationName = value;
      break;
    case "binary_transfer":
    case "binarytransfer":
      config.binaryTransfer = value === "true" || value === "1";
      break;
    case "compression":
      config.compression = value === "zstd" ? "zstd" : "off";
      break;
    default:
      break;
  }
}

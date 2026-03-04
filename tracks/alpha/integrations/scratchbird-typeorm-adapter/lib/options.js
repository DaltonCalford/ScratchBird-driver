"use strict";

function parseBoolean(value) {
  if (value === undefined || value === null) {
    return undefined;
  }
  const normalized = String(value).trim().toLowerCase();
  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }
  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }
  return undefined;
}

function parseUrl(urlString) {
  if (!urlString) {
    return {};
  }
  let parsed;
  try {
    parsed = new URL(urlString);
  } catch (err) {
    throw new Error(`Invalid ScratchBird URL: ${err.message}`);
  }

  const query = {};
  parsed.searchParams.forEach((value, key) => {
    query[key] = value;
  });

  return {
    protocol: parsed.protocol,
    host: parsed.hostname || undefined,
    port: parsed.port ? Number(parsed.port) : undefined,
    database: parsed.pathname ? parsed.pathname.replace(/^\//, "") : undefined,
    username: parsed.username || undefined,
    password: parsed.password || undefined,
    query,
  };
}

function enforceGuardrails(params) {
  const normalized = Object.create(null);
  for (const [rawKey, rawValue] of Object.entries(params || {})) {
    const key = String(rawKey).toLowerCase();
    const value = String(rawValue).trim().toLowerCase();

    if (key === "sslmode" && value === "disable") {
      throw new Error("sslmode=disable is not supported");
    }
    if (["binarytransfer", "binary_transfer"].includes(key)) {
      const boolValue = parseBoolean(value);
      if (boolValue === false) {
        throw new Error("binaryTransfer=false is not supported");
      }
    }
    if (key === "compression" && value === "zstd") {
      throw new Error("compression=zstd is not supported");
    }

    normalized[rawKey] = rawValue;
  }
  return normalized;
}

function normalizeTypeOrmOptions(options) {
  const input = options || {};
  const fromUrl = parseUrl(input.url);

  if (fromUrl.protocol && fromUrl.protocol !== "scratchbird:") {
    throw new Error("TypeORM URL protocol must be scratchbird://");
  }

  const mergedExtra = {
    ...(fromUrl.query || {}),
    ...(input.extra || {}),
  };

  enforceGuardrails(mergedExtra);

  return {
    type: input.type || "scratchbird",
    host: input.host || fromUrl.host || "localhost",
    port: Number(input.port || fromUrl.port || 3092),
    database: input.database || fromUrl.database || "main",
    username: input.username || fromUrl.username,
    password: input.password || fromUrl.password,
    extra: mergedExtra,
  };
}

module.exports = {
  normalizeTypeOrmOptions,
  enforceGuardrails,
  parseBoolean,
};

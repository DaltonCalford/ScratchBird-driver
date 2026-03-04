"use strict";

function _isFalsey(value) {
  return ["false", "0", "no", "off"].includes(String(value).trim().toLowerCase());
}

function parseScratchbirdConnectionUrl(urlString) {
  if (!urlString || typeof urlString !== "string") {
    throw new Error("connection URL is required");
  }

  let parsed;
  try {
    parsed = new URL(urlString);
  } catch (error) {
    throw new Error(`invalid connection URL: ${error.message}`);
  }

  if (parsed.protocol !== "scratchbird:") {
    throw new Error("Prisma adapter requires scratchbird:// URLs");
  }

  const params = Object.fromEntries(parsed.searchParams.entries());

  if (String(params.sslmode || "require").toLowerCase() === "disable") {
    throw new Error("sslmode=disable is not supported");
  }

  const binaryTransfer = params.binaryTransfer ?? params.binary_transfer;
  if (binaryTransfer !== undefined && _isFalsey(binaryTransfer)) {
    throw new Error("binary_transfer=false is not supported");
  }

  if (String(params.compression || "off").toLowerCase() === "zstd") {
    throw new Error("compression=zstd is not supported");
  }

  return {
    host: parsed.hostname || "localhost",
    port: parsed.port ? Number(parsed.port) : 3092,
    database: (parsed.pathname || "").replace(/^\//, ""),
    username: decodeURIComponent(parsed.username || ""),
    password: decodeURIComponent(parsed.password || ""),
    params,
  };
}

function validatePrismaSchemaText(schemaText) {
  if (!schemaText || typeof schemaText !== "string") {
    throw new Error("schema.prisma text is required");
  }

  if (!/\bdatasource\s+\w+\s*\{/.test(schemaText)) {
    throw new Error("schema.prisma is missing datasource block");
  }
  if (!/\bgenerator\s+\w+\s*\{/.test(schemaText)) {
    throw new Error("schema.prisma is missing generator block");
  }
  if (!/url\s*=\s*env\(\s*"DATABASE_URL"\s*\)/.test(schemaText)) {
    throw new Error("schema.prisma datasource must use env(\"DATABASE_URL\")");
  }

  return true;
}

module.exports = {
  parseScratchbirdConnectionUrl,
  validatePrismaSchemaText,
};

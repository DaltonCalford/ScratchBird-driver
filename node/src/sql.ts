import { Buffer } from "node:buffer";

function escapeString(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/'/g, "''");
}

function formatParam(value: any): string {
  if (value === null || value === undefined) {
    return "NULL";
  }
  if (typeof value === "boolean") {
    return value ? "TRUE" : "FALSE";
  }
  if (typeof value === "number" || typeof value === "bigint") {
    return String(value);
  }
  if (value instanceof Buffer) {
    return `X'${value.toString("hex").toUpperCase()}'`;
  }
  if (value instanceof Uint8Array) {
    return `X'${Buffer.from(value).toString("hex").toUpperCase()}'`;
  }
  if (value instanceof Date) {
    const iso = value.toISOString().replace("T", " ").replace("Z", "");
    return `TIMESTAMP '${iso}'`;
  }
  if (Array.isArray(value)) {
    return formatArray(value);
  }
  if (typeof value === "object") {
    return `JSON '${escapeString(JSON.stringify(value))}'`;
  }
  return `'${escapeString(String(value))}'`;
}

function formatArray(values: any[]): string {
  const items = values.map((item) => (Array.isArray(item) ? formatArray(item) : formatParam(item)));
  return `ARRAY[${items.join(", ")}]`;
}

export function substituteParameters(sql: string, params?: any[] | Record<string, any>): string {
  if (!params) {
    return sql;
  }
  if (!Array.isArray(params)) {
    return substituteNamed(sql, params);
  }
  return substitutePositional(sql, params);
}

function substituteNamed(sql: string, params: Record<string, any>): string {
  let result = "";
  let i = 0;
  while (i < sql.length) {
    const ch = sql[i];
    if (ch === "'" && i + 1 < sql.length) {
      result += ch;
      i++;
      while (i < sql.length) {
        result += sql[i];
        if (sql[i] === "'" && (i + 1 >= sql.length || sql[i + 1] !== "'")) {
          i++;
          break;
        }
        if (sql[i] === "'" && sql[i + 1] === "'") {
          i++;
        }
        i++;
      }
      continue;
    }
    if (ch === ":" && i + 1 < sql.length && /[a-zA-Z_]/.test(sql[i + 1])) {
      let j = i + 1;
      while (j < sql.length && /[a-zA-Z0-9_]/.test(sql[j])) j++;
      const key = sql.slice(i + 1, j);
      if (Object.prototype.hasOwnProperty.call(params, key)) {
        result += formatParam(params[key]);
      } else {
        result += sql.slice(i, j);
      }
      i = j;
      continue;
    }
    result += ch;
    i++;
  }
  return result;
}

function substitutePositional(sql: string, values: any[]): string {
  let result = "";
  let i = 0;
  let nextParam = 0;
  while (i < sql.length) {
    const ch = sql[i];
    if (ch === "$" && i + 1 < sql.length && /[0-9]/.test(sql[i + 1])) {
      let j = i + 1;
      let num = 0;
      while (j < sql.length && /[0-9]/.test(sql[j])) {
        num = num * 10 + Number(sql[j]);
        j++;
      }
      if (num > 0 && num <= values.length) {
        result += formatParam(values[num - 1]);
      } else {
        result += sql.slice(i, j);
      }
      i = j;
      continue;
    }
    if (ch === "?") {
      if (nextParam < values.length) {
        result += formatParam(values[nextParam]);
        nextParam++;
      } else {
        result += ch;
      }
      i++;
      continue;
    }
    if (ch === "'" && i + 1 < sql.length) {
      result += ch;
      i++;
      while (i < sql.length) {
        result += sql[i];
        if (sql[i] === "'" && (i + 1 >= sql.length || sql[i + 1] !== "'")) {
          i++;
          break;
        }
        if (sql[i] === "'" && sql[i + 1] === "'") {
          i++;
        }
        i++;
      }
      continue;
    }
    if (ch === "-" && i + 1 < sql.length && sql[i + 1] === "-") {
      while (i < sql.length && sql[i] !== "\n") {
        result += sql[i];
        i++;
      }
      continue;
    }
    if (ch === "/" && i + 1 < sql.length && sql[i + 1] === "*") {
      result += ch + sql[i + 1];
      i += 2;
      while (i + 1 < sql.length && !(sql[i] === "*" && sql[i + 1] === "/")) {
        result += sql[i];
        i++;
      }
      if (i + 1 < sql.length) {
        result += sql[i] + sql[i + 1];
        i += 2;
      }
      continue;
    }
    result += ch;
    i++;
  }
  return result;
}

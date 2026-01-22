export interface NormalizedQuery {
  sql: string;
  params: any[];
}

export function normalizeQuery(sql: string, params?: any[] | Record<string, any>): NormalizedQuery {
  if (!params) {
    return { sql, params: [] };
  }
  if (Array.isArray(params)) {
    if (sql.includes("?")) {
      const rewritten = rewritePositional(sql, params);
      return { sql: rewritten.sql, params: rewritten.params };
    }
    return { sql, params };
  }
  if (!hasNamedParams(sql)) {
    throw new Error("named parameters provided but query has no named placeholders");
  }
  const rewritten = rewriteNamed(sql, params);
  return { sql: rewritten.sql, params: rewritten.params };
}

function hasNamedParams(sql: string): boolean {
  let inString = false;
  for (let i = 0; i + 1 < sql.length; i++) {
    const ch = sql[i];
    if (ch === "'") {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if ((ch === ":" || ch === "@") && isIdentStart(sql[i + 1])) {
      return true;
    }
  }
  return false;
}

function rewriteNamed(sql: string, params: Record<string, any>): NormalizedQuery {
  const lookup: Record<string, any> = {};
  for (const [key, value] of Object.entries(params)) {
    lookup[key.replace(/^[@:]/, "")] = value;
  }
  let result = "";
  const ordered: any[] = [];
  let inString = false;
  for (let i = 0; i < sql.length; ) {
    const ch = sql[i];
    if (ch === "'") {
      inString = !inString;
      result += ch;
      i++;
      continue;
    }
    if (!inString && (ch === ":" || ch === "@") && i + 1 < sql.length && isIdentStart(sql[i + 1])) {
      let j = i + 1;
      while (j < sql.length && isIdentPart(sql[j])) j++;
      const key = sql.slice(i + 1, j);
      if (!(key in lookup)) {
        throw new Error(`missing named parameter: ${key}`);
      }
      ordered.push(lookup[key]);
      result += `$${ordered.length}`;
      i = j;
      continue;
    }
    result += ch;
    i++;
  }
  return { sql: result, params: ordered };
}

function rewritePositional(sql: string, params: any[]): NormalizedQuery {
  let result = "";
  const ordered: any[] = [];
  let inString = false;
  let index = 0;
  for (let i = 0; i < sql.length; ) {
    const ch = sql[i];
    if (ch === "'") {
      inString = !inString;
      result += ch;
      i++;
      continue;
    }
    if (!inString && ch === "?") {
      if (index >= params.length) {
        throw new Error("not enough parameters");
      }
      ordered.push(params[index]);
      index++;
      result += `$${ordered.length}`;
      i++;
      continue;
    }
    result += ch;
    i++;
  }
  if (index < params.length) {
    throw new Error("too many parameters");
  }
  return { sql: result, params: ordered };
}

function isIdentStart(ch: string): boolean {
  return /[A-Za-z_]/.test(ch);
}

function isIdentPart(ch: string): boolean {
  return /[A-Za-z0-9_]/.test(ch);
}

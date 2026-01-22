import crypto from "node:crypto";

export class ScramExchange {
  private clientNonce: string;
  private clientFirstBare = "";
  private serverSignature?: Buffer;

  constructor(private username: string, nonce?: string) {
    this.clientNonce = nonce ?? generateNonce();
  }

  clientFirstMessage(): string {
    this.clientFirstBare = `n=${escapeValue(this.username)},r=${this.clientNonce}`;
    return `n,,${this.clientFirstBare}`;
  }

  handleServerFirst(password: string, serverFirst: string): string {
    const attrs = parseAttributes(serverFirst);
    const nonce = attrs.r;
    const saltB64 = attrs.s;
    const iterStr = attrs.i;

    if (!nonce || !nonce.startsWith(this.clientNonce)) {
      throw new Error("SCRAM server nonce mismatch");
    }
    if (!saltB64 || !iterStr) {
      throw new Error("SCRAM server-first missing fields");
    }

    const iterations = Number(iterStr);
    const salt = Buffer.from(saltB64, "base64");
    const saltedPassword = hi(password, salt, iterations);
    const clientKey = hmac(saltedPassword, "Client Key");
    const storedKey = sha256(clientKey);

    const clientFinalWithoutProof = `c=biws,r=${nonce}`;
    const authMessage = `${this.clientFirstBare},${serverFirst},${clientFinalWithoutProof}`;

    const clientSignature = hmac(storedKey, authMessage);
    const clientProof = xor(clientKey, clientSignature);
    const serverKey = hmac(saltedPassword, "Server Key");
    this.serverSignature = hmac(serverKey, authMessage);

    return `${clientFinalWithoutProof},p=${clientProof.toString("base64")}`;
  }

  verifyServerFinal(serverFinal: string): void {
    const attrs = parseAttributes(serverFinal);
    const verifier = attrs.v;
    if (!verifier || !this.serverSignature) {
      throw new Error("SCRAM server-final missing verifier");
    }
    const expected = this.serverSignature.toString("base64");
    if (verifier !== expected) {
      throw new Error("SCRAM server signature mismatch");
    }
  }
}

function generateNonce(): string {
  return crypto.randomBytes(18).toString("base64");
}

function escapeValue(value: string): string {
  return value.replace(/=/g, "=3D").replace(/,/g, "=2C");
}

function parseAttributes(message: string): Record<string, string> {
  const attrs: Record<string, string> = {};
  if (!message) return attrs;
  for (const part of message.split(",")) {
    const idx = part.indexOf("=");
    if (idx > 0) {
      attrs[part.slice(0, idx)] = part.slice(idx + 1);
    }
  }
  return attrs;
}

function hi(password: string, salt: Buffer, iterations: number): Buffer {
  return crypto.pbkdf2Sync(password, salt, iterations, 32, "sha256");
}

function hmac(key: Buffer, data: string): Buffer {
  return crypto.createHmac("sha256", key).update(data).digest();
}

function sha256(data: Buffer): Buffer {
  return crypto.createHash("sha256").update(data).digest();
}

function xor(left: Buffer, right: Buffer): Buffer {
  const out = Buffer.alloc(left.length);
  for (let i = 0; i < left.length; i++) {
    out[i] = left[i] ^ right[i];
  }
  return out;
}

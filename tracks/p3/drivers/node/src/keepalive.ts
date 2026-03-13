// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

export interface KeepaliveConfig {
  intervalMs?: number;
  maxIdleBeforeCheckMs?: number;
  validationTimeoutMs?: number;
}

export class KeepaliveTracker {
  private lastActivity = Date.now();

  constructor(private readonly config: Required<KeepaliveConfig>) {}

  markActive(): void {
    this.lastActivity = Date.now();
  }

  needsValidation(): boolean {
    return Date.now() - this.lastActivity > this.config.maxIdleBeforeCheckMs;
  }

  idleDurationMs(): number {
    return Date.now() - this.lastActivity;
  }
}

type Pinger = () => boolean | Promise<boolean>;

export class KeepaliveManager {
  private readonly config: Required<KeepaliveConfig>;
  private readonly trackers = new Map<string, KeepaliveTracker>();
  private readonly pingers = new Map<string, Pinger>();
  private timer?: NodeJS.Timeout;

  constructor(config: KeepaliveConfig = {}) {
    this.config = {
      intervalMs: config.intervalMs ?? 120_000,
      maxIdleBeforeCheckMs: config.maxIdleBeforeCheckMs ?? 600_000,
      validationTimeoutMs: config.validationTimeoutMs ?? 5_000,
    };
  }

  start(): void {
    if (this.timer) {
      return;
    }
    this.timer = setInterval(() => void this.checkConnections(), this.config.intervalMs);
    this.timer.unref?.();
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
  }

  register(connId: string, pinger: Pinger): KeepaliveTracker {
    const tracker = new KeepaliveTracker(this.config);
    this.trackers.set(connId, tracker);
    this.pingers.set(connId, pinger);
    return tracker;
  }

  unregister(connId: string): void {
    this.trackers.delete(connId);
    this.pingers.delete(connId);
  }

  private async checkConnections(): Promise<void> {
    for (const [connId, tracker] of this.trackers.entries()) {
      if (!tracker.needsValidation()) {
        continue;
      }
      const pinger = this.pingers.get(connId);
      if (!pinger) {
        continue;
      }
      try {
        const healthy = await this.pingWithTimeout(pinger, this.config.validationTimeoutMs);
        if (healthy) {
          tracker.markActive();
        }
      } catch {
        // ping failed; connection will be handled on next request
      }
    }
  }

  private async pingWithTimeout(pinger: Pinger, timeoutMs: number): Promise<boolean> {
    const result = Promise.resolve().then(() => pinger());
    const timeout = new Promise<boolean>((resolve) => {
      const handle = setTimeout(() => resolve(false), timeoutMs);
      handle.unref?.();
    });
    return Promise.race([result, timeout]);
  }
}

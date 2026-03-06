// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data;

namespace ScratchBird.Data;

public enum ScratchBirdTransactionAccessMode : byte
{
    ReadWrite = 0,
    ReadOnly = 1
}

public sealed class ScratchBirdTransactionOptions
{
    public IsolationLevel IsolationLevel { get; set; } = IsolationLevel.ReadCommitted;
    public ScratchBirdTransactionAccessMode? AccessMode { get; set; }
    public bool? Deferrable { get; set; }
    public bool? Wait { get; set; }
    public int? TimeoutMs { get; set; }
    public bool? AutoCommit { get; set; }
}

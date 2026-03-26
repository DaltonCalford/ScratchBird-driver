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

public enum ScratchBirdReadCommittedMode : byte
{
    Default = ProtocolConstants.ReadCommittedModeDefault,
    ReadConsistency = ProtocolConstants.ReadCommittedModeReadConsistency,
    RecordVersion = ProtocolConstants.ReadCommittedModeRecordVersion,
    NoRecordVersion = ProtocolConstants.ReadCommittedModeNoRecordVersion
}

public sealed class ScratchBirdTransactionOptions
{
    // Public isolation aliases map onto the canonical MGA modes:
    // ReadCommitted => READ COMMITTED
    // RepeatableRead => SNAPSHOT
    // Serializable / Snapshot / Chaos => SNAPSHOT TABLE STABILITY
    // ReadCommittedMode selects the canonical READ COMMITTED sub-mode when the
    // public isolation surface stays in the READ COMMITTED alias family.
    public IsolationLevel IsolationLevel { get; set; } = IsolationLevel.ReadCommitted;
    public ScratchBirdReadCommittedMode? ReadCommittedMode { get; set; }
    public ScratchBirdTransactionAccessMode? AccessMode { get; set; }
    public bool? Deferrable { get; set; }
    public bool? Wait { get; set; }
    public int? TimeoutMs { get; set; }
    public bool? AutoCommit { get; set; }
}

// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
namespace ScratchBird.Data;

public sealed record FieldSummary(string Name, uint TypeOid, ushort Format, bool Nullable);

public sealed record ResultSetSummary(
    IReadOnlyList<object?[]> Rows,
    long RowCount,
    IReadOnlyList<FieldSummary> Fields,
    string Command,
    long LastInsertId);

public sealed record BatchItemSummary(
    int Index,
    long RowCount,
    IReadOnlyList<FieldSummary> Fields,
    string Command,
    long LastInsertId);

public sealed record BatchSummary(
    IReadOnlyList<BatchItemSummary> Items,
    long TotalRowCount);

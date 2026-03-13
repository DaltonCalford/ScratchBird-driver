// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
namespace ScratchBird.Data;

public sealed record DdlEditorSchemaNode(
    string Name,
    string FullPath,
    bool IsTerminal,
    IReadOnlyList<DdlEditorSchemaNode> Children);

public sealed record DdlEditorSchemaPayload(
    string? SchemaPattern,
    bool ExpandSchemaParents,
    IReadOnlyList<string> SchemaPaths,
    IReadOnlyList<DdlEditorSchemaNode> SchemaTree);

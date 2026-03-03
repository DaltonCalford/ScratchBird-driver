{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program MetadataRecursiveSchemaTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Variants, ScratchBird.Metadata;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(Value: Boolean; const MessageText: string);
begin
  if not Value then
    Fail(MessageText);
end;

procedure AssertEqualInt(Expected, Actual: Integer; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

procedure AssertEqualString(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected="' + Expected + '" actual="' + Actual + '"');
end;

procedure AssertVariantInt(Expected: Integer; const Value: Variant; const MessageText: string);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    Fail(MessageText + ': expected integer but value is null/empty');
  if Integer(Value) <> Expected then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Integer(Value)));
end;

function MetadataField(const Name: string; const Value: Variant): TMetadataField;
begin
  Result.Name := Name;
  Result.Value := Value;
end;

function MetadataRow(const Fields: array of TMetadataField): TMetadataRow;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Fields));
  for I := 0 to High(Fields) do
    Result[I] := Fields[I];
end;

function SchemaRow(const SchemaName: string): TMetadataRow;
begin
  Result := MetadataRow([MetadataField('schema_name', SchemaName)]);
end;

function StringArray(const Values: array of string): TArray<string>;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Values));
  for I := 0 to High(Values) do
    Result[I] := Values[I];
end;

function CollectSchemaValues(const Rows: TMetadataRows; const Key: string): TArray<string>;
var
  Value: Variant;
  I, Count: Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  for I := 0 to High(Rows) do
  begin
    if not MetadataRowTryGetValue(Rows[I], Key, Value) then
      Continue;
    if VarIsNull(Value) or VarIsEmpty(Value) then
      Continue;
    Count := Length(Result);
    SetLength(Result, Count + 1);
    Result[Count] := VarToStr(Value);
  end;
end;

procedure AssertEqualStringArray(const Expected, Actual: TArray<string>; const MessageText: string);
var
  I: Integer;
begin
  if Length(Expected) <> Length(Actual) then
    Fail(MessageText + ': expected count=' + IntToStr(Length(Expected)) + ' actual count=' + IntToStr(Length(Actual)));
  for I := 0 to High(Expected) do
    if Expected[I] <> Actual[I] then
      Fail(MessageText + ': mismatch at index ' + IntToStr(I) + ' expected="' + Expected[I] + '" actual="' + Actual[I] + '"');
end;

function CountChildrenByName(Node: TMetadataSchemaTreeNode; const Name: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Node.ChildCount - 1 do
  begin
    if Node.Children[I].Name = Name then
      Inc(Result);
  end;
end;

procedure TestExpandMetadataRowsSupportsDatabaseDefaultBranchStyleRows;
var
  Rows: TMetadataRows;
  Expanded: TMetadataRows;
  SchemaId: Variant;
begin
  SetLength(Rows, 2);
  Rows[0] := MetadataRow([
    MetadataField('schema_id', 11),
    MetadataField('TABLE_SCHEM', 'database.default.users'),
    MetadataField('TABLE_CATALOG', 'database')
  ]);
  Rows[1] := MetadataRow([
    MetadataField('schema_id', 12),
    MetadataField('TABLE_SCHEM', 'database.default.audit'),
    MetadataField('TABLE_CATALOG', 'database')
  ]);

  Expanded := ExpandSchemaMetadataRows(Rows);

  AssertEqualStringArray(
    StringArray(['database', 'database.default', 'database.default.users', 'database.default.audit']),
    CollectSchemaValues(Expanded, 'TABLE_SCHEM'),
    'database/default branch-style schema expansion');

  AssertTrue(MetadataRowTryGetValue(Expanded[0], 'schema_id', SchemaId), 'expanded row 0 should include schema_id');
  AssertTrue(VarIsNull(SchemaId), 'expanded row 0 schema_id should be null');
  AssertTrue(MetadataRowTryGetValue(Expanded[1], 'schema_id', SchemaId), 'expanded row 1 should include schema_id');
  AssertTrue(VarIsNull(SchemaId), 'expanded row 1 schema_id should be null');
  AssertTrue(MetadataRowTryGetValue(Expanded[2], 'schema_id', SchemaId), 'expanded row 2 should include schema_id');
  AssertVariantInt(11, SchemaId, 'expanded row 2 schema_id');
  AssertTrue(MetadataRowTryGetValue(Expanded[3], 'schema_id', SchemaId), 'expanded row 3 should include schema_id');
  AssertVariantInt(12, SchemaId, 'expanded row 3 schema_id');
end;

procedure TestListMetadataSchemaPathsExpandsDottedParents;
var
  Rows: TMetadataRows;
  ExpandedPaths: TArray<string>;
begin
  SetLength(Rows, 6);
  Rows[0] := SchemaRow('users.alice.dev');
  Rows[1] := SchemaRow('sys');
  Rows[2] := SchemaRow('users.bob.dev');
  Rows[3] := SchemaRow('users.bob.dev');
  Rows[4] := SchemaRow('users..bob.dev');
  Rows[5] := SchemaRow('');

  ExpandedPaths := ListMetadataSchemaPaths(Rows, True);
  AssertEqualStringArray(
    StringArray(['users', 'users.alice', 'users.alice.dev', 'sys', 'users.bob', 'users.bob.dev']),
    ExpandedPaths,
    'dotted parent expansion order and uniqueness');
end;

procedure TestBuildMetadataSchemaTreeEnforcesPerParentUniqueness;
var
  Rows: TMetadataRows;
  Tree: TMetadataSchemaTree;
  BobNode: TMetadataSchemaTreeNode;
begin
  SetLength(Rows, 3);
  Rows[0] := SchemaRow('users.bob.dev');
  Rows[1] := SchemaRow('users.bob.dev');
  Rows[2] := SchemaRow('users.bob.prod');

  Tree := BuildMetadataSchemaTree(Rows, False);
  try
    BobNode := Tree.FindNodeByPath('users.bob');
    AssertTrue(BobNode <> nil, 'users.bob node should exist');
    AssertEqualInt(2, BobNode.ChildCount, 'users.bob child count');
    AssertEqualString('users.bob.dev', BobNode.Children[0].Path, 'first child path');
    AssertEqualString('users.bob.prod', BobNode.Children[1].Path, 'second child path');
    AssertEqualInt(1, CountChildrenByName(BobNode, 'dev'), 'unique child names per parent');
  finally
    Tree.Free;
  end;
end;

procedure TestBuildMetadataSchemaTreeAllowsSameLeafUnderDifferentParents;
var
  Rows: TMetadataRows;
  Tree: TMetadataSchemaTree;
  AliceDev, BobDev: TMetadataSchemaTreeNode;
begin
  SetLength(Rows, 2);
  Rows[0] := SchemaRow('users.alice.dev');
  Rows[1] := SchemaRow('users.bob.dev');

  Tree := BuildMetadataSchemaTree(Rows, True, 'demo');
  try
    AssertEqualString('demo', Tree.Database, 'tree database label');
    AliceDev := Tree.FindNodeByPath('users.alice.dev');
    BobDev := Tree.FindNodeByPath('users.bob.dev');
    AssertTrue(AliceDev <> nil, 'users.alice.dev should exist');
    AssertTrue(BobDev <> nil, 'users.bob.dev should exist');
    AssertEqualString('dev', AliceDev.Name, 'alice leaf name');
    AssertEqualString('dev', BobDev.Name, 'bob leaf name');
    AssertTrue(AliceDev.Path <> BobDev.Path, 'leaf paths should differ');
    AssertTrue(AliceDev <> BobDev, 'leaf nodes should be distinct instances');
  finally
    Tree.Free;
  end;
end;

begin
  try
    TestExpandMetadataRowsSupportsDatabaseDefaultBranchStyleRows;
    TestListMetadataSchemaPathsExpandsDottedParents;
    TestBuildMetadataSchemaTreeEnforcesPerParentUniqueness;
    TestBuildMetadataSchemaTreeAllowsSameLeafUnderDifferentParents;
    Writeln('MetadataRecursiveSchemaTests: OK');
  except
    on E: Exception do
    begin
      Writeln('MetadataRecursiveSchemaTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

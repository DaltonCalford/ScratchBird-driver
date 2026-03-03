{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/ }

unit ScratchBird.Metadata;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, Classes, Variants, Contnrs;

type
  TMetadataField = record
    Name: string;
    Value: Variant;
  end;

  TMetadataRow = TArray<TMetadataField>;
  TMetadataRows = TArray<TMetadataRow>;

  TMetadataSchemaTreeNode = class
  private
    FName: string;
    FPath: string;
    FTerminal: Boolean;
    FChildren: TObjectList;
    function GetChild(Index: Integer): TMetadataSchemaTreeNode;
    function GetChildCount: Integer;
  public
    constructor Create(const AName, APath: string; ATerminal: Boolean);
    destructor Destroy; override;
    function EnsureChild(const AName, APath: string; ATerminal: Boolean): TMetadataSchemaTreeNode;
    function FindDescendantByPath(const APath: string): TMetadataSchemaTreeNode;
    property Name: string read FName;
    property Path: string read FPath;
    property Terminal: Boolean read FTerminal write FTerminal;
    property ChildCount: Integer read GetChildCount;
    property Children[Index: Integer]: TMetadataSchemaTreeNode read GetChild;
  end;

  TMetadataSchemaTree = class
  private
    FDatabase: string;
    FSchemaRoots: TObjectList;
    function GetSchema(Index: Integer): TMetadataSchemaTreeNode;
    function GetSchemaCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function EnsureRoot(const AName, APath: string; ATerminal: Boolean): TMetadataSchemaTreeNode;
    function FindNodeByPath(const APath: string): TMetadataSchemaTreeNode;
    property Database: string read FDatabase write FDatabase;
    property SchemaCount: Integer read GetSchemaCount;
    property Schemas[Index: Integer]: TMetadataSchemaTreeNode read GetSchema;
  end;

function MetadataSchemasQuery: string;
function MetadataTablesQuery: string;
function MetadataColumnsQuery: string;
function MetadataIndexesQuery: string;
function MetadataIndexColumnsQuery: string;
function MetadataConstraintsQuery: string;
function MetadataProceduresQuery: string;
function MetadataFunctionsQuery: string;
function MetadataRowTryGetValue(const Row: TMetadataRow; const Key: string; out Value: Variant): Boolean;
function ExpandSchemaPaths(const SchemaPaths: array of string): TArray<string>;
function ListMetadataSchemaPaths(const Rows: TMetadataRows; ExpandParents: Boolean): TArray<string>;
function ExpandSchemaMetadataRows(const Rows: TMetadataRows): TMetadataRows;
function BuildMetadataSchemaTree(const Rows: TMetadataRows; ExpandParents: Boolean;
  const Database: string = ''): TMetadataSchemaTree;

implementation

const
  SCHEMA_FIELD_CANDIDATES: array[0..5] of string = (
    'schema_name',
    'TABLE_SCHEM',
    'table_schem',
    'table_schema',
    'TABLE_SCHEMA',
    'schema'
  );

function AppendUniqueString(var Values: TArray<string>; Seen: TStringList; const Value: string): Boolean;
var
  Count: Integer;
begin
  if Seen.IndexOf(Value) >= 0 then
    Exit(False);
  Seen.Add(Value);
  Count := Length(Values);
  SetLength(Values, Count + 1);
  Values[Count] := Value;
  Result := True;
end;

function MarkSeen(Seen: TStringList; const Value: string): Boolean;
begin
  if Seen.IndexOf(Value) >= 0 then
    Exit(False);
  Seen.Add(Value);
  Result := True;
end;

function IsSchemaFieldCandidate(const Name: string): Boolean;
var
  I: Integer;
begin
  for I := Low(SCHEMA_FIELD_CANDIDATES) to High(SCHEMA_FIELD_CANDIDATES) do
  begin
    if SameText(Name, SCHEMA_FIELD_CANDIDATES[I]) then
      Exit(True);
  end;
  Result := False;
end;

function SplitSchemaPath(const Value: string): TArray<string>;
var
  I, StartIndex, Count: Integer;
  Segment: string;
begin
  Result := nil;
  SetLength(Result, 0);
  StartIndex := 1;
  for I := 1 to Length(Value) + 1 do
  begin
    if (I > Length(Value)) or (Value[I] = '.') then
    begin
      Segment := Trim(Copy(Value, StartIndex, I - StartIndex));
      if Segment <> '' then
      begin
        Count := Length(Result);
        SetLength(Result, Count + 1);
        Result[Count] := Segment;
      end;
      StartIndex := I + 1;
    end;
  end;
end;

function NormalizeSchemaPath(const Value: string; out Normalized: string): Boolean;
var
  Parts: TArray<string>;
  I: Integer;
begin
  Parts := SplitSchemaPath(Value);
  if Length(Parts) = 0 then
  begin
    Normalized := '';
    Exit(False);
  end;
  Normalized := Parts[0];
  for I := 1 to High(Parts) do
    Normalized := Normalized + '.' + Parts[I];
  Result := True;
end;

function CloneMetadataRow(const Row: TMetadataRow): TMetadataRow;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Row));
  for I := 0 to High(Row) do
  begin
    Result[I].Name := Row[I].Name;
    Result[I].Value := Row[I].Value;
  end;
end;

function MetadataRowTryGetValue(const Row: TMetadataRow; const Key: string; out Value: Variant): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Row) do
  begin
    if SameText(Row[I].Name, Key) then
    begin
      Value := Row[I].Value;
      Exit(True);
    end;
  end;
  Value := Null;
  Result := False;
end;

function TryReadSchemaPath(const Row: TMetadataRow; out SchemaPath: string): Boolean;
var
  I: Integer;
  Value: Variant;
begin
  for I := Low(SCHEMA_FIELD_CANDIDATES) to High(SCHEMA_FIELD_CANDIDATES) do
  begin
    if not MetadataRowTryGetValue(Row, SCHEMA_FIELD_CANDIDATES[I], Value) then
      Continue;
    if VarIsNull(Value) or VarIsEmpty(Value) then
      Continue;
    if NormalizeSchemaPath(VarToStr(Value), SchemaPath) then
      Exit(True);
  end;
  SchemaPath := '';
  Result := False;
end;

function CreateSyntheticSchemaRow(const Sample: TMetadataRow; const SchemaPath: string): TMetadataRow;
var
  I, Count: Integer;
  AssignedSchemaField: Boolean;
begin
  Result := nil;
  SetLength(Result, Length(Sample));
  for I := 0 to High(Sample) do
  begin
    Result[I].Name := Sample[I].Name;
    Result[I].Value := Null;
  end;

  AssignedSchemaField := False;
  for I := 0 to High(Result) do
  begin
    if not IsSchemaFieldCandidate(Result[I].Name) then
      Continue;
    Result[I].Value := SchemaPath;
    AssignedSchemaField := True;
  end;

  if not AssignedSchemaField then
  begin
    Count := Length(Result);
    SetLength(Result, Count + 1);
    Result[Count].Name := 'schema_name';
    Result[Count].Value := SchemaPath;
  end;
end;

function MetadataSchemasQuery: string;
begin
  Result := 'SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name';
end;

function MetadataTablesQuery: string;
begin
  Result := 'SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name';
end;

function MetadataColumnsQuery: string;
begin
  Result := 'SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position';
end;

function MetadataIndexesQuery: string;
begin
  Result := 'SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name';
end;

function MetadataIndexColumnsQuery: string;
begin
  Result := 'SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position';
end;

function MetadataConstraintsQuery: string;
begin
  Result := 'SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name';
end;

function MetadataProceduresQuery: string;
begin
  Result := 'SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name';
end;

function MetadataFunctionsQuery: string;
begin
  Result := 'SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name';
end;

function ExpandSchemaPaths(const SchemaPaths: array of string): TArray<string>;
var
  Seen: TStringList;
  Parts: TArray<string>;
  NormalizedPath: string;
  CurrentPath: string;
  I, J: Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  Seen := TStringList.Create;
  try
    Seen.CaseSensitive := True;
    Seen.Sorted := False;
    for I := 0 to High(SchemaPaths) do
    begin
      if not NormalizeSchemaPath(SchemaPaths[I], NormalizedPath) then
        Continue;
      Parts := SplitSchemaPath(NormalizedPath);
      if Length(Parts) = 0 then
        Continue;
      CurrentPath := '';
      for J := 0 to High(Parts) do
      begin
        if CurrentPath <> '' then
          CurrentPath := CurrentPath + '.';
        CurrentPath := CurrentPath + Parts[J];
        AppendUniqueString(Result, Seen, CurrentPath);
      end;
    end;
  finally
    Seen.Free;
  end;
end;

function ListMetadataSchemaPaths(const Rows: TMetadataRows; ExpandParents: Boolean): TArray<string>;
var
  Seen: TStringList;
  BasePaths: TArray<string>;
  SchemaPath: string;
  I: Integer;
begin
  SetLength(BasePaths, 0);
  Seen := TStringList.Create;
  try
    Seen.CaseSensitive := True;
    Seen.Sorted := False;
    for I := 0 to High(Rows) do
    begin
      if not TryReadSchemaPath(Rows[I], SchemaPath) then
        Continue;
      AppendUniqueString(BasePaths, Seen, SchemaPath);
    end;
  finally
    Seen.Free;
  end;

  if ExpandParents then
    Result := ExpandSchemaPaths(BasePaths)
  else
    Result := BasePaths;
end;

function ExpandSchemaMetadataRows(const Rows: TMetadataRows): TMetadataRows;
var
  Seen: TStringList;
  SchemaPath: string;
  Parts: TArray<string>;
  CurrentPath: string;
  RowCount, I, J: Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  Seen := TStringList.Create;
  try
    Seen.CaseSensitive := True;
    Seen.Sorted := False;

    for I := 0 to High(Rows) do
    begin
      if not TryReadSchemaPath(Rows[I], SchemaPath) then
      begin
        RowCount := Length(Result);
        SetLength(Result, RowCount + 1);
        Result[RowCount] := CloneMetadataRow(Rows[I]);
        Continue;
      end;

      Parts := SplitSchemaPath(SchemaPath);
      if Length(Parts) = 0 then
      begin
        RowCount := Length(Result);
        SetLength(Result, RowCount + 1);
        Result[RowCount] := CloneMetadataRow(Rows[I]);
        Continue;
      end;

      CurrentPath := '';
      for J := 0 to High(Parts) do
      begin
        if CurrentPath <> '' then
          CurrentPath := CurrentPath + '.';
        CurrentPath := CurrentPath + Parts[J];
        if not MarkSeen(Seen, CurrentPath) then
          Continue;
        RowCount := Length(Result);
        SetLength(Result, RowCount + 1);
        if J = High(Parts) then
          Result[RowCount] := CloneMetadataRow(Rows[I])
        else
          Result[RowCount] := CreateSyntheticSchemaRow(Rows[I], CurrentPath);
      end;
    end;
  finally
    Seen.Free;
  end;
end;

constructor TMetadataSchemaTreeNode.Create(const AName, APath: string; ATerminal: Boolean);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FTerminal := ATerminal;
  FChildren := TObjectList.Create(True);
end;

destructor TMetadataSchemaTreeNode.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

function TMetadataSchemaTreeNode.GetChild(Index: Integer): TMetadataSchemaTreeNode;
begin
  Result := TMetadataSchemaTreeNode(FChildren[Index]);
end;

function TMetadataSchemaTreeNode.GetChildCount: Integer;
begin
  Result := FChildren.Count;
end;

function TMetadataSchemaTreeNode.EnsureChild(const AName, APath: string; ATerminal: Boolean): TMetadataSchemaTreeNode;
var
  I: Integer;
  Child: TMetadataSchemaTreeNode;
begin
  for I := 0 to FChildren.Count - 1 do
  begin
    Child := TMetadataSchemaTreeNode(FChildren[I]);
    if Child.Path = APath then
    begin
      if ATerminal then
        Child.Terminal := True;
      Exit(Child);
    end;
  end;

  Result := TMetadataSchemaTreeNode.Create(AName, APath, ATerminal);
  FChildren.Add(Result);
end;

function TMetadataSchemaTreeNode.FindDescendantByPath(const APath: string): TMetadataSchemaTreeNode;
var
  I: Integer;
begin
  if FPath = APath then
    Exit(Self);

  for I := 0 to FChildren.Count - 1 do
  begin
    Result := TMetadataSchemaTreeNode(FChildren[I]).FindDescendantByPath(APath);
    if Result <> nil then
      Exit;
  end;
  Result := nil;
end;

constructor TMetadataSchemaTree.Create;
begin
  inherited Create;
  FSchemaRoots := TObjectList.Create(True);
end;

destructor TMetadataSchemaTree.Destroy;
begin
  FSchemaRoots.Free;
  inherited Destroy;
end;

function TMetadataSchemaTree.GetSchema(Index: Integer): TMetadataSchemaTreeNode;
begin
  Result := TMetadataSchemaTreeNode(FSchemaRoots[Index]);
end;

function TMetadataSchemaTree.GetSchemaCount: Integer;
begin
  Result := FSchemaRoots.Count;
end;

function TMetadataSchemaTree.EnsureRoot(const AName, APath: string; ATerminal: Boolean): TMetadataSchemaTreeNode;
var
  I: Integer;
  Node: TMetadataSchemaTreeNode;
begin
  for I := 0 to FSchemaRoots.Count - 1 do
  begin
    Node := TMetadataSchemaTreeNode(FSchemaRoots[I]);
    if Node.Path = APath then
    begin
      if ATerminal then
        Node.Terminal := True;
      Exit(Node);
    end;
  end;

  Result := TMetadataSchemaTreeNode.Create(AName, APath, ATerminal);
  FSchemaRoots.Add(Result);
end;

function TMetadataSchemaTree.FindNodeByPath(const APath: string): TMetadataSchemaTreeNode;
var
  I: Integer;
begin
  for I := 0 to FSchemaRoots.Count - 1 do
  begin
    Result := TMetadataSchemaTreeNode(FSchemaRoots[I]).FindDescendantByPath(APath);
    if Result <> nil then
      Exit;
  end;
  Result := nil;
end;

function BuildMetadataSchemaTree(const Rows: TMetadataRows; ExpandParents: Boolean;
  const Database: string): TMetadataSchemaTree;
var
  BasePaths, ExpandedPaths: TArray<string>;
  TerminalPaths: TStringList;
  Parts: TArray<string>;
  CurrentPath: string;
  ParentNode, Node: TMetadataSchemaTreeNode;
  I, J: Integer;
begin
  BasePaths := ListMetadataSchemaPaths(Rows, False);
  if ExpandParents then
    ExpandedPaths := ExpandSchemaPaths(BasePaths)
  else
    ExpandedPaths := BasePaths;

  TerminalPaths := TStringList.Create;
  try
    TerminalPaths.CaseSensitive := True;
    TerminalPaths.Sorted := False;
    if ExpandParents then
    begin
      for I := 0 to High(ExpandedPaths) do
        MarkSeen(TerminalPaths, ExpandedPaths[I]);
    end
    else
    begin
      for I := 0 to High(BasePaths) do
        MarkSeen(TerminalPaths, BasePaths[I]);
    end;

    Result := TMetadataSchemaTree.Create;
    Result.Database := Trim(Database);

    for I := 0 to High(ExpandedPaths) do
    begin
      Parts := SplitSchemaPath(ExpandedPaths[I]);
      if Length(Parts) = 0 then
        Continue;

      CurrentPath := '';
      ParentNode := nil;
      for J := 0 to High(Parts) do
      begin
        if CurrentPath <> '' then
          CurrentPath := CurrentPath + '.';
        CurrentPath := CurrentPath + Parts[J];

        if ParentNode = nil then
          Node := Result.EnsureRoot(Parts[J], CurrentPath, TerminalPaths.IndexOf(CurrentPath) >= 0)
        else
          Node := ParentNode.EnsureChild(Parts[J], CurrentPath, TerminalPaths.IndexOf(CurrentPath) >= 0);
        ParentNode := Node;
      end;
    end;
  finally
    TerminalPaths.Free;
  end;
end;

end.

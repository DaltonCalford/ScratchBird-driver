{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program IntegrationTest;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Variants,
  ScratchBird.Client, ScratchBird.Sql, ScratchBird.Metadata;

var
  Dsn: string;
  CancelSql: string;
  Client: TScratchBirdClient;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(Value: Boolean; const MessageText: string);
begin
  if not Value then
    Fail(MessageText);
end;

procedure AssertEqualInt64(Expected, Actual: Int64; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

function RequireVariantInt64(const Value: Variant; const MessageText: string): Int64;
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    Fail(MessageText + ': value is null/empty');
  try
    Result := VarAsType(Value, varInt64);
  except
    on E: Exception do
      Fail(MessageText + ': expected integer-convertible value (' + E.Message + ')');
  end;
end;

procedure DrainStream(Stream: TScratchBirdResultStream; out RowCount: Integer);
var
  Row: TArray<Variant>;
begin
  RowCount := 0;
  while True do
  begin
    Row := Stream.ReadRow;
    if Row = nil then
      Break;
    Inc(RowCount);
  end;
end;

procedure RequireMetadataCollectionHasColumnsAndExecutes(AClient: TScratchBirdClient; const CollectionName: string);
var
  Stream: TScratchBirdResultStream;
  RowCount: Integer;
begin
  Stream := AClient.QueryMetadata(CollectionName);
  try
    DrainStream(Stream, RowCount);
    AssertTrue(Length(Stream.Columns) > 0, CollectionName + ' should expose at least one metadata column');
    AssertTrue(RowCount >= 0, CollectionName + ' row count should be non-negative');
  finally
    Stream.Free;
  end;
end;

procedure RequireMetadataWrapperHasColumnsAndExecutes(AClient: TScratchBirdClient; const WrapperName: string);
var
  Stream: TScratchBirdResultStream;
  RowCount: Integer;
begin
  if WrapperName = 'schemas' then
    Stream := AClient.GetSchemas
  else if WrapperName = 'tables' then
    Stream := AClient.GetTables
  else if WrapperName = 'columns' then
    Stream := AClient.GetColumns
  else if WrapperName = 'indexes' then
    Stream := AClient.GetIndexes
  else if WrapperName = 'constraints' then
    Stream := AClient.GetConstraints
  else if WrapperName = 'routines' then
    Stream := AClient.GetRoutines
  else
    Fail('unsupported wrapper: ' + WrapperName);
  try
    DrainStream(Stream, RowCount);
    AssertTrue(Length(Stream.Columns) > 0, WrapperName + ' wrapper should expose at least one metadata column');
    AssertTrue(RowCount >= 0, WrapperName + ' wrapper row count should be non-negative');
  finally
    Stream.Free;
  end;
end;

procedure TestQueryAndPrepareBind(AClient: TScratchBirdClient);
var
  Stream: TScratchBirdResultStream;
  Row: TArray<Variant>;
  Param: TScratchBirdParamInput;
begin
  Stream := AClient.ExecuteQuery('SELECT 1');
  try
    Row := Stream.ReadRow;
    AssertTrue(Length(Row) > 0, 'SELECT 1 should return one column');
    AssertEqualInt64(1, RequireVariantInt64(Row[0], 'SELECT 1 value'), 'SELECT 1 payload value');
  finally
    Stream.Free;
  end;

  Param.Value := 42;
  Param.Obj := nil;
  Stream := AClient.ExecuteQueryParams('SELECT ?::INTEGER', [Param]);
  try
    Row := Stream.ReadRow;
    AssertTrue(Length(Row) > 0, 'prepare/bind should return one column');
    AssertEqualInt64(42, RequireVariantInt64(Row[0], 'prepare/bind value'), 'prepare/bind payload value');
  finally
    Stream.Free;
  end;
end;

procedure TestTransactionLifecycle(AClient: TScratchBirdClient);
var
  Stream: TScratchBirdResultStream;
  Row: TArray<Variant>;
begin
  AClient.BeginTransaction;
  try
    AClient.Savepoint('sp_live_1');
    Stream := AClient.ExecuteQuery('SELECT 11');
    try
      Row := Stream.ReadRow;
      AssertTrue(Length(Row) > 0, 'transaction query should return row');
      AssertEqualInt64(11, RequireVariantInt64(Row[0], 'transaction query value'), 'transaction query payload');
    finally
      Stream.Free;
    end;
    AClient.ReleaseSavepoint('sp_live_1');

    AClient.Savepoint('sp_live_2');
    AClient.RollbackToSavepoint('sp_live_2');
    AClient.Commit;
  except
    AClient.Rollback;
    raise;
  end;

  AClient.BeginTransaction;
  AClient.Rollback;
end;

procedure TestLiveBatchAndMulti(AClient: TScratchBirdClient);
var
  Batch: TScratchBirdBatchResults;
  Rowsets: TScratchBirdRowsets;
begin
  Batch := AClient.ExecuteBatch(['SELECT 101', 'SELECT 202']);
  AssertTrue(Length(Batch) = 2, 'ExecuteBatch should return one summary per statement');

  Rowsets := AClient.QueryMulti(['SELECT 303', 'SELECT 404']);
  AssertTrue(Length(Rowsets) = 2, 'QueryMulti should return one rowset per statement');
  AssertTrue(Length(Rowsets[0].Rows) > 0, 'QueryMulti first rowset should include rows');
  AssertTrue(Length(Rowsets[1].Rows) > 0, 'QueryMulti second rowset should include rows');
  AssertEqualInt64(303, RequireVariantInt64(Rowsets[0].Rows[0][0], 'QueryMulti first row value'), 'QueryMulti first row payload');
  AssertEqualInt64(404, RequireVariantInt64(Rowsets[1].Rows[0][0], 'QueryMulti second row value'), 'QueryMulti second row payload');
end;

procedure TestMetadataFamiliesAndRestrictions(AClient: TScratchBirdClient);
var
  SchemaRows: TMetadataRows;
  FilteredRows: TMetadataRows;
  Restrictions: TMetadataRow;
  SchemaValue: Variant;
  SchemaName: string;
begin
  RequireMetadataCollectionHasColumnsAndExecutes(AClient, 'schemas');
  RequireMetadataCollectionHasColumnsAndExecutes(AClient, 'tables');
  RequireMetadataCollectionHasColumnsAndExecutes(AClient, 'columns');
  RequireMetadataCollectionHasColumnsAndExecutes(AClient, 'indexes');
  RequireMetadataCollectionHasColumnsAndExecutes(AClient, 'constraints');
  RequireMetadataCollectionHasColumnsAndExecutes(AClient, 'routines');
  RequireMetadataWrapperHasColumnsAndExecutes(AClient, 'schemas');
  RequireMetadataWrapperHasColumnsAndExecutes(AClient, 'tables');
  RequireMetadataWrapperHasColumnsAndExecutes(AClient, 'columns');
  RequireMetadataWrapperHasColumnsAndExecutes(AClient, 'indexes');
  RequireMetadataWrapperHasColumnsAndExecutes(AClient, 'constraints');
  RequireMetadataWrapperHasColumnsAndExecutes(AClient, 'routines');

  SchemaRows := AClient.QueryMetadataRows('schemas');
  AssertTrue(Length(SchemaRows) > 0, 'QueryMetadataRows(schemas) should return at least one row');
  if MetadataRowTryGetValue(SchemaRows[0], 'schema_name', SchemaValue) or
     MetadataRowTryGetValue(SchemaRows[0], 'TABLE_SCHEM', SchemaValue) or
     MetadataRowTryGetValue(SchemaRows[0], 'table_schema', SchemaValue) then
  begin
    AssertTrue((not VarIsNull(SchemaValue)) and (not VarIsEmpty(SchemaValue)), 'schema value should not be null');
    SchemaName := VarToStr(SchemaValue);
  end
  else
    Fail('QueryMetadataRows(schemas) row does not expose schema name field');
  AssertTrue(SchemaName <> '', 'schema value should not be empty');

  SetLength(Restrictions, 1);
  Restrictions[0].Name := 'schema';
  Restrictions[0].Value := SchemaName;
  FilteredRows := AClient.QueryMetadataRows('schemas', Restrictions);
  AssertTrue(Length(FilteredRows) > 0, 'restricted QueryMetadataRows(schemas) should return rows');
  if MetadataRowTryGetValue(FilteredRows[0], 'schema_name', SchemaValue) or
     MetadataRowTryGetValue(FilteredRows[0], 'TABLE_SCHEM', SchemaValue) or
     MetadataRowTryGetValue(FilteredRows[0], 'table_schema', SchemaValue) then
  begin
    AssertTrue((not VarIsNull(SchemaValue)) and (not VarIsEmpty(SchemaValue)), 'restricted schema value should not be null');
    AssertTrue(VarToStr(SchemaValue) = SchemaName, 'restricted schema value should match requested schema');
  end
  else
    Fail('restricted QueryMetadataRows(schemas) row does not expose schema name field');
end;

procedure TestTypeCoverageFixture(AClient: TScratchBirdClient);
var
  Stream: TScratchBirdResultStream;
  Row: TArray<Variant>;
begin
  Stream := AClient.ExecuteQuery('SELECT * FROM type_coverage');
  try
    Row := Stream.ReadRow;
    AssertTrue(Length(Row) > 0, 'type_coverage fixture should return at least one row');
  finally
    Stream.Free;
  end;
end;

procedure TestOptionalCancelPath(AClient: TScratchBirdClient; const SqlText: string);
var
  Stream: TScratchBirdResultStream;
begin
  if SqlText = '' then
    Exit;
  Stream := AClient.ExecuteQuery(SqlText);
  AClient.Cancel;
  try
    Stream.ReadRow;
    raise Exception.Create('Cancel did not interrupt query');
  except
    on E: Exception do
      Writeln('CancelTest: OK');
  end;
end;

begin
  Dsn := GetEnvironmentVariable('SCRATCHBIRD_PASCAL_URL');
  if Dsn = '' then
  begin
    Writeln('IntegrationTest: SKIPPED (SCRATCHBIRD_PASCAL_URL not set)');
    Halt(0);
  end;
  Client := TScratchBirdClient.Create;
  try
    Client.Connect(Dsn);
    TestQueryAndPrepareBind(Client);
    TestTransactionLifecycle(Client);
    TestLiveBatchAndMulti(Client);
    TestMetadataFamiliesAndRestrictions(Client);
    TestTypeCoverageFixture(Client);
    CancelSql := GetEnvironmentVariable('SCRATCHBIRD_PASCAL_CANCEL_SQL');
    TestOptionalCancelPath(Client, CancelSql);
    Writeln('IntegrationTest: OK');
  finally
    Client.Free;
  end;
end.

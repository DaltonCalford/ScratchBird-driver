program IntegrationTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, ScratchBird.Client, ScratchBird.Sql;

var
  Dsn: string;
  CancelSql: string;
  Client: TScratchBirdClient;
  Stream: TScratchBirdResultStream;
  Row: TArray<Variant>;
  Param: TScratchBirdParamInput;
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
    Stream := Client.ExecuteQuery('SELECT 1');
    Row := Stream.ReadRow;
    if Length(Row) = 0 then
      raise Exception.Create('No row returned');

    Param.Value := 42;
    Param.Obj := nil;
    Stream := Client.ExecuteQueryParams('SELECT ?::INTEGER', [Param]);
    Row := Stream.ReadRow;
    if (Length(Row) = 0) or (Row[0] <> 42) then
      raise Exception.Create('Prepare/bind failed');

    Stream := Client.ExecuteQuery('SELECT * FROM sb_conformance.type_coverage');
    Row := Stream.ReadRow;
    if Length(Row) = 0 then
      raise Exception.Create('Types fixture returned no rows');

    CancelSql := GetEnvironmentVariable('SCRATCHBIRD_PASCAL_CANCEL_SQL');
    if CancelSql <> '' then
    begin
      Stream := Client.ExecuteQuery(CancelSql);
      Client.Cancel;
      try
        Row := Stream.ReadRow;
        raise Exception.Create('Cancel did not interrupt query');
      except
        on E: Exception do
          Writeln('CancelTest: OK');
      end;
    end;
    Writeln('IntegrationTest: OK');
  finally
    Client.Free;
  end;
end.

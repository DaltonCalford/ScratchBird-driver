program IntegrationTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, ScratchBird.Client;

var
  Dsn: string;
  Client: TScratchBirdClient;
  Stream: TScratchBirdResultStream;
  Row: TArray<Variant>;
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
    Writeln('IntegrationTest: OK');
  finally
    Client.Free;
  end;
end.

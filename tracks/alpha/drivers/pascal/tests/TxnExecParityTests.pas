{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program TxnExecParityTests;

{$mode delphi}
{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Variants,
  ScratchBird.Client, ScratchBird.Protocol, ScratchBird.Sql, ScratchBird.Errors;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(Value: Boolean; const MessageText: string);
begin
  if not Value then
    Fail(MessageText);
end;

procedure AssertEqualString(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected="' + Expected + '" actual="' + Actual + '"');
end;

procedure AssertEqualWord(Expected, Actual: Word; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

procedure AssertEqualUInt32(Expected, Actual: Cardinal; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

procedure AssertContains(const Needle, Haystack, MessageText: string);
begin
  if Pos(Needle, Haystack) = 0 then
    Fail(MessageText + ': expected "' + Needle + '" in "' + Haystack + '"');
end;

function ReadUInt16LEAt(const Buffer: TBytes; Offset: Integer): Word;
begin
  Result := Word(Buffer[Offset]) or (Word(Buffer[Offset + 1]) shl 8);
end;

function ReadUInt32LEAt(const Buffer: TBytes; Offset: Integer): Cardinal;
begin
  Result := Cardinal(Buffer[Offset]) or (Cardinal(Buffer[Offset + 1]) shl 8) or
    (Cardinal(Buffer[Offset + 2]) shl 16) or (Cardinal(Buffer[Offset + 3]) shl 24);
end;

procedure TestBeginTransactionRequiresConnectedClient;
var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    try
      Client.BeginTransaction;
      Fail('expected begin transaction disconnected guard');
    except
      on E: EScratchbirdConnectionError do
      begin
        AssertEqualString('08003', E.SQLState, 'begin disconnected SQLSTATE');
        AssertContains('Client is not connected', E.Message, 'begin disconnected message');
      end;
    end;
  finally
    Client.Free;
  end;
end;

procedure TestCommitRollbackNoopWithoutActiveTransaction;
var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    Client.Commit;
    Client.Rollback;
  finally
    Client.Free;
  end;
end;

procedure TestSavepointRequiresActiveTransaction;
var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    try
      Client.Savepoint('sp1');
      Fail('expected active transaction guard for savepoint');
    except
      on E: EScratchbirdTransactionError do
      begin
        AssertEqualString('25000', E.SQLState, 'savepoint active txn SQLSTATE');
        AssertContains('active transaction', E.Message, 'savepoint active txn message');
      end;
    end;
  finally
    Client.Free;
  end;
end;

procedure TestSavepointRejectsBlankName;
var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    try
      Client.Savepoint('   ');
      Fail('expected savepoint name validation failure');
    except
      on E: EScratchbirdSyntaxError do
      begin
        AssertEqualString('42601', E.SQLState, 'savepoint name SQLSTATE');
        AssertContains('savepoint name is required', E.Message, 'savepoint name message');
      end;
    end;
  finally
    Client.Free;
  end;
end;

procedure TestExecRejectsBlankSql;
var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    try
      Client.ExecSQL('    ');
      Fail('expected empty SQL guard for ExecSQL');
    except
      on E: EScratchbirdSyntaxError do
      begin
        AssertEqualString('42601', E.SQLState, 'exec empty SQLSTATE');
        AssertContains('SQL text is required', E.Message, 'exec empty SQL message');
      end;
    end;

    try
      Client.ExecuteQuery(#9#10);
      Fail('expected empty SQL guard for ExecuteQuery');
    except
      on E: EScratchbirdSyntaxError do
      begin
        AssertEqualString('42601', E.SQLState, 'query empty SQLSTATE');
        AssertContains('SQL text is required', E.Message, 'query empty SQL message');
      end;
    end;
  finally
    Client.Free;
  end;
end;

procedure TestTxnBeginPayloadEncodesFlagsAndTimeout;
var
  Flags: Word;
  Payload: TBytes;
begin
  Flags := TXN_FLAG_HAS_ISOLATION or TXN_FLAG_HAS_ACCESS or TXN_FLAG_HAS_DEFERRABLE or
    TXN_FLAG_HAS_WAIT or TXN_FLAG_HAS_TIMEOUT or TXN_FLAG_HAS_AUTOCOMMIT;
  Payload := BuildTxnBeginPayload(Flags, 2, 1, ISOLATION_SERIALIZABLE, 1, 1, 0, 250);
  AssertEqualWord(12, Word(Length(Payload)), 'txn begin payload length');
  AssertEqualWord(Flags, ReadUInt16LEAt(Payload, 0), 'txn begin payload flags');
  AssertTrue(Payload[2] = 2, 'txn begin conflict action');
  AssertTrue(Payload[3] = 1, 'txn begin autocommit');
  AssertTrue(Payload[4] = ISOLATION_SERIALIZABLE, 'txn begin isolation');
  AssertTrue(Payload[5] = 1, 'txn begin access mode');
  AssertTrue(Payload[6] = 1, 'txn begin deferrable');
  AssertTrue(Payload[7] = 0, 'txn begin wait mode');
  AssertEqualUInt32(250, ReadUInt32LEAt(Payload, 8), 'txn begin timeout');
end;

procedure TestNamedNormalizationPreservesCastMarkers;
var
  Names: TArray<string>;
  Params: TArray<TScratchBirdParamInput>;
  Ordered: TArray<TScratchBirdParamInput>;
  OutSql: string;
begin
  SetLength(Names, 1);
  Names[0] := 'id';
  SetLength(Params, 1);
  Params[0].Value := 7;
  Params[0].Obj := nil;
  OutSql := NormalizeNamedSql('SELECT :id::INTEGER AS v, ''::literal'' AS t', Names, Params, Ordered);
  AssertEqualString('SELECT $1::INTEGER AS v, ''::literal'' AS t', OutSql, 'named cast normalization');
  AssertEqualWord(1, Word(Length(Ordered)), 'named cast ordered count');
  AssertTrue(Ordered[0].Value = 7, 'named cast ordered value');
end;

begin
  try
    TestBeginTransactionRequiresConnectedClient;
    TestCommitRollbackNoopWithoutActiveTransaction;
    TestSavepointRequiresActiveTransaction;
    TestSavepointRejectsBlankName;
    TestExecRejectsBlankSql;
    TestTxnBeginPayloadEncodesFlagsAndTimeout;
    TestNamedNormalizationPreservesCastMarkers;
    Writeln('TxnExecParityTests: OK');
  except
    on E: Exception do
    begin
      Writeln('TxnExecParityTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program AdapterTransactionOptionsTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  ScratchBird.Protocol, ScratchBird.Errors,
  ScratchBird.FireDAC, ScratchBird.IBX, ScratchBird.Zeos, ScratchBird.SQLdb;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertEqualString(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected="' + Expected + '" actual="' + Actual + '"');
end;

procedure TestFireDACStartTransactionExDisconnected;
var
  Connection: TScratchBirdFDConnection;
begin
  Connection := TScratchBirdFDConnection.Create(nil);
  try
    try
      Connection.StartTransactionEx(ISOLATION_SERIALIZABLE, 1, True, False, 250, 1, 2);
      Fail('FireDAC StartTransactionEx: expected disconnected connection error');
    except
      on E: EScratchbirdConnectionError do
        AssertEqualString('08003', E.SQLState, 'FireDAC StartTransactionEx SQLSTATE');
    end;
  finally
    Connection.Free;
  end;
end;

procedure TestIBXStartTransactionExDisconnected;
var
  Database: TScratchBirdIBDatabase;
begin
  Database := TScratchBirdIBDatabase.Create(nil);
  try
    try
      Database.StartTransactionEx(ISOLATION_SERIALIZABLE, 1, True, False, 250, 1, 2);
      Fail('IBX StartTransactionEx: expected disconnected connection error');
    except
      on E: EScratchbirdConnectionError do
        AssertEqualString('08003', E.SQLState, 'IBX StartTransactionEx SQLSTATE');
    end;
  finally
    Database.Free;
  end;
end;

procedure TestZeosStartTransactionExDisconnected;
var
  Connection: TScratchBirdZConnection;
begin
  Connection := TScratchBirdZConnection.Create(nil);
  try
    try
      Connection.StartTransactionEx(ISOLATION_SERIALIZABLE, 1, True, False, 250, 1, 2);
      Fail('Zeos StartTransactionEx: expected disconnected connection error');
    except
      on E: EScratchbirdConnectionError do
        AssertEqualString('08003', E.SQLState, 'Zeos StartTransactionEx SQLSTATE');
    end;
  finally
    Connection.Free;
  end;
end;

procedure TestSQLdbStartTransactionExDisconnected;
var
  Connection: TScratchBirdSQLConnection;
begin
  Connection := TScratchBirdSQLConnection.Create(nil);
  try
    try
      Connection.StartTransactionEx(ISOLATION_SERIALIZABLE, 1, True, False, 250, 1, 2);
      Fail('SQLdb StartTransactionEx: expected disconnected connection error');
    except
      on E: EScratchbirdConnectionError do
        AssertEqualString('08003', E.SQLState, 'SQLdb StartTransactionEx SQLSTATE');
    end;
  finally
    Connection.Free;
  end;
end;

begin
  try
    TestFireDACStartTransactionExDisconnected;
    TestIBXStartTransactionExDisconnected;
    TestZeosStartTransactionExDisconnected;
    TestSQLdbStartTransactionExDisconnected;
    Writeln('AdapterTransactionOptionsTests: OK');
  except
    on E: Exception do
    begin
      Writeln('AdapterTransactionOptionsTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program ErrorMappingTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  ScratchBird.Errors;

type
  TScratchBirdErrorClass = class of EScratchBirdError;

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

procedure AssertMappedClass(const SQLState: string; ExpectedClass: TScratchBirdErrorClass);
var
  Err: EScratchBirdError;
begin
  Err := MapSqlState(SQLState, 'message', 'detail', 'hint');
  try
    AssertTrue(Err is ExpectedClass, 'mapped class mismatch for SQLSTATE ' + SQLState);
    AssertEqualString(SQLState, Err.SQLState, 'sqlstate roundtrip');
    AssertEqualString('detail', Err.Detail, 'detail roundtrip');
    AssertEqualString('hint', Err.Hint, 'hint roundtrip');
  finally
    Err.Free;
  end;
end;

procedure TestMappedCategories;
begin
  AssertMappedClass('01000', EScratchbirdWarning);
  AssertMappedClass('02000', EScratchbirdNoData);
  AssertMappedClass('08006', EScratchbirdConnectionError);
  AssertMappedClass('0A000', EScratchbirdNotSupported);
  AssertMappedClass('22P02', EScratchbirdDataError);
  AssertMappedClass('23505', EScratchbirdIntegrityError);
  AssertMappedClass('28P01', EScratchbirdAuthError);
  AssertMappedClass('40001', EScratchbirdTransactionError);
  AssertMappedClass('42601', EScratchbirdSyntaxError);
  AssertMappedClass('53300', EScratchbirdResourceError);
  AssertMappedClass('54000', EScratchbirdLimitError);
  AssertMappedClass('57014', EScratchbirdOperatorInterventionError);
  AssertMappedClass('58000', EScratchbirdSystemError);
  AssertMappedClass('XX000', EScratchbirdInternalError);
end;

procedure TestFallbackForUnknownSqlState;
begin
  AssertMappedClass('ZZ999', EScratchBirdError);
end;

procedure TestFallbackForInvalidSqlStateLength;
begin
  AssertMappedClass('42P1', EScratchBirdError);
end;

begin
  try
    TestMappedCategories;
    TestFallbackForUnknownSqlState;
    TestFallbackForInvalidSqlStateLength;
    Writeln('ErrorMappingTests: OK');
  except
    on E: Exception do
    begin
      Writeln('ErrorMappingTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

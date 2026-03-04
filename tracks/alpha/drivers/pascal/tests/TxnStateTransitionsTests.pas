{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program TxnStateTransitionsTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  ScratchBird.Client, ScratchBird.Config, ScratchBird.Errors, ScratchBird.Protocol, ScratchBird.Transport;

type
  TFakeTransport = class(TInterfacedObject, IScratchBirdTransport)
  private
    FReadBuffer: TBytes;
    FReadOffset: Integer;
    FWrites: array of TBytes;
    FConnected: Boolean;
  public
    procedure Configure(const Config: TScratchBirdConfig);
    procedure Connect;
    procedure Disconnect;
    function ReadExact(Length: Integer): TBytes;
    procedure Write(const Data: TBytes);
    function IsConnected: Boolean;
    procedure QueueInbound(const Frame: TBytes);
    function WriteCount: Integer;
    function WriteAt(Index: Integer): TBytes;
  end;

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

procedure AssertEqualBytes(const Expected, Actual: TBytes; const MessageText: string);
var
  I: Integer;
begin
  if Length(Expected) <> Length(Actual) then
    Fail(MessageText + ': expected length=' + IntToStr(Length(Expected)) + ' actual length=' + IntToStr(Length(Actual)));
  for I := 0 to High(Expected) do
    if Expected[I] <> Actual[I] then
      Fail(MessageText + ': mismatch at index ' + IntToStr(I));
end;

procedure AppendErrorField(var Payload: TBytes; FieldTag: Byte; const Value: string);
var
  ValueBytes: TBytes;
  Start: Integer;
begin
  Start := Length(Payload);
  SetLength(Payload, Start + 1);
  Payload[Start] := FieldTag;
  ValueBytes := TEncoding.UTF8.GetBytes(Value);
  Start := Length(Payload);
  SetLength(Payload, Start + Length(ValueBytes) + 1);
  if Length(ValueBytes) > 0 then
    Move(ValueBytes[0], Payload[Start], Length(ValueBytes));
  Payload[Start + Length(ValueBytes)] := 0;
end;

function BuildErrorPayload(const Severity, SqlState, MessageText, DetailText, HintText: string): TBytes;
begin
  SetLength(Result, 0);
  AppendErrorField(Result, Byte(AnsiChar('S')), Severity);
  AppendErrorField(Result, Byte(AnsiChar('C')), SqlState);
  AppendErrorField(Result, Byte(AnsiChar('M')), MessageText);
  if DetailText <> '' then
    AppendErrorField(Result, Byte(AnsiChar('D')), DetailText);
  if HintText <> '' then
    AppendErrorField(Result, Byte(AnsiChar('H')), HintText);
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := 0;
end;

procedure WriteUInt64LEAt(var Buffer: TBytes; Offset: Integer; Value: UInt64);
begin
  Buffer[Offset] := Byte(Value and $FF);
  Buffer[Offset + 1] := Byte((Value shr 8) and $FF);
  Buffer[Offset + 2] := Byte((Value shr 16) and $FF);
  Buffer[Offset + 3] := Byte((Value shr 24) and $FF);
  Buffer[Offset + 4] := Byte((Value shr 32) and $FF);
  Buffer[Offset + 5] := Byte((Value shr 40) and $FF);
  Buffer[Offset + 6] := Byte((Value shr 48) and $FF);
  Buffer[Offset + 7] := Byte((Value shr 56) and $FF);
end;

function BuildReadyPayload(Status: Byte; TxnId, Visibility: UInt64): TBytes;
begin
  SetLength(Result, 20);
  FillChar(Result[0], Length(Result), 0);
  Result[0] := Status;
  WriteUInt64LEAt(Result, 4, TxnId);
  WriteUInt64LEAt(Result, 12, Visibility);
end;

procedure DecodeOutboundFrame(const Frame: TBytes; out MsgType: TScratchBirdMessageType; out Payload: TBytes);
var
  Header: TBytes;
  Flags: Byte;
  PayloadLength: Integer;
  Sequence: Cardinal;
  AttachmentId: TBytes;
  TxnId: UInt64;
begin
  AssertTrue(Length(Frame) >= HEADER_SIZE, 'outbound frame includes header');
  Header := Copy(Frame, 0, HEADER_SIZE);
  AssertTrue(DecodeHeader(Header, MsgType, Flags, PayloadLength, Sequence, AttachmentId, TxnId), 'decode outbound header');
  AssertEqualInt(HEADER_SIZE + PayloadLength, Length(Frame), 'outbound frame length');
  Payload := Copy(Frame, HEADER_SIZE, PayloadLength);
end;

procedure DecodeOutboundType(const Frame: TBytes; out MsgType: TScratchBirdMessageType);
var
  Payload: TBytes;
begin
  DecodeOutboundFrame(Frame, MsgType, Payload);
end;

procedure TestBeginSavepointCommitLifecycleTransitions;
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  MsgType: TScratchBirdMessageType;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 41, 0), 0, 1, nil, 41));
    Client.BeginTransaction;

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 41, 0), 0, 2, nil, 41));
    Client.Savepoint('sp_a');

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 41, 0), 0, 3, nil, 41));
    Client.ReleaseSavepoint('sp_a');

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 41, 0), 0, 4, nil, 41));
    Client.RollbackToSavepoint('sp_a');

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 5, nil, 0));
    Client.Commit;

    try
      Client.Savepoint('sp_after_commit');
      Fail('savepoint after commit should fail without active txn');
    except
      on E: EScratchbirdTransactionError do
        AssertEqualString('25000', E.SQLState, 'savepoint after commit SQLSTATE');
    end;

    AssertEqualInt(5, Transport.WriteCount, 'commit lifecycle write count');
    DecodeOutboundType(Transport.WriteAt(0), MsgType);
    AssertTrue(MsgType = MSG_TXN_BEGIN, 'first write should be txn begin');
    DecodeOutboundType(Transport.WriteAt(1), MsgType);
    AssertTrue(MsgType = MSG_TXN_SAVEPOINT, 'second write should be savepoint');
    DecodeOutboundType(Transport.WriteAt(2), MsgType);
    AssertTrue(MsgType = MSG_TXN_RELEASE, 'third write should be release savepoint');
    DecodeOutboundType(Transport.WriteAt(3), MsgType);
    AssertTrue(MsgType = MSG_TXN_ROLLBACK_TO, 'fourth write should be rollback to savepoint');
    DecodeOutboundType(Transport.WriteAt(4), MsgType);
    AssertTrue(MsgType = MSG_TXN_COMMIT, 'fifth write should be txn commit');
  finally
    Client.Free;
  end;
end;

procedure TestBeginRollbackClearsActiveTxnState;
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  MsgType: TScratchBirdMessageType;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 77, 0), 0, 1, nil, 77));
    Client.BeginTransaction;

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 2, nil, 0));
    Client.Rollback;

    try
      Client.ReleaseSavepoint('sp_after_rollback');
      Fail('release savepoint after rollback should fail without active txn');
    except
      on E: EScratchbirdTransactionError do
        AssertEqualString('25000', E.SQLState, 'release savepoint after rollback SQLSTATE');
    end;

    AssertEqualInt(2, Transport.WriteCount, 'rollback lifecycle write count');
    DecodeOutboundType(Transport.WriteAt(0), MsgType);
    AssertTrue(MsgType = MSG_TXN_BEGIN, 'first write should be txn begin');
    DecodeOutboundType(Transport.WriteAt(1), MsgType);
    AssertTrue(MsgType = MSG_TXN_ROLLBACK, 'second write should be txn rollback');
  finally
    Client.Free;
  end;
end;

procedure TestBeginTransactionExOptionMatrixEncodesPayload;
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  MsgType: TScratchBirdMessageType;
  Payload: TBytes;
  ExpectedPayload: TBytes;
  Flags: Word;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 9001, 0), 0, 1, nil, 9001));
    Client.BeginTransactionEx(ISOLATION_SERIALIZABLE, 1, True, True, 250, 1, 2);

    Flags := TXN_FLAG_HAS_ISOLATION or TXN_FLAG_HAS_ACCESS or TXN_FLAG_HAS_DEFERRABLE or
      TXN_FLAG_HAS_WAIT or TXN_FLAG_HAS_TIMEOUT or TXN_FLAG_HAS_AUTOCOMMIT;
    ExpectedPayload := BuildTxnBeginPayload(Flags, 2, 1, ISOLATION_SERIALIZABLE, 1, 1, 1, 250);
    DecodeOutboundFrame(Transport.WriteAt(0), MsgType, Payload);
    AssertTrue(MsgType = MSG_TXN_BEGIN, 'full matrix write should be txn begin');
    AssertEqualBytes(ExpectedPayload, Payload, 'full matrix begin payload');

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 2, nil, 0));
    Client.Commit;

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 9002, 0), 0, 3, nil, 9002));
    Client.BeginTransactionEx(ISOLATION_REPEATABLE_READ, 0, False, False, 0, 0, 0);

    Flags := TXN_FLAG_HAS_ISOLATION;
    ExpectedPayload := BuildTxnBeginPayload(Flags, 0, 0, ISOLATION_REPEATABLE_READ, 0, 0, 0, 0);
    DecodeOutboundFrame(Transport.WriteAt(2), MsgType, Payload);
    AssertTrue(MsgType = MSG_TXN_BEGIN, 'minimal matrix write should be txn begin');
    AssertEqualBytes(ExpectedPayload, Payload, 'minimal matrix begin payload');

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 4, nil, 0));
    Client.Rollback;

    AssertEqualInt(4, Transport.WriteCount, 'option matrix lifecycle write count');
    DecodeOutboundType(Transport.WriteAt(1), MsgType);
    AssertTrue(MsgType = MSG_TXN_COMMIT, 'second write should be commit');
    DecodeOutboundType(Transport.WriteAt(3), MsgType);
    AssertTrue(MsgType = MSG_TXN_ROLLBACK, 'fourth write should be rollback');
  finally
    Client.Free;
  end;
end;

procedure TestBeginTransactionExConflictPathLeavesTxnInactive;
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  MsgType: TScratchBirdMessageType;
  Payload: TBytes;
  ExpectedPayload: TBytes;
  ErrorPayload: TBytes;
  Flags: Word;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    ErrorPayload := BuildErrorPayload(
      'ERROR', '40001', 'serialization failure during begin', 'conflicting transaction',
      'retry the transaction');
    Transport.QueueInbound(EncodeMessage(MSG_ERROR, ErrorPayload, 0, 1, nil, 0));

    try
      Client.BeginTransactionEx(ISOLATION_SERIALIZABLE, 1, True, False, 0, 0, 2);
      Fail('BeginTransactionEx conflict path should raise transaction error');
    except
      on E: EScratchbirdTransactionError do
      begin
        AssertEqualString('40001', E.SQLState, 'begin conflict SQLSTATE');
        AssertTrue(Pos('serialization failure during begin', E.Message) > 0,
          'begin conflict message should round-trip');
      end;
    end;

    Flags := TXN_FLAG_HAS_ISOLATION or TXN_FLAG_HAS_ACCESS or TXN_FLAG_HAS_DEFERRABLE;
    ExpectedPayload := BuildTxnBeginPayload(Flags, 2, 0, ISOLATION_SERIALIZABLE, 1, 1, 0, 0);
    DecodeOutboundFrame(Transport.WriteAt(0), MsgType, Payload);
    AssertTrue(MsgType = MSG_TXN_BEGIN, 'conflict path first write should be txn begin');
    AssertEqualBytes(ExpectedPayload, Payload, 'conflict path begin payload');

    try
      Client.Savepoint('sp_after_conflict');
      Fail('savepoint after failed begin should fail without active txn');
    except
      on E: EScratchbirdTransactionError do
        AssertEqualString('25000', E.SQLState, 'savepoint after failed begin SQLSTATE');
    end;

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 9010, 0), 0, 2, nil, 9010));
    Client.BeginTransactionEx(ISOLATION_READ_COMMITTED, 0, False, False, 0, 0, 0);

    Flags := TXN_FLAG_HAS_ISOLATION;
    ExpectedPayload := BuildTxnBeginPayload(Flags, 0, 0, ISOLATION_READ_COMMITTED, 0, 0, 0, 0);
    DecodeOutboundFrame(Transport.WriteAt(1), MsgType, Payload);
    AssertTrue(MsgType = MSG_TXN_BEGIN, 'retry begin should emit txn begin');
    AssertEqualBytes(ExpectedPayload, Payload, 'retry begin payload');

    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 3, nil, 0));
    Client.Rollback;

    AssertEqualInt(3, Transport.WriteCount, 'conflict path lifecycle write count');
    DecodeOutboundType(Transport.WriteAt(2), MsgType);
    AssertTrue(MsgType = MSG_TXN_ROLLBACK, 'third write should be rollback after retry begin');
  finally
    Client.Free;
  end;
end;

procedure TFakeTransport.Configure(const Config: TScratchBirdConfig);
begin
  // no-op for deterministic unit tests
end;

procedure TFakeTransport.Connect;
begin
  FConnected := True;
end;

procedure TFakeTransport.Disconnect;
begin
  FConnected := False;
end;

function TFakeTransport.ReadExact(Length: Integer): TBytes;
begin
  if Length < 0 then
    raise Exception.Create('read length must be non-negative');
  if FReadOffset + Length > System.Length(FReadBuffer) then
    raise Exception.Create('fake transport read underflow');
  SetLength(Result, Length);
  if Length > 0 then
    Move(FReadBuffer[FReadOffset], Result[0], Length);
  Inc(FReadOffset, Length);
end;

procedure TFakeTransport.Write(const Data: TBytes);
var
  Index: Integer;
begin
  Index := Length(FWrites);
  SetLength(FWrites, Index + 1);
  FWrites[Index] := Copy(Data, 0, Length(Data));
end;

function TFakeTransport.IsConnected: Boolean;
begin
  Result := FConnected;
end;

procedure TFakeTransport.QueueInbound(const Frame: TBytes);
var
  Start, Count: Integer;
begin
  Count := Length(Frame);
  if Count = 0 then
    Exit;
  Start := Length(FReadBuffer);
  SetLength(FReadBuffer, Start + Count);
  Move(Frame[0], FReadBuffer[Start], Count);
end;

function TFakeTransport.WriteCount: Integer;
begin
  Result := Length(FWrites);
end;

function TFakeTransport.WriteAt(Index: Integer): TBytes;
begin
  Result := FWrites[Index];
end;

begin
  try
    TestBeginSavepointCommitLifecycleTransitions;
    TestBeginRollbackClearsActiveTxnState;
    TestBeginTransactionExOptionMatrixEncodesPayload;
    TestBeginTransactionExConflictPathLeavesTxnInactive;
    Writeln('TxnStateTransitionsTests: OK');
  except
    on E: Exception do
    begin
      Writeln('TxnStateTransitionsTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

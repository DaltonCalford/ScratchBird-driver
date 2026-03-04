{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program MetadataExecutionFlowTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Variants,
  ScratchBird.Client, ScratchBird.Config, ScratchBird.Metadata, ScratchBird.Protocol, ScratchBird.Transport, ScratchBird.Types;

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

procedure AppendUInt16LE(var Buffer: TBytes; Value: Word);
var
  Start: Integer;
begin
  Start := Length(Buffer);
  SetLength(Buffer, Start + 2);
  Buffer[Start] := Byte(Value and $FF);
  Buffer[Start + 1] := Byte((Value shr 8) and $FF);
end;

procedure AppendUInt32LE(var Buffer: TBytes; Value: Cardinal);
var
  Start: Integer;
begin
  Start := Length(Buffer);
  SetLength(Buffer, Start + 4);
  Buffer[Start] := Byte(Value and $FF);
  Buffer[Start + 1] := Byte((Value shr 8) and $FF);
  Buffer[Start + 2] := Byte((Value shr 16) and $FF);
  Buffer[Start + 3] := Byte((Value shr 24) and $FF);
end;

procedure AppendBytes(var Buffer: TBytes; const Bytes: TBytes);
var
  Start, Count: Integer;
begin
  Count := Length(Bytes);
  if Count = 0 then
    Exit;
  Start := Length(Buffer);
  SetLength(Buffer, Start + Count);
  Move(Bytes[0], Buffer[Start], Count);
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

function BuildCommandCompletePayload(CommandType: Byte; Rows, LastId: UInt64; const Tag: string): TBytes;
var
  TagBytes: TBytes;
begin
  TagBytes := TEncoding.UTF8.GetBytes(Tag);
  SetLength(Result, 20 + Length(TagBytes) + 1);
  FillChar(Result[0], Length(Result), 0);
  Result[0] := CommandType;
  WriteUInt64LEAt(Result, 4, Rows);
  WriteUInt64LEAt(Result, 12, LastId);
  if Length(TagBytes) > 0 then
    Move(TagBytes[0], Result[20], Length(TagBytes));
  Result[20 + Length(TagBytes)] := 0;
end;

function BuildRowDescriptionPayloadText(const ColumnNames: array of string): TBytes;
var
  I: Integer;
  NameBytes: TBytes;
begin
  Result := nil;
  AppendUInt16LE(Result, Length(ColumnNames));
  AppendUInt16LE(Result, 0);
  for I := 0 to High(ColumnNames) do
  begin
    NameBytes := TEncoding.UTF8.GetBytes(ColumnNames[I]);
    AppendUInt32LE(Result, Cardinal(Length(NameBytes)));
    AppendBytes(Result, NameBytes);
    AppendUInt32LE(Result, 0);
    AppendUInt16LE(Result, I + 1);
    AppendUInt32LE(Result, OID_TEXT);
    AppendUInt16LE(Result, $FFFF);
    AppendUInt32LE(Result, Cardinal($FFFFFFFF));
    AppendBytes(Result, TBytes.Create(FORMAT_TEXT, 1, 0, 0));
  end;
end;

function BuildDataRowPayloadText(const Values: array of string): TBytes;
var
  I: Integer;
  ValueBytes: TBytes;
  NullBytes: Integer;
begin
  Result := nil;
  AppendUInt16LE(Result, Length(Values));
  NullBytes := (Length(Values) + 7) div 8;
  AppendUInt16LE(Result, NullBytes);
  for I := 1 to NullBytes do
    AppendBytes(Result, TBytes.Create(0));
  for I := 0 to High(Values) do
  begin
    ValueBytes := TEncoding.UTF8.GetBytes(Values[I]);
    AppendUInt32LE(Result, Cardinal(Length(ValueBytes)));
    AppendBytes(Result, ValueBytes);
  end;
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
  AssertTrue(Length(Frame) >= HEADER_SIZE, 'outbound frame must include header');
  Header := Copy(Frame, 0, HEADER_SIZE);
  AssertTrue(DecodeHeader(Header, MsgType, Flags, PayloadLength, Sequence, AttachmentId, TxnId), 'outbound header decode');
  AssertEqualInt(HEADER_SIZE + PayloadLength, Length(Frame), 'outbound frame length');
  Payload := Copy(Frame, HEADER_SIZE, PayloadLength);
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

procedure TestMetadataWrappersEmitExpectedCollectionQueries;
const
  CollectionCount = 6;
  Collections: array[0..CollectionCount - 1] of string = ('schemas', 'tables', 'columns', 'indexes', 'constraints', 'routines');
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  Stream: TScratchBirdResultStream;
  MsgType: TScratchBirdMessageType;
  Payload: TBytes;
  Row: TArray<Variant>;
  I: Integer;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    for I := 0 to CollectionCount - 1 do
    begin
      Transport.QueueInbound(EncodeMessage(MSG_ROW_DESCRIPTION, BuildRowDescriptionPayloadText(['name']), 0, 10 + I * 3, nil, 0));
      Transport.QueueInbound(EncodeMessage(MSG_COMMAND_COMPLETE, BuildCommandCompletePayload(0, 0, 0, 'SELECT 0'), 0, 11 + I * 3, nil, 0));
      Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 12 + I * 3, nil, 0));
    end;

    for I := 0 to CollectionCount - 1 do
    begin
      if Collections[I] = 'schemas' then
        Stream := Client.GetSchemas
      else if Collections[I] = 'tables' then
        Stream := Client.GetTables
      else if Collections[I] = 'columns' then
        Stream := Client.GetColumns
      else if Collections[I] = 'indexes' then
        Stream := Client.GetIndexes
      else if Collections[I] = 'constraints' then
        Stream := Client.GetConstraints
      else
        Stream := Client.GetRoutines;
      try
        Row := Stream.ReadRow;
        AssertEqualInt(0, Length(Row), Collections[I] + ' expected zero-row stream');
      finally
        Stream.Free;
      end;
    end;

    AssertEqualInt(CollectionCount, Transport.WriteCount, 'metadata wrapper write count');
    for I := 0 to CollectionCount - 1 do
    begin
      DecodeOutboundFrame(Transport.WriteAt(I), MsgType, Payload);
      AssertTrue(MsgType = MSG_QUERY, Collections[I] + ' should send query message');
      AssertEqualBytes(
        BuildQueryPayload(ResolveMetadataCollectionQuery(Collections[I]), 0, 0, 0),
        Payload,
        Collections[I] + ' query payload');
    end;
  finally
    Client.Free;
  end;
end;

procedure TestQueryMetadataRowsAppliesRestrictionsFromWireRows;
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  Restrictions: TMetadataRow;
  Rows: TMetadataRows;
  SchemaValue, TableValue: Variant;
  MsgType: TScratchBirdMessageType;
  Payload: TBytes;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    Transport.QueueInbound(EncodeMessage(
      MSG_ROW_DESCRIPTION,
      BuildRowDescriptionPayloadText(['table_schema', 'table_name']),
      0, 50, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_DATA_ROW, BuildDataRowPayloadText(['users', 'accounts']), 0, 51, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_DATA_ROW, BuildDataRowPayloadText(['sys', 'catalog_tables']), 0, 52, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_COMMAND_COMPLETE, BuildCommandCompletePayload(0, 2, 0, 'SELECT 2'), 0, 53, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 54, nil, 0));

    Restrictions := MetadataRow([MetadataField('schema', 'users')]);
    Rows := Client.QueryMetadataRows('tables', Restrictions);

    AssertEqualInt(1, Length(Rows), 'filtered metadata row count');
    AssertTrue(MetadataRowTryGetValue(Rows[0], 'table_schema', SchemaValue), 'table_schema value should exist');
    AssertTrue(MetadataRowTryGetValue(Rows[0], 'table_name', TableValue), 'table_name value should exist');
    AssertEqualString('users', VarToStr(SchemaValue), 'filtered table_schema');
    AssertEqualString('accounts', VarToStr(TableValue), 'filtered table_name');

    AssertEqualInt(1, Transport.WriteCount, 'metadata rows write count');
    DecodeOutboundFrame(Transport.WriteAt(0), MsgType, Payload);
    AssertTrue(MsgType = MSG_QUERY, 'metadata rows should send query message');
    AssertEqualBytes(
      BuildQueryPayload(ResolveMetadataCollectionQuery('tables'), 0, 0, 0),
      Payload,
      'tables query payload');
  finally
    Client.Free;
  end;
end;

procedure TestQueryMetadataRowsAppliesRoutineRestrictionsFromWireRows;
var
  Transport: TFakeTransport;
  Client: TScratchBirdClient;
  Restrictions: TMetadataRow;
  Rows: TMetadataRows;
  RoutineValue: Variant;
  MsgType: TScratchBirdMessageType;
  Payload: TBytes;
begin
  Transport := TFakeTransport.Create;
  Client := TScratchBirdClient.CreateWithTransport(Transport, True);
  try
    Transport.QueueInbound(EncodeMessage(
      MSG_ROW_DESCRIPTION,
      BuildRowDescriptionPayloadText(['routine_name', 'routine_type']),
      0, 80, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_DATA_ROW, BuildDataRowPayloadText(['refresh_cache', 'PROCEDURE']), 0, 81, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_DATA_ROW, BuildDataRowPayloadText(['to_json_text', 'FUNCTION']), 0, 82, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_COMMAND_COMPLETE, BuildCommandCompletePayload(0, 2, 0, 'SELECT 2'), 0, 83, nil, 0));
    Transport.QueueInbound(EncodeMessage(MSG_READY, BuildReadyPayload(0, 0, 0), 0, 84, nil, 0));

    Restrictions := MetadataRow([MetadataField('procedure', 'refresh_cache')]);
    Rows := Client.QueryMetadataRows('routines', Restrictions);

    AssertEqualInt(1, Length(Rows), 'filtered routines row count');
    AssertTrue(MetadataRowTryGetValue(Rows[0], 'routine_name', RoutineValue), 'routine_name value should exist');
    AssertEqualString('refresh_cache', VarToStr(RoutineValue), 'filtered routine_name');

    AssertEqualInt(1, Transport.WriteCount, 'routines metadata rows write count');
    DecodeOutboundFrame(Transport.WriteAt(0), MsgType, Payload);
    AssertTrue(MsgType = MSG_QUERY, 'routines metadata rows should send query message');
    AssertEqualBytes(
      BuildQueryPayload(ResolveMetadataCollectionQuery('routines'), 0, 0, 0),
      Payload,
      'routines query payload');
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
    TestMetadataWrappersEmitExpectedCollectionQueries;
    TestQueryMetadataRowsAppliesRestrictionsFromWireRows;
    TestQueryMetadataRowsAppliesRoutineRestrictionsFromWireRows;
    Writeln('MetadataExecutionFlowTests: OK');
  except
    on E: Exception do
    begin
      Writeln('MetadataExecutionFlowTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

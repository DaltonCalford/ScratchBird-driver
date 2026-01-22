unit ScratchBird.Protocol;

interface

uses
  SysUtils, Classes;

const
  PROTOCOL_MAGIC = $42444253;
  PROTOCOL_VERSION = $0100;
  MAX_MESSAGE_SIZE = 16 * 1024 * 1024;

type
  TScratchBirdMessageType = Byte;

const
  MSG_CONNECT_REQUEST = $01;
  MSG_CONNECT_RESPONSE = $02;
  MSG_DISCONNECT = $03;
  MSG_AUTH_REQUEST = $10;
  MSG_AUTH_RESPONSE = $11;
  MSG_QUERY = $20;
  MSG_QUERY_RESULT = $21;
  MSG_QUERY_ERROR = $22;
  MSG_QUERY_CANCEL = $23;
  MSG_PREPARE = $30;
  MSG_PREPARE_RESPONSE = $31;
  MSG_EXECUTE = $32;
  MSG_CLOSE_STATEMENT = $33;
  MSG_DESCRIBE = $34;
  MSG_DESCRIBE_RESPONSE = $35;
  MSG_BEGIN = $40;
  MSG_COMMIT = $41;
  MSG_ROLLBACK = $42;
  MSG_ROW_DESCRIPTION = $50;
  MSG_ROW_DATA = $51;
  MSG_END_RESULTS = $52;
  MSG_COMMAND_COMPLETE = $53;

type
  TAuthMethod = Byte;

const
  AUTH_SCRAM_SHA256 = 2;

type
  TAuthStatus = Byte;

const
  AUTH_OK = 0;
  AUTH_ERROR = 1;
  AUTH_CONTINUE = 2;

type
  TWireType = Byte;

const
  WIRE_NULL = $00;
  WIRE_BOOL = $01;
  WIRE_INT16 = $02;
  WIRE_INT32 = $03;
  WIRE_INT64 = $04;
  WIRE_FLOAT32 = $05;
  WIRE_FLOAT64 = $06;
  WIRE_DECIMAL = $07;
  WIRE_VARCHAR = $08;
  WIRE_CHAR = $09;
  WIRE_BYTEA = $0A;
  WIRE_DATE = $0B;
  WIRE_TIME = $0C;
  WIRE_TIMESTAMP = $0D;
  WIRE_TIMESTAMPTZ = $0E;
  WIRE_INTERVAL = $0F;
  WIRE_UUID = $10;
  WIRE_JSON = $11;
  WIRE_JSONB = $12;
  WIRE_ARRAY = $13;
  WIRE_COMPOSITE = $14;
  WIRE_GEOMETRY = $15;
  WIRE_VECTOR = $16;
  WIRE_MONEY = $17;
  WIRE_XML = $18;
  WIRE_INET = $19;
  WIRE_CIDR = $1A;
  WIRE_MACADDR = $1B;
  WIRE_TSVECTOR = $1C;
  WIRE_TSQUERY = $1D;
  WIRE_RANGE = $1E;
  WIRE_UNKNOWN = $FF;

type
  TColumnInfo = record
    Name: string;
    WireType: TWireType;
    TypeModifier: Cardinal;
    FormatCode: Word;
  end;

  TColumnValue = record
    Data: TBytes;
    IsNull: Boolean;
  end;

  TScratchBirdMessage = record
    MsgType: TScratchBirdMessageType;
    Flags: Byte;
    Payload: TBytes;
  end;

function EncodeMessage(MsgType: TScratchBirdMessageType; const Payload: TBytes; Flags: Byte = 0): TBytes;
function DecodeHeader(const Header: TBytes; out MsgType: TScratchBirdMessageType; out Flags: Byte; out Length: Integer): Boolean;

function BuildConnectRequest(const Database, ClientName: string; Pid: Cardinal): TBytes;
function ParseConnectResponse(const Payload: TBytes; out SessionId: TBytes; out ServerName, ServerVersion, ErrorMessage: string): Boolean;

function BuildAuthRequest(const SessionId: TBytes; const UserName: string; Method: TAuthMethod; const Payload: TBytes): TBytes;
procedure ParseAuthResponse(const Payload: TBytes; out Status: TAuthStatus; out UserId: Cardinal; out ErrorMessage: string; out Extra: TBytes);

function BuildQuery(const SessionId: TBytes; const Sql: string; Flags: Byte = 0): TBytes;
function ParseRowDescription(const Payload: TBytes): TArray<TColumnInfo>;
function ParseRowData(const Payload: TBytes): TArray<TColumnValue>;
procedure ParseCommandComplete(const Payload: TBytes; out Tag: string; out Rows: Int64);
procedure ParseQueryResult(const Payload: TBytes; out Status: Byte; out ColumnCount: Cardinal; out RowCount: Int64);
procedure ParseQueryError(const Payload: TBytes; out ErrorCode: Cardinal; out SqlState, Message, Detail, Hint: string);

function BuildBegin(const SessionId: TBytes; Isolation: Byte; ReadOnly: Boolean): TBytes;
function BuildCommit(const SessionId: TBytes): TBytes;
function BuildRollback(const SessionId: TBytes): TBytes;
function BuildDisconnect(const SessionId: TBytes): TBytes;

implementation

function ConcatBytes(const Left, Right: TBytes): TBytes;
begin
  SetLength(Result, Length(Left) + Length(Right));
  if Length(Left) > 0 then
    Move(Left[0], Result[0], Length(Left));
  if Length(Right) > 0 then
    Move(Right[0], Result[Length(Left)], Length(Right));
end;

function ByteToBytes(Value: Byte): TBytes;
begin
  SetLength(Result, 1);
  Result[0] := Value;
end;

function WriteUInt16LE(Value: Word): TBytes;
begin
  SetLength(Result, 2);
  Result[0] := Byte(Value and $FF);
  Result[1] := Byte((Value shr 8) and $FF);
end;

function WriteUInt32LE(Value: Cardinal): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := Byte(Value and $FF);
  Result[1] := Byte((Value shr 8) and $FF);
  Result[2] := Byte((Value shr 16) and $FF);
  Result[3] := Byte((Value shr 24) and $FF);
end;

function WriteUInt64LE(Value: UInt64): TBytes;
begin
  SetLength(Result, 8);
  Result[0] := Byte(Value and $FF);
  Result[1] := Byte((Value shr 8) and $FF);
  Result[2] := Byte((Value shr 16) and $FF);
  Result[3] := Byte((Value shr 24) and $FF);
  Result[4] := Byte((Value shr 32) and $FF);
  Result[5] := Byte((Value shr 40) and $FF);
  Result[6] := Byte((Value shr 48) and $FF);
  Result[7] := Byte((Value shr 56) and $FF);
end;

function ReadUInt16LE(const Data: TBytes; Offset: Integer): Word;
begin
  Result := Word(Data[Offset]) or (Word(Data[Offset + 1]) shl 8);
end;

function ReadUInt32LE(const Data: TBytes; Offset: Integer): Cardinal;
begin
  Result := Cardinal(Data[Offset]) or (Cardinal(Data[Offset + 1]) shl 8) or
    (Cardinal(Data[Offset + 2]) shl 16) or (Cardinal(Data[Offset + 3]) shl 24);
end;

function ReadUInt64LE(const Data: TBytes; Offset: Integer): UInt64;
begin
  Result := UInt64(Data[Offset]) or (UInt64(Data[Offset + 1]) shl 8) or
    (UInt64(Data[Offset + 2]) shl 16) or (UInt64(Data[Offset + 3]) shl 24) or
    (UInt64(Data[Offset + 4]) shl 32) or (UInt64(Data[Offset + 5]) shl 40) or
    (UInt64(Data[Offset + 6]) shl 48) or (UInt64(Data[Offset + 7]) shl 56);
end;

function EncodeMessage(MsgType: TScratchBirdMessageType; const Payload: TBytes; Flags: Byte): TBytes;
var
  Header: TBytes;
  LengthBytes: TBytes;
begin
  SetLength(Header, 12);
  Move(WriteUInt32LE(PROTOCOL_MAGIC)[0], Header[0], 4);
  Move(WriteUInt16LE(PROTOCOL_VERSION)[0], Header[4], 2);
  Header[6] := MsgType;
  Header[7] := Flags;
  LengthBytes := WriteUInt32LE(Length(Payload));
  Move(LengthBytes[0], Header[8], 4);
  Result := ConcatBytes(Header, Payload);
end;

function DecodeHeader(const Header: TBytes; out MsgType: TScratchBirdMessageType; out Flags: Byte; out Length: Integer): Boolean;
var
  Magic: Cardinal;
begin
  Result := False;
  if Length(Header) <> 12 then
    Exit;
  Magic := ReadUInt32LE(Header, 0);
  if Magic <> PROTOCOL_MAGIC then
    Exit;
  MsgType := Header[6];
  Flags := Header[7];
  Length := Integer(ReadUInt32LE(Header, 8));
  if Length > MAX_MESSAGE_SIZE then
    Exit;
  Result := True;
end;

function WriteNullTerminated(const Value: string; Length: Integer): TBytes;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(Value);
  SetLength(Result, Length);
  FillChar(Result[0], Length, 0);
  if Length(Bytes) > Length - 1 then
    SetLength(Bytes, Length - 1);
  Move(Bytes[0], Result[0], Length(Bytes));
end;

function ReadNullTerminated(const Data: TBytes; Offset, Length: Integer): string;
var
  I: Integer;
begin
  I := 0;
  while (I < Length) and (Data[Offset + I] <> 0) do
    Inc(I);
  Result := TEncoding.UTF8.GetString(Data, Offset, I);
end;

function BuildConnectRequest(const Database, ClientName: string; Pid: Cardinal): TBytes;
var
  Payload: TBytes;
begin
  Payload := WriteUInt16LE(PROTOCOL_VERSION);
  Payload := ConcatBytes(Payload, WriteUInt16LE(0));
  Payload := ConcatBytes(Payload, WriteUInt32LE(Pid));
  Payload := ConcatBytes(Payload, WriteNullTerminated(Database, 256));
  Payload := ConcatBytes(Payload, WriteNullTerminated(ClientName, 64));
  Payload := ConcatBytes(Payload, WriteNullTerminated('1.0.0', 32));
  Result := EncodeMessage(MSG_CONNECT_REQUEST, Payload);
end;

function ParseConnectResponse(const Payload: TBytes; out SessionId: TBytes; out ServerName, ServerVersion, ErrorMessage: string): Boolean;
var
  Offset: Integer;
  Status: Byte;
  ErrLen: Word;
begin
  Result := False;
  if Length(Payload) < 1 + 2 + 2 + 16 + 64 + 32 then
    Exit;
  Offset := 0;
  Status := Payload[Offset];
  Inc(Offset);
  Inc(Offset, 2);
  Inc(Offset, 2);
  SetLength(SessionId, 16);
  Move(Payload[Offset], SessionId[0], 16);
  Inc(Offset, 16);
  ServerName := ReadNullTerminated(Payload, Offset, 64);
  Inc(Offset, 64);
  ServerVersion := ReadNullTerminated(Payload, Offset, 32);
  Inc(Offset, 32);
  ErrorMessage := '';
  if (Status <> 0) and (Offset + 2 <= Length(Payload)) then
  begin
    ErrLen := ReadUInt16LE(Payload, Offset);
    Inc(Offset, 2);
    if Offset + ErrLen <= Length(Payload) then
      ErrorMessage := TEncoding.UTF8.GetString(Payload, Offset, ErrLen);
  end;
  Result := Status = 0;
end;

function BuildAuthRequest(const SessionId: TBytes; const UserName: string; Method: TAuthMethod; const Payload: TBytes): TBytes;
var
  Buffer: TBytes;
begin
  if Length(SessionId) <> 16 then
    raise Exception.Create('sessionId must be 16 bytes');
  Buffer := SessionId;
  Buffer := ConcatBytes(Buffer, WriteNullTerminated(UserName, 64));
  Buffer := ConcatBytes(Buffer, ByteToBytes(Method));
  Buffer := ConcatBytes(Buffer, WriteUInt16LE(Length(Payload)));
  Buffer := ConcatBytes(Buffer, Payload);
  Result := EncodeMessage(MSG_AUTH_REQUEST, Buffer);
end;

procedure ParseAuthResponse(const Payload: TBytes; out Status: TAuthStatus; out UserId: Cardinal; out ErrorMessage: string; out Extra: TBytes);
begin
  if Length(Payload) < 1 + 4 + 256 then
    raise Exception.Create('Auth response truncated');
  Status := Payload[0];
  UserId := ReadUInt32LE(Payload, 1);
  ErrorMessage := ReadNullTerminated(Payload, 5, 256);
  Extra := Copy(Payload, 5 + 256, Length(Payload) - (5 + 256));
end;

function BuildQuery(const SessionId: TBytes; const Sql: string; Flags: Byte): TBytes;
var
  SqlBytes: TBytes;
  Payload: TBytes;
begin
  if Length(SessionId) <> 16 then
    raise Exception.Create('sessionId must be 16 bytes');
  SqlBytes := TEncoding.UTF8.GetBytes(Sql);
  Payload := SessionId;
  Payload := ConcatBytes(Payload, WriteUInt32LE(Length(SqlBytes)));
  Payload := ConcatBytes(Payload, ByteToBytes(Flags));
  Payload := ConcatBytes(Payload, SqlBytes);
  Result := EncodeMessage(MSG_QUERY, Payload);
end;

function ParseRowDescription(const Payload: TBytes): TArray<TColumnInfo>;
var
  Offset, I, Count, NameLen: Integer;
begin
  if Length(Payload) < 2 then
    raise Exception.Create('Row description truncated');
  Offset := 0;
  Count := ReadUInt16LE(Payload, Offset);
  Inc(Offset, 2);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    NameLen := ReadUInt16LE(Payload, Offset);
    Inc(Offset, 2);
    Result[I].Name := TEncoding.UTF8.GetString(Payload, Offset, NameLen);
    Inc(Offset, NameLen);
    Result[I].WireType := Payload[Offset];
    Inc(Offset);
    Result[I].TypeModifier := ReadUInt32LE(Payload, Offset);
    Inc(Offset, 4);
    Result[I].FormatCode := ReadUInt16LE(Payload, Offset);
    Inc(Offset, 2);
  end;
end;

function ParseRowData(const Payload: TBytes): TArray<TColumnValue>;
var
  Offset, I, Count: Integer;
  LengthValue: Integer;
begin
  if Length(Payload) < 2 then
    raise Exception.Create('Row data truncated');
  Offset := 0;
  Count := ReadUInt16LE(Payload, Offset);
  Inc(Offset, 2);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    LengthValue := Integer(ReadUInt32LE(Payload, Offset));
    Inc(Offset, 4);
    if LengthValue and Integer($80000000) <> 0 then
    begin
      Result[I].IsNull := True;
      Result[I].Data := nil;
      Continue;
    end;
    Result[I].IsNull := False;
    SetLength(Result[I].Data, LengthValue);
    if LengthValue > 0 then
      Move(Payload[Offset], Result[I].Data[0], LengthValue);
    Inc(Offset, LengthValue);
  end;
end;

procedure ParseCommandComplete(const Payload: TBytes; out Tag: string; out Rows: Int64);
begin
  if Length(Payload) < 64 + 8 then
    raise Exception.Create('Command complete truncated');
  Tag := ReadNullTerminated(Payload, 0, 64);
  Rows := Int64(ReadUInt64LE(Payload, 64));
end;

procedure ParseQueryResult(const Payload: TBytes; out Status: Byte; out ColumnCount: Cardinal; out RowCount: Int64);
begin
  if Length(Payload) < 1 + 4 + 8 then
    raise Exception.Create('Query result truncated');
  Status := Payload[0];
  ColumnCount := ReadUInt32LE(Payload, 1);
  RowCount := Int64(ReadUInt64LE(Payload, 5));
end;

procedure ParseQueryError(const Payload: TBytes; out ErrorCode: Cardinal; out SqlState, Message, Detail, Hint: string);
var
  Offset: Integer;
  MsgLen, DetailLen, HintLen: Word;
begin
  if Length(Payload) < 4 + 6 + 2 + 2 + 2 then
    raise Exception.Create('Query error truncated');
  Offset := 0;
  ErrorCode := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  SqlState := ReadNullTerminated(Payload, Offset, 6);
  Inc(Offset, 6);
  MsgLen := ReadUInt16LE(Payload, Offset);
  Inc(Offset, 2);
  DetailLen := ReadUInt16LE(Payload, Offset);
  Inc(Offset, 2);
  HintLen := ReadUInt16LE(Payload, Offset);
  Inc(Offset, 2);
  Message := TEncoding.UTF8.GetString(Payload, Offset, MsgLen);
  Inc(Offset, MsgLen);
  Detail := TEncoding.UTF8.GetString(Payload, Offset, DetailLen);
  Inc(Offset, DetailLen);
  Hint := TEncoding.UTF8.GetString(Payload, Offset, HintLen);
end;

function BuildBegin(const SessionId: TBytes; Isolation: Byte; ReadOnly: Boolean): TBytes;
var
  Payload: TBytes;
begin
  if Length(SessionId) <> 16 then
    raise Exception.Create('sessionId must be 16 bytes');
  Payload := SessionId;
  Payload := ConcatBytes(Payload, ByteToBytes(Isolation));
  Payload := ConcatBytes(Payload, ByteToBytes(Byte(Ord(ReadOnly))));
  Result := EncodeMessage(MSG_BEGIN, Payload);
end;

function BuildCommit(const SessionId: TBytes): TBytes;
begin
  Result := EncodeMessage(MSG_COMMIT, SessionId);
end;

function BuildRollback(const SessionId: TBytes): TBytes;
begin
  Result := EncodeMessage(MSG_ROLLBACK, SessionId);
end;

function BuildDisconnect(const SessionId: TBytes): TBytes;
begin
  Result := EncodeMessage(MSG_DISCONNECT, SessionId);
end;

end.

unit ScratchBird.Types;

interface

uses
  SysUtils, Variants, DateUtils;

function DecodeValue(WireType: Byte; const Data: TBytes; IsNull: Boolean): Variant;
function WireTypeName(WireType: Byte): string;

implementation

function ReadUInt16LE(const Data: TBytes; Offset: Integer): Word;
begin
  Result := Word(Data[Offset]) or (Word(Data[Offset + 1]) shl 8);
end;

function ReadUInt32LE(const Data: TBytes; Offset: Integer): Cardinal;
begin
  Result := Cardinal(Data[Offset]) or (Cardinal(Data[Offset + 1]) shl 8) or
    (Cardinal(Data[Offset + 2]) shl 16) or (Cardinal(Data[Offset + 3]) shl 24);
end;

function ReadSingleLE(const Data: TBytes; Offset: Integer): Single;
begin
  Move(Data[Offset], Result, SizeOf(Result));
end;

function ReadDoubleLE(const Data: TBytes; Offset: Integer): Double;
begin
  Move(Data[Offset], Result, SizeOf(Result));
end;

function ReadInt64LE(const Data: TBytes; Offset: Integer): Int64;
var
  Value: UInt64;
begin
  Value := UInt64(Data[Offset]) or (UInt64(Data[Offset + 1]) shl 8) or
    (UInt64(Data[Offset + 2]) shl 16) or (UInt64(Data[Offset + 3]) shl 24) or
    (UInt64(Data[Offset + 4]) shl 32) or (UInt64(Data[Offset + 5]) shl 40) or
    (UInt64(Data[Offset + 6]) shl 48) or (UInt64(Data[Offset + 7]) shl 56);
  Result := Int64(Value);
end;

function DecodeDate(const Data: TBytes): TDateTime;
var
  Days: Integer;
  Base: TDateTime;
begin
  Days := Integer(ReadUInt32LE(Data, 0));
  Base := EncodeDate(2000, 1, 1);
  Result := Base + Days;
end;

function DecodeTime(const Data: TBytes): TDateTime;
var
  Micros: Int64;
  Seconds: Int64;
  MicroRemainder: Int64;
begin
  Micros := ReadInt64LE(Data, 0);
  Seconds := Micros div 1000000;
  MicroRemainder := Micros mod 1000000;
  Result := EncodeTime(0, 0, 0, 0) + (Seconds / 86400) + (MicroRemainder / 86400 / 1000000);
end;

function DecodeTimestamp(const Data: TBytes): TDateTime;
var
  Micros: Int64;
begin
  Micros := ReadInt64LE(Data, 0);
  Result := UnixToDateTime(Micros div 1000000, False) + (Micros mod 1000000) / 86400 / 1000000;
end;

function DecodeMoney(const Data: TBytes): Currency;
var
  Cents: Int64;
begin
  Cents := ReadInt64LE(Data, 0);
  Result := Cents / 100;
end;

function BytesToHex(const Data: TBytes): string;
var
  I: Integer;
const
  HexChars: array[0..15] of Char = '0123456789abcdef';
begin
  SetLength(Result, Length(Data) * 2);
  for I := 0 to Length(Data) - 1 do
  begin
    Result[I * 2 + 1] := HexChars[Data[I] shr 4];
    Result[I * 2 + 2] := HexChars[Data[I] and $F];
  end;
end;

function DecodeUuid(const Data: TBytes): string;
var
  Hex: string;
begin
  Hex := BytesToHex(Data);
  if Length(Hex) <> 32 then
    Exit(Hex);
  Result := Copy(Hex, 1, 8) + '-' + Copy(Hex, 9, 4) + '-' + Copy(Hex, 13, 4) + '-' +
    Copy(Hex, 17, 4) + '-' + Copy(Hex, 21, 12);
end;

function DecodeValue(WireType: Byte; const Data: TBytes; IsNull: Boolean): Variant;
begin
  if IsNull then
    Exit(Null);
  case WireType of
    $01: Result := Data[0] = 1;
    $02: Result := SmallInt(ReadUInt16LE(Data, 0));
    $03: Result := Integer(ReadUInt32LE(Data, 0));
    $04: Result := ReadInt64LE(Data, 0);
    $05: Result := ReadSingleLE(Data, 0);
    $06: Result := ReadDoubleLE(Data, 0);
    $07: Result := TEncoding.UTF8.GetString(Data);
    $08, $09, $11, $12, $18, $1C, $1D: Result := TEncoding.UTF8.GetString(Data);
    $0A: Result := Data;
    $0B: Result := DecodeDate(Data);
    $0C: Result := DecodeTime(Data);
    $0D, $0E: Result := DecodeTimestamp(Data);
    $0F: Result := TEncoding.UTF8.GetString(Data);
    $10: Result := DecodeUuid(Data);
    $17: Result := DecodeMoney(Data);
    $19, $1A: Result := TEncoding.UTF8.GetString(Data);
    $13, $16: Result := TEncoding.UTF8.GetString(Data);
  else
    Result := Data;
  end;
end;

function WireTypeName(WireType: Byte): string;
begin
  case WireType of
    $01: Result := 'boolean';
    $02: Result := 'int16';
    $03: Result := 'int32';
    $04: Result := 'int64';
    $05: Result := 'float32';
    $06: Result := 'float64';
    $07: Result := 'decimal';
    $08: Result := 'varchar';
    $09: Result := 'char';
    $0A: Result := 'bytea';
    $0B: Result := 'date';
    $0C: Result := 'time';
    $0D: Result := 'timestamp';
    $0E: Result := 'timestamptz';
    $0F: Result := 'interval';
    $10: Result := 'uuid';
    $11: Result := 'json';
    $12: Result := 'jsonb';
    $13: Result := 'array';
    $14: Result := 'composite';
    $15: Result := 'geometry';
    $16: Result := 'vector';
    $17: Result := 'money';
    $18: Result := 'xml';
    $19: Result := 'inet';
    $1A: Result := 'cidr';
    $1B: Result := 'macaddr';
    $1C: Result := 'tsvector';
    $1D: Result := 'tsquery';
    $1E: Result := 'range';
  else
    Result := 'unknown';
  end;
end;

end.

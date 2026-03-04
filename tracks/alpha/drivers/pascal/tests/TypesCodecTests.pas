{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program TypesCodecTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, Variants,
  ScratchBird.Protocol, ScratchBird.Types;

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

procedure AssertEqualInt64(Expected, Actual: Int64; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

procedure AssertEqualCardinal(Expected, Actual: Cardinal; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

procedure AssertEqualString(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected="' + Expected + '" actual="' + Actual + '"');
end;

function ConcatBytes(const Left, Right: TBytes): TBytes;
begin
  SetLength(Result, Length(Left) + Length(Right));
  if Length(Left) > 0 then
    Move(Left[0], Result[0], Length(Left));
  if Length(Right) > 0 then
    Move(Right[0], Result[Length(Left)], Length(Right));
end;

function WriteInt32LE(Value: Integer): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := Byte(Value and $FF);
  Result[1] := Byte((Value shr 8) and $FF);
  Result[2] := Byte((Value shr 16) and $FF);
  Result[3] := Byte((Value shr 24) and $FF);
end;

function WriteInt64LE(Value: Int64): TBytes;
begin
  SetLength(Result, 8);
  Move(Value, Result[0], 8);
end;

function ReadInt32LEAt(const Data: TBytes; Offset: Integer): Integer;
begin
  Result := Integer(Cardinal(Data[Offset]) or (Cardinal(Data[Offset + 1]) shl 8) or
    (Cardinal(Data[Offset + 2]) shl 16) or (Cardinal(Data[Offset + 3]) shl 24));
end;

function ReadInt64LEAt(const Data: TBytes; Offset: Integer): Int64;
var
  Raw: UInt64;
begin
  Raw := UInt64(Data[Offset]) or (UInt64(Data[Offset + 1]) shl 8) or
    (UInt64(Data[Offset + 2]) shl 16) or (UInt64(Data[Offset + 3]) shl 24) or
    (UInt64(Data[Offset + 4]) shl 32) or (UInt64(Data[Offset + 5]) shl 40) or
    (UInt64(Data[Offset + 6]) shl 48) or (UInt64(Data[Offset + 7]) shl 56);
  Result := Int64(Raw);
end;

function HexToBytes(const Hex: string): TBytes;
var
  I: Integer;
  PairText: string;
begin
  if (Length(Hex) mod 2) <> 0 then
    Fail('hex length must be even');
  SetLength(Result, Length(Hex) div 2);
  for I := 0 to High(Result) do
  begin
    PairText := '$' + Copy(Hex, I * 2 + 1, 2);
    Result[I] := StrToInt(PairText);
  end;
end;

function WithLengthPrefix(const Payload: TBytes): TBytes;
begin
  Result := ConcatBytes(WriteInt32LE(Length(Payload)), Payload);
end;

function TimeMicros(const Value: TDateTime): Int64;
begin
  Result := Trunc(Frac(Value) * 86400 * 1000000);
end;

procedure AssertTimeMicrosNear(Expected, Actual: TDateTime; ToleranceMicros: Int64; const MessageText: string);
var
  Diff: Int64;
begin
  Diff := Abs(TimeMicros(Expected) - TimeMicros(Actual));
  if Diff > ToleranceMicros then
    Fail(MessageText + ': expectedMicros=' + IntToStr(TimeMicros(Expected)) +
      ' actualMicros=' + IntToStr(TimeMicros(Actual)) + ' diff=' + IntToStr(Diff));
end;

procedure TestEncodeBooleanParamUsesBoolOid;
var
  Param: TParamValue;
  Oid: Cardinal;
begin
  AssertTrue(EncodeParam(True, nil, Param, Oid), 'bool encode should succeed');
  AssertEqualInt(FORMAT_BINARY, Param.Format, 'bool encode format');
  AssertEqualCardinal(OID_BOOL, Oid, 'bool encode oid');
  AssertTrue(not Param.IsNull, 'bool encode null flag');
  AssertEqualInt(1, Length(Param.Data), 'bool payload length');
  AssertEqualInt(1, Param.Data[0], 'bool payload value');
end;

procedure TestEncodeUuidStringParamUsesUuidOid;
var
  Param: TParamValue;
  Oid: Cardinal;
  Decoded: Variant;
begin
  AssertTrue(EncodeParam('11111111-2222-3333-4444-555555555555', nil, Param, Oid), 'uuid string encode should succeed');
  AssertEqualCardinal(OID_UUID, Oid, 'uuid encode oid');
  AssertEqualInt(16, Length(Param.Data), 'uuid payload length');
  Decoded := DecodeValue(OID_UUID, Param.Data, FORMAT_BINARY);
  AssertEqualString('11111111-2222-3333-4444-555555555555', VarToStr(Decoded), 'uuid round-trip decode');
end;

procedure TestEncodeNumericArrayStillUsesVectorOid;
var
  Param: TParamValue;
  Oid: Cardinal;
  Value: Variant;
begin
  Value := VarArrayCreate([0, 2], varInteger);
  Value[0] := 1;
  Value[1] := 2;
  Value[2] := 3;
  AssertTrue(EncodeParam(Value, nil, Param, Oid), 'numeric array encode should succeed');
  AssertEqualCardinal(OID_SB_VECTOR, Oid, 'numeric array oid');
  AssertTrue(Length(Param.Data) > 4, 'numeric array payload should be length-prefixed text');
end;

procedure TestDecodeUuidBinaryCanonicalizesHyphenFormat;
var
  Decoded: Variant;
begin
  Decoded := DecodeValue(OID_UUID, HexToBytes('123456789abcdef0123456789abcdef0'), FORMAT_BINARY);
  AssertEqualString('12345678-9abc-def0-1234-56789abcdef0', VarToStr(Decoded), 'uuid decode canonical text');
end;

procedure TestDecodeVectorBinaryReturnsNumericVariantArray;
var
  Decoded: Variant;
begin
  Decoded := DecodeValue(OID_SB_VECTOR, WithLengthPrefix(TEncoding.UTF8.GetBytes('[1.5,2,3.25]')), FORMAT_BINARY);
  AssertTrue(VarIsArray(Decoded), 'vector decode should return array');
  AssertEqualInt(3, VarArrayHighBound(Decoded, 1) - VarArrayLowBound(Decoded, 1) + 1, 'vector decode element count');
  AssertTrue(Abs(VarAsType(Decoded[0], varDouble) - 1.5) < 0.000001, 'vector value 0');
  AssertTrue(Abs(VarAsType(Decoded[1], varDouble) - 2.0) < 0.000001, 'vector value 1');
  AssertTrue(Abs(VarAsType(Decoded[2], varDouble) - 3.25) < 0.000001, 'vector value 2');
end;

procedure TestDecodeJsonbBinaryReturnsWrapper;
var
  Decoded: Variant;
  Jsonb: IScratchBirdJsonb;
begin
  Decoded := DecodeValue(OID_JSONB, WithLengthPrefix(TEncoding.UTF8.GetBytes('{"k":1}')), FORMAT_BINARY);
  AssertTrue((VarType(Decoded) = varUnknown) and Supports(IInterface(Decoded), IScratchBirdJsonb, Jsonb),
    'jsonb decode should return IScratchBirdJsonb');
  AssertEqualString('{"k":1}', TEncoding.UTF8.GetString(Jsonb.GetRaw), 'jsonb raw payload');
end;

procedure TestDecodeCompositeRoundTripReturnsFields;
var
  Composite: TScratchBirdComposite;
  Param: TParamValue;
  Oid: Cardinal;
  Decoded: Variant;
  DecodedComposite: IScratchBirdComposite;
begin
  Composite := TScratchBirdComposite.Create([OID_INT4], [77]);
  try
    AssertTrue(EncodeParam(Null, Composite, Param, Oid), 'composite encode should succeed');
  finally
    Composite.Free;
  end;
  AssertEqualCardinal(OID_RECORD, Oid, 'composite encode oid');
  Decoded := DecodeValue(OID_RECORD, Param.Data, FORMAT_BINARY);
  AssertTrue((VarType(Decoded) = varUnknown) and Supports(IInterface(Decoded), IScratchBirdComposite, DecodedComposite),
    'composite decode should return IScratchBirdComposite');
  AssertEqualInt(1, DecodedComposite.GetFieldCount, 'composite field count');
  AssertEqualCardinal(OID_INT4, DecodedComposite.GetFieldOid(0), 'composite field oid');
  AssertEqualInt(77, VarAsType(DecodedComposite.GetFieldValue(0), varInteger), 'composite field value');
end;

procedure TestDecodeUnknownUsesTextHeuristics;
var
  BoolText: Variant;
  IntText: Variant;
begin
  BoolText := DecodeValue(0, TEncoding.UTF8.GetBytes('true'), FORMAT_TEXT);
  AssertTrue(Boolean(BoolText), 'unknown text bool decode');
  IntText := DecodeValue(0, TBytes.Create(Ord('4'), Ord('2'), 0), FORMAT_BINARY);
  AssertEqualInt(42, VarAsType(IntText, varInteger), 'unknown binary trailing-null int decode');
end;

procedure TestDecodeTimeTzTwelveBytePayloadPreservesOffsetAndNormalizesDay;
var
  Payload: TBytes;
  Decoded: Variant;
  TimeValue: TDateTime;
  OffsetSecondsEast: Integer;
  Expected: TDateTime;
begin
  Payload := ConcatBytes(WriteInt64LE(Int64(25 * 60 * 60 * 1000000) + 123456), WriteInt32LE(18000));
  Decoded := DecodeValue(OID_TIMETZ, Payload, FORMAT_BINARY);
  AssertTrue(VarIsArray(Decoded), 'timetz decode (12-byte) should return array');
  TimeValue := VarToDateTime(Decoded[0]);
  OffsetSecondsEast := VarAsType(Decoded[1], varInteger);
  Expected := EncodeTime(1, 0, 0, 0) + (123456 / 86400 / 1000000);
  AssertTimeMicrosNear(Expected, TimeValue, 32, 'timetz decode normalized time');
  AssertEqualInt(-18000, OffsetSecondsEast, 'timetz decode offset seconds east');
end;

procedure TestDecodeTimeTzEightBytePayloadDefaultsToUtc;
var
  Payload: TBytes;
  Decoded: Variant;
  TimeValue: TDateTime;
  OffsetSecondsEast: Integer;
begin
  Payload := WriteInt64LE(Int64((1 * 60 * 60 + 1 * 60 + 1) * 1000000));
  Decoded := DecodeValue(OID_TIMETZ, Payload, FORMAT_BINARY);
  AssertTrue(VarIsArray(Decoded), 'timetz decode (8-byte) should return array');
  TimeValue := VarToDateTime(Decoded[0]);
  OffsetSecondsEast := VarAsType(Decoded[1], varInteger);
  AssertTimeMicrosNear(EncodeTime(1, 1, 1, 0), TimeValue, 8, 'timetz 8-byte time');
  AssertEqualInt(0, OffsetSecondsEast, 'timetz 8-byte default offset');
end;

procedure TestEncodeTimeTzVariantArrayUsesTimetzOidAndPayloadShape;
var
  Param: TParamValue;
  Oid: Cardinal;
  Value: Variant;
  Micros: Int64;
  ZoneSecondsWest: Integer;
  ExpectedMicros: Int64;
begin
  Value := VarArrayOf([VarFromDateTime(EncodeTime(14, 30, 15, 250)), 3600]);
  AssertTrue(EncodeParam(Value, nil, Param, Oid), 'timetz encode should succeed');
  AssertEqualCardinal(OID_TIMETZ, Oid, 'timetz encode oid');
  AssertEqualInt(12, Length(Param.Data), 'timetz payload length');

  Micros := ReadInt64LEAt(Param.Data, 0);
  ZoneSecondsWest := ReadInt32LEAt(Param.Data, 8);
  ExpectedMicros := TimeMicros(EncodeTime(14, 30, 15, 250));

  AssertTrue(Abs(Micros - ExpectedMicros) <= 2, 'timetz encoded micros');
  AssertEqualInt(-3600, ZoneSecondsWest, 'timetz encoded zone seconds west');
end;

begin
  try
    TestEncodeBooleanParamUsesBoolOid;
    TestEncodeUuidStringParamUsesUuidOid;
    TestEncodeNumericArrayStillUsesVectorOid;
    TestDecodeUuidBinaryCanonicalizesHyphenFormat;
    TestDecodeVectorBinaryReturnsNumericVariantArray;
    TestDecodeJsonbBinaryReturnsWrapper;
    TestDecodeCompositeRoundTripReturnsFields;
    TestDecodeUnknownUsesTextHeuristics;
    TestDecodeTimeTzTwelveBytePayloadPreservesOffsetAndNormalizesDay;
    TestDecodeTimeTzEightBytePayloadDefaultsToUtc;
    TestEncodeTimeTzVariantArrayUsesTimetzOidAndPayloadShape;
    Writeln('TypesCodecTests: OK');
  except
    on E: Exception do
    begin
      Writeln('TypesCodecTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

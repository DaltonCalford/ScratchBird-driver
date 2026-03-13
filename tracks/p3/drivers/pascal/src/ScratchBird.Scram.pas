{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Scram;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, Classes, Math;

type
  TScramClient = class
  private
    FUserName: string;
    FClientNonce: string;
    FClientFirstBare: string;
    FServerSignature: TBytes;
    function ConcatBytes(const Left, Right: TBytes): TBytes;
    function BytesFromInt(I: Integer): TBytes;
    function EscapeValue(const Value: string): string;
    function HmacSha256(const Key, Data: TBytes): TBytes;
    function Sha256(const Data: TBytes): TBytes;
    function Pbkdf2Sha256(const Password, Salt: TBytes; Iterations, KeyLen: Integer): TBytes;
    function XorBytes(const Left, Right: TBytes): TBytes;
    function Base64Encode(const Data: TBytes): string;
    function Base64Decode(const Value: string): TBytes;
    function ParseAttributes(const Message: string): TStringList;
  public
    constructor Create(const UserName: string);
    function ClientFirstMessage: string;
    function HandleServerFirst(const Password, ServerFirst: string): string;
    procedure VerifyServerFinal(const ServerFinal: string);
  end;

implementation

{$IFDEF FPC}
type
  TSha256State = array[0..7] of Cardinal;
  TSha256Block = array[0..63] of Cardinal;

const
  Sha256Init: TSha256State = (
    $6A09E667, $BB67AE85, $3C6EF372, $A54FF53A,
    $510E527F, $9B05688C, $1F83D9AB, $5BE0CD19
  );

  Sha256K: array[0..63] of Cardinal = (
    $428A2F98, $71374491, $B5C0FBCF, $E9B5DBA5,
    $3956C25B, $59F111F1, $923F82A4, $AB1C5ED5,
    $D807AA98, $12835B01, $243185BE, $550C7DC3,
    $72BE5D74, $80DEB1FE, $9BDC06A7, $C19BF174,
    $E49B69C1, $EFBE4786, $0FC19DC6, $240CA1CC,
    $2DE92C6F, $4A7484AA, $5CB0A9DC, $76F988DA,
    $983E5152, $A831C66D, $B00327C8, $BF597FC7,
    $C6E00BF3, $D5A79147, $06CA6351, $14292967,
    $27B70A85, $2E1B2138, $4D2C6DFC, $53380D13,
    $650A7354, $766A0ABB, $81C2C92E, $92722C85,
    $A2BFE8A1, $A81A664B, $C24B8B70, $C76C51A3,
    $D192E819, $D6990624, $F40E3585, $106AA070,
    $19A4C116, $1E376C08, $2748774C, $34B0BCB5,
    $391C0CB3, $4ED8AA4A, $5B9CCA4F, $682E6FF3,
    $748F82EE, $78A5636F, $84C87814, $8CC70208,
    $90BEFFFA, $A4506CEB, $BEF9A3F7, $C67178F2
  );

function RotR32(Value: Cardinal; Bits: Byte): Cardinal;
begin
  Result := (Value shr Bits) or (Value shl (32 - Bits));
end;

function Ch(X, Y, Z: Cardinal): Cardinal;
begin
  Result := (X and Y) xor ((not X) and Z);
end;

function Maj(X, Y, Z: Cardinal): Cardinal;
begin
  Result := (X and Y) xor (X and Z) xor (Y and Z);
end;

function BigSigma0(X: Cardinal): Cardinal;
begin
  Result := RotR32(X, 2) xor RotR32(X, 13) xor RotR32(X, 22);
end;

function BigSigma1(X: Cardinal): Cardinal;
begin
  Result := RotR32(X, 6) xor RotR32(X, 11) xor RotR32(X, 25);
end;

function SmallSigma0(X: Cardinal): Cardinal;
begin
  Result := RotR32(X, 7) xor RotR32(X, 18) xor (X shr 3);
end;

function SmallSigma1(X: Cardinal): Cardinal;
begin
  Result := RotR32(X, 17) xor RotR32(X, 19) xor (X shr 10);
end;

function Sha256Digest(const Data: TBytes): TBytes;
var
  State: TSha256State;
  Block: TSha256Block;
  A, B, C, D, E, F, G, H: Cardinal;
  T1, T2: Cardinal;
  I, J: Integer;
  Padded: TBytes;
  BitLen: UInt64;
  Offset: Integer;
begin
  State := Sha256Init;
  BitLen := UInt64(Length(Data)) * 8;

  Padded := Copy(Data, 0, Length(Data));
  SetLength(Padded, Length(Padded) + 1);
  Padded[Length(Padded) - 1] := $80;
  while (Length(Padded) mod 64) <> 56 do
    SetLength(Padded, Length(Padded) + 1);
  SetLength(Padded, Length(Padded) + 8);
  for I := 0 to 7 do
    Padded[Length(Padded) - 8 + I] := Byte((BitLen shr (56 - I * 8)) and $FF);

  Offset := 0;
  while Offset < Length(Padded) do
  begin
    for I := 0 to 15 do
    begin
      J := Offset + I * 4;
      Block[I] := (Cardinal(Padded[J]) shl 24) or
                  (Cardinal(Padded[J + 1]) shl 16) or
                  (Cardinal(Padded[J + 2]) shl 8) or
                   Cardinal(Padded[J + 3]);
    end;
    for I := 16 to 63 do
      Block[I] := SmallSigma1(Block[I - 2]) + Block[I - 7] + SmallSigma0(Block[I - 15]) + Block[I - 16];

    A := State[0];
    B := State[1];
    C := State[2];
    D := State[3];
    E := State[4];
    F := State[5];
    G := State[6];
    H := State[7];

    for I := 0 to 63 do
    begin
      T1 := H + BigSigma1(E) + Ch(E, F, G) + Sha256K[I] + Block[I];
      T2 := BigSigma0(A) + Maj(A, B, C);
      H := G;
      G := F;
      F := E;
      E := D + T1;
      D := C;
      C := B;
      B := A;
      A := T1 + T2;
    end;

    State[0] := State[0] + A;
    State[1] := State[1] + B;
    State[2] := State[2] + C;
    State[3] := State[3] + D;
    State[4] := State[4] + E;
    State[5] := State[5] + F;
    State[6] := State[6] + G;
    State[7] := State[7] + H;

    Inc(Offset, 64);
  end;

  SetLength(Result, 32);
  for I := 0 to 7 do
  begin
    Result[I * 4] := Byte((State[I] shr 24) and $FF);
    Result[I * 4 + 1] := Byte((State[I] shr 16) and $FF);
    Result[I * 4 + 2] := Byte((State[I] shr 8) and $FF);
    Result[I * 4 + 3] := Byte(State[I] and $FF);
  end;
end;

{$ELSE}
uses
  System.NetEncoding, System.Hash;
{$ENDIF}

constructor TScramClient.Create(const UserName: string);
var
  Nonce: TBytes;
  Guid: TGUID;
begin
  inherited Create;
  FUserName := UserName;
  SetLength(Nonce, 18);
  Randomize;
  if Length(Nonce) > 0 then
    FillChar(Nonce[0], Length(Nonce), 0);
  if CreateGUID(Guid) = 0 then
    Move(Guid, Nonce[0], Min(SizeOf(TGUID), Length(Nonce)));
  FClientNonce := Base64Encode(Nonce);
end;

function TScramClient.ClientFirstMessage: string;
begin
  FClientFirstBare := 'n=' + EscapeValue(FUserName) + ',r=' + FClientNonce;
  Result := 'n,,' + FClientFirstBare;
end;

function TScramClient.HandleServerFirst(const Password, ServerFirst: string): string;
var
  Attrs: TStringList;
  Nonce, SaltB64, IterStr: string;
  Iterations: Integer;
  Salt, Salted, ClientKey, StoredKey, ClientSignature, ClientProof, ServerKey: TBytes;
  ClientFinalNoProof, AuthMessage: string;
begin
  Attrs := ParseAttributes(ServerFirst);
  try
    Nonce := Attrs.Values['r'];
    SaltB64 := Attrs.Values['s'];
    IterStr := Attrs.Values['i'];
  finally
    Attrs.Free;
  end;
  if (Nonce = '') or (Pos(FClientNonce, Nonce) <> 1) then
    raise Exception.Create('SCRAM server nonce mismatch');
  if (SaltB64 = '') or (IterStr = '') then
    raise Exception.Create('SCRAM server-first missing fields');
  Iterations := StrToIntDef(IterStr, 0);
  if Iterations <= 0 then
    raise Exception.Create('Invalid SCRAM iteration count');
  Salt := Base64Decode(SaltB64);
  Salted := Pbkdf2Sha256(TEncoding.UTF8.GetBytes(Password), Salt, Iterations, 32);
  ClientKey := HmacSha256(Salted, TEncoding.UTF8.GetBytes('Client Key'));
  StoredKey := Sha256(ClientKey);
  ClientFinalNoProof := 'c=biws,r=' + Nonce;
  AuthMessage := FClientFirstBare + ',' + ServerFirst + ',' + ClientFinalNoProof;
  ClientSignature := HmacSha256(StoredKey, TEncoding.UTF8.GetBytes(AuthMessage));
  ClientProof := XorBytes(ClientKey, ClientSignature);
  ServerKey := HmacSha256(Salted, TEncoding.UTF8.GetBytes('Server Key'));
  FServerSignature := HmacSha256(ServerKey, TEncoding.UTF8.GetBytes(AuthMessage));
  Result := ClientFinalNoProof + ',p=' + Base64Encode(ClientProof);
end;

procedure TScramClient.VerifyServerFinal(const ServerFinal: string);
var
  Attrs: TStringList;
  Verifier: string;
begin
  Attrs := ParseAttributes(ServerFinal);
  try
    Verifier := Attrs.Values['v'];
  finally
    Attrs.Free;
  end;
  if (Verifier = '') or (Length(FServerSignature) = 0) then
    raise Exception.Create('SCRAM server-final missing verifier');
  if Verifier <> Base64Encode(FServerSignature) then
    raise Exception.Create('SCRAM server signature mismatch');
end;

function TScramClient.EscapeValue(const Value: string): string;
begin
  Result := StringReplace(StringReplace(Value, '=', '=3D', [rfReplaceAll]), ',', '=2C', [rfReplaceAll]);
end;

function TScramClient.ParseAttributes(const Message: string): TStringList;
var
  Parts: TStringList;
  Part: string;
  SepPos: Integer;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';
  Parts := TStringList.Create;
  try
    ExtractStrings([','], [], PChar(Message), Parts);
    for Part in Parts do
    begin
      SepPos := Pos('=', Part);
      if SepPos > 0 then
        Result.Values[Copy(Part, 1, SepPos - 1)] := Copy(Part, SepPos + 1, MaxInt);
    end;
  finally
    Parts.Free;
  end;
end;

function TScramClient.XorBytes(const Left, Right: TBytes): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(Left));
  for I := 0 to Length(Left) - 1 do
    Result[I] := Left[I] xor Right[I];
end;

function TScramClient.ConcatBytes(const Left, Right: TBytes): TBytes;
begin
  SetLength(Result, Length(Left) + Length(Right));
  if Length(Left) > 0 then
    Move(Left[0], Result[0], Length(Left));
  if Length(Right) > 0 then
    Move(Right[0], Result[Length(Left)], Length(Right));
end;

function TScramClient.BytesFromInt(I: Integer): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := Byte((I shr 24) and $FF);
  Result[1] := Byte((I shr 16) and $FF);
  Result[2] := Byte((I shr 8) and $FF);
  Result[3] := Byte(I and $FF);
end;

function TScramClient.Base64Encode(const Data: TBytes): string;
{$IFDEF FPC}
const
  Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  I: Integer;
  B0, B1, B2: Byte;
  Pad: Integer;
  Chunk: Integer;
begin
  Result := '';
  I := 0;
  while I < Length(Data) do
  begin
    B0 := Data[I];
    if I + 1 < Length(Data) then
      B1 := Data[I + 1]
    else
      B1 := 0;
    if I + 2 < Length(Data) then
      B2 := Data[I + 2]
    else
      B2 := 0;
    Chunk := (B0 shl 16) or (B1 shl 8) or B2;
    Pad := 0;
    if I + 1 >= Length(Data) then
      Pad := 2
    else if I + 2 >= Length(Data) then
      Pad := 1;
    Result := Result + Alphabet[((Chunk shr 18) and $3F) + 1];
    Result := Result + Alphabet[((Chunk shr 12) and $3F) + 1];
    if Pad >= 2 then
      Result := Result + '='
    else
      Result := Result + Alphabet[((Chunk shr 6) and $3F) + 1];
    if Pad >= 1 then
      Result := Result + '='
    else
      Result := Result + Alphabet[(Chunk and $3F) + 1];
    Inc(I, 3);
  end;
end;
{$ELSE}
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(Data);
end;
{$ENDIF}

function TScramClient.Base64Decode(const Value: string): TBytes;
{$IFDEF FPC}
const
  Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  Map: array[0..255] of ShortInt;
  I: Integer;
  C: Char;
  Buf: array[0..3] of Integer;
  BufCount: Integer;
  OutLen: Integer;
  Triplet: Integer;
begin
  for I := 0 to 255 do
    Map[I] := -1;
  for I := 1 to Length(Alphabet) do
    Map[Ord(Alphabet[I])] := I - 1;

  SetLength(Result, 0);
  BufCount := 0;
  for C in Value do
  begin
    if C = '=' then
      Buf[BufCount] := -2
    else
      Buf[BufCount] := Map[Ord(C)];
    if Buf[BufCount] = -1 then
      Continue;
    Inc(BufCount);
    if BufCount = 4 then
    begin
      Triplet := (Buf[0] shl 18) or (Buf[1] shl 12) or ((Buf[2] and $3F) shl 6) or (Buf[3] and $3F);
      OutLen := Length(Result);
      SetLength(Result, OutLen + 3);
      Result[OutLen] := Byte((Triplet shr 16) and $FF);
      if Buf[2] <> -2 then
        Result[OutLen + 1] := Byte((Triplet shr 8) and $FF)
      else
        SetLength(Result, OutLen + 1);
      if Buf[3] <> -2 then
        Result[OutLen + 2] := Byte(Triplet and $FF)
      else if Length(Result) > OutLen + 1 then
        SetLength(Result, OutLen + 2);
      BufCount := 0;
    end;
  end;
end;
{$ELSE}
begin
  Result := TNetEncoding.Base64.DecodeStringToBytes(Value);
end;
{$ENDIF}

function TScramClient.Sha256(const Data: TBytes): TBytes;
{$IFDEF FPC}
begin
  Result := Sha256Digest(Data);
end;
{$ELSE}
begin
  Result := THashSHA2.GetHashBytes(Data);
end;
{$ENDIF}

function TScramClient.HmacSha256(const Key, Data: TBytes): TBytes;
var
  BlockSize: Integer;
  KeyBlock, OKeyPad, IKeyPad, Inner: TBytes;
  I: Integer;
begin
  BlockSize := 64;
  KeyBlock := Key;
  if Length(KeyBlock) > BlockSize then
    KeyBlock := Sha256(KeyBlock);
  SetLength(KeyBlock, BlockSize);
  SetLength(OKeyPad, BlockSize);
  SetLength(IKeyPad, BlockSize);
  for I := 0 to BlockSize - 1 do
  begin
    OKeyPad[I] := KeyBlock[I] xor $5C;
    IKeyPad[I] := KeyBlock[I] xor $36;
  end;
  Inner := Sha256(ConcatBytes(IKeyPad, Data));
  Result := Sha256(ConcatBytes(OKeyPad, Inner));
end;

function TScramClient.Pbkdf2Sha256(const Password, Salt: TBytes; Iterations, KeyLen: Integer): TBytes;
var
  BlockCount, I, J: Integer;
  Block: TBytes;
  U, T: TBytes;
  Counter: TBytes;
begin
  BlockCount := (KeyLen + 31) div 32;
  SetLength(Result, 0);
  for I := 1 to BlockCount do
  begin
    Counter := BytesFromInt(I);
    Block := ConcatBytes(Salt, Counter);
    U := HmacSha256(Password, Block);
    T := Copy(U, 0, Length(U));
    for J := 2 to Iterations do
    begin
      U := HmacSha256(Password, U);
      T := XorBytes(T, U);
    end;
    Result := ConcatBytes(Result, T);
  end;
  SetLength(Result, KeyLen);
end;

end.

unit ScratchBird.Scram;

interface

uses
  SysUtils, Classes;

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
uses
  Base64, sha256;
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
begin
  Result := EncodeStringBase64(TEncoding.UTF8.GetString(Data));
end;
{$ELSE}
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(Data);
end;
{$ENDIF}

function TScramClient.Base64Decode(const Value: string): TBytes;
{$IFDEF FPC}
begin
  Result := TEncoding.UTF8.GetBytes(DecodeStringBase64(Value));
end;
{$ELSE}
begin
  Result := TNetEncoding.Base64.DecodeStringToBytes(Value);
end;
{$ENDIF}

function TScramClient.Sha256(const Data: TBytes): TBytes;
{$IFDEF FPC}
var
  Digest: TSHA256Digest;
begin
  SHA256Buffer(Data[0], Length(Data), Digest);
  SetLength(Result, SizeOf(Digest));
  Move(Digest, Result[0], SizeOf(Digest));
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

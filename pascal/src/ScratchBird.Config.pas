unit ScratchBird.Config;

interface

uses
  SysUtils, Classes;

type
  TScratchBirdConfig = record
    Host: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    SSLMode: string;
    SSLRootCert: string;
    SSLCert: string;
    SSLKey: string;
    ConnectTimeoutMs: Integer;
    SocketTimeoutMs: Integer;
    ApplicationName: string;
    BinaryTransfer: Boolean;
    Compression: string;
  end;

function DefaultConfig: TScratchBirdConfig;
function ParseConfig(const Dsn: string): TScratchBirdConfig;

implementation

function DefaultConfig: TScratchBirdConfig;
begin
  Result.Host := 'localhost';
  Result.Port := 3092;
  Result.Database := '';
  Result.UserName := '';
  Result.Password := '';
  Result.SSLMode := 'prefer';
  Result.SSLRootCert := '';
  Result.SSLCert := '';
  Result.SSLKey := '';
  Result.ConnectTimeoutMs := 30000;
  Result.SocketTimeoutMs := 0;
  Result.ApplicationName := 'scratchbird_pascal';
  Result.BinaryTransfer := True;
  Result.Compression := 'off';
end;

procedure ApplyParam(var Config: TScratchBirdConfig; const Key, Value: string);
var
  KeyLower: string;
begin
  KeyLower := LowerCase(Key);
  if (KeyLower = 'host') or (KeyLower = 'server') or (KeyLower = 'data source') or (KeyLower = 'datasource') then
    Config.Host := Value
  else if KeyLower = 'port' then
    Config.Port := StrToIntDef(Value, Config.Port)
  else if (KeyLower = 'database') or (KeyLower = 'dbname') or (KeyLower = 'initial catalog') then
    Config.Database := Value
  else if (KeyLower = 'user') or (KeyLower = 'username') or (KeyLower = 'user id') or (KeyLower = 'uid') then
    Config.UserName := Value
  else if (KeyLower = 'password') or (KeyLower = 'pwd') then
    Config.Password := Value
  else if (KeyLower = 'sslmode') or (KeyLower = 'ssl mode') then
    Config.SSLMode := Value
  else if KeyLower = 'sslrootcert' then
    Config.SSLRootCert := Value
  else if KeyLower = 'sslcert' then
    Config.SSLCert := Value
  else if KeyLower = 'sslkey' then
    Config.SSLKey := Value
  else if (KeyLower = 'connect_timeout') or (KeyLower = 'connecttimeout') or (KeyLower = 'timeout') then
    Config.ConnectTimeoutMs := StrToIntDef(Value, Config.ConnectTimeoutMs div 1000) * 1000
  else if (KeyLower = 'socket_timeout') or (KeyLower = 'sockettimeout') then
    Config.SocketTimeoutMs := StrToIntDef(Value, Config.SocketTimeoutMs div 1000) * 1000
  else if (KeyLower = 'application_name') or (KeyLower = 'applicationname') then
    Config.ApplicationName := Value
  else if (KeyLower = 'binary_transfer') or (KeyLower = 'binarytransfer') then
    Config.BinaryTransfer := SameText(Value, 'true') or (Value = '1')
  else if KeyLower = 'compression' then
  begin
    if SameText(Value, 'zstd') then
      Config.Compression := 'zstd'
    else
      Config.Compression := 'off';
  end;
end;

function UrlDecode(const Value: string): string;
var
  I: Integer;
  Hex: string;
begin
  Result := '';
  I := 1;
  while I <= Length(Value) do
  begin
    if Value[I] = '%' then
    begin
      if I + 2 <= Length(Value) then
      begin
        Hex := Copy(Value, I + 1, 2);
        Result := Result + Chr(StrToIntDef('$' + Hex, Ord('?')));
        Inc(I, 3);
        Continue;
      end;
    end;
    if Value[I] = '+' then
      Result := Result + ' '
    else
      Result := Result + Value[I];
    Inc(I);
  end;
end;

function ParseUri(const Dsn: string): TScratchBirdConfig;
var
  Work, Auth, Path, Query: string;
  AtPos, SlashPos, QueryPos, ColonPos: Integer;
  UserInfo, HostPort: string;
  Key, Value: string;
  QueryList: TStringList;
  Pair: string;
begin
  Result := DefaultConfig;
  Work := Dsn;
  if Copy(Work, 1, 13) <> 'scratchbird://' then
    raise Exception.Create('Unsupported DSN scheme');
  Work := Copy(Work, 14, MaxInt);
  QueryPos := Pos('?', Work);
  if QueryPos > 0 then
  begin
    Query := Copy(Work, QueryPos + 1, MaxInt);
    Work := Copy(Work, 1, QueryPos - 1);
  end
  else
    Query := '';
  SlashPos := Pos('/', Work);
  if SlashPos > 0 then
  begin
    Auth := Copy(Work, 1, SlashPos - 1);
    Path := Copy(Work, SlashPos + 1, MaxInt);
  end
  else
  begin
    Auth := Work;
    Path := '';
  end;
  AtPos := Pos('@', Auth);
  if AtPos > 0 then
  begin
    UserInfo := Copy(Auth, 1, AtPos - 1);
    HostPort := Copy(Auth, AtPos + 1, MaxInt);
    ColonPos := Pos(':', UserInfo);
    if ColonPos > 0 then
    begin
      Result.UserName := UrlDecode(Copy(UserInfo, 1, ColonPos - 1));
      Result.Password := UrlDecode(Copy(UserInfo, ColonPos + 1, MaxInt));
    end
    else
      Result.UserName := UrlDecode(UserInfo);
  end
  else
    HostPort := Auth;
  ColonPos := LastDelimiter(':', HostPort);
  if ColonPos > 0 then
  begin
    Result.Host := Copy(HostPort, 1, ColonPos - 1);
    Result.Port := StrToIntDef(Copy(HostPort, ColonPos + 1, MaxInt), Result.Port);
  end
  else if HostPort <> '' then
    Result.Host := HostPort;
  if Path <> '' then
    Result.Database := Path;
  if Query <> '' then
  begin
    QueryList := TStringList.Create;
    try
      ExtractStrings(['&'], [], PChar(Query), QueryList);
      for Pair in QueryList do
      begin
        ColonPos := Pos('=', Pair);
        if ColonPos <= 0 then
          Continue;
        Key := Copy(Pair, 1, ColonPos - 1);
        Value := UrlDecode(Copy(Pair, ColonPos + 1, MaxInt));
        ApplyParam(Result, Key, Value);
      end;
    finally
      QueryList.Free;
    end;
  end;
end;


function ParseKeyValue(const Dsn: string): TScratchBirdConfig;
var
  Separator: Char;
  Parts: TStringList;
  Pair: string;
  SepPos: Integer;
  Key, Value: string;
begin
  Result := DefaultConfig;
  if Pos(';', Dsn) > 0 then
    Separator := ';'
  else
    Separator := ' ';
  Parts := TStringList.Create;
  try
    ExtractStrings([Separator], [], PChar(Dsn), Parts);
    for Pair in Parts do
    begin
      Pair := Trim(Pair);
      if Pair = '' then
        Continue;
      SepPos := Pos('=', Pair);
      if SepPos <= 0 then
        Continue;
      Key := Trim(Copy(Pair, 1, SepPos - 1));
      Value := Trim(Copy(Pair, SepPos + 1, MaxInt));
      if (Length(Value) >= 2) and (Value[1] = '"') and (Value[Length(Value)] = '"') then
        Value := Copy(Value, 2, Length(Value) - 2);
      ApplyParam(Result, Key, Value);
    end;
  finally
    Parts.Free;
  end;
end;

function ParseConfig(const Dsn: string): TScratchBirdConfig;
begin
  if Trim(Dsn) = '' then
    Exit(DefaultConfig);
  if Pos('://', Dsn) > 0 then
    Result := ParseUri(Dsn)
  else
    Result := ParseKeyValue(Dsn);
end;

end.

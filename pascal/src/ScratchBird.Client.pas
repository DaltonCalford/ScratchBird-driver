unit ScratchBird.Client;

interface

uses
  SysUtils, Classes,
  ScratchBird.Config, ScratchBird.Protocol, ScratchBird.Errors, ScratchBird.Scram, ScratchBird.Types, ScratchBird.Sql,
  IdTCPClient, IdSSL, IdSSLOpenSSL
  {$IFNDEF MSWINDOWS}
  , BaseUnix
  {$ENDIF};

type
  TScratchBirdResultStream = class
  private
    FClient: TObject;
    FColumns: TArray<TColumnInfo>;
    FRowsAffected: Int64;
    FRowCountHint: Int64;
    FCommandTag: string;
    FDone: Boolean;
  public
    constructor Create(Client: TObject);
    function ReadRow: TArray<Variant>;
    property Columns: TArray<TColumnInfo> read FColumns;
    property RowsAffected: Int64 read FRowsAffected;
    property CommandTag: string read FCommandTag;
  end;

  TScratchBirdClient = class
  private
    FConfig: TScratchBirdConfig;
    FSessionId: TBytes;
    FTcp: TIdTCPClient;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FConnected: Boolean;
    function ReadExact(Length: Integer): TBytes;
    procedure SendBytes(const Data: TBytes);
    function ReceiveMessage: TScratchBirdMessage;
    procedure Authenticate;
    function BuildQueryError(const Payload: TBytes): EScratchBirdError;
    procedure DrainUntilComplete;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect(const Dsn: string);
    procedure Disconnect;
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
    procedure ExecSQL(const Sql: string);
    function ExecuteQuery(const Sql: string): TScratchBirdResultStream;
    property Connected: Boolean read FConnected;
    property Config: TScratchBirdConfig read FConfig;
  end;

implementation

function GetProcessIdValue: Cardinal;
begin
  {$IFDEF MSWINDOWS}
  Result := GetCurrentProcessId;
  {$ELSE}
  Result := fpGetPid;
  {$ENDIF}
end;

constructor TScratchBirdResultStream.Create(Client: TObject);
begin
  inherited Create;
  FClient := Client;
  FRowsAffected := -1;
  FRowCountHint := -1;
  FCommandTag := '';
  FDone := False;
end;

function TScratchBirdResultStream.ReadRow: TArray<Variant>;
var
  Client: TScratchBirdClient;
  Msg: TScratchBirdMessage;
  Values: TArray<TColumnValue>;
  Row: TArray<Variant>;
  I: Integer;
  Status: Byte;
  ColumnCount: Cardinal;
begin
  if FDone then
    Exit(nil);
  Client := TScratchBirdClient(FClient);
  while True do
  begin
    Msg := Client.ReceiveMessage;
    case Msg.MsgType of
      MSG_QUERY_ERROR:
        raise Client.BuildQueryError(Msg.Payload);
      MSG_QUERY_RESULT:
        ParseQueryResult(Msg.Payload, Status, ColumnCount, FRowCountHint);
      MSG_ROW_DESCRIPTION:
        FColumns := ParseRowDescription(Msg.Payload);
      MSG_ROW_DATA:
      begin
        Values := ParseRowData(Msg.Payload);
        SetLength(Row, Length(Values));
        for I := 0 to High(Values) do
        begin
          if I < Length(FColumns) then
            Row[I] := DecodeValue(FColumns[I].WireType, Values[I].Data, Values[I].IsNull)
          else
            Row[I] := DecodeValue(WIRE_UNKNOWN, Values[I].Data, Values[I].IsNull);
        end;
        Exit(Row);
      end;
      MSG_COMMAND_COMPLETE:
        ParseCommandComplete(Msg.Payload, FCommandTag, FRowsAffected);
      MSG_END_RESULTS:
      begin
        FDone := True;
        Exit(nil);
      end;
    end;
  end;
end;

constructor TScratchBirdClient.Create;
begin
  inherited Create;
  FTcp := TIdTCPClient.Create(nil);
  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  FTcp.IOHandler := FSSL;
end;

destructor TScratchBirdClient.Destroy;
begin
  Disconnect;
  FSSL.Free;
  FTcp.Free;
  inherited Destroy;
end;

procedure TScratchBirdClient.Connect(const Dsn: string);
var
  ConnectMsg: TBytes;
  Msg: TScratchBirdMessage;
  Ok: Boolean;
  ServerName, ServerVersion, ErrorMessage: string;
  Mode: string;
  UseTls: Boolean;
begin
  FConfig := ParseConfig(Dsn);
  Mode := LowerCase(FConfig.SSLMode);
  UseTls := Mode <> 'disable';
  FTcp.Host := FConfig.Host;
  FTcp.Port := FConfig.Port;
  FTcp.ConnectTimeout := FConfig.ConnectTimeoutMs;
  FTcp.ReadTimeout := FConfig.SocketTimeoutMs;
  FSSL.SSLOptions.Method := sslvTLSv1_3;
  FSSL.SSLOptions.Mode := sslmClient;
  if FConfig.SSLCert <> '' then
    FSSL.SSLOptions.CertFile := FConfig.SSLCert;
  if FConfig.SSLKey <> '' then
    FSSL.SSLOptions.KeyFile := FConfig.SSLKey;
  if FConfig.SSLRootCert <> '' then
    FSSL.SSLOptions.RootCertFile := FConfig.SSLRootCert;
  if (Mode = 'verify-full') or (Mode = 'verify-ca') then
    FSSL.SSLOptions.VerifyMode := [sslvrfPeer]
  else if Mode = 'require' then
    FSSL.SSLOptions.VerifyMode := [sslvrfPeer]
  else
    FSSL.SSLOptions.VerifyMode := [];
  if UseTls then
    FTcp.IOHandler := FSSL
  else
    FTcp.IOHandler := nil;
  try
    FTcp.Connect;
  except
    if (Mode = 'allow') or (Mode = 'prefer') then
    begin
      FTcp.IOHandler := nil;
      FTcp.Connect;
    end
    else
      raise;
  end;
  ConnectMsg := BuildConnectRequest(FConfig.Database, FConfig.ApplicationName, GetProcessIdValue);
  SendBytes(ConnectMsg);
  Msg := ReceiveMessage;
  if Msg.MsgType <> MSG_CONNECT_RESPONSE then
    raise EScratchbirdConnectionError.CreateWithInfo('Unexpected connect response', '08001', '', '');
  Ok := ParseConnectResponse(Msg.Payload, FSessionId, ServerName, ServerVersion, ErrorMessage);
  if not Ok then
    raise EScratchbirdConnectionError.CreateWithInfo(ErrorMessage, '08001', '', '');
  if FConfig.UserName <> '' then
    Authenticate;
  FConnected := True;
end;

procedure TScratchBirdClient.Disconnect;
begin
  if not FConnected then
    Exit;
  try
    if Length(FSessionId) = 16 then
      SendBytes(BuildDisconnect(FSessionId));
  except
  end;
  FTcp.Disconnect;
  FConnected := False;
end;

procedure TScratchBirdClient.BeginTransaction;
begin
  SendBytes(BuildBegin(FSessionId, 0, False));
  DrainUntilComplete;
end;

procedure TScratchBirdClient.Commit;
begin
  SendBytes(BuildCommit(FSessionId));
  DrainUntilComplete;
end;

procedure TScratchBirdClient.Rollback;
begin
  SendBytes(BuildRollback(FSessionId));
  DrainUntilComplete;
end;

procedure TScratchBirdClient.ExecSQL(const Sql: string);
begin
  SendBytes(BuildQuery(FSessionId, Sql, 0));
  DrainUntilComplete;
end;

function TScratchBirdClient.ExecuteQuery(const Sql: string): TScratchBirdResultStream;
begin
  SendBytes(BuildQuery(FSessionId, Sql, 0));
  Result := TScratchBirdResultStream.Create(Self);
end;

procedure TScratchBirdClient.SendBytes(const Data: TBytes);
begin
  if Length(Data) = 0 then
    Exit;
  FTcp.IOHandler.Write(Data);
end;

function TScratchBirdClient.ReadExact(Length: Integer): TBytes;
begin
  SetLength(Result, Length);
  FTcp.IOHandler.ReadBytes(Result, Length, False);
end;

function TScratchBirdClient.ReceiveMessage: TScratchBirdMessage;
var
  Header: TBytes;
  MsgType: TScratchBirdMessageType;
  Flags: Byte;
  PayloadLen: Integer;
begin
  Header := ReadExact(12);
  if not DecodeHeader(Header, MsgType, Flags, PayloadLen) then
    raise EScratchbirdConnectionError.CreateWithInfo('Invalid header', '08006', '', '');
  Result.MsgType := MsgType;
  Result.Flags := Flags;
  if PayloadLen > 0 then
    Result.Payload := ReadExact(PayloadLen)
  else
    Result.Payload := nil;
end;

procedure TScratchBirdClient.Authenticate;
var
  Scram: TScramClient;
  ClientFirst, ClientFinal: string;
  Msg: TScratchBirdMessage;
  Status: TAuthStatus;
  UserId: Cardinal;
  ErrorMessage: string;
  Extra: TBytes;
begin
  Scram := TScramClient.Create(FConfig.UserName);
  try
    ClientFirst := Scram.ClientFirstMessage;
    SendBytes(BuildAuthRequest(FSessionId, FConfig.UserName, AUTH_SCRAM_SHA256, TEncoding.UTF8.GetBytes(ClientFirst)));
    Msg := ReceiveMessage;
    if Msg.MsgType <> MSG_AUTH_RESPONSE then
      raise EScratchbirdAuthError.CreateWithInfo('Unexpected auth response', '28000', '', '');
    ParseAuthResponse(Msg.Payload, Status, UserId, ErrorMessage, Extra);
    if Status <> AUTH_CONTINUE then
      raise EScratchbirdAuthError.CreateWithInfo(ErrorMessage, '28000', '', '');
    ClientFinal := Scram.HandleServerFirst(FConfig.Password, TEncoding.UTF8.GetString(Extra));
    SendBytes(BuildAuthRequest(FSessionId, FConfig.UserName, AUTH_SCRAM_SHA256, TEncoding.UTF8.GetBytes(ClientFinal)));
    Msg := ReceiveMessage;
    if Msg.MsgType <> MSG_AUTH_RESPONSE then
      raise EScratchbirdAuthError.CreateWithInfo('Unexpected SCRAM final', '28000', '', '');
    ParseAuthResponse(Msg.Payload, Status, UserId, ErrorMessage, Extra);
    if Status <> AUTH_OK then
      raise EScratchbirdAuthError.CreateWithInfo(ErrorMessage, '28000', '', '');
    if Length(Extra) > 0 then
      Scram.VerifyServerFinal(TEncoding.UTF8.GetString(Extra));
  finally
    Scram.Free;
  end;
end;

function TScratchBirdClient.BuildQueryError(const Payload: TBytes): EScratchBirdError;
var
  Code: Cardinal;
  SqlState, Msg, Detail, Hint: string;
begin
  ParseQueryError(Payload, Code, SqlState, Msg, Detail, Hint);
  Result := MapSqlState(SqlState, Msg, Detail, Hint);
end;

procedure TScratchBirdClient.DrainUntilComplete;
var
  Msg: TScratchBirdMessage;
begin
  while True do
  begin
    Msg := ReceiveMessage;
    case Msg.MsgType of
      MSG_QUERY_ERROR:
        raise BuildQueryError(Msg.Payload);
      MSG_COMMAND_COMPLETE:
        Continue;
      MSG_END_RESULTS:
        Exit;
    end;
  end;
end;

end.

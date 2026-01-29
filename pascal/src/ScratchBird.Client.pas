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
    FCommandTag: string;
    FDone: Boolean;
    FSeenRows: Int64;
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
    FTcp: TIdTCPClient;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FConnected: Boolean;
    FAttachmentId: TBytes;
    FTxnId: UInt64;
    FSequence: Cardinal;
    FLastQuerySequence: Cardinal;
    FParameters: TStringList;
    function ReadExact(Length: Integer): TBytes;
    procedure SendBytes(const Data: TBytes);
    function ReceiveMessage: TScratchBirdMessage;
    procedure HandshakeAndAuth;
    procedure ApplySchema;
    function BuildQueryError(const Payload: TBytes): EScratchBirdError;
    procedure DrainUntilReady;
    function SendMessage(MsgType: TScratchBirdMessageType; const Payload: TBytes; Flags: Byte; ForceZero: Boolean): Cardinal;
    procedure SendSimpleQuery(const Sql: string);
    procedure SendExtendedQuery(const Sql: string; const Params: array of TScratchBirdParamInput);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect(const Dsn: string);
    procedure Disconnect;
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
    procedure ExecSQL(const Sql: string);
    procedure ExecSQLParams(const Sql: string; const Params: array of TScratchBirdParamInput);
    function ExecuteQuery(const Sql: string): TScratchBirdResultStream;
    function ExecuteQueryParams(const Sql: string; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
    procedure Cancel;
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

function QuoteIdentifier(const Name: string): string;
begin
  Result := '"' + StringReplace(Name, '"', '""', [rfReplaceAll]) + '"';
end;

function BuildSchemaStatement(const Schema: string): string;
var
  Parts: TStringList;
  I: Integer;
  Trimmed: string;
begin
  Trimmed := Trim(Schema);
  if Trimmed = '' then
    Exit('');
  if Pos(',', Trimmed) > 0 then
  begin
    Parts := TStringList.Create;
    try
      ExtractStrings([','], [], PChar(Trimmed), Parts);
      for I := Parts.Count - 1 downto 0 do
      begin
        Parts[I] := Trim(Parts[I]);
        if Parts[I] = '' then
          Parts.Delete(I)
        else
          Parts[I] := QuoteIdentifier(Parts[I]);
      end;
      if Parts.Count = 0 then
        Exit('');
      Result := 'SET SEARCH_PATH TO ' + StringReplace(Parts.CommaText, ',', ', ', [rfReplaceAll]);
      Exit;
    finally
      Parts.Free;
    end;
  end;
  Result := 'SET SCHEMA ' + QuoteIdentifier(Trimmed);
end;

constructor TScratchBirdResultStream.Create(Client: TObject);
begin
  inherited Create;
  FClient := Client;
  FRowsAffected := -1;
  FCommandTag := '';
  FDone := False;
  FSeenRows := 0;
end;

function TScratchBirdResultStream.ReadRow: TArray<Variant>;
var
  Client: TScratchBirdClient;
  Msg: TScratchBirdMessage;
  Values: TArray<TColumnValue>;
  Row: TArray<Variant>;
  I: Integer;
  CommandType: Byte;
  Rows, LastId: UInt64;
  Tag: string;
begin
  if FDone then
    Exit(nil);
  Client := TScratchBirdClient(FClient);
  while True do
  begin
    Msg := Client.ReceiveMessage;
    case Msg.MsgType of
      MSG_ERROR:
        raise Client.BuildQueryError(Msg.Payload);
      MSG_ROW_DESCRIPTION:
        FColumns := ParseRowDescription(Msg.Payload);
      MSG_DATA_ROW:
      begin
        Values := ParseRowData(Msg.Payload);
        SetLength(Row, Length(Values));
        for I := 0 to High(Values) do
        begin
          if I < Length(FColumns) then
            Row[I] := DecodeValue(FColumns[I].TypeOid, Values[I].Data, FColumns[I].Format)
          else
            Row[I] := DecodeValue(0, Values[I].Data, FORMAT_BINARY);
        end;
        Inc(FSeenRows);
        Exit(Row);
      end;
      MSG_COMMAND_COMPLETE:
      begin
        ParseCommandComplete(Msg.Payload, CommandType, Rows, LastId, Tag);
        FCommandTag := Tag;
        FRowsAffected := Rows;
      end;
      MSG_READY:
      begin
        FDone := True;
        if FRowsAffected < 0 then
          FRowsAffected := FSeenRows;
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
  SetLength(FAttachmentId, 16);
  FillChar(FAttachmentId[0], 16, 0);
  FSequence := 0;
  FTxnId := 0;
  FParameters := TStringList.Create;
end;

destructor TScratchBirdClient.Destroy;
begin
  Disconnect;
  FParameters.Free;
  FSSL.Free;
  FTcp.Free;
  inherited Destroy;
end;

procedure TScratchBirdClient.Connect(const Dsn: string);
var
  Mode: string;
begin
  FConfig := ParseConfig(Dsn);
  if (FConfig.UserName = '') or (FConfig.Database = '') then
    raise EScratchbirdConnectionError.CreateWithInfo('user and database are required', '08001', '', '');

  Mode := LowerCase(FConfig.SSLMode);
  if Mode = 'disable' then
    raise EScratchbirdConnectionError.CreateWithInfo('TLS is required for ScratchBird connections', '08001', '', '');

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
  if (Mode = 'verify-full') or (Mode = 'verify-ca') or (Mode = 'require') then
    FSSL.SSLOptions.VerifyMode := [sslvrfPeer]
  else
    FSSL.SSLOptions.VerifyMode := [];
  FTcp.IOHandler := FSSL;
  FTcp.Connect;
  HandshakeAndAuth;
  ApplySchema;
  FConnected := True;
end;

procedure TScratchBirdClient.Disconnect;
begin
  if not FConnected then
    Exit;
  FTcp.Disconnect;
  FConnected := False;
end;

procedure TScratchBirdClient.ApplySchema;
var
  Schema: string;
  Statement: string;
begin
  Schema := Trim(FConfig.Schema);
  if (Schema = '') or SameText(Schema, 'public') then
    Exit;
  Statement := BuildSchemaStatement(Schema);
  if Statement = '' then
    Exit;
  ExecSQL(Statement);
end;

procedure TScratchBirdClient.BeginTransaction;
begin
end;

procedure TScratchBirdClient.Commit;
begin
  ExecSQL('COMMIT');
end;

procedure TScratchBirdClient.Rollback;
begin
  ExecSQL('ROLLBACK');
end;

procedure TScratchBirdClient.ExecSQL(const Sql: string);
begin
  ExecSQLParams(Sql, []);
end;

procedure TScratchBirdClient.ExecSQLParams(const Sql: string; const Params: array of TScratchBirdParamInput);
begin
  if Length(Params) = 0 then
  begin
    SendSimpleQuery(Sql);
  end
  else
  begin
    SendExtendedQuery(Sql, Params);
  end;
  DrainUntilReady;
end;

function TScratchBirdClient.ExecuteQuery(const Sql: string): TScratchBirdResultStream;
begin
  Result := ExecuteQueryParams(Sql, []);
end;

function TScratchBirdClient.ExecuteQueryParams(const Sql: string; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
begin
  if Length(Params) = 0 then
    SendSimpleQuery(Sql)
  else
    SendExtendedQuery(Sql, Params);
  Result := TScratchBirdResultStream.Create(Self);
end;

procedure TScratchBirdClient.Cancel;
begin
  SendMessage(MSG_CANCEL, BuildCancelPayload(0, FLastQuerySequence), MSG_FLAG_URGENT, False);
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
  Sequence: Cardinal;
  AttachmentId: TBytes;
  TxnId: UInt64;
begin
  Header := ReadExact(HEADER_SIZE);
  if not DecodeHeader(Header, MsgType, Flags, PayloadLen, Sequence, AttachmentId, TxnId) then
    raise EScratchbirdConnectionError.CreateWithInfo('Invalid header', '08006', '', '');
  Result.MsgType := MsgType;
  Result.Flags := Flags;
  Result.Sequence := Sequence;
  Result.AttachmentId := AttachmentId;
  Result.TxnId := TxnId;
  if PayloadLen > 0 then
    Result.Payload := ReadExact(PayloadLen)
  else
    Result.Payload := nil;
end;

function TScratchBirdClient.SendMessage(MsgType: TScratchBirdMessageType; const Payload: TBytes; Flags: Byte; ForceZero: Boolean): Cardinal;
var
  AttachmentId: TBytes;
  TxnId: UInt64;
begin
  Result := FSequence;
  Inc(FSequence);
  if ForceZero then
  begin
    SetLength(AttachmentId, 16);
    FillChar(AttachmentId[0], 16, 0);
    TxnId := 0;
  end
  else
  begin
    AttachmentId := FAttachmentId;
    TxnId := FTxnId;
  end;
  SendBytes(EncodeMessage(MsgType, Payload, Flags, Result, AttachmentId, TxnId));
end;

procedure TScratchBirdClient.HandshakeAndAuth;
var
  Params: TStringList;
  Features: UInt64;
  Startup: TBytes;
  Msg: TScratchBirdMessage;
  Scram: TScramClient;
  Method, Stage: Byte;
  Data, SessionId, ServerInfo: TBytes;
  Name, Value: string;
  Status: Byte;
  TxnId, Visibility: UInt64;
begin
  Params := TStringList.Create;
  try
    Params.Values['database'] := FConfig.Database;
    Params.Values['user'] := FConfig.UserName;
    if FConfig.ApplicationName <> '' then
      Params.Values['application_name'] := FConfig.ApplicationName;
    Features := 0;
    if SameText(FConfig.Compression, 'zstd') then
      Features := Features or FEATURE_COMPRESSION;
    if FConfig.BinaryTransfer then
      Features := Features or FEATURE_STREAMING;
    Startup := BuildStartupPayload(Features, Params);
    SendMessage(MSG_STARTUP, Startup, 0, True);
  finally
    Params.Free;
  end;

  Scram := nil;
  try
    while True do
    begin
      Msg := ReceiveMessage;
      case Msg.MsgType of
        MSG_NEGOTIATE_VERSION:
          Continue;
        MSG_AUTH_REQUEST:
          begin
            ParseAuthRequest(Msg.Payload, Method, Data);
            if Method = AUTH_OK then
              Continue;
            if Method = AUTH_PASSWORD then
            begin
              SendMessage(MSG_AUTH_RESPONSE, TEncoding.UTF8.GetBytes(FConfig.Password), 0, True);
              Continue;
            end;
            if Method = AUTH_SCRAM_SHA256 then
            begin
              if Scram = nil then
                Scram := TScramClient.Create(FConfig.UserName);
              SendMessage(MSG_AUTH_RESPONSE, TEncoding.UTF8.GetBytes(Scram.ClientFirstMessage), 0, True);
              Continue;
            end;
            raise EScratchbirdAuthError.CreateWithInfo('Unsupported auth method', '28000', '', '');
          end;
        MSG_AUTH_CONTINUE:
          begin
            ParseAuthContinue(Msg.Payload, Method, Stage, Data);
            if (Method <> AUTH_SCRAM_SHA256) or (Scram = nil) then
              raise EScratchbirdAuthError.CreateWithInfo('Unsupported auth continue', '28000', '', '');
            SendMessage(MSG_AUTH_RESPONSE, TEncoding.UTF8.GetBytes(Scram.HandleServerFirst(FConfig.Password,
              TEncoding.UTF8.GetString(Data))), 0, True);
            Continue;
          end;
        MSG_AUTH_OK:
          begin
            ParseAuthOk(Msg.Payload, SessionId, ServerInfo);
            FAttachmentId := Msg.AttachmentId;
            FTxnId := Msg.TxnId;
            if (Scram <> nil) and (Length(ServerInfo) > 0) then
              Scram.VerifyServerFinal(TEncoding.UTF8.GetString(ServerInfo));
            Continue;
          end;
        MSG_PARAMETER_STATUS:
          begin
            ParseParameterStatus(Msg.Payload, Name, Value);
            FParameters.Values[Name] := Value;
            Continue;
          end;
        MSG_READY:
          begin
            ParseReady(Msg.Payload, Status, TxnId, Visibility);
            FTxnId := TxnId;
            Exit;
          end;
        MSG_ERROR:
          raise BuildQueryError(Msg.Payload);
      end;
    end;
  finally
    Scram.Free;
  end;
end;

function TScratchBirdClient.BuildQueryError(const Payload: TBytes): EScratchBirdError;
var
  Severity, SqlState, Msg, Detail, Hint: string;
begin
  ParseErrorMessage(Payload, Severity, SqlState, Msg, Detail, Hint);
  Result := MapSqlState(SqlState, Msg, Detail, Hint);
end;

procedure TScratchBirdClient.DrainUntilReady;
var
  Msg: TScratchBirdMessage;
  Status: Byte;
  TxnId, Visibility: UInt64;
  Name, Value: string;
begin
  while True do
  begin
    Msg := ReceiveMessage;
    case Msg.MsgType of
      MSG_ERROR:
        raise BuildQueryError(Msg.Payload);
      MSG_PARAMETER_STATUS:
        begin
          ParseParameterStatus(Msg.Payload, Name, Value);
          FParameters.Values[Name] := Value;
        end;
      MSG_READY:
        begin
          ParseReady(Msg.Payload, Status, TxnId, Visibility);
          FTxnId := TxnId;
          Exit;
        end;
    end;
  end;
end;

procedure TScratchBirdClient.SendSimpleQuery(const Sql: string);
var
  Flags: Cardinal;
  Payload: TBytes;
begin
  Flags := 0;
  if FConfig.BinaryTransfer then
    Flags := Flags or $04;
  Payload := BuildQueryPayload(Sql, Flags, 0, 0);
  FLastQuerySequence := SendMessage(MSG_QUERY, Payload, 0, False);
end;

procedure TScratchBirdClient.SendExtendedQuery(const Sql: string; const Params: array of TScratchBirdParamInput);
var
  ParamValues: TArray<TParamValue>;
  ParamTypes: TArray<Cardinal>;
  I: Integer;
  Param: TParamValue;
  Oid: Cardinal;
  ParsePayload, BindPayload, ExecPayload: TBytes;
  ResultFormats: TArray<Word>;
begin
  SetLength(ParamValues, Length(Params));
  SetLength(ParamTypes, Length(Params));
  for I := 0 to High(Params) do
  begin
    EncodeParam(Params[I].Value, Params[I].Obj, Param, Oid);
    ParamValues[I] := Param;
    ParamTypes[I] := Oid;
  end;
  ParsePayload := BuildParsePayload('', Sql, ParamTypes);
  SendMessage(MSG_PARSE, ParsePayload, 0, False);
  if FConfig.BinaryTransfer then
  begin
    SetLength(ResultFormats, 1);
    ResultFormats[0] := FORMAT_BINARY;
  end
  else
    ResultFormats := nil;
  BindPayload := BuildBindPayload('', '', ParamValues, ResultFormats);
  SendMessage(MSG_BIND, BindPayload, 0, False);
  ExecPayload := BuildExecutePayload('', 0);
  FLastQuerySequence := SendMessage(MSG_EXECUTE, ExecPayload, 0, False);
  SendMessage(MSG_SYNC, nil, 0, False);
end;

end.

{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
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

  TNotification = record
    ProcessId: Cardinal;
    Channel: string;
    Payload: TBytes;
    ChangeType: string;
    RowId: UInt64;
    HasRowId: Boolean;
  end;

  TNotificationHandler = procedure(const Notice: TNotification) of object;

  TQueryPlan = record
    Format: Cardinal;
    PlanningTimeUs: UInt64;
    EstimatedRows: UInt64;
    EstimatedCost: UInt64;
    Plan: TBytes;
  end;

  TSblrCompiled = record
    Hash: UInt64;
    Version: Cardinal;
    Bytecode: TBytes;
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
    FLastMaxRows: Cardinal;
    FParameters: TStringList;
    FOnNotification: TNotificationHandler;
    FLastPlan: TQueryPlan;
    FHasLastPlan: Boolean;
    FLastSblr: TSblrCompiled;
    FHasLastSblr: Boolean;
    function ReadExact(Length: Integer): TBytes;
    procedure SendBytes(const Data: TBytes);
    function ReceiveMessage: TScratchBirdMessage;
    procedure HandshakeAndAuth;
    procedure ApplySchema;
    function BuildQueryError(const Payload: TBytes): EScratchBirdError;
    procedure HandleParameterStatus(const Name, Value: string);
    function HandleAsyncMessage(const Msg: TScratchBirdMessage): Boolean;
    procedure DrainUntilReady;
    function DescribeStatement(const StatementName: string): Integer;
    function SendMessage(MsgType: TScratchBirdMessageType; const Payload: TBytes; Flags: Byte; ForceZero: Boolean): Cardinal;
    procedure SendSimpleQuery(const Sql: string; MaxRows: Cardinal);
    procedure SendExtendedQuery(const Sql: string; const Params: array of TScratchBirdParamInput; MaxRows: Cardinal);
    function CurrentMaxRows: Cardinal;
    procedure ParseNotification(const Payload: TBytes; out Notice: TNotification);
    procedure ParseQueryPlan(const Payload: TBytes; out Plan: TQueryPlan);
    procedure ParseSblrCompiled(const Payload: TBytes; out Compiled: TSblrCompiled);
    function ParseUuidBytes(const Value: string): TBytes;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect(const Dsn: string);
    procedure Disconnect;
    procedure BeginTransaction;
    procedure BeginTransactionEx(IsolationLevel: Byte; AccessMode: Byte; Deferrable: Boolean; WaitMode: Boolean;
      TimeoutMs: Cardinal; AutocommitMode: Byte; ConflictAction: Byte);
    procedure Commit(Flags: Byte = 0);
    procedure Rollback(Flags: Byte = 0);
    procedure Savepoint(const Name: string);
    procedure ReleaseSavepoint(const Name: string);
    procedure RollbackToSavepoint(const Name: string);
    procedure SetOption(const Name, Value: string);
    procedure Ping;
    procedure Terminate;
    procedure Subscribe(SubscribeType: Byte; const Channel, FilterExpr: string);
    procedure Unsubscribe(const Channel: string);
    function ExecuteSblr(SblrHash: UInt64; const Bytecode: TBytes; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
    procedure StreamControl(ControlType: Byte; WindowSize, TimeoutMs: Cardinal);
    procedure AttachCreate(const EmulationMode, DbName: string);
    procedure AttachDetach;
    function AttachList: TScratchBirdResultStream;
    procedure ExecSQL(const Sql: string);
    procedure ExecSQLParams(const Sql: string; const Params: array of TScratchBirdParamInput);
    function ExecuteQuery(const Sql: string): TScratchBirdResultStream;
    function ExecuteQueryParams(const Sql: string; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
    procedure Cancel;
    function GetLastPlan(out Plan: TQueryPlan): Boolean;
    function GetLastSblr(out Compiled: TSblrCompiled): Boolean;
    property OnNotification: TNotificationHandler read FOnNotification write FOnNotification;
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
    if Client.HandleAsyncMessage(Msg) then
      Continue;
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
      MSG_PORTAL_SUSPENDED:
      begin
        Client.SendMessage(MSG_EXECUTE, BuildExecutePayload('', Client.CurrentMaxRows), 0, False);
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
  FLastMaxRows := 0;
  FParameters := TStringList.Create;
  FHasLastPlan := False;
  FHasLastSblr := False;
  FOnNotification := nil;
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
  if not FConfig.BinaryTransfer then
    raise EScratchbirdNotSupported.CreateWithInfo('binary_transfer=false is not supported', '0A000', '', '');
  if SameText(FConfig.Compression, 'zstd') then
    raise EScratchbirdNotSupported.CreateWithInfo('compression=zstd is not supported', '0A000', '', '');

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
  BeginTransactionEx(ISOLATION_READ_COMMITTED, 0, False, False, 0, 0, 0);
end;

procedure TScratchBirdClient.BeginTransactionEx(IsolationLevel: Byte; AccessMode: Byte; Deferrable: Boolean; WaitMode: Boolean;
  TimeoutMs: Cardinal; AutocommitMode: Byte; ConflictAction: Byte);
var
  Flags: Word;
  Payload: TBytes;
begin
  Flags := TXN_FLAG_HAS_ISOLATION;
  if AccessMode <> 0 then
    Flags := Flags or TXN_FLAG_HAS_ACCESS;
  if Deferrable then
    Flags := Flags or TXN_FLAG_HAS_DEFERRABLE;
  if WaitMode then
    Flags := Flags or TXN_FLAG_HAS_WAIT;
  if TimeoutMs > 0 then
    Flags := Flags or TXN_FLAG_HAS_TIMEOUT;
  if AutocommitMode <> 0 then
    Flags := Flags or TXN_FLAG_HAS_AUTOCOMMIT;
  Payload := BuildTxnBeginPayload(Flags, ConflictAction, AutocommitMode, IsolationLevel, AccessMode,
    Ord(Deferrable), Ord(WaitMode), TimeoutMs);
  SendMessage(MSG_TXN_BEGIN, Payload, 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Commit(Flags: Byte = 0);
var
  Payload: TBytes;
begin
  Payload := BuildTxnCommitPayload(Flags);
  SendMessage(MSG_TXN_COMMIT, Payload, 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Rollback(Flags: Byte = 0);
var
  Payload: TBytes;
begin
  Payload := BuildTxnRollbackPayload(Flags);
  SendMessage(MSG_TXN_ROLLBACK, Payload, 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Savepoint(const Name: string);
begin
  SendMessage(MSG_TXN_SAVEPOINT, BuildTxnSavepointPayload(Name), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.ReleaseSavepoint(const Name: string);
begin
  SendMessage(MSG_TXN_RELEASE, BuildTxnReleasePayload(Name), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.RollbackToSavepoint(const Name: string);
begin
  SendMessage(MSG_TXN_ROLLBACK_TO, BuildTxnRollbackToPayload(Name), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.SetOption(const Name, Value: string);
begin
  SendMessage(MSG_SET_OPTION, BuildSetOptionPayload(Name, Value), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Ping;
var
  Msg: TScratchBirdMessage;
  Status: Byte;
  TxnId, Visibility: UInt64;
begin
  SendMessage(MSG_PING, nil, 0, False);
  while True do
  begin
    Msg := ReceiveMessage;
    if HandleAsyncMessage(Msg) then
      Continue;
    case Msg.MsgType of
      MSG_PONG:
        Exit;
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
end;

procedure TScratchBirdClient.Terminate;
begin
  SendMessage(MSG_TERMINATE, nil, 0, False);
  Disconnect;
end;

procedure TScratchBirdClient.Subscribe(SubscribeType: Byte; const Channel, FilterExpr: string);
begin
  SendMessage(MSG_SUBSCRIBE, BuildSubscribePayload(SubscribeType, Channel, FilterExpr), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Unsubscribe(const Channel: string);
begin
  SendMessage(MSG_UNSUBSCRIBE, BuildUnsubscribePayload(Channel), 0, False);
  DrainUntilReady;
end;

function TScratchBirdClient.ExecuteSblr(SblrHash: UInt64; const Bytecode: TBytes; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
var
  ParamValues: TArray<TParamValue>;
  Param: TParamValue;
  Oid: Cardinal;
  I: Integer;
  Payload: TBytes;
begin
  SetLength(ParamValues, Length(Params));
  for I := 0 to High(Params) do
  begin
    EncodeParam(Params[I].Value, Params[I].Obj, Param, Oid);
    ParamValues[I] := Param;
  end;
  FHasLastPlan := False;
  FHasLastSblr := False;
  Payload := BuildSblrExecutePayload(SblrHash, Bytecode, ParamValues);
  FLastQuerySequence := SendMessage(MSG_SBLR_EXECUTE, Payload, 0, False);
  SendMessage(MSG_SYNC, nil, 0, False);
  Result := TScratchBirdResultStream.Create(Self);
end;

procedure TScratchBirdClient.StreamControl(ControlType: Byte; WindowSize, TimeoutMs: Cardinal);
begin
  SendMessage(MSG_STREAM_CONTROL, BuildStreamControlPayload(ControlType, WindowSize, TimeoutMs), 0, False);
end;

procedure TScratchBirdClient.AttachCreate(const EmulationMode, DbName: string);
begin
  SendMessage(MSG_ATTACH_CREATE, BuildAttachCreatePayload(EmulationMode, DbName), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.AttachDetach;
begin
  SendMessage(MSG_ATTACH_DETACH, nil, 0, False);
  DrainUntilReady;
end;

function TScratchBirdClient.AttachList: TScratchBirdResultStream;
begin
  SendMessage(MSG_ATTACH_LIST, nil, 0, False);
  SendMessage(MSG_SYNC, nil, 0, False);
  Result := TScratchBirdResultStream.Create(Self);
end;

procedure TScratchBirdClient.ExecSQL(const Sql: string);
begin
  ExecSQLParams(Sql, []);
end;

procedure TScratchBirdClient.ExecSQLParams(const Sql: string; const Params: array of TScratchBirdParamInput);
begin
  if Length(Params) = 0 then
  begin
    SendSimpleQuery(Sql, 0);
  end
  else
  begin
    SendExtendedQuery(Sql, Params, 0);
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
    SendSimpleQuery(Sql, Cardinal(FConfig.FetchSize))
  else
    SendExtendedQuery(Sql, Params, Cardinal(FConfig.FetchSize));
  Result := TScratchBirdResultStream.Create(Self);
end;

procedure TScratchBirdClient.Cancel;
begin
  SendMessage(MSG_CANCEL, BuildCancelPayload(0, FLastQuerySequence), MSG_FLAG_URGENT, False);
end;

function TScratchBirdClient.GetLastPlan(out Plan: TQueryPlan): Boolean;
begin
  Result := FHasLastPlan;
  if Result then
    Plan := FLastPlan;
end;

function TScratchBirdClient.GetLastSblr(out Compiled: TSblrCompiled): Boolean;
begin
  Result := FHasLastSblr;
  if Result then
    Compiled := FLastSblr;
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
    if FConfig.Role <> '' then
      Params.Values['role'] := FConfig.Role;
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
            HandleParameterStatus(Name, Value);
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

procedure TScratchBirdClient.HandleParameterStatus(const Name, Value: string);
var
  Bytes: TBytes;
  Parsed: UInt64;
begin
  FParameters.Values[Name] := Value;
  if SameText(Name, 'attachment_id') then
  begin
    Bytes := ParseUuidBytes(Value);
    if Length(Bytes) = 16 then
      FAttachmentId := Bytes;
  end;
  if SameText(Name, 'current_txn_id') then
  begin
    if TryStrToUInt64(Value, Parsed) then
      FTxnId := Parsed;
  end;
end;

function TScratchBirdClient.HandleAsyncMessage(const Msg: TScratchBirdMessage): Boolean;
var
  Name, Value: string;
  Notice: TNotification;
  Plan: TQueryPlan;
  Compiled: TSblrCompiled;
begin
  Result := True;
  case Msg.MsgType of
    MSG_PARAMETER_STATUS:
      begin
        ParseParameterStatus(Msg.Payload, Name, Value);
        HandleParameterStatus(Name, Value);
      end;
    MSG_NOTIFICATION:
      begin
        ParseNotification(Msg.Payload, Notice);
        if Assigned(FOnNotification) then
          FOnNotification(Notice);
      end;
    MSG_QUERY_PLAN:
      begin
        ParseQueryPlan(Msg.Payload, Plan);
        FLastPlan := Plan;
        FHasLastPlan := True;
      end;
    MSG_SBLR_COMPILED:
      begin
        ParseSblrCompiled(Msg.Payload, Compiled);
        FLastSblr := Compiled;
        FHasLastSblr := True;
      end;
  else
    Result := False;
  end;
end;

procedure TScratchBirdClient.ParseNotification(const Payload: TBytes; out Notice: TNotification);
var
  Offset: Integer;
  ChannelLen, PayloadLen: Cardinal;
  function ReadUInt32LE(const Buffer: TBytes; Index: Integer): Cardinal;
  begin
    Result := 0;
    if Index + SizeOf(Result) <= Length(Buffer) then
      Move(Buffer[Index], Result, SizeOf(Result));
  end;
  function ReadUInt64LE(const Buffer: TBytes; Index: Integer): UInt64;
  begin
    Result := 0;
    if Index + SizeOf(Result) <= Length(Buffer) then
      Move(Buffer[Index], Result, SizeOf(Result));
  end;
begin
  FillChar(Notice, SizeOf(Notice), 0);
  Offset := 0;
  if Length(Payload) < 12 then
    Exit;
  Notice.ProcessId := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  ChannelLen := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  if Offset + Integer(ChannelLen) + 4 > Length(Payload) then
    Exit;
  Notice.Channel := TEncoding.UTF8.GetString(Copy(Payload, Offset, ChannelLen));
  Inc(Offset, ChannelLen);
  PayloadLen := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  if Offset + Integer(PayloadLen) > Length(Payload) then
    Exit;
  Notice.Payload := Copy(Payload, Offset, PayloadLen);
  Inc(Offset, PayloadLen);
  Notice.ChangeType := '';
  Notice.HasRowId := False;
  if Offset < Length(Payload) then
  begin
    Notice.ChangeType := Char(Payload[Offset]);
    Inc(Offset);
    if Offset + SizeOf(UInt64) <= Length(Payload) then
    begin
      Notice.RowId := ReadUInt64LE(Payload, Offset);
      Notice.HasRowId := True;
    end;
  end;
end;

procedure TScratchBirdClient.ParseQueryPlan(const Payload: TBytes; out Plan: TQueryPlan);
var
  Offset: Integer;
  PlanLen: Cardinal;
  function ReadUInt32LE(const Buffer: TBytes; Index: Integer): Cardinal;
  begin
    Result := 0;
    if Index + SizeOf(Result) <= Length(Buffer) then
      Move(Buffer[Index], Result, SizeOf(Result));
  end;
  function ReadUInt64LE(const Buffer: TBytes; Index: Integer): UInt64;
  begin
    Result := 0;
    if Index + SizeOf(Result) <= Length(Buffer) then
      Move(Buffer[Index], Result, SizeOf(Result));
  end;
begin
  FillChar(Plan, SizeOf(Plan), 0);
  if Length(Payload) < 32 then
    Exit;
  Offset := 0;
  Plan.Format := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  PlanLen := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  Plan.PlanningTimeUs := ReadUInt64LE(Payload, Offset);
  Inc(Offset, 8);
  Plan.EstimatedRows := ReadUInt64LE(Payload, Offset);
  Inc(Offset, 8);
  Plan.EstimatedCost := ReadUInt64LE(Payload, Offset);
  Inc(Offset, 8);
  if Offset + Integer(PlanLen) > Length(Payload) then
    Exit;
  Plan.Plan := Copy(Payload, Offset, PlanLen);
end;

procedure TScratchBirdClient.ParseSblrCompiled(const Payload: TBytes; out Compiled: TSblrCompiled);
var
  Offset: Integer;
  Len: Cardinal;
  function ReadUInt32LE(const Buffer: TBytes; Index: Integer): Cardinal;
  begin
    Result := 0;
    if Index + SizeOf(Result) <= Length(Buffer) then
      Move(Buffer[Index], Result, SizeOf(Result));
  end;
  function ReadUInt64LE(const Buffer: TBytes; Index: Integer): UInt64;
  begin
    Result := 0;
    if Index + SizeOf(Result) <= Length(Buffer) then
      Move(Buffer[Index], Result, SizeOf(Result));
  end;
begin
  FillChar(Compiled, SizeOf(Compiled), 0);
  if Length(Payload) < 16 then
    Exit;
  Offset := 0;
  Compiled.Hash := ReadUInt64LE(Payload, Offset);
  Inc(Offset, 8);
  Compiled.Version := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  Len := ReadUInt32LE(Payload, Offset);
  Inc(Offset, 4);
  if Offset + Integer(Len) > Length(Payload) then
    Exit;
  Compiled.Bytecode := Copy(Payload, Offset, Len);
end;

function TScratchBirdClient.ParseUuidBytes(const Value: string): TBytes;
var
  Hex: string;
  I: Integer;
  ByteVal: Integer;
begin
  Hex := StringReplace(Value, '-', '', [rfReplaceAll]);
  if Length(Hex) <> 32 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  SetLength(Result, 16);
  for I := 0 to 15 do
  begin
    if not TryStrToInt('$' + Copy(Hex, I * 2 + 1, 2), ByteVal) then
    begin
      SetLength(Result, 0);
      Exit;
    end;
    Result[I] := Byte(ByteVal);
  end;
end;

procedure TScratchBirdClient.DrainUntilReady;
var
  Msg: TScratchBirdMessage;
  Status: Byte;
  TxnId, Visibility: UInt64;
begin
  while True do
  begin
    Msg := ReceiveMessage;
    if HandleAsyncMessage(Msg) then
      Continue;
    case Msg.MsgType of
      MSG_ERROR:
        raise BuildQueryError(Msg.Payload);
      MSG_READY:
        begin
          ParseReady(Msg.Payload, Status, TxnId, Visibility);
          FTxnId := TxnId;
          Exit;
        end;
    end;
  end;
end;

function TScratchBirdClient.DescribeStatement(const StatementName: string): Integer;
var
  Payload: TBytes;
  Msg: TScratchBirdMessage;
  Status: Byte;
  TxnId, Visibility: UInt64;
  Types: TArray<Cardinal>;
begin
  Payload := BuildDescribePayload(Ord('S'), StatementName);
  SendMessage(MSG_DESCRIBE, Payload, 0, False);
  SendMessage(MSG_SYNC, nil, 0, False);
  Result := -1;
  while True do
  begin
    Msg := ReceiveMessage;
    if HandleAsyncMessage(Msg) then
      Continue;
    case Msg.MsgType of
      MSG_PARAMETER_DESCRIPTION:
        begin
          Types := ParseParameterDescription(Msg.Payload);
          Result := Length(Types);
        end;
      MSG_ERROR:
        raise BuildQueryError(Msg.Payload);
      MSG_READY:
        begin
          ParseReady(Msg.Payload, Status, TxnId, Visibility);
          FTxnId := TxnId;
          Exit;
        end;
    end;
  end;
end;

procedure TScratchBirdClient.SendSimpleQuery(const Sql: string; MaxRows: Cardinal);
var
  Flags: Cardinal;
  Payload: TBytes;
begin
  Flags := 0;
  if FConfig.BinaryTransfer then
    Flags := Flags or $04;
  FLastMaxRows := MaxRows;
  Payload := BuildQueryPayload(Sql, Flags, MaxRows, 0);
  FHasLastPlan := False;
  FHasLastSblr := False;
  FLastQuerySequence := SendMessage(MSG_QUERY, Payload, 0, False);
end;

procedure TScratchBirdClient.SendExtendedQuery(const Sql: string; const Params: array of TScratchBirdParamInput; MaxRows: Cardinal);
var
  ParamValues: TArray<TParamValue>;
  ParamTypes: TArray<Cardinal>;
  I: Integer;
  Param: TParamValue;
  Oid: Cardinal;
  ParamCount: Integer;
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
  ParamCount := DescribeStatement('');
  if (ParamCount >= 0) and (ParamCount <> Length(Params)) then
    raise EScratchBirdError.CreateWithInfo('parameter count mismatch', '07001', '', '');
  if FConfig.BinaryTransfer then
  begin
    SetLength(ResultFormats, 1);
    ResultFormats[0] := FORMAT_BINARY;
  end
  else
    ResultFormats := nil;
  BindPayload := BuildBindPayload('', '', ParamValues, ResultFormats);
  SendMessage(MSG_BIND, BindPayload, 0, False);
  FLastMaxRows := MaxRows;
  ExecPayload := BuildExecutePayload('', MaxRows);
  FHasLastPlan := False;
  FHasLastSblr := False;
  FLastQuerySequence := SendMessage(MSG_EXECUTE, ExecPayload, 0, False);
  if MaxRows = 0 then
    SendMessage(MSG_SYNC, nil, 0, False);
end;

function TScratchBirdClient.CurrentMaxRows: Cardinal;
begin
  Result := FLastMaxRows;
end;

end.

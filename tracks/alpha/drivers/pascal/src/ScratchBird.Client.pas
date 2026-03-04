{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Client;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, Classes,
  ScratchBird.Config, ScratchBird.Protocol, ScratchBird.Errors, ScratchBird.Scram, ScratchBird.Types, ScratchBird.Sql, ScratchBird.Metadata,
  ScratchBird.Transport, ScratchBird.Transport.Native,
  {$IFDEF SCRATCHBIRD_USE_INDY}
  ScratchBird.Transport.Indy,
  {$ENDIF}
  SBCircuitBreaker, SBKeepalive, SBLeakDetector, SBTelemetry
  {$IFDEF MSWINDOWS}
  , Windows
  {$ENDIF}
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
    FTransport: IScratchBirdTransport;
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
    FCircuitBreaker: TCircuitBreaker;
    FTelemetry: TTelemetryCollector;
    FKeepaliveTracker: TKeepaliveTracker;
    FLeakDetector: TLeakDetector;
    FConnectionId: string;
    function ReadExact(Length: Integer): TBytes;
    procedure SendBytes(const Data: TBytes);
    function ReceiveMessage: TScratchBirdMessage;
    procedure SendManagerFrame(MsgType: Byte; const Payload: TBytes);
    procedure ReceiveManagerFrame(out MsgType: Byte; out Payload: TBytes);
    procedure AppendLengthPrefixedString(var Buffer: TBytes; const Value: string);
    procedure PerformManagerConnect;
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
    procedure EnsureConnected;
    procedure EnsureTransactionActive(const Operation: string);
    function NormalizeSavepointName(const Name: string): string;
    function NormalizeSqlText(const Sql: string): string;
    procedure InitializeClient(const Transport: IScratchBirdTransport);
    function BeginOperation(const Name, Sql: string): TSpanContext;
    procedure EndOperation(Span: TSpanContext; Success: Boolean);
  public
    constructor Create; overload;
    constructor CreateWithTransport(const Transport: IScratchBirdTransport); overload;
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
    function QueryMetadata(const CollectionName: string = 'tables'): TScratchBirdResultStream;
    function GetSchema(const CollectionName: string = 'tables'): TScratchBirdResultStream;
    function QueryMetadataRows(const CollectionName: string = 'tables'): TMetadataRows; overload;
    function QueryMetadataRows(const CollectionName: string; const Restrictions: TMetadataRow): TMetadataRows; overload;
    function GetSchemaRows(const CollectionName: string = 'tables'): TMetadataRows; overload;
    function GetSchemaRows(const CollectionName: string; const Restrictions: TMetadataRow): TMetadataRows; overload;
    function GetCatalogs: TScratchBirdResultStream;
    function GetSchemas: TScratchBirdResultStream;
    function GetTables: TScratchBirdResultStream;
    function GetColumns: TScratchBirdResultStream;
    function GetIndexes: TScratchBirdResultStream;
    function GetConstraints: TScratchBirdResultStream;
    function GetProcedures: TScratchBirdResultStream;
    function GetFunctions: TScratchBirdResultStream;
    function GetRoutines: TScratchBirdResultStream;
    function GetPrimaryKeys: TScratchBirdResultStream;
    function GetForeignKeys: TScratchBirdResultStream;
    function GetTablePrivileges: TScratchBirdResultStream;
    function GetColumnPrivileges: TScratchBirdResultStream;
    function GetTypeInfo: TScratchBirdResultStream;
    procedure Cancel;
    function GetLastPlan(out Plan: TQueryPlan): Boolean;
    function GetLastSblr(out Compiled: TSblrCompiled): Boolean;
    property OnNotification: TNotificationHandler read FOnNotification write FOnNotification;
    property Connected: Boolean read FConnected;
    property Config: TScratchBirdConfig read FConfig;
  end;

implementation

const
  MANAGER_PROTOCOL_MAGIC = $42444253; // SBDB
  MANAGER_PROTOCOL_VERSION = $0101;
  MANAGER_HEADER_SIZE = 12;
  MANAGER_MAX_PAYLOAD_SIZE = 16 * 1024 * 1024;
  MCP_PROTOCOL_VERSION = $0100;

  MCP_MSG_CONNECT_RESPONSE = $02;
  MCP_MSG_AUTH_CHALLENGE = $12;
  MCP_MSG_AUTH_RESPONSE = $11;
  MCP_MSG_STATUS_RESPONSE = $64;
  MCP_MSG_HELLO = $65;
  MCP_MSG_AUTH_START = $66;
  MCP_MSG_AUTH_CONTINUE = $67;
  MCP_MSG_DB_CONNECT = $69;
  MCP_AUTH_METHOD_TOKEN = 4;

function ReadUInt16LEValue(const Data: TBytes; Offset: Integer): Word;
begin
  Result := Word(Data[Offset]) or (Word(Data[Offset + 1]) shl 8);
end;

function ReadUInt32LEValue(const Data: TBytes; Offset: Integer): Cardinal;
begin
  Result := Cardinal(Data[Offset]) or (Cardinal(Data[Offset + 1]) shl 8) or
    (Cardinal(Data[Offset + 2]) shl 16) or (Cardinal(Data[Offset + 3]) shl 24);
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

procedure TScratchBirdClient.InitializeClient(const Transport: IScratchBirdTransport);
begin
  FTransport := Transport;
  if not Assigned(FTransport) then
    raise EScratchbirdConnectionError.CreateWithInfo('Transport is not assigned', '08001', '', '');

  SetLength(FAttachmentId, 16);
  FillChar(FAttachmentId[0], 16, 0);
  FSequence := 0;
  FTxnId := 0;
  FLastMaxRows := 0;
  FParameters := TStringList.Create;
  FHasLastPlan := False;
  FHasLastSblr := False;
  FOnNotification := nil;
  FConnectionId := 'conn-' + IntToStr(NativeInt(Self));
  FCircuitBreaker := TCircuitBreaker.Create(DefaultCircuitBreakerConfig, 'pascal');
  FTelemetry := TTelemetryCollector.Create(DefaultTelemetryConfig);
  FKeepaliveTracker := TKeepaliveTracker.Create(DefaultKeepaliveConfig);
  FLeakDetector := TLeakDetector.Create(DefaultLeakDetectionConfig);
  FLeakDetector.Start;
end;

constructor TScratchBirdClient.Create;
var
  Transport: IScratchBirdTransport;
begin
  inherited Create;
  {$IFDEF SCRATCHBIRD_USE_INDY}
  Transport := TIndyScratchBirdTransport.Create;
  {$ELSE}
  Transport := TNativeScratchBirdTransport.Create;
  {$ENDIF}
  InitializeClient(Transport);
end;

constructor TScratchBirdClient.CreateWithTransport(const Transport: IScratchBirdTransport);
begin
  inherited Create;
  InitializeClient(Transport);
end;

destructor TScratchBirdClient.Destroy;
begin
  Disconnect;
  if Assigned(FLeakDetector) then
  begin
    FLeakDetector.Checkin(FConnectionId);
    FLeakDetector.Stop;
    FLeakDetector.Free;
  end;
  FKeepaliveTracker.Free;
  FTelemetry.Free;
  FCircuitBreaker.Free;
  FParameters.Free;
  inherited Destroy;
end;

procedure TScratchBirdClient.Connect(const Dsn: string);
begin
  FConfig := ParseConfig(Dsn);
  if (Trim(FConfig.Protocol) = '') or SameText(FConfig.Protocol, 'native') or
     SameText(FConfig.Protocol, 'scratchbird') or SameText(FConfig.Protocol, 'scratchbird-native') or
     SameText(FConfig.Protocol, 'scratchbird_native') then
    FConfig.Protocol := 'native'
  else
    raise EScratchbirdNotSupported.CreateWithInfo(
      'Only protocol=native is supported; connect to the native parser listener/port.',
      '0A000', '', '');
  if (FConfig.UserName = '') or (FConfig.Database = '') then
    raise EScratchbirdConnectionError.CreateWithInfo('user and database are required', '08001', '', '');
  FConfig.FrontDoorMode := LowerCase(Trim(FConfig.FrontDoorMode));
  if (FConfig.FrontDoorMode = '') then
    FConfig.FrontDoorMode := 'direct'
  else if (FConfig.FrontDoorMode = 'manager-proxy') or (FConfig.FrontDoorMode = 'managed') then
    FConfig.FrontDoorMode := 'manager_proxy';
  if (FConfig.FrontDoorMode <> 'direct') and (FConfig.FrontDoorMode <> 'manager_proxy') then
    raise EScratchbirdNotSupported.CreateWithInfo(
      'front_door_mode must be direct or manager_proxy.',
      '0A000', '', '');
  if (FConfig.FrontDoorMode = 'manager_proxy') and (Trim(FConfig.ManagerAuthToken) = '') then
    raise EScratchbirdConnectionError.CreateWithInfo(
      'manager_proxy mode requires manager_auth_token',
      '08001', '', '');
  if not FConfig.BinaryTransfer then
    raise EScratchbirdNotSupported.CreateWithInfo('binary_transfer=false is not supported', '0A000', '', '');
  if SameText(FConfig.Compression, 'zstd') then
    raise EScratchbirdNotSupported.CreateWithInfo('compression=zstd is not supported', '0A000', '', '');
  FTransport.Configure(FConfig);
  FTransport.Connect;
  if FConfig.FrontDoorMode = 'manager_proxy' then
    PerformManagerConnect;
  HandshakeAndAuth;
  ApplySchema;
  FConnected := True;
  if Assigned(FLeakDetector) then
    FLeakDetector.Checkout(FConnectionId, []);
end;

procedure TScratchBirdClient.Disconnect;
begin
  if not FConnected then
    Exit;
  FTransport.Disconnect;
  FConnected := False;
  FTxnId := 0;
  if Length(FAttachmentId) = 16 then
    FillChar(FAttachmentId[0], 16, 0);
  if Assigned(FLeakDetector) then
    FLeakDetector.Checkin(FConnectionId);
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
  EnsureConnected;
  if FTxnId <> 0 then
    raise EScratchbirdTransactionError.CreateWithInfo('transaction already active', '25000', '', '');
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
  if FTxnId = 0 then
    Exit;
  EnsureConnected;
  Payload := BuildTxnCommitPayload(Flags);
  SendMessage(MSG_TXN_COMMIT, Payload, 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Rollback(Flags: Byte = 0);
var
  Payload: TBytes;
begin
  if FTxnId = 0 then
    Exit;
  EnsureConnected;
  Payload := BuildTxnRollbackPayload(Flags);
  SendMessage(MSG_TXN_ROLLBACK, Payload, 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.Savepoint(const Name: string);
var
  SavepointName: string;
begin
  SavepointName := NormalizeSavepointName(Name);
  EnsureTransactionActive('savepoint');
  EnsureConnected;
  SendMessage(MSG_TXN_SAVEPOINT, BuildTxnSavepointPayload(SavepointName), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.ReleaseSavepoint(const Name: string);
var
  SavepointName: string;
begin
  SavepointName := NormalizeSavepointName(Name);
  EnsureTransactionActive('release_savepoint');
  EnsureConnected;
  SendMessage(MSG_TXN_RELEASE, BuildTxnReleasePayload(SavepointName), 0, False);
  DrainUntilReady;
end;

procedure TScratchBirdClient.RollbackToSavepoint(const Name: string);
var
  SavepointName: string;
begin
  SavepointName := NormalizeSavepointName(Name);
  EnsureTransactionActive('rollback_to_savepoint');
  EnsureConnected;
  SendMessage(MSG_TXN_ROLLBACK_TO, BuildTxnRollbackToPayload(SavepointName), 0, False);
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
  Span: TSpanContext;
begin
  Span := BeginOperation('sblr_execute', '');
  try
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
    EndOperation(Span, True);
  except
    on E: Exception do
    begin
      EndOperation(Span, False);
      raise;
    end;
  end;
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
var
  Span: TSpanContext;
  SqlText: string;
begin
  SqlText := NormalizeSqlText(Sql);
  EnsureConnected;
  Span := BeginOperation('exec', SqlText);
  try
    if Length(Params) = 0 then
    begin
      SendSimpleQuery(SqlText, 0);
    end
    else
    begin
      SendExtendedQuery(SqlText, Params, 0);
    end;
    DrainUntilReady;
    EndOperation(Span, True);
  except
    on E: Exception do
    begin
      EndOperation(Span, False);
      raise;
    end;
  end;
end;

function TScratchBirdClient.ExecuteQuery(const Sql: string): TScratchBirdResultStream;
begin
  Result := ExecuteQueryParams(Sql, []);
end;

function TScratchBirdClient.ExecuteQueryParams(const Sql: string; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
var
  Span: TSpanContext;
  SqlText: string;
begin
  SqlText := NormalizeSqlText(Sql);
  EnsureConnected;
  Span := BeginOperation('query', SqlText);
  try
    if Length(Params) = 0 then
      SendSimpleQuery(SqlText, Cardinal(FConfig.FetchSize))
    else
      SendExtendedQuery(SqlText, Params, Cardinal(FConfig.FetchSize));
    Result := TScratchBirdResultStream.Create(Self);
    EndOperation(Span, True);
  except
    on E: Exception do
    begin
      EndOperation(Span, False);
      raise;
    end;
  end;
end;

function TScratchBirdClient.QueryMetadata(const CollectionName: string): TScratchBirdResultStream;
begin
  Result := ExecuteQuery(ResolveMetadataCollectionQuery(CollectionName));
end;

function TScratchBirdClient.GetSchema(const CollectionName: string): TScratchBirdResultStream;
begin
  Result := QueryMetadata(CollectionName);
end;

function TScratchBirdClient.QueryMetadataRows(const CollectionName: string): TMetadataRows;
var
  EmptyRestrictions: TMetadataRow;
begin
  SetLength(EmptyRestrictions, 0);
  Result := QueryMetadataRows(CollectionName, EmptyRestrictions);
end;

function TScratchBirdClient.QueryMetadataRows(const CollectionName: string; const Restrictions: TMetadataRow): TMetadataRows;
var
  Stream: TScratchBirdResultStream;
  RawRow: TArray<Variant>;
  Columns: TArray<TColumnInfo>;
  RowIndex, I: Integer;
begin
  Stream := QueryMetadata(CollectionName);
  try
    Result := nil;
    SetLength(Result, 0);
    while True do
    begin
      RawRow := Stream.ReadRow;
      if RawRow = nil then
        Break;

      Columns := Stream.Columns;
      RowIndex := Length(Result);
      SetLength(Result, RowIndex + 1);
      SetLength(Result[RowIndex], Length(RawRow));
      for I := 0 to High(RawRow) do
      begin
        if I < Length(Columns) then
          Result[RowIndex][I].Name := Columns[I].Name
        else
          Result[RowIndex][I].Name := 'column_' + IntToStr(I + 1);
        Result[RowIndex][I].Value := RawRow[I];
      end;
    end;
  finally
    Stream.Free;
  end;

  Result := FilterMetadataRowsByRestrictions(Result, Restrictions, CollectionName);
end;

function TScratchBirdClient.GetSchemaRows(const CollectionName: string): TMetadataRows;
begin
  Result := QueryMetadataRows(CollectionName);
end;

function TScratchBirdClient.GetSchemaRows(const CollectionName: string; const Restrictions: TMetadataRow): TMetadataRows;
begin
  Result := QueryMetadataRows(CollectionName, Restrictions);
end;

function TScratchBirdClient.GetCatalogs: TScratchBirdResultStream;
begin
  Result := QueryMetadata('catalogs');
end;

function TScratchBirdClient.GetSchemas: TScratchBirdResultStream;
begin
  Result := QueryMetadata('schemas');
end;

function TScratchBirdClient.GetTables: TScratchBirdResultStream;
begin
  Result := QueryMetadata('tables');
end;

function TScratchBirdClient.GetColumns: TScratchBirdResultStream;
begin
  Result := QueryMetadata('columns');
end;

function TScratchBirdClient.GetIndexes: TScratchBirdResultStream;
begin
  Result := QueryMetadata('indexes');
end;

function TScratchBirdClient.GetConstraints: TScratchBirdResultStream;
begin
  Result := QueryMetadata('constraints');
end;

function TScratchBirdClient.GetProcedures: TScratchBirdResultStream;
begin
  Result := QueryMetadata('procedures');
end;

function TScratchBirdClient.GetFunctions: TScratchBirdResultStream;
begin
  Result := QueryMetadata('functions');
end;

function TScratchBirdClient.GetRoutines: TScratchBirdResultStream;
begin
  Result := QueryMetadata('routines');
end;

function TScratchBirdClient.GetPrimaryKeys: TScratchBirdResultStream;
begin
  Result := QueryMetadata('primary_keys');
end;

function TScratchBirdClient.GetForeignKeys: TScratchBirdResultStream;
begin
  Result := QueryMetadata('foreign_keys');
end;

function TScratchBirdClient.GetTablePrivileges: TScratchBirdResultStream;
begin
  Result := QueryMetadata('table_privileges');
end;

function TScratchBirdClient.GetColumnPrivileges: TScratchBirdResultStream;
begin
  Result := QueryMetadata('column_privileges');
end;

function TScratchBirdClient.GetTypeInfo: TScratchBirdResultStream;
begin
  Result := QueryMetadata('type_info');
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
  FTransport.Write(Data);
end;

function TScratchBirdClient.ReadExact(Length: Integer): TBytes;
begin
  Result := FTransport.ReadExact(Length);
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

procedure TScratchBirdClient.AppendLengthPrefixedString(var Buffer: TBytes; const Value: string);
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(Value);
  AppendUInt32LE(Buffer, Cardinal(Length(Bytes)));
  AppendBytes(Buffer, Bytes);
end;

procedure TScratchBirdClient.SendManagerFrame(MsgType: Byte; const Payload: TBytes);
var
  Frame: TBytes;
  Start: Integer;
begin
  SetLength(Frame, 0);
  AppendUInt32LE(Frame, MANAGER_PROTOCOL_MAGIC);
  AppendUInt16LE(Frame, MANAGER_PROTOCOL_VERSION);
  Start := Length(Frame);
  SetLength(Frame, Start + 2);
  Frame[Start] := MsgType;
  Frame[Start + 1] := 0;
  AppendUInt32LE(Frame, Cardinal(Length(Payload)));
  AppendBytes(Frame, Payload);
  SendBytes(Frame);
end;

procedure TScratchBirdClient.ReceiveManagerFrame(out MsgType: Byte; out Payload: TBytes);
var
  Header: TBytes;
  Magic: Cardinal;
  Version: Word;
  PayloadLen: Cardinal;
begin
  Header := ReadExact(MANAGER_HEADER_SIZE);
  Magic := ReadUInt32LEValue(Header, 0);
  if Magic <> MANAGER_PROTOCOL_MAGIC then
    raise EScratchbirdConnectionError.CreateWithInfo('Manager frame magic mismatch', '08P01', '', '');
  Version := ReadUInt16LEValue(Header, 4);
  if Version <> MANAGER_PROTOCOL_VERSION then
    raise EScratchbirdConnectionError.CreateWithInfo('Manager frame version mismatch', '08P01', '', '');
  MsgType := Header[6];
  PayloadLen := ReadUInt32LEValue(Header, 8);
  if PayloadLen > MANAGER_MAX_PAYLOAD_SIZE then
    raise EScratchbirdConnectionError.CreateWithInfo('Manager payload too large', '08P01', '', '');
  if PayloadLen > 0 then
    Payload := ReadExact(PayloadLen)
  else
    SetLength(Payload, 0);
end;

procedure TScratchBirdClient.PerformManagerConnect;
var
  Token: string;
  ManagerUser, ManagerDatabase, ManagerProfile, ManagerIntent: string;
  HelloPayload, AuthStart, AuthContinue, DbConnect, Nonce, TokenBytes: TBytes;
  MsgType: Byte;
  Payload: TBytes;
  Start: Integer;
  I: Integer;
  ErrText: string;
  ErrOffset, ErrLen: Cardinal;
begin
  Token := Trim(FConfig.ManagerAuthToken);
  if Token = '' then
    raise EScratchbirdConnectionError.CreateWithInfo('manager_proxy mode requires manager_auth_token', '08001', '', '');

  ManagerUser := Trim(FConfig.ManagerUsername);
  if ManagerUser = '' then
  begin
    if Trim(FConfig.UserName) <> '' then
      ManagerUser := FConfig.UserName
    else
      ManagerUser := 'admin';
  end;
  ManagerDatabase := Trim(FConfig.ManagerDatabase);
  if ManagerDatabase = '' then
    ManagerDatabase := FConfig.Database;
  ManagerProfile := Trim(FConfig.ManagerConnectionProfile);
  if ManagerProfile = '' then
    ManagerProfile := 'native_v3';
  ManagerIntent := Trim(FConfig.ManagerClientIntent);
  if ManagerIntent = '' then
    ManagerIntent := 'native_v3';

  SetLength(HelloPayload, 0);
  AppendUInt16LE(HelloPayload, MCP_PROTOCOL_VERSION);
  AppendUInt16LE(HelloPayload, Word(FConfig.ManagerClientFlags and $FFFF));
  SendManagerFrame(MCP_MSG_HELLO, HelloPayload);
  ReceiveManagerFrame(MsgType, Payload);
  if MsgType <> MCP_MSG_STATUS_RESPONSE then
    raise EScratchbirdConnectionError.CreateWithInfo('Expected MCP hello status response', '08P01', '', '');

  SetLength(AuthStart, 0);
  AppendLengthPrefixedString(AuthStart, ManagerUser);
  Start := Length(AuthStart);
  SetLength(AuthStart, Start + 1);
  AuthStart[Start] := MCP_AUTH_METHOD_TOKEN;
  if FConfig.ManagerAuthFastPath then
  begin
    TokenBytes := TEncoding.UTF8.GetBytes(Token);
    AppendUInt32LE(AuthStart, Cardinal(Length(TokenBytes)));
    AppendBytes(AuthStart, TokenBytes);
  end
  else
    AppendUInt32LE(AuthStart, 0);

  SendManagerFrame(MCP_MSG_AUTH_START, AuthStart);
  ReceiveManagerFrame(MsgType, Payload);
  if MsgType = MCP_MSG_AUTH_CHALLENGE then
  begin
    TokenBytes := TEncoding.UTF8.GetBytes(Token);
    SetLength(AuthContinue, 0);
    AppendUInt32LE(AuthContinue, Cardinal(Length(TokenBytes)));
    AppendBytes(AuthContinue, TokenBytes);
    SendManagerFrame(MCP_MSG_AUTH_CONTINUE, AuthContinue);
    ReceiveManagerFrame(MsgType, Payload);
  end;
  if MsgType <> MCP_MSG_AUTH_RESPONSE then
    raise EScratchbirdConnectionError.CreateWithInfo('Expected MCP auth response', '08P01', '', '');
  if Length(Payload) < (1 + 4 + 256) then
    raise EScratchbirdConnectionError.CreateWithInfo('Truncated MCP auth response', '08P01', '', '');
  if Payload[0] <> 0 then
  begin
    ErrText := StringReplace(TEncoding.UTF8.GetString(Copy(Payload, 5, 256)), #0, '', [rfReplaceAll]);
    if Trim(ErrText) = '' then
      ErrText := 'MCP authentication failed';
    raise EScratchbirdAuthError.CreateWithInfo(ErrText, '28000', '', '');
  end;

  SetLength(DbConnect, 0);
  AppendBytes(DbConnect, TEncoding.ASCII.GetBytes('MCP1'));
  AppendLengthPrefixedString(DbConnect, ManagerDatabase);
  AppendLengthPrefixedString(DbConnect, ManagerProfile);
  AppendLengthPrefixedString(DbConnect, ManagerIntent);
  SetLength(Nonce, 16);
  Randomize;
  for I := 0 to High(Nonce) do
    Nonce[I] := Byte(Random(256));
  AppendUInt16LE(DbConnect, Word(Length(Nonce)));
  AppendBytes(DbConnect, Nonce);
  SendManagerFrame(MCP_MSG_DB_CONNECT, DbConnect);
  ReceiveManagerFrame(MsgType, Payload);
  if MsgType <> MCP_MSG_CONNECT_RESPONSE then
    raise EScratchbirdConnectionError.CreateWithInfo('Expected MCP connect response', '08P01', '', '');
  if Length(Payload) < (1 + 2 + 2 + 16 + 64 + 32) then
    raise EScratchbirdConnectionError.CreateWithInfo('Truncated MCP connect response', '08P01', '', '');
  if Payload[0] <> 0 then
  begin
    ErrText := 'MCP database connect failed';
    ErrOffset := 1 + 2 + 2 + 16 + 64 + 32;
    if Length(Payload) >= Integer(ErrOffset + 4) then
    begin
      ErrLen := ReadUInt32LEValue(Payload, ErrOffset);
      if Length(Payload) >= Integer(ErrOffset + 4 + ErrLen) then
        ErrText := TEncoding.UTF8.GetString(Copy(Payload, ErrOffset + 4, ErrLen));
    end;
    raise EScratchbirdAuthError.CreateWithInfo(ErrText, '28000', '', '');
  end;
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

procedure TScratchBirdClient.EnsureConnected;
begin
  if not FConnected then
    raise EScratchbirdConnectionError.CreateWithInfo('Client is not connected', '08003', '', '');
end;

procedure TScratchBirdClient.EnsureTransactionActive(const Operation: string);
begin
  if FTxnId = 0 then
    raise EScratchbirdTransactionError.CreateWithInfo(Operation + ' requires an active transaction', '25000', '', '');
end;

function TScratchBirdClient.NormalizeSavepointName(const Name: string): string;
begin
  Result := Trim(Name);
  if Result = '' then
    raise EScratchbirdSyntaxError.CreateWithInfo('savepoint name is required', '42601', '', '');
end;

function TScratchBirdClient.NormalizeSqlText(const Sql: string): string;
begin
  Result := Trim(Sql);
  if Result = '' then
    raise EScratchbirdSyntaxError.CreateWithInfo('SQL text is required', '42601', '', '');
end;

function TScratchBirdClient.BeginOperation(const Name, Sql: string): TSpanContext;
begin
  if Assigned(FCircuitBreaker) and (not FCircuitBreaker.AllowRequest) then
    raise EScratchbirdConnectionError.CreateWithInfo('Circuit breaker is OPEN', '08006', '', '');
  if Assigned(FKeepaliveTracker) and FKeepaliveTracker.NeedsValidation then
  begin
    Ping;
    FKeepaliveTracker.MarkActive;
  end;
  if Assigned(FTelemetry) then
    Result := FTelemetry.StartSpan(Name)
  else
    Result := nil;
  if (Result <> nil) and (Sql <> '') then
    Result.WithAttribute('db.statement', TTelemetryCollector.SanitizeQuery(Sql));
end;

procedure TScratchBirdClient.EndOperation(Span: TSpanContext; Success: Boolean);
begin
  if Assigned(FCircuitBreaker) then
  begin
    if Success then
      FCircuitBreaker.RecordSuccess
    else
      FCircuitBreaker.RecordFailure;
  end;
  if Assigned(FKeepaliveTracker) then
    FKeepaliveTracker.MarkActive;
  if Assigned(FTelemetry) then
    FTelemetry.EndSpan(Span, Success);
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

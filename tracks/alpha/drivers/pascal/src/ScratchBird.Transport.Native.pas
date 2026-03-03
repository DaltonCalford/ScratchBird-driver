{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Transport.Native;

{$mode delphi}
{$H+}

interface

uses
  SysUtils,
  ScratchBird.Config, ScratchBird.Errors, ScratchBird.Transport,
  ScratchBird.Tls.Types, ScratchBird.Tls.Context;

type
  TNativeScratchBirdTransport = class(TInterfacedObject, IScratchBirdTransport)
  private
    FConfig: TScratchBirdConfig;
    FTlsConfig: TTlsConfig;
    FTlsContext: TTlsContext;
    FConnected: Boolean;
    function ParseTlsMode(const SSLMode: string): TTlsMode;
    procedure RaiseTlsFailure(const Stage: string; const Status: TTlsStatus);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configure(const Config: TScratchBirdConfig);
    procedure Connect;
    procedure Disconnect;
    function ReadExact(Length: Integer): TBytes;
    procedure Write(const Data: TBytes);
    function IsConnected: Boolean;
  end;

implementation

constructor TNativeScratchBirdTransport.Create;
begin
  inherited Create;
  FTlsContext := TTlsContext.Create;
  FTlsConfig := DefaultTlsConfig;
  FConnected := False;
end;

function TNativeScratchBirdTransport.ParseTlsMode(const SSLMode: string): TTlsMode;
var
  Mode: string;
begin
  Mode := LowerCase(Trim(SSLMode));
  if (Mode = '') or (Mode = 'require') then
    Exit(tmRequire);
  if Mode = 'disable' then
    raise EScratchbirdConnectionError.CreateWithInfo(
      'TLS mode "disable" is not allowed for ScratchBird connections.',
      '08001', '', '');
  if Mode = 'allow' then
    Exit(tmAllow);
  if Mode = 'prefer' then
    Exit(tmPrefer);
  if (Mode = 'verify-ca') or (Mode = 'verify_ca') then
    Exit(tmVerifyCA);
  if (Mode = 'verify-full') or (Mode = 'verify_full') then
    Exit(tmVerifyFull);
  raise EScratchbirdConnectionError.CreateWithInfo(
    'Unsupported sslmode value: ' + SSLMode,
    '08001', '', '');
end;

destructor TNativeScratchBirdTransport.Destroy;
begin
  Disconnect;
  FTlsContext.Free;
  inherited Destroy;
end;

procedure TNativeScratchBirdTransport.Configure(const Config: TScratchBirdConfig);
begin
  FConfig := Config;
  FTlsConfig.Mode := ParseTlsMode(Config.SSLMode);
  if FTlsConfig.Mode in [tmVerifyCA, tmVerifyFull] then
    FTlsConfig.RevocationPolicy := trpHardFail
  else
    FTlsConfig.RevocationPolicy := trpSoftFail;
  FTlsConfig.ServerName := Config.Host;
  FTlsConfig.Port := Config.Port;
  FTlsConfig.RootCAPath := Config.SSLRootCert;
  FTlsConfig.ClientCertPath := Config.SSLCert;
  FTlsConfig.ClientKeyPath := Config.SSLKey;
  FTlsConfig.ClientKeyPassword := Config.SSLPassword;
  FTlsConfig.ConnectTimeoutMs := Config.ConnectTimeoutMs;
  FTlsConfig.SocketTimeoutMs := Config.SocketTimeoutMs;
end;

procedure TNativeScratchBirdTransport.RaiseTlsFailure(const Stage: string; const Status: TTlsStatus);
var
  MessageText: string;
begin
  MessageText := Stage;
  if Status.LastError.MessageText <> '' then
    MessageText := MessageText + ': ' + Status.LastError.MessageText;
  if Status.LastError.Category = teNotImplemented then
    raise EScratchbirdNotSupported.CreateWithInfo(MessageText, '0A000', '', '');
  raise EScratchbirdConnectionError.CreateWithInfo(MessageText, '08001', '', '');
end;

procedure TNativeScratchBirdTransport.Connect;
var
  Status: TTlsStatus;
  SocketHandle: TSocketHandle;
begin
  Status := FTlsContext.Initialize(FTlsConfig);
  if not Status.Success then
    RaiseTlsFailure('native TLS initialize failed', Status);
  SocketHandle := INVALID_TLS_SOCKET_HANDLE;
  Status := FTlsContext.Handshake(SocketHandle);
  if not Status.Success then
    RaiseTlsFailure('native TLS handshake failed', Status);
  FConnected := True;
end;

procedure TNativeScratchBirdTransport.Disconnect;
begin
  FTlsContext.Shutdown;
  FConnected := False;
end;

function TNativeScratchBirdTransport.ReadExact(Length: Integer): TBytes;
var
  Status: TTlsStatus;
  Offset: Integer;
  BytesRead: Integer;
begin
  Result := nil;
  if Length <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  SetLength(Result, Length);
  Offset := 0;
  while Offset < Length do
  begin
    BytesRead := FTlsContext.Read(Result[Offset], Length - Offset);
    if BytesRead <= 0 then
    begin
      SetLength(Result, 0);
      Status.Success := False;
      Status.LastError := FTlsContext.LastError;
      RaiseTlsFailure('native TLS read failed', Status);
    end;
    Inc(Offset, BytesRead);
  end;
end;

procedure TNativeScratchBirdTransport.Write(const Data: TBytes);
var
  Status: TTlsStatus;
  Offset: Integer;
  BytesWritten: Integer;
begin
  if Length(Data) = 0 then
    Exit;
  Offset := 0;
  while Offset < Length(Data) do
  begin
    BytesWritten := FTlsContext.Write(Data[Offset], Length(Data) - Offset);
    if BytesWritten <= 0 then
    begin
      Status.Success := False;
      Status.LastError := FTlsContext.LastError;
      RaiseTlsFailure('native TLS write failed', Status);
    end;
    Inc(Offset, BytesWritten);
  end;
end;

function TNativeScratchBirdTransport.IsConnected: Boolean;
begin
  Result := FConnected;
end;

end.

{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Tls.Context;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, ScratchBird.Tls.Types, ScratchBird.Tls.Handshake, ScratchBird.Tls.RecordLayer,
  ScratchBird.Tls.Crypto, ScratchBird.Tls.X509;

type
  TTlsContext = class
  private
    FConfig: TTlsConfig;
    FPeerInfo: TTlsPeerInfo;
    FLastError: TTlsError;
    FInitialized: Boolean;
    FHandshake: TTlsHandshakeStateMachine;
    FEarlySecret: TBytes;
    FHandshakeSecret: TBytes;
    FTranscriptHash: TBytes;
    FPeerChain: TTlsCertificateChain;
    FHasPeerChain: Boolean;
    procedure ClearPeerInfo;
    procedure ClearLastError;
    procedure ResetCryptoState;
    procedure SetError(Category: TTlsErrorCategory; const MessageText: string;
      AlertCode: Integer = 0; SystemCode: Integer = 0);
    function BuildStatus(Success: Boolean): TTlsStatus;
    function ValidateConfig(out ErrorText: string): Boolean;
    function ComputeTranscriptSeed: TBytes;
    function ValidatePeerPolicy(out Category: TTlsErrorCategory; out ErrorText: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Initialize(const Config: TTlsConfig): TTlsStatus;
    function Handshake: TTlsStatus; overload;
    function Handshake(var SocketHandle: TSocketHandle): TTlsStatus; overload;
    function Read(var Buffer; Count: Integer): Integer;
    function Write(const Buffer; Count: Integer): Integer;
    function Shutdown: TTlsStatus;
    function PeerInfo: TTlsPeerInfo;
    function LastError: TTlsError;
    function HandshakeState: TTlsHandshakeState;
    procedure SetPeerCertificateChain(const Chain: TTlsCertificateChain);
  end;

implementation

constructor TTlsContext.Create;
begin
  inherited Create;
  FHandshake := TTlsHandshakeStateMachine.Create;
  FInitialized := False;
  FHasPeerChain := False;
  ClearPeerInfo;
  ResetCryptoState;
  ClearLastError;
end;

destructor TTlsContext.Destroy;
begin
  FHandshake.Free;
  inherited Destroy;
end;

procedure TTlsContext.ClearPeerInfo;
begin
  FPeerInfo.Subject := '';
  FPeerInfo.Issuer := '';
  FPeerInfo.AlpnProtocol := '';
  FPeerInfo.Version := tvUnknown;
  FPeerInfo.CipherSuite := 0;
end;

procedure TTlsContext.ClearLastError;
begin
  FLastError.Category := teNone;
  FLastError.MessageText := '';
  FLastError.AlertCode := 0;
  FLastError.SystemCode := 0;
end;

procedure TTlsContext.ResetCryptoState;
begin
  SetLength(FEarlySecret, 0);
  SetLength(FHandshakeSecret, 0);
  SetLength(FTranscriptHash, 0);
end;

procedure TTlsContext.SetError(Category: TTlsErrorCategory; const MessageText: string;
  AlertCode: Integer; SystemCode: Integer);
begin
  FLastError.Category := Category;
  FLastError.MessageText := MessageText;
  FLastError.AlertCode := AlertCode;
  FLastError.SystemCode := SystemCode;
end;

function TTlsContext.BuildStatus(Success: Boolean): TTlsStatus;
begin
  Result.Success := Success;
  Result.LastError := FLastError;
end;

function TTlsContext.ValidateConfig(out ErrorText: string): Boolean;
begin
  ErrorText := '';
  if FConfig.Mode = tmDisable then
  begin
    ErrorText := 'TLS mode "disable" is not allowed for ScratchBird connections.';
    Exit(False);
  end;
  if FConfig.MinVersion = tvUnknown then
  begin
    ErrorText := 'TLS minimum version must be explicitly configured.';
    Exit(False);
  end;
  if FConfig.MaxVersion = tvUnknown then
  begin
    ErrorText := 'TLS maximum version must be explicitly configured.';
    Exit(False);
  end;
  if Ord(FConfig.MinVersion) > Ord(FConfig.MaxVersion) then
  begin
    ErrorText := 'TLS minimum version cannot be greater than maximum version.';
    Exit(False);
  end;
  if (FConfig.Mode = tmVerifyFull) and (Trim(FConfig.ServerName) = '') then
  begin
    ErrorText := 'TLS verify-full mode requires a server name for hostname checks.';
    Exit(False);
  end;
  if (FConfig.RevocationPolicy = trpHardFail) and (Trim(FConfig.RootCAPath) = '') then
  begin
    ErrorText := 'hard-fail revocation policy requires an explicit root CA path.';
    Exit(False);
  end;
  Result := True;
end;

function BytesFromString(const Value: string): TBytes;
var
  Utf8Value: UTF8String;
  I: Integer;
begin
  Result := nil;
  Utf8Value := UTF8String(Value);
  SetLength(Result, Length(Utf8Value));
  for I := 1 to Length(Utf8Value) do
    Result[I - 1] := Byte(Utf8Value[I]);
end;

function TTlsContext.ComputeTranscriptSeed: TBytes;
var
  SeedInput: TBytes;
begin
  SeedInput := BytesFromString('scratchbird-native:' + LowerCase(FConfig.ServerName));
  Result := Sha256(SeedInput);
end;

function TTlsContext.ValidatePeerPolicy(out Category: TTlsErrorCategory; out ErrorText: string): Boolean;
var
  NowUtc: TDateTime;
begin
  Category := teNone;
  ErrorText := '';
  if (FConfig.Mode = tmAllow) or (FConfig.Mode = tmPrefer) then
    Exit(True);
  if not FHasPeerChain then
  begin
    Category := teNotImplemented;
    ErrorText := 'peer certificate parsing is not wired yet for native TLS.';
    Exit(False);
  end;
  NowUtc := Now;
  Result := ValidateCertificateChainPolicy(
    FPeerChain,
    FConfig.ServerName,
    FConfig.RevocationPolicy,
    NowUtc,
    Category,
    ErrorText
  );
end;

function TTlsContext.Initialize(const Config: TTlsConfig): TTlsStatus;
var
  ErrorText: string;
begin
  FConfig := Config;
  ClearPeerInfo;
  FHandshake.Reset;
  ResetCryptoState;
  ClearLastError;
  if not ValidateConfig(ErrorText) then
  begin
    SetError(teConfigError, ErrorText);
    FInitialized := False;
    Exit(BuildStatus(False));
  end;
  FInitialized := True;
  if FConfig.MaxVersion = tvTLS13 then
    FPeerInfo.Version := tvTLS13
  else if FConfig.MaxVersion = tvTLS12 then
    FPeerInfo.Version := tvTLS12;
  FEarlySecret := HkdfExtract(nil, nil);
  FTranscriptHash := ComputeTranscriptSeed;
  FHandshakeSecret := HkdfExtract(FEarlySecret, FTranscriptHash);
  Result := BuildStatus(True);
end;

function TTlsContext.Handshake: TTlsStatus;
var
  SocketHandle: TSocketHandle;
begin
  SocketHandle := INVALID_TLS_SOCKET_HANDLE;
  Result := Handshake(SocketHandle);
end;

function TTlsContext.Handshake(var SocketHandle: TSocketHandle): TTlsStatus;
var
  PolicyCategory: TTlsErrorCategory;
  PolicyError: string;
begin
  if SocketHandle = INVALID_TLS_SOCKET_HANDLE then
  begin
    // Native socket binding is still in progress; keep API shape for callers.
  end;

  if not FInitialized then
  begin
    SetError(teConfigError, 'Native TLS handshake requested before Initialize.');
    Exit(BuildStatus(False));
  end;

  if FHandshake.IsComplete then
  begin
    ClearLastError;
    Exit(BuildStatus(True));
  end;

  if FHandshake.State = hsIdle then
  begin
    try
      FHandshake.MarkClientHelloSent;
    except
      on E: ETlsHandshakeStateError do
      begin
        FHandshake.MarkError;
        SetError(teProtocolError, E.Message);
        Exit(BuildStatus(False));
      end;
    end;
  end;

  if not ValidatePeerPolicy(PolicyCategory, PolicyError) then
  begin
    FHandshake.MarkError;
    SetError(PolicyCategory, PolicyError);
    Exit(BuildStatus(False));
  end;

  FHandshake.MarkError;
  SetError(teNotImplemented,
    'Native TLS key exchange, certificate parsing, and record protection are still in progress.');
  Result := BuildStatus(False);
end;

function TTlsContext.Read(var Buffer; Count: Integer): Integer;
begin
  if Count < 0 then
  begin
    SetError(teConfigError, 'TLS read count cannot be negative.');
    Exit(-1);
  end;
  if not FHandshake.IsComplete then
  begin
    SetError(teHandshakeFailed, 'TLS read requested before handshake completion.');
    Exit(-1);
  end;
  Result := -1;
  SetError(teNotImplemented, 'Native TLS record decryption path is not implemented yet.');
end;

function TTlsContext.Write(const Buffer; Count: Integer): Integer;
begin
  if Count < 0 then
  begin
    SetError(teConfigError, 'TLS write count cannot be negative.');
    Exit(-1);
  end;
  if not FHandshake.IsComplete then
  begin
    SetError(teHandshakeFailed, 'TLS write requested before handshake completion.');
    Exit(-1);
  end;
  Result := -1;
  SetError(teNotImplemented, 'Native TLS record encryption path is not implemented yet.');
end;

function TTlsContext.Shutdown: TTlsStatus;
begin
  if FHandshake.State <> hsClosed then
    FHandshake.MarkClosed;
  FInitialized := False;
  ClearLastError;
  Result := BuildStatus(True);
end;

function TTlsContext.PeerInfo: TTlsPeerInfo;
begin
  Result := FPeerInfo;
end;

function TTlsContext.LastError: TTlsError;
begin
  Result := FLastError;
end;

function TTlsContext.HandshakeState: TTlsHandshakeState;
begin
  Result := FHandshake.State;
end;

procedure TTlsContext.SetPeerCertificateChain(const Chain: TTlsCertificateChain);
begin
  FPeerChain := Chain;
  FHasPeerChain := True;
end;

end.

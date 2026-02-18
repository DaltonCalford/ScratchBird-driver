{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Tls.Handshake;

{$mode delphi}
{$H+}

interface

uses
  SysUtils;

type
  TTlsHandshakeState = (
    hsIdle,
    hsClientHelloSent,
    hsServerHelloReceived,
    hsEncryptedExtensionsReceived,
    hsCertificateChainReceived,
    hsCertificateVerifyReceived,
    hsFinishedReceived,
    hsHandshakeComplete,
    hsClosed,
    hsError
  );

  ETlsHandshakeStateError = class(Exception);

  TTlsHandshakeStateMachine = class
  private
    FState: TTlsHandshakeState;
    procedure RequireState(Expected: TTlsHandshakeState; const MessageText: string);
  public
    constructor Create;
    procedure Reset;
    procedure MarkClientHelloSent;
    procedure MarkServerHelloReceived;
    procedure MarkEncryptedExtensionsReceived;
    procedure MarkCertificateChainReceived;
    procedure MarkCertificateVerifyReceived;
    procedure MarkFinishedReceived;
    procedure MarkClosed;
    procedure MarkError;
    function IsComplete: Boolean;
    property State: TTlsHandshakeState read FState;
  end;

implementation

constructor TTlsHandshakeStateMachine.Create;
begin
  inherited Create;
  Reset;
end;

procedure TTlsHandshakeStateMachine.Reset;
begin
  FState := hsIdle;
end;

procedure TTlsHandshakeStateMachine.RequireState(Expected: TTlsHandshakeState; const MessageText: string);
begin
  if FState <> Expected then
    raise ETlsHandshakeStateError.Create(MessageText);
end;

procedure TTlsHandshakeStateMachine.MarkClientHelloSent;
begin
  RequireState(hsIdle, 'TLS state violation: client hello can only be sent from idle state.');
  FState := hsClientHelloSent;
end;

procedure TTlsHandshakeStateMachine.MarkServerHelloReceived;
begin
  RequireState(hsClientHelloSent, 'TLS state violation: server hello received before client hello.');
  FState := hsServerHelloReceived;
end;

procedure TTlsHandshakeStateMachine.MarkEncryptedExtensionsReceived;
begin
  RequireState(hsServerHelloReceived, 'TLS state violation: encrypted extensions out of order.');
  FState := hsEncryptedExtensionsReceived;
end;

procedure TTlsHandshakeStateMachine.MarkCertificateChainReceived;
begin
  RequireState(hsEncryptedExtensionsReceived, 'TLS state violation: certificate chain out of order.');
  FState := hsCertificateChainReceived;
end;

procedure TTlsHandshakeStateMachine.MarkCertificateVerifyReceived;
begin
  RequireState(hsCertificateChainReceived, 'TLS state violation: certificate verify out of order.');
  FState := hsCertificateVerifyReceived;
end;

procedure TTlsHandshakeStateMachine.MarkFinishedReceived;
begin
  RequireState(hsCertificateVerifyReceived, 'TLS state violation: finished message out of order.');
  FState := hsFinishedReceived;
  FState := hsHandshakeComplete;
end;

procedure TTlsHandshakeStateMachine.MarkClosed;
begin
  FState := hsClosed;
end;

procedure TTlsHandshakeStateMachine.MarkError;
begin
  FState := hsError;
end;

function TTlsHandshakeStateMachine.IsComplete: Boolean;
begin
  Result := FState = hsHandshakeComplete;
end;

end.

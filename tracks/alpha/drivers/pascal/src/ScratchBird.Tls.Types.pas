{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Tls.Types;

{$mode delphi}
{$H+}

interface

uses
  SysUtils;

type
  TSocketHandle = PtrInt;

const
  INVALID_TLS_SOCKET_HANDLE = TSocketHandle(-1);

type
  TTlsMode = (tmDisable, tmAllow, tmPrefer, tmRequire, tmVerifyCA, tmVerifyFull);
  TTlsVersion = (tvUnknown, tvTLS12, tvTLS13);
  TTlsRevocationPolicy = (trpDisabled, trpSoftFail, trpHardFail);

  TTlsErrorCategory = (
    teNone,
    teHandshakeFailed,
    teCertificateInvalid,
    teHostnameMismatch,
    teIoError,
    teProtocolError,
    teConfigError,
    teNotImplemented
  );

  TTlsConfig = record
    Mode: TTlsMode;
    ServerName: string;
    RootCAPath: string;
    ClientCertPath: string;
    ClientKeyPath: string;
    ClientKeyPassword: string;
    MinVersion: TTlsVersion;
    MaxVersion: TTlsVersion;
    RevocationPolicy: TTlsRevocationPolicy;
  end;

  TTlsPeerInfo = record
    Subject: string;
    Issuer: string;
    AlpnProtocol: string;
    Version: TTlsVersion;
    CipherSuite: Cardinal;
  end;

  TTlsError = record
    Category: TTlsErrorCategory;
    MessageText: string;
    AlertCode: Integer;
    SystemCode: Integer;
  end;

  TTlsStatus = record
    Success: Boolean;
    LastError: TTlsError;
  end;

function DefaultTlsConfig: TTlsConfig;

implementation

function DefaultTlsConfig: TTlsConfig;
begin
  Result.Mode := tmRequire;
  Result.ServerName := '';
  Result.RootCAPath := '';
  Result.ClientCertPath := '';
  Result.ClientKeyPath := '';
  Result.ClientKeyPassword := '';
  Result.MinVersion := tvTLS13;
  Result.MaxVersion := tvTLS13;
  Result.RevocationPolicy := trpSoftFail;
end;

end.

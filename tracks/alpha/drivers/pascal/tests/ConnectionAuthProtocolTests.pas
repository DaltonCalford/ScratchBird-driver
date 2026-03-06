{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program ConnectionAuthProtocolTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  ScratchBird.Config,
  ScratchBird.Client,
  ScratchBird.Transport.Native,
  ScratchBird.Protocol;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(Value: Boolean; const MessageText: string);
begin
  if not Value then
    Fail(MessageText);
end;

procedure AssertContains(const Needle, Haystack, MessageText: string);
begin
  if Pos(Needle, Haystack) = 0 then
    Fail(MessageText + ': expected "' + Needle + '" in "' + Haystack + '"');
end;

procedure WriteUInt32LEAt(var Buffer: TBytes; Offset: Integer; Value: Cardinal);
begin
  Buffer[Offset] := Byte(Value and $FF);
  Buffer[Offset + 1] := Byte((Value shr 8) and $FF);
  Buffer[Offset + 2] := Byte((Value shr 16) and $FF);
  Buffer[Offset + 3] := Byte((Value shr 24) and $FF);
end;

procedure TestParseConfigRejectsUnsupportedProtocol;
begin
  try
    ParseConfig('scratchbird://user:pass@localhost:3092/db?protocol=postgresql');
    Fail('expected unsupported protocol parse failure');
  except
    on E: Exception do
      AssertContains('Only protocol=native is supported', E.Message, 'unsupported protocol error');
  end;
end;

procedure TestManagerProxyRequiresAuthTokenBeforeDial;
var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    try
      Client.Connect('scratchbird://user:pass@localhost:3092/db?front_door_mode=manager_proxy');
      Fail('expected manager_proxy token validation failure');
    except
      on E: Exception do
        AssertContains('manager_proxy mode requires manager_auth_token', E.Message, 'manager_proxy token error');
    end;
  finally
    Client.Free;
  end;
end;

procedure TestNativeTransportAllowsSslModeDisableAtConfigure;
var
  Transport: TNativeScratchBirdTransport;
  Config: TScratchBirdConfig;
begin
  Transport := TNativeScratchBirdTransport.Create;
  try
    Config := DefaultConfig;
    Config.SSLMode := 'disable';
    Transport.Configure(Config);
  finally
    Transport.Free;
  end;
end;

procedure TestDecodeHeaderRejectsOversizedPayload;
var
  Header: TBytes;
  MsgType: TScratchBirdMessageType;
  Flags: Byte;
  PayloadLength: Integer;
  Sequence: Cardinal;
  AttachmentId: TBytes;
  TxnId: UInt64;
begin
  SetLength(Header, HEADER_SIZE);
  FillChar(Header[0], HEADER_SIZE, 0);
  WriteUInt32LEAt(Header, 0, PROTOCOL_MAGIC);
  Header[4] := PROTOCOL_VERSION_MAJOR;
  Header[5] := PROTOCOL_VERSION_MINOR;
  Header[6] := MSG_READY;
  Header[7] := 0;
  WriteUInt32LEAt(Header, 8, Cardinal(MAX_MESSAGE_SIZE + 1));
  WriteUInt32LEAt(Header, 12, 99);

  AssertTrue(
    not DecodeHeader(Header, MsgType, Flags, PayloadLength, Sequence, AttachmentId, TxnId),
    'DecodeHeader should reject oversized payload length'
  );
end;

procedure TestParseAuthContinueRejectsTruncatedPayload;
var
  Payload: TBytes;
  Method, Stage: Byte;
  Data: TBytes;
begin
  SetLength(Payload, 8);
  FillChar(Payload[0], Length(Payload), 0);
  Payload[0] := AUTH_SCRAM_SHA256;
  Payload[1] := 1;
  WriteUInt32LEAt(Payload, 4, 5);
  try
    ParseAuthContinue(Payload, Method, Stage, Data);
    Fail('expected auth continue truncation failure');
  except
    on E: Exception do
      AssertContains('Auth continue truncated', E.Message, 'auth continue truncation error');
  end;
end;

begin
  try
    TestParseConfigRejectsUnsupportedProtocol;
    TestManagerProxyRequiresAuthTokenBeforeDial;
    TestNativeTransportAllowsSslModeDisableAtConfigure;
    TestDecodeHeaderRejectsOversizedPayload;
    TestParseAuthContinueRejectsTruncatedPayload;
    Writeln('ConnectionAuthProtocolTests: OK');
  except
    on E: Exception do
    begin
      Writeln('ConnectionAuthProtocolTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

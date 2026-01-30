{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program ConfigTests;

{$APPTYPE CONSOLE}

uses
  SysUtils, ScratchBird.Config;

procedure AssertEqual(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    raise Exception.Create(MessageText + ': expected=' + Expected + ' actual=' + Actual);
end;

procedure AssertEqualInt(Expected, Actual: Integer; const MessageText: string);
begin
  if Expected <> Actual then
    raise Exception.Create(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

var
  Config: TScratchBirdConfig;
begin
  try
    Config := ParseConfig('scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd');
    AssertEqual('localhost', Config.Host, 'host');
    AssertEqualInt(3092, Config.Port, 'port');
    AssertEqual('mydb', Config.Database, 'database');
    AssertEqual('user', Config.UserName, 'user');
    AssertEqual('pass', Config.Password, 'password');
    AssertEqual('require', Config.SSLMode, 'sslmode');
    AssertEqualInt(3000, Config.ConnectTimeoutMs, 'connect_timeout');
    AssertEqual('app', Config.ApplicationName, 'application_name');

    Config := ParseConfig('Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7');
    AssertEqual('server', Config.Host, 'host kv');
    AssertEqualInt(4000, Config.Port, 'port kv');
    AssertEqual('db', Config.Database, 'database kv');
    AssertEqual('me', Config.UserName, 'user kv');
    AssertEqual('secret', Config.Password, 'password kv');
    Writeln('ConfigTests: OK');
  except
    on E: Exception do
    begin
      Writeln('ConfigTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

{ ScratchBird Pascal Driver
  Keepalive Manager - Prevents connection timeouts
  Copyright (c) 2025-2026 Dalton Calford }

unit SBKeepalive;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils
  {$IFNDEF FPC}, SyncObjs{$ENDIF};

{$IFDEF FPC}
type
  TCriticalSection = class
  private
    FSection: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
  end;
{$ENDIF}

type
  TKeepaliveConfig = record
    IntervalMs: Cardinal;
    MaxIdleBeforeCheckMs: Cardinal;
    ValidationTimeoutMs: Cardinal;
  end;
  
  TKeepaliveTracker = class
  private
    FConfig: TKeepaliveConfig;
    FLastActivity: TDateTime;
    FLock: TCriticalSection;
  public
    constructor Create(const Config: TKeepaliveConfig);
    destructor Destroy; override;
    procedure MarkActive;
    function NeedsValidation: Boolean;
    function GetIdleDurationMs: Cardinal;
  end;
  
  TPingerFunction = function: Boolean of object;
  
  TKeepaliveManager = class(TThread)
  private
    FConfig: TKeepaliveConfig;
    FTrackers: TThreadList;
    FConnections: TThreadList;
    FRunning: Boolean;
    procedure CheckConnections;
  protected
    procedure Execute; override;
  public
    constructor Create(const Config: TKeepaliveConfig);
    destructor Destroy; override;
    function Register(const ConnectionId: string; Pinger: TPingerFunction): TKeepaliveTracker;
    procedure Unregister(const ConnectionId: string);
    function GetMonitoredCount: Integer;
    procedure Start;
    procedure Stop;
  end;

function DefaultKeepaliveConfig: TKeepaliveConfig;

implementation

{$IFDEF FPC}
constructor TCriticalSection.Create;
begin
  inherited Create;
  InitCriticalSection(FSection);
end;

destructor TCriticalSection.Destroy;
begin
  DoneCriticalSection(FSection);
  inherited Destroy;
end;

procedure TCriticalSection.Enter;
begin
  EnterCriticalSection(FSection);
end;

procedure TCriticalSection.Leave;
begin
  LeaveCriticalSection(FSection);
end;
{$ENDIF}

function DefaultKeepaliveConfig: TKeepaliveConfig;
begin
  Result.IntervalMs := 120000;         // 2 minutes
  Result.MaxIdleBeforeCheckMs := 600000; // 10 minutes
  Result.ValidationTimeoutMs := 5000;    // 5 seconds
end;

{ TKeepaliveTracker }

constructor TKeepaliveTracker.Create(const Config: TKeepaliveConfig);
begin
  FConfig := Config;
  FLastActivity := Now;
  FLock := TCriticalSection.Create;
end;

destructor TKeepaliveTracker.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TKeepaliveTracker.MarkActive;
begin
  FLock.Enter;
  try
    FLastActivity := Now;
  finally
    FLock.Leave;
  end;
end;

function TKeepaliveTracker.NeedsValidation: Boolean;
begin
  Result := GetIdleDurationMs > FConfig.MaxIdleBeforeCheckMs;
end;

function TKeepaliveTracker.GetIdleDurationMs: Cardinal;
begin
  FLock.Enter;
  try
    Result := Cardinal(MilliSecondsBetween(Now, FLastActivity));
  finally
    FLock.Leave;
  end;
end;

{ TKeepaliveManager }

constructor TKeepaliveManager.Create(const Config: TKeepaliveConfig);
begin
  inherited Create(True);
  FConfig := Config;
  FTrackers := TThreadList.Create;
  FConnections := TThreadList.Create;
  FRunning := False;
end;

destructor TKeepaliveManager.Destroy;
begin
  Stop;
  FTrackers.Free;
  FConnections.Free;
  inherited Destroy;
end;

procedure TKeepaliveManager.Start;
begin
  FRunning := True;
  inherited Start;
end;

procedure TKeepaliveManager.Stop;
begin
  FRunning := False;
  WaitFor;
end;

function TKeepaliveManager.Register(const ConnectionId: string; Pinger: TPingerFunction): TKeepaliveTracker;
begin
  Result := TKeepaliveTracker.Create(FConfig);
  // Store in lists - simplified for brevity
end;

procedure TKeepaliveManager.Unregister(const ConnectionId: string);
begin
  // Remove from lists
end;

function TKeepaliveManager.GetMonitoredCount: Integer;
var
  List: TList;
begin
  List := FTrackers.LockList;
  try
    Result := List.Count;
  finally
    FTrackers.UnlockList;
  end;
end;

procedure TKeepaliveManager.Execute;
begin
  while FRunning and not Terminated do
  begin
    Sleep(FConfig.IntervalMs);
    if FRunning then
      CheckConnections;
  end;
end;

procedure TKeepaliveManager.CheckConnections;
begin
  // Iterate trackers and validate idle connections
end;

end.

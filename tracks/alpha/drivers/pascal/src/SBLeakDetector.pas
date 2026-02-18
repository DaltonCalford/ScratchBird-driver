{ ScratchBird Pascal Driver - Connection Leak Detector
  Copyright (c) 2025-2026 Dalton Calford }

unit SBLeakDetector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils;

type
  TLeakLogLevel = (llDebug, llWarn, llError);
  
  TLeakDetectionConfig = record
    ThresholdMs: Cardinal;
    CaptureStackTrace: Boolean;
    CheckIntervalMs: Cardinal;
    LogLevel: TLeakLogLevel;
  end;
  
  TCheckoutInfo = class
  public
    CheckoutTime: TDateTime;
    ThreadId: Cardinal;
    StackTrace: string;
    Metadata: TStringList;
    constructor Create(CaptureStackTrace: Boolean; const Meta: array of string);
    destructor Destroy; override;
    function GetHeldDurationMs: Cardinal;
  end;
  
  TLeakDetector = class(TThread)
  private
    FConfig: TLeakDetectionConfig;
    FCheckouts: TThreadList;
    FRunning: Boolean;
    procedure CheckLeaks;
    procedure LogLeak(const ConnId: string; Info: TCheckoutInfo);
  protected
    procedure Execute; override;
  public
    constructor Create(const Config: TLeakDetectionConfig);
    destructor Destroy; override;
    procedure Checkout(const ConnectionId: string; const Metadata: array of string);
    procedure Checkin(const ConnectionId: string);
    function GetActiveCount: Integer;
    procedure Start;
    procedure Stop;
  end;

function DefaultLeakDetectionConfig: TLeakDetectionConfig;

implementation

{$IFDEF FPC}
function GetStackTraceInfo: string;
begin
  Result := '';
end;
{$ENDIF}

function DefaultLeakDetectionConfig: TLeakDetectionConfig;
begin
  Result.ThresholdMs := 30000;      // 30 seconds
  Result.CaptureStackTrace := False;
  Result.CheckIntervalMs := 10000;  // 10 seconds
  Result.LogLevel := llWarn;
end;

{ TCheckoutInfo }

constructor TCheckoutInfo.Create(CaptureStackTrace: Boolean; const Meta: array of string);
begin
  CheckoutTime := Now;
  ThreadId := ThreadID;
  Metadata := TStringList.Create;
  if CaptureStackTrace then
    StackTrace := GetStackTraceInfo
  else
    StackTrace := '';
end;

destructor TCheckoutInfo.Destroy;
begin
  Metadata.Free;
  inherited Destroy;
end;

function TCheckoutInfo.GetHeldDurationMs: Cardinal;
begin
  Result := Cardinal(MilliSecondsBetween(Now, CheckoutTime));
end;

{ TLeakDetector }

constructor TLeakDetector.Create(const Config: TLeakDetectionConfig);
begin
  inherited Create(True);
  FConfig := Config;
  FCheckouts := TThreadList.Create;
  FRunning := False;
end;

destructor TLeakDetector.Destroy;
begin
  Stop;
  FCheckouts.Free;
  inherited Destroy;
end;

procedure TLeakDetector.Start;
begin
  FRunning := True;
  inherited Start;
end;

procedure TLeakDetector.Stop;
begin
  FRunning := False;
  WaitFor;
end;

procedure TLeakDetector.Checkout(const ConnectionId: string; const Metadata: array of string);
var
  Info: TCheckoutInfo;
begin
  Info := TCheckoutInfo.Create(FConfig.CaptureStackTrace, Metadata);
  // Add to list
end;

procedure TLeakDetector.Checkin(const ConnectionId: string);
begin
  // Remove from list
end;

function TLeakDetector.GetActiveCount: Integer;
var
  List: TList;
begin
  List := FCheckouts.LockList;
  try
    Result := List.Count;
  finally
    FCheckouts.UnlockList;
  end;
end;

procedure TLeakDetector.Execute;
begin
  while FRunning and not Terminated do
  begin
    Sleep(FConfig.CheckIntervalMs);
    if FRunning then
      CheckLeaks;
  end;
end;

procedure TLeakDetector.CheckLeaks;
begin
  // Check for leaks
end;

procedure TLeakDetector.LogLeak(const ConnId: string; Info: TCheckoutInfo);
begin
  WriteLn('POSSIBLE CONNECTION LEAK: conn=', ConnId, ', held=', Info.GetHeldDurationMs, 'ms');
end;

end.

{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
program ResourceResilienceTests;

{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  SBKeepalive,
  SBLeakDetector;

type
  TPingerProbe = class
  private
    FCalls: Integer;
    FHealthy: Boolean;
  public
    constructor Create(Healthy: Boolean = True);
    function Ping: Boolean;
    property Calls: Integer read FCalls;
  end;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(Value: Boolean; const MessageText: string);
begin
  if not Value then
    Fail(MessageText);
end;

procedure AssertFalse(Value: Boolean; const MessageText: string);
begin
  if Value then
    Fail(MessageText);
end;

procedure AssertEqualInt(Expected, Actual: Integer; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected=' + IntToStr(Expected) + ' actual=' + IntToStr(Actual));
end;

procedure AssertEqualString(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    Fail(MessageText + ': expected="' + Expected + '" actual="' + Actual + '"');
end;

constructor TPingerProbe.Create(Healthy: Boolean);
begin
  inherited Create;
  FCalls := 0;
  FHealthy := Healthy;
end;

function TPingerProbe.Ping: Boolean;
begin
  Inc(FCalls);
  Result := FHealthy;
end;

procedure TestKeepaliveTrackerValidationWindow;
var
  Config: TKeepaliveConfig;
  Tracker: TKeepaliveTracker;
begin
  Config := DefaultKeepaliveConfig;
  Config.MaxIdleBeforeCheckMs := 50;

  Tracker := TKeepaliveTracker.Create(Config);
  try
    AssertFalse(Tracker.NeedsValidation, 'new tracker should not require validation');
    Sleep(80);
    AssertTrue(Tracker.NeedsValidation, 'idle tracker should require validation');
    Tracker.MarkActive;
    AssertFalse(Tracker.NeedsValidation, 'mark active should reset idle window');
  finally
    Tracker.Free;
  end;
end;

procedure TestKeepaliveManagerRegisterUnregisterAndPing;
var
  Config: TKeepaliveConfig;
  Manager: TKeepaliveManager;
  ProbeA, ProbeB: TPingerProbe;
  TrackerA, TrackerB: TKeepaliveTracker;
begin
  Config := DefaultKeepaliveConfig;
  Config.IntervalMs := 10;
  Config.MaxIdleBeforeCheckMs := 0;

  Manager := TKeepaliveManager.Create(Config);
  ProbeA := TPingerProbe.Create(True);
  ProbeB := TPingerProbe.Create(True);
  try
    TrackerA := Manager.Register('conn-1', ProbeA.Ping);
    AssertTrue(TrackerA <> nil, 'register should return tracker');
    AssertEqualInt(1, Manager.GetMonitoredCount, 'register should increase monitored count');

    TrackerB := Manager.Register('conn-1', ProbeB.Ping);
    AssertTrue(TrackerA = TrackerB, 'duplicate register should reuse tracker');
    AssertEqualInt(1, Manager.GetMonitoredCount, 'duplicate register should not duplicate entry count');

    Manager.Start;
    Sleep(80);
    AssertTrue(ProbeB.Calls > 0, 'manager should invoke replacement pinger for idle tracker');

    Manager.Unregister('conn-1');
    AssertEqualInt(0, Manager.GetMonitoredCount, 'unregister should remove monitored entry');
    Manager.Stop;
  finally
    ProbeB.Free;
    ProbeA.Free;
    Manager.Free;
  end;
end;

procedure TestCheckoutInfoCapturesMetadataPairs;
var
  Info: TCheckoutInfo;
begin
  Info := TCheckoutInfo.Create(False, ['driver', 'pascal', 'role', 'writer', 'tail']);
  try
    AssertEqualString('pascal', Info.Metadata.Values['driver'], 'metadata driver value');
    AssertEqualString('writer', Info.Metadata.Values['role'], 'metadata role value');
    AssertEqualString('tail', Info.Metadata.Values['meta_2'], 'odd metadata tail value');
  finally
    Info.Free;
  end;
end;

procedure TestLeakDetectorCheckoutCheckinAndReplace;
var
  Config: TLeakDetectionConfig;
  Detector: TLeakDetector;
begin
  Config := DefaultLeakDetectionConfig;
  Detector := TLeakDetector.Create(Config);
  try
    Detector.Checkout('conn-a', ['driver', 'pascal']);
    AssertEqualInt(1, Detector.GetActiveCount, 'first checkout should register active connection');

    Detector.Checkout('conn-a', ['driver', 'pascal-updated']);
    AssertEqualInt(1, Detector.GetActiveCount, 'duplicate checkout should replace entry');

    Detector.Checkout('conn-b', []);
    AssertEqualInt(2, Detector.GetActiveCount, 'second checkout should increase active count');

    Detector.Checkin('missing');
    AssertEqualInt(2, Detector.GetActiveCount, 'missing checkin should be ignored');

    Detector.Checkin('conn-a');
    AssertEqualInt(1, Detector.GetActiveCount, 'checkin should remove matching entry');

    Detector.Checkin('conn-b');
    AssertEqualInt(0, Detector.GetActiveCount, 'all checked-in entries should clear active count');
  finally
    Detector.Free;
  end;
end;

procedure TestLeakDetectorBackgroundLifecycle;
var
  Config: TLeakDetectionConfig;
  Detector: TLeakDetector;
begin
  Config := DefaultLeakDetectionConfig;
  Config.ThresholdMs := 0;
  Config.CheckIntervalMs := 5;

  Detector := TLeakDetector.Create(Config);
  try
    Detector.Start;
    Detector.Checkout('conn-z', ['driver', 'pascal']);
    Sleep(20);
    Detector.Checkin('conn-z');
    Detector.Stop;
    Detector.Stop;
    AssertEqualInt(0, Detector.GetActiveCount, 'background lifecycle should not leak checkout state');
  finally
    Detector.Free;
  end;
end;

begin
  try
    TestKeepaliveTrackerValidationWindow;
    TestKeepaliveManagerRegisterUnregisterAndPing;
    TestCheckoutInfoCapturesMetadataPairs;
    TestLeakDetectorCheckoutCheckinAndReplace;
    TestLeakDetectorBackgroundLifecycle;
    Writeln('ResourceResilienceTests: OK');
  except
    on E: Exception do
    begin
      Writeln('ResourceResilienceTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

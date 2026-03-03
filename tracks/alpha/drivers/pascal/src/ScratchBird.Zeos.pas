{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Zeos;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, Classes, Variants,
  ScratchBird.Client, ScratchBird.Common, ScratchBird.Sql;

type
  TScratchBirdZConnection = class(TComponent)
  private
    FClient: TScratchBirdClient;
    FDsn: string;
    FConnected: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    property Connected: Boolean read FConnected;
    property Dsn: string read FDsn write FDsn;
    property Client: TScratchBirdClient read FClient;
  end;

  TScratchBirdZQuery = class(TComponent)
  private
    FConnection: TScratchBirdZConnection;
    FSQL: TStringList;
    FParams: TScratchBirdParams;
    FResult: TScratchBirdQueryResult;
    FPreparedSql: string;
    FPreparedParams: TArray<TScratchBirdParamInput>;
    FPrepared: Boolean;
    function BuildSql(out Ordered: TArray<TScratchBirdParamInput>): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Prepare;
    procedure Open;
    procedure ExecSQL;
    procedure Next;
    function Eof: Boolean;
    function FieldByName(const Name: string): Variant;
    function RowsAffected: Int64;
    function ParamByName(const Name: string): TScratchBirdParam;
    property SQL: TStringList read FSQL;
    property Params: TScratchBirdParams read FParams;
    property Connection: TScratchBirdZConnection read FConnection write FConnection;
  end;

implementation

constructor TScratchBirdZConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClient := TScratchBirdClient.Create;
end;

destructor TScratchBirdZConnection.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

procedure TScratchBirdZConnection.Connect;
begin
  if FConnected then
    Exit;
  FClient.Connect(FDsn);
  FConnected := True;
end;

procedure TScratchBirdZConnection.Disconnect;
begin
  if not FConnected then
    Exit;
  FClient.Disconnect;
  FConnected := False;
end;

procedure TScratchBirdZConnection.StartTransaction;
begin
  FClient.BeginTransaction;
end;

procedure TScratchBirdZConnection.Commit;
begin
  FClient.Commit;
end;

procedure TScratchBirdZConnection.Rollback;
begin
  FClient.Rollback;
end;

constructor TScratchBirdZQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  FParams := TScratchBirdParams.Create;
  FPrepared := False;
end;

destructor TScratchBirdZQuery.Destroy;
begin
  FParams.Free;
  FSQL.Free;
  inherited Destroy;
end;

function TScratchBirdZQuery.BuildSql(out Ordered: TArray<TScratchBirdParamInput>): string;
var
  Names: array of string;
  Values: array of TScratchBirdParamInput;
  I: Integer;
begin
  if FParams.Count = 0 then
  begin
    Ordered := nil;
    Exit(FSQL.Text);
  end;
  SetLength(Names, FParams.Count);
  SetLength(Values, FParams.Count);
  for I := 0 to FParams.Count - 1 do
  begin
    Names[I] := FParams[I].Name;
    Values[I].Value := FParams[I].Value;
    Values[I].Obj := FParams[I].ObjectValue;
  end;
  if (Pos('@', FSQL.Text) > 0) or (Pos(':', FSQL.Text) > 0) then
    Result := NormalizeNamedSql(FSQL.Text, Names, Values, Ordered)
  else
    Result := NormalizePositionalSql(FSQL.Text, Values, Ordered);
end;

procedure TScratchBirdZQuery.Prepare;
var
  Ordered: TArray<TScratchBirdParamInput>;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  FPreparedSql := BuildSql(Ordered);
  FPreparedParams := Ordered;
  FPrepared := True;
end;

procedure TScratchBirdZQuery.Open;
var
  Ordered: TArray<TScratchBirdParamInput>;
  SqlText: string;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  if FPrepared then
  begin
    SqlText := FPreparedSql;
    Ordered := Copy(FPreparedParams);
  end
  else
    SqlText := BuildSql(Ordered);
  FResult := TScratchBirdQueryResult.Create(FConnection.Client.ExecuteQueryParams(SqlText, Ordered));
  FResult.Next;
end;

procedure TScratchBirdZQuery.ExecSQL;
var
  Ordered: TArray<TScratchBirdParamInput>;
  SqlText: string;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  if FPrepared then
  begin
    SqlText := FPreparedSql;
    Ordered := Copy(FPreparedParams);
  end
  else
    SqlText := BuildSql(Ordered);
  FConnection.Client.ExecSQLParams(SqlText, Ordered);
end;

procedure TScratchBirdZQuery.Next;
begin
  if Assigned(FResult) then
    FResult.Next;
end;

function TScratchBirdZQuery.Eof: Boolean;
begin
  Result := (FResult = nil) or FResult.Eof;
end;

function TScratchBirdZQuery.FieldByName(const Name: string): Variant;
begin
  if FResult = nil then
    Result := Null
  else
    Result := FResult.FieldByName(Name);
end;

function TScratchBirdZQuery.RowsAffected: Int64;
begin
  if FResult = nil then
    Result := 0
  else
    Result := FResult.RowsAffected;
end;

function TScratchBirdZQuery.ParamByName(const Name: string): TScratchBirdParam;
begin
  Result := FParams.ParamByName(Name);
end;

end.

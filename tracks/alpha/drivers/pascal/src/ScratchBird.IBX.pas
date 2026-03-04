{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.IBX;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, Classes, Variants,
  ScratchBird.Client, ScratchBird.Common, ScratchBird.Sql;

type
  TScratchBirdIBDatabase = class(TComponent)
  private
    FClient: TScratchBirdClient;
    FDsn: string;
    FConnected: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure ExecSQLParams(const Sql: string; const Params: array of TScratchBirdParamInput); virtual;
    function ExecuteQueryParams(const Sql: string; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream; virtual;
    function GetSchema(const CollectionName: string = 'tables'): TScratchBirdResultStream;
    property Connected: Boolean read FConnected;
    property Dsn: string read FDsn write FDsn;
    property Client: TScratchBirdClient read FClient;
  end;

  TScratchBirdIBQuery = class(TComponent)
  private
    FDatabase: TScratchBirdIBDatabase;
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
    function ParamByName(const Name: string): TScratchBirdParam;
    property SQL: TStringList read FSQL;
    property Params: TScratchBirdParams read FParams;
    property Database: TScratchBirdIBDatabase read FDatabase write FDatabase;
  end;

implementation

constructor TScratchBirdIBDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClient := TScratchBirdClient.Create;
end;

destructor TScratchBirdIBDatabase.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

procedure TScratchBirdIBDatabase.Open;
begin
  if FConnected then
    Exit;
  FClient.Connect(FDsn);
  FConnected := True;
end;

procedure TScratchBirdIBDatabase.Close;
begin
  if not FConnected then
    Exit;
  FClient.Disconnect;
  FConnected := False;
end;

procedure TScratchBirdIBDatabase.StartTransaction;
begin
  FClient.BeginTransaction;
end;

procedure TScratchBirdIBDatabase.Commit;
begin
  FClient.Commit;
end;

procedure TScratchBirdIBDatabase.Rollback;
begin
  FClient.Rollback;
end;

procedure TScratchBirdIBDatabase.ExecSQLParams(const Sql: string; const Params: array of TScratchBirdParamInput);
begin
  FClient.ExecSQLParams(Sql, Params);
end;

function TScratchBirdIBDatabase.ExecuteQueryParams(const Sql: string; const Params: array of TScratchBirdParamInput): TScratchBirdResultStream;
begin
  Result := FClient.ExecuteQueryParams(Sql, Params);
end;

function TScratchBirdIBDatabase.GetSchema(const CollectionName: string): TScratchBirdResultStream;
begin
  Result := FClient.GetSchema(CollectionName);
end;

constructor TScratchBirdIBQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  FParams := TScratchBirdParams.Create;
  FPrepared := False;
end;

destructor TScratchBirdIBQuery.Destroy;
begin
  FParams.Free;
  FSQL.Free;
  inherited Destroy;
end;

function TScratchBirdIBQuery.BuildSql(out Ordered: TArray<TScratchBirdParamInput>): string;
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

procedure TScratchBirdIBQuery.Prepare;
var
  Ordered: TArray<TScratchBirdParamInput>;
begin
  if FDatabase = nil then
    raise Exception.Create('Database not assigned');
  FPreparedSql := BuildSql(Ordered);
  FPreparedParams := Ordered;
  FPrepared := True;
end;

procedure TScratchBirdIBQuery.Open;
var
  Ordered: TArray<TScratchBirdParamInput>;
  SqlText: string;
begin
  if FDatabase = nil then
    raise Exception.Create('Database not assigned');
  if FPrepared then
  begin
    SqlText := FPreparedSql;
    Ordered := Copy(FPreparedParams);
  end
  else
    SqlText := BuildSql(Ordered);
  FResult := TScratchBirdQueryResult.Create(FDatabase.ExecuteQueryParams(SqlText, Ordered));
  FResult.Next;
end;

procedure TScratchBirdIBQuery.ExecSQL;
var
  Ordered: TArray<TScratchBirdParamInput>;
  SqlText: string;
begin
  if FDatabase = nil then
    raise Exception.Create('Database not assigned');
  if FPrepared then
  begin
    SqlText := FPreparedSql;
    Ordered := Copy(FPreparedParams);
  end
  else
    SqlText := BuildSql(Ordered);
  FDatabase.ExecSQLParams(SqlText, Ordered);
end;

procedure TScratchBirdIBQuery.Next;
begin
  if Assigned(FResult) then
    FResult.Next;
end;

function TScratchBirdIBQuery.Eof: Boolean;
begin
  Result := (FResult = nil) or FResult.Eof;
end;

function TScratchBirdIBQuery.FieldByName(const Name: string): Variant;
begin
  if FResult = nil then
    Result := Null
  else
    Result := FResult.FieldByName(Name);
end;

function TScratchBirdIBQuery.ParamByName(const Name: string): TScratchBirdParam;
begin
  Result := FParams.ParamByName(Name);
end;

end.

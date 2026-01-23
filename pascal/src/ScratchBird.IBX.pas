unit ScratchBird.IBX;

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

constructor TScratchBirdIBQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  FParams := TScratchBirdParams.Create;
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
begin
end;

procedure TScratchBirdIBQuery.Open;
var
  Ordered: TArray<TScratchBirdParamInput>;
  SqlText: string;
begin
  if FDatabase = nil then
    raise Exception.Create('Database not assigned');
  SqlText := BuildSql(Ordered);
  FResult := TScratchBirdQueryResult.Create(FDatabase.Client.ExecuteQueryParams(SqlText, Ordered));
  FResult.Next;
end;

procedure TScratchBirdIBQuery.ExecSQL;
var
  Ordered: TArray<TScratchBirdParamInput>;
  SqlText: string;
begin
  if FDatabase = nil then
    raise Exception.Create('Database not assigned');
  SqlText := BuildSql(Ordered);
  FDatabase.Client.ExecSQLParams(SqlText, Ordered);
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

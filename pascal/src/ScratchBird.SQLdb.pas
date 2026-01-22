unit ScratchBird.SQLdb;

interface

uses
  SysUtils, Classes, Variants,
  ScratchBird.Client, ScratchBird.Common, ScratchBird.Sql;

type
  TScratchBirdSQLConnection = class(TComponent)
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

  TScratchBirdSQLQuery = class(TComponent)
  private
    FConnection: TScratchBirdSQLConnection;
    FSQL: TStringList;
    FParams: TScratchBirdParams;
    FResult: TScratchBirdQueryResult;
    function BuildSql: string;
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
    property Connection: TScratchBirdSQLConnection read FConnection write FConnection;
  end;

implementation

constructor TScratchBirdSQLConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClient := TScratchBirdClient.Create;
end;

destructor TScratchBirdSQLConnection.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

procedure TScratchBirdSQLConnection.Open;
begin
  if FConnected then
    Exit;
  FClient.Connect(FDsn);
  FConnected := True;
end;

procedure TScratchBirdSQLConnection.Close;
begin
  if not FConnected then
    Exit;
  FClient.Disconnect;
  FConnected := False;
end;

procedure TScratchBirdSQLConnection.StartTransaction;
begin
  FClient.BeginTransaction;
end;

procedure TScratchBirdSQLConnection.Commit;
begin
  FClient.Commit;
end;

procedure TScratchBirdSQLConnection.Rollback;
begin
  FClient.Rollback;
end;

constructor TScratchBirdSQLQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  FParams := TScratchBirdParams.Create;
end;

destructor TScratchBirdSQLQuery.Destroy;
begin
  FParams.Free;
  FSQL.Free;
  inherited Destroy;
end;

function TScratchBirdSQLQuery.BuildSql: string;
var
  Names: array of string;
  Values: array of Variant;
  I: Integer;
begin
  if FParams.Count = 0 then
    Exit(FSQL.Text);
  SetLength(Names, FParams.Count);
  SetLength(Values, FParams.Count);
  for I := 0 to FParams.Count - 1 do
  begin
    Names[I] := FParams[I].Name;
    Values[I] := FParams[I].Value;
  end;
  if (Pos('@', FSQL.Text) > 0) or (Pos(':', FSQL.Text) > 0) then
    Result := SubstituteNamedSql(FSQL.Text, Names, Values)
  else
    Result := SubstituteSql(FSQL.Text, Values);
end;

procedure TScratchBirdSQLQuery.Prepare;
begin
end;

procedure TScratchBirdSQLQuery.Open;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  FResult := TScratchBirdQueryResult.Create(FConnection.Client.ExecuteQuery(BuildSql));
  FResult.Next;
end;

procedure TScratchBirdSQLQuery.ExecSQL;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  FConnection.Client.ExecSQL(BuildSql);
end;

procedure TScratchBirdSQLQuery.Next;
begin
  if Assigned(FResult) then
    FResult.Next;
end;

function TScratchBirdSQLQuery.Eof: Boolean;
begin
  Result := (FResult = nil) or FResult.Eof;
end;

function TScratchBirdSQLQuery.FieldByName(const Name: string): Variant;
begin
  if FResult = nil then
    Result := Null
  else
    Result := FResult.FieldByName(Name);
end;

function TScratchBirdSQLQuery.RowsAffected: Int64;
begin
  if FResult = nil then
    Result := 0
  else
    Result := FResult.RowsAffected;
end;

function TScratchBirdSQLQuery.ParamByName(const Name: string): TScratchBirdParam;
begin
  Result := FParams.ParamByName(Name);
end;

end.

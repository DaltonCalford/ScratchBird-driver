unit ScratchBird.FireDAC;

interface

uses
  SysUtils, Classes, Variants,
  ScratchBird.Client, ScratchBird.Common, ScratchBird.Sql;

type
  TScratchBirdFDConnection = class(TComponent)
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
    procedure ExecSQL(const Sql: string);
    property Connected: Boolean read FConnected;
    property Dsn: string read FDsn write FDsn;
    property Client: TScratchBirdClient read FClient;
  end;

  TScratchBirdFDQuery = class(TComponent)
  private
    FConnection: TScratchBirdFDConnection;
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
    property Connection: TScratchBirdFDConnection read FConnection write FConnection;
  end;

implementation

constructor TScratchBirdFDConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClient := TScratchBirdClient.Create;
end;

destructor TScratchBirdFDConnection.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

procedure TScratchBirdFDConnection.Open;
begin
  if FConnected then
    Exit;
  FClient.Connect(FDsn);
  FConnected := True;
end;

procedure TScratchBirdFDConnection.Close;
begin
  if not FConnected then
    Exit;
  FClient.Disconnect;
  FConnected := False;
end;

procedure TScratchBirdFDConnection.StartTransaction;
begin
  FClient.BeginTransaction;
end;

procedure TScratchBirdFDConnection.Commit;
begin
  FClient.Commit;
end;

procedure TScratchBirdFDConnection.Rollback;
begin
  FClient.Rollback;
end;

procedure TScratchBirdFDConnection.ExecSQL(const Sql: string);
begin
  FClient.ExecSQL(Sql);
end;

constructor TScratchBirdFDQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  FParams := TScratchBirdParams.Create;
end;

destructor TScratchBirdFDQuery.Destroy;
begin
  FParams.Free;
  FSQL.Free;
  inherited Destroy;
end;

procedure TScratchBirdFDQuery.Prepare;
begin
end;

procedure TScratchBirdFDQuery.Open;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  FResult := TScratchBirdQueryResult.Create(FConnection.Client.ExecuteQuery(BuildSql));
  FResult.Next;
end;

procedure TScratchBirdFDQuery.ExecSQL;
begin
  if FConnection = nil then
    raise Exception.Create('Connection not assigned');
  FConnection.Client.ExecSQL(BuildSql);
end;

procedure TScratchBirdFDQuery.Next;
begin
  if Assigned(FResult) then
    FResult.Next;
end;

function TScratchBirdFDQuery.Eof: Boolean;
begin
  Result := (FResult = nil) or FResult.Eof;
end;

function TScratchBirdFDQuery.FieldByName(const Name: string): Variant;
begin
  if FResult = nil then
    Result := Null
  else
    Result := FResult.FieldByName(Name);
end;

function TScratchBirdFDQuery.RowsAffected: Int64;
begin
  if FResult = nil then
    Result := 0
  else
    Result := FResult.RowsAffected;
end;

function TScratchBirdFDQuery.ParamByName(const Name: string): TScratchBirdParam;
begin
  Result := FParams.ParamByName(Name);
end;

function TScratchBirdFDQuery.BuildSql: string;
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

end.

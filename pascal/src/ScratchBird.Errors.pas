unit ScratchBird.Errors;

interface

uses
  SysUtils;

type
  EScratchBirdError = class(Exception)
  public
    SQLState: string;
    Detail: string;
    Hint: string;
    constructor CreateWithInfo(const Msg, ASQLState, ADetail, AHint: string);
  end;

  EScratchbirdWarning = class(EScratchBirdError);
  EScratchbirdNoData = class(EScratchBirdError);
  EScratchbirdConnectionError = class(EScratchBirdError);
  EScratchbirdNotSupported = class(EScratchBirdError);
  EScratchbirdDataError = class(EScratchBirdError);
  EScratchbirdIntegrityError = class(EScratchBirdError);
  EScratchbirdAuthError = class(EScratchBirdError);
  EScratchbirdTransactionError = class(EScratchBirdError);
  EScratchbirdSyntaxError = class(EScratchBirdError);
  EScratchbirdResourceError = class(EScratchBirdError);
  EScratchbirdLimitError = class(EScratchBirdError);
  EScratchbirdOperatorInterventionError = class(EScratchBirdError);
  EScratchbirdSystemError = class(EScratchBirdError);
  EScratchbirdInternalError = class(EScratchBirdError);

function MapSqlState(const SQLState: string; const Msg, Detail, Hint: string): EScratchBirdError;

implementation

constructor EScratchBirdError.CreateWithInfo(const Msg, ASQLState, ADetail, AHint: string);
begin
  inherited Create(Msg);
  SQLState := ASQLState;
  Detail := ADetail;
  Hint := AHint;
end;

function MapSqlState(const SQLState: string; const Msg, Detail, Hint: string): EScratchBirdError;
var
  Prefix: string;
begin
  if Length(SQLState) >= 2 then
    Prefix := Copy(SQLState, 1, 2)
  else
    Prefix := '';
  if Prefix = '01' then
    Result := EScratchbirdWarning.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '02' then
    Result := EScratchbirdNoData.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '08' then
    Result := EScratchbirdConnectionError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '0A' then
    Result := EScratchbirdNotSupported.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '22' then
    Result := EScratchbirdDataError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '23' then
    Result := EScratchbirdIntegrityError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '28' then
    Result := EScratchbirdAuthError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '40' then
    Result := EScratchbirdTransactionError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '42' then
    Result := EScratchbirdSyntaxError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '53' then
    Result := EScratchbirdResourceError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '54' then
    Result := EScratchbirdLimitError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '57' then
    Result := EScratchbirdOperatorInterventionError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = '58' then
    Result := EScratchbirdSystemError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else if Prefix = 'XX' then
    Result := EScratchbirdInternalError.CreateWithInfo(Msg, SQLState, Detail, Hint)
  else
    Result := EScratchBirdError.CreateWithInfo(Msg, SQLState, Detail, Hint);
end;

end.

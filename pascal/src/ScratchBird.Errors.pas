{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
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
  if Length(SQLState) = 5 then
  begin
    if SQLState = '01000' then
      Exit(EScratchbirdWarning.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if SQLState = '02000' then
      Exit(EScratchbirdNoData.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '08001') or (SQLState = '08003') or (SQLState = '08004') or
            (SQLState = '08006') or (SQLState = '08P01') then
      Exit(EScratchbirdConnectionError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if SQLState = '0A000' then
      Exit(EScratchbirdNotSupported.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '22001') or (SQLState = '22003') or (SQLState = '22007') or
            (SQLState = '22012') or (SQLState = '22023') or (SQLState = '22P02') or
            (SQLState = '22P03') then
      Exit(EScratchbirdDataError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '23000') or (SQLState = '23502') or (SQLState = '23503') or
            (SQLState = '23505') or (SQLState = '23514') then
      Exit(EScratchbirdIntegrityError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '28000') or (SQLState = '28P01') then
      Exit(EScratchbirdAuthError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '40001') or (SQLState = '40P01') then
      Exit(EScratchbirdTransactionError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '42501') or (SQLState = '42601') or (SQLState = '42703') or
            (SQLState = '42704') or (SQLState = '42710') or (SQLState = '42883') or
            (SQLState = '42P01') or (SQLState = '42P07') then
      Exit(EScratchbirdSyntaxError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '53P00') or (SQLState = '53100') or (SQLState = '53200') or
            (SQLState = '53300') then
      Exit(EScratchbirdResourceError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if SQLState = '54000' then
      Exit(EScratchbirdLimitError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if (SQLState = '57014') or (SQLState = '57P01') or (SQLState = '57P03') then
      Exit(EScratchbirdOperatorInterventionError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if SQLState = '58000' then
      Exit(EScratchbirdSystemError.CreateWithInfo(Msg, SQLState, Detail, Hint))
    else if SQLState = 'XX000' then
      Exit(EScratchbirdInternalError.CreateWithInfo(Msg, SQLState, Detail, Hint));
  end;
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

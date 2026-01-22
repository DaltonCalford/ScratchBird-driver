unit ScratchBird.Sql;

interface

uses
  SysUtils, Variants;

function SubstituteSql(const Sql: string; const Params: array of Variant): string;
function SubstituteNamedSql(const Sql: string; const Names: array of string; const Values: array of Variant): string;

function IndexOf(const Names: array of string; const Name: string): Integer;

implementation

function EscapeString(const Value: string): string;
begin
  Result := StringReplace(StringReplace(Value, '\', '\\', [rfReplaceAll]), '''', '''''', [rfReplaceAll]);
end;

function FormatValue(const Value: Variant): string;
begin
  if VarIsNull(Value) then
    Exit('NULL');
  case VarType(Value) of
    varBoolean:
      if Value then
        Result := 'TRUE'
      else
        Result := 'FALSE';
    varSmallint, varInteger, varInt64, varShortInt, varByte, varWord, varLongWord:
      Result := VarToStr(Value);
    varSingle, varDouble, varCurrency:
      Result := VarToStr(Value);
    varString, varUString, varOleStr:
      Result := '''' + EscapeString(VarToStr(Value)) + '''';
  else
    Result := '''' + EscapeString(VarToStr(Value)) + '''';
  end;
end;

function SubstituteSql(const Sql: string; const Params: array of Variant): string;
var
  I, Index: Integer;
  OutSql: string;
begin
  OutSql := '';
  Index := 0;
  I := 1;
  while I <= Length(Sql) do
  begin
    if Sql[I] = '?' then
    begin
      if Index <= High(Params) then
      begin
        OutSql := OutSql + FormatValue(Params[Index]);
        Inc(Index);
      end
      else
        OutSql := OutSql + '?';
      Inc(I);
      Continue;
    end;
    if (Sql[I] = '''') and (I < Length(Sql)) then
    begin
      OutSql := OutSql + Sql[I];
      Inc(I);
      while I <= Length(Sql) do
      begin
        OutSql := OutSql + Sql[I];
        if (Sql[I] = '''') and ((I = Length(Sql)) or (Sql[I + 1] <> '''')) then
        begin
          Inc(I);
          Break;
        end;
        if (Sql[I] = '''') and (I < Length(Sql)) and (Sql[I + 1] = '''') then
          Inc(I);
        Inc(I);
      end;
      Continue;
    end;
    OutSql := OutSql + Sql[I];
    Inc(I);
  end;
  Result := OutSql;
end;

function IndexOf(const Names: array of string; const Name: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(Names) do
    if SameText(Names[I], Name) then
      Exit(I);
end;

function IsIdentChar(Ch: Char): Boolean;
begin
  Result := (Ch >= 'a') and (Ch <= 'z') or (Ch >= 'A') and (Ch <= 'Z') or
    (Ch >= '0') and (Ch <= '9') or (Ch = '_');
end;

function SubstituteNamedSql(const Sql: string; const Names: array of string; const Values: array of Variant): string;
var
  I, J: Integer;
  OutSql: string;
  Token: string;
  Index: Integer;
begin
  OutSql := '';
  I := 1;
  while I <= Length(Sql) do
  begin
    if (Sql[I] = '''') and (I < Length(Sql)) then
    begin
      OutSql := OutSql + Sql[I];
      Inc(I);
      while I <= Length(Sql) do
      begin
        OutSql := OutSql + Sql[I];
        if (Sql[I] = '''') and ((I = Length(Sql)) or (Sql[I + 1] <> '''')) then
        begin
          Inc(I);
          Break;
        end;
        if (Sql[I] = '''') and (I < Length(Sql)) and (Sql[I + 1] = '''') then
          Inc(I);
        Inc(I);
      end;
      Continue;
    end;
    if (Sql[I] = '@') or (Sql[I] = ':') then
    begin
      J := I + 1;
      while (J <= Length(Sql)) and IsIdentChar(Sql[J]) do
        Inc(J);
      Token := Copy(Sql, I + 1, J - I - 1);
      Index := IndexOf(Names, Token);
      if (Index >= 0) and (Index <= High(Values)) then
        OutSql := OutSql + FormatValue(Values[Index])
      else
        OutSql := OutSql + Copy(Sql, I, J - I);
      I := J;
      Continue;
    end;
    OutSql := OutSql + Sql[I];
    Inc(I);
  end;
  Result := OutSql;
end;

end.

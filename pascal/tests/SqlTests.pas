program SqlTests;

{$APPTYPE CONSOLE}

uses
  SysUtils, Variants, ScratchBird.Sql;

procedure AssertEqual(const Expected, Actual, MessageText: string);
begin
  if Expected <> Actual then
    raise Exception.Create(MessageText + ': expected=' + Expected + ' actual=' + Actual);
end;

var
  OutSql: string;
begin
  try
    OutSql := SubstituteSql('SELECT * FROM t WHERE id = ? AND name = ?', [42, 'Ada']);
    AssertEqual('SELECT * FROM t WHERE id = 42 AND name = ''Ada''', OutSql, 'positional');
    OutSql := SubstituteNamedSql('SELECT * FROM users WHERE name = @name AND active = :active', ['name', 'active'], ['Ada', True]);
    AssertEqual('SELECT * FROM users WHERE name = ''Ada'' AND active = TRUE', OutSql, 'named');
    Writeln('SqlTests: OK');
  except
    on E: Exception do
    begin
      Writeln('SqlTests: FAILED - ' + E.Message);
      Halt(1);
    end;
  end;
end.

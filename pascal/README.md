# ScratchBird Pascal/Delphi Driver

ScratchBird native wire protocol client and adapters for Delphi/FreePascal.

## Documentation

- Getting started: `docs/getting-started/pascal.md`
- API reference: `docs/api-reference/pascal.md`

## Usage (core client)

```pascal
uses
  ScratchBird.Client;

var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    Client.Connect('scratchbird://user:pass@localhost:3092/mydb');
    Client.ExecSQL('SELECT 1');
  finally
    Client.Free;
  end;
end;
```

## Adapters

- FireDAC: `ScratchBird.FireDAC`
- IBX: `ScratchBird.IBX`
- Zeos: `ScratchBird.Zeos`
- SQLdb: `ScratchBird.SQLdb`

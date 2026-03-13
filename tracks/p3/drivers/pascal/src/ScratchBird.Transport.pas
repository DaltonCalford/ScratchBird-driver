{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
}
unit ScratchBird.Transport;

{$mode delphi}
{$H+}

interface

uses
  SysUtils, ScratchBird.Config;

type
  IScratchBirdTransport = interface
    ['{46B68F95-53FD-43F8-84F2-C0A1E7A86949}']
    procedure Configure(const Config: TScratchBirdConfig);
    procedure Connect;
    procedure Disconnect;
    function ReadExact(Length: Integer): TBytes;
    procedure Write(const Data: TBytes);
    function IsConnected: Boolean;
  end;

implementation

end.

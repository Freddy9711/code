program ServerProject;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  server in 'server.pas';

var
  MYsockobj : MYservers;
begin
  MYsockobj := MYservers.Create;
  MYsockobj.start;
end.

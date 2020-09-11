program ServerProject;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  Dialogs,
  server in 'server.pas';

var
  MYsockobj : MYservers;
begin



  MYsockobj := MYservers.Create;
  MYsockobj.start;
end.

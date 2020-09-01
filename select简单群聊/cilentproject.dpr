program cilentproject;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  cilent in 'cilent.pas';

var
  MYclientobj : MYclient;
begin
  MYclientobj := MYclient.Create;
  MYclientobj.start;
end.

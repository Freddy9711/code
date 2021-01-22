program gameserver;

uses
  Vcl.Forms,
  mainform in 'mainform.pas' {FormMain},
  Tcpgameserver in 'Tcpgameserver.pas',
  LogServer in 'LogServer.pas',
  Tcpserver in 'Tcpserver.pas',
  GameProtocol in 'GameProtocol.pas',
  GameSqlServer in 'GameSqlServer.pas',
  TBotFindPlayer in 'TBotFindPlayer.pas',
  LoginSQL in 'LoginSQL.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TForm1, LoginSqlForm);
  Application.Run;
end.

program Project1;

uses
  Forms,
  Controls,
  Dialogs,
  Classes,
  MinForm in 'MinForm.pas' {MintForm},
  LoginForm in 'LoginForm.pas' {FormLogin},
  connectserver in 'connectserver.pas',
  sendrecv in 'sendrecv.pas';


{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  MessageInfo := TMessageInfo.Create;
  UserString := TStringList.Create;
  UserInfoList := TStringList.Create;
  userinfo:= Tuserinfo.Create;
  sendobj := TMessageSend.Create(True);
  recvobj := TMessageRecv.Create(True);
  Client := Tcilent.Create(False);
   client.SetIPPort('10.246.54.171', 1234);
//  client.SetIPPort('10.246.54.151', 1234);
  while True do
  begin
    if client.ConnectFailed then
    begin
      ShowMessage('连接失败！');
      Exit;
    end;
    if client.Connected then
    begin
      ShowMessage('连接成功！');
      Break;
    end;
  end;
  FormLogin := TFormLogin.Create(nil);
  if FormLogin.ShowModal <> mrCancel then
  begin
    Application.CreateForm(TMintForm, MintForm);
    Application.Run;
  end;
end.


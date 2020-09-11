unit LoginForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SyncObjs;

type
  TFormLogin = class(TForm)
    usernameedit: TEdit;
    UserIdEdit: TEdit;
    PasswordEdit: TEdit;
    BtLogin: TButton;
    BtRegeister: TButton;
    BtEnd: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure BtEndClick(Sender: TObject);
    procedure BtLoginClick(Sender: TObject);
    procedure AddUserInfo;
    procedure BtRegeisterClick(Sender: TObject);
  private
    FLock: TCriticalSection;
  public
  end;

var
  FormLogin: TFormLogin;
  UserString: TStringList;
  MessageString: TStringList;
  UserInfoList: TStringList;
  LoginSign: Boolean;

implementation

uses
  sendrecv, connectserver;
{$R *.dfm}

procedure TFormLogin.AddUserInfo;
begin
 // FLock.Enter;
//  try
  UserString.Add(UserIdEdit.Text);
  UserString.add(PasswordEdit.Text);
 // finally
  //  FLock.Leave;
 // end;
end;

procedure TFormLogin.BtEndClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFormLogin.BtLoginClick(Sender: TObject);
begin
  if Length(UserIdEdit.text) = 0 then
  begin
    ShowMessage('账户不能为空');
    Exit;
  end
  else if Length(PasswordEdit.text) = 0 then
  begin
    ShowMessage('密码不能为空');
    Exit;
  end;
  AddUserInfo;
  SendObj.GetSock(client.socked);
  SendObj.SetOperator(C_LOGIN);
  sendobj.Resume;
  recvobj.GetSock(client.socked);
  recvobj.Resume;
  while True do
  begin
    if recvobj.recvsign = Loginfail then
    begin
      ShowMessage('登陆失败');
      Break;
    end;
    if recvobj.recvsign = Loginsuccess then
    begin
      ShowMessage('登陆成功');
      ModalResult := 1;
      break;
    end;
  end;

end;

procedure TFormLogin.BtRegeisterClick(Sender: TObject);
begin
  if Length(UserIdEdit.text) = 0 then
  begin
    ShowMessage('账户不能为空');
    Exit;
  end
  else if Length(PasswordEdit.text) = 0 then
  begin
    ShowMessage('密码不能为空');
    Exit;
  end;
  AddUserInfo;
  SendObj.GetSock(client.socked);
  SendObj.SetOperator(C_REGEISTER);
  sendobj.Resume;
  recvobj.GetSock(client.socked);
  recvobj.Resume;
  while True do
  begin
    if recvobj.recvsign = Regeristersuccess then
    begin
      ShowMessage('注册成功');
      Break;
    end;
    if recvobj.recvsign = Regeristerfail then
    begin
      ShowMessage('注册失败');
      Break;
    end;
  end;
end;

end.


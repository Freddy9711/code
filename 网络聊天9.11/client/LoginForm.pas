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
    ShowMessage('�˻�����Ϊ��');
    Exit;
  end
  else if Length(PasswordEdit.text) = 0 then
  begin
    ShowMessage('���벻��Ϊ��');
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
      ShowMessage('��½ʧ��');
      Break;
    end;
    if recvobj.recvsign = Loginsuccess then
    begin
      ShowMessage('��½�ɹ�');
      ModalResult := 1;
      break;
    end;
  end;

end;

procedure TFormLogin.BtRegeisterClick(Sender: TObject);
begin
  if Length(UserIdEdit.text) = 0 then
  begin
    ShowMessage('�˻�����Ϊ��');
    Exit;
  end
  else if Length(PasswordEdit.text) = 0 then
  begin
    ShowMessage('���벻��Ϊ��');
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
      ShowMessage('ע��ɹ�');
      Break;
    end;
    if recvobj.recvsign = Regeristerfail then
    begin
      ShowMessage('ע��ʧ��');
      Break;
    end;
  end;
end;

end.


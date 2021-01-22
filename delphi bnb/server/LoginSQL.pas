unit LoginSQL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    sqlnaem: TLabel;
    password: TLabel;
    hostname: TLabel;
    protocol: TLabel;
    useredt: TEdit;
    passwordedt: TEdit;
    datebaseedt: TEdit;
    protocoledt: TEdit;
    hostnameedt: TEdit;
    start: TButton;
    procedure startClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LoginSqlForm: TForm1;

implementation

{$R *.dfm}
uses
  GameSqlServer;

procedure TForm1.startClick(Sender: TObject);
var
  User, PassWord, DataBase, Protocol, HostName: AnsiString;
begin
  if Length(useredt.Text) <> 0 then
  begin
    User := useredt.Text;
  end
  else
  begin
    ShowMessage('请输入数据库用户名');
  end;
  if Length(passwordedt.Text) <> 0 then
  begin
    PassWord := passwordedt.Text;
  end
  else
  begin
    ShowMessage('请输入数据库用户密码');
  end;
  if Length(hostnameedt.Text) <> 0 then
  begin
    HostName := hostnameedt.Text;
  end
  else
  begin
    ShowMessage('请输入数据库IP地址');
  end;
  if Length(datebaseedt.Text) <> 0 then
  begin
    DataBase := datebaseedt.Text;
  end
  else
  begin
    ShowMessage('请输入数据库名');
  end;
  if Length(protocoledt.Text) <> 0 then
  begin
    Protocol := protocoledt.Text;
  end
  else
  begin
    ShowMessage('请输入数据库类型');
  end;
  SQLserver := TSQLserver.Create(User, Password, DataBase, Protocol, HostName);
end;

end.


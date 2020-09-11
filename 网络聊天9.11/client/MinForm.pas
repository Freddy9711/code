unit MinForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TMintForm = class(TForm)
    MessageMemo: TMemo;
    Btsend: TButton;
    SendMemo: TMemo;
    UserBox: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure BtsendClick(Sender: TObject);
    procedure AddMessageString;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MintForm: TMintForm;

implementation

{$R *.dfm}
uses
  sendrecv, connectserver, LoginForm;

procedure TMintForm.AddMessageString;
begin
  MessageString.add(SendMemo.text);
end;

procedure TMintForm.BtsendClick(Sender: TObject);
begin
  if Length(SendMemo.Text) = 0 then
  begin
    ShowMessage('«Î ‰»Îœ˚œ¢');
    ShowMessage(UserBox.Text);
  end
  else
  begin
   AddMessageString;
    sendobj.GetSock(client.socked);
    sendobj.SetOperator(C_CHAT);
    sendobj.Resume;

  end;
end;




procedure TMintForm.FormCreate(Sender: TObject);
var
  i: Integer;
  count: integer;
begin
  MessageMemo.Clear;
  SendMemo.Clear;
  sendobj.GetSock(client.socked);
  sendobj.SetOperator(C_GETONLINEUERS);
  sendobj.Resume;
  recvobj.GetSock(client.socked);
  recvobj.Resume;
  while True do
  begin
    if recvobj.ListCode = FinishList then
    begin
      count := recvobj.UserList.Count;
      Break;
    end;
  end;
  for i := 0 to count - 1 do
  begin
    UserBox.Items.Add(recvobj.UserList[i]);
  end;
end;

end.


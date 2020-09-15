unit MinForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinSock, sendrecv, SyncObjs, ExtCtrls;

type
  TMintForm = class(TForm)
    MessageMemo: TMemo;
    Btsend: TButton;
    SendMemo: TMemo;
    btreaduser: TButton;
    Timer1: TTimer;
    userbox: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure BtsendClick(Sender: TObject);
    procedure AddMessageString;
    procedure btreaduserClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TReadUserInfo = class(TThread)
  public
    Consocket: TSocket;
    recvmes: array[0..511] of Char;
    headmes: TChatHead;
    procedure GetSock(Socked: TSocket);
  protected
    procedure Execute; override;
  end;

  Tuserinfo = class
  private
    FLock: TCriticalSection;
    FInfoStrings: TStringList;
  public
    procedure AddInfo(NameContext: AnsiString; IDContext: AnsiString);
    procedure GetInfo(userbox: TComboBox);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TMessageInfo = class
  private
    FLock: TCriticalSection;
  public
    FMessageStrings: TStringList;
    procedure GetMessage(MessageMemo: TMemo);
    procedure AddMessage(Srcname: AnsiString; msg: AnsiString);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  MintForm: TMintForm;
  userinfo: Tuserinfo;
  MessageString: AnsiString;
  ReadUserInfo: TReadUserInfo;
  MessageInfo: TMessageInfo;
  RecvMessage: TChat;
  UserCount: Integer;
  UserList: array of RUserInfo;
  RecvUserList: array of RUserInfo;
  MessageStrings: AnsiString;

implementation

{$R *.dfm}
uses
  connectserver, LoginForm;

function FindListID(PosName: AnsiString): Integer;
var
  I: Integer;
begin
  for I := 0 to Length(UserList) - 1 do
  begin
    if UserList[I].Name = PosName then
    begin
      Result := UserList[I].ID;
    end;
  end;

end;

procedure TMintForm.AddMessageString;
begin
  if Length(SendMemo.text) > 256 then
  begin
    ShowMessage('请输入小于256字符');
  end
  else
  begin
    MessageString := SendMemo.text;
  end;

end;

procedure TMintForm.btreaduserClick(Sender: TObject);
begin
  sendobj.GetSock(client.socked);
  sendobj.SetOperator(C_GETONLINEUERS);
  sendobj.Resume;
  if ReadUserInfo = nil then
    ReadUserInfo := TReadUserInfo.Create(True);
  ReadUserInfo.GetSock(client.socked);
  ReadUserInfo.Resume;
  Timer1.Enabled := True;

end;

procedure TMintForm.BtsendClick(Sender: TObject);
var
  id: Integer;
begin
  if Length(SendMemo.Text) = 0 then
  begin
    ShowMessage('请输入消息');
  end
  else
  begin
    AddMessageString;
    PosName := userBox.Text;
    if Length(PosName) = 0  then
    begin
      ShowMessage('请选择聊天用户');
      Exit;
    end;
    PosID := FindListID(PosName);
    MyID := FindListID(MyName);
    sendobj.GetSock(client.socked);
    sendobj.SetOperator(C_CHAT);
    sendobj.Resume;
    MessageMemo.Lines.Add(('你' + '->' + PosName + ': ' + MessageString));
    SendMemo.Clear;
  end;
end;

procedure TMintForm.FormCreate(Sender: TObject);
var
  i: Integer;
  count: integer;
begin
  Caption := MyName;
  MessageMemo.Clear;
  SendMemo.Clear;

end;

procedure TMintForm.Timer1Timer(Sender: TObject);
begin
  userinfo.GetInfo(userbox);
  MessageInfo.GetMessage(MessageMemo);
end;

procedure TReadUserInfo.Execute;
var
  i: Integer;
  TmpNameString: AnsiString;
  TmpIDString: AnsiString;
  RecvSize: Integer;
  SendName: AnsiString;
  msg: AnsiString;
begin
  while not terminated do
  begin
    RecvSize := recv(Consocket, recvmes, 512, 0);
    if RecvSize = -1 then
      Exit;
    CopyMemory(@headmes, @recvmes[0], 12);
    if headmes.Operation = S_GETONLINEUERS then
    begin
      CopyMemory(@UserCount, @recvmes[12], 4);
      SetLength(UserList, UserCount);
      SetLength(RecvUserList, UserCount);
      CopyMemory(UserList, @recvmes[16], RecvSize - 16);
      CopyMemory(RecvUserList, @recvmes[16], RecvSize - 16);
    end
    else if headmes.Operation = S_CHAT then
    begin
      CopyMemory(@RecvMessage, @recvmes, 316);
      SendName := StrPas(@(RecvMessage.UserName[0]));
      msg := StrPas(@(RecvMessage.Msg[0]));
      MessageInfo.AddMessage(SendName, msg);
    end;

  end;

end;

procedure TReadUserInfo.GetSock(Socked: TSocket);
begin
  Consocket := Socked;
end;

{ Tuserinfo }



{ Tuserinfo }

procedure Tuserinfo.AddInfo(NameContext: AnsiString; IDContext: AnsiString);
begin
  FLock.Enter;
  try
    FInfoStrings.Add(NameContext);
    FInfoStrings.Values[NameContext] := IDContext;
  finally
    FLock.Leave;
  end;
end;

constructor Tuserinfo.Create;
begin
  FLock := TCriticalSection.Create;
  FInfoStrings := TStringList.Create;
end;

destructor Tuserinfo.Destroy;
begin
  FInfoStrings.Free;
  FLock.Free;
  inherited;
end;

procedure Tuserinfo.GetInfo(userbox: TComboBox);
var
  i: Integer;
begin
  FLock.Enter;
  try
    if Length(RecvUserList) <> 0 then
    begin
      userbox.Clear;
      for i := 0 to Length(RecvUserList) - 1 do
      begin
        userbox.Items.Add(RecvUserList[i].Name);
      end;
    end;
    SetLength(RecvUserList, 0);
  finally
    FLock.Leave;
  end;
end;

{ TMessageInfo }

procedure TMessageInfo.AddMessage(Srcname: AnsiString; msg: AnsiString);
begin
  FLock.Enter;
  try
    FMessageStrings.Add(Srcname + '->' + '你' + ': ' + msg);
  finally
    FLock.Leave;
  end;

end;

constructor TMessageInfo.Create;
begin
  FLock := TCriticalSection.Create;
  FMessageStrings := TStringList.Create;

end;

destructor TMessageInfo.Destroy;
begin
  FMessageStrings.Free;
  FLock.Free;
  inherited;
end;

procedure TMessageInfo.GetMessage(MessageMemo: TMemo);
var
  i: Integer;
begin
  FLock.Enter;
  try
    for i := 0 to FMessageStrings.Count - 1 do
    begin
      MessageMemo.Lines.Add(FMessageStrings[i]);
    end;
    FMessageStrings.Clear;
  finally
    FLock.Leave;
  end;

end;

end.


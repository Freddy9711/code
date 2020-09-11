unit sendrecv;

interface

uses
  WinSock, StdCtrls, SysUtils, Variants, Classes, Controls, Dialogs, Windows,
  SyncObjs, LoginForm;

const
  PACKAGE_FLAG = $FFEE8899;

type
  TChatHead = record
    Flag: Integer;
    Size: Integer;
    Operation: Integer;
  end;

  C_RLOGIN = record
    Head: TChatHead;
    Sign: Boolean;
    NickName: array[0..19] of Char;
    UserName: array[0..19] of Char;
    Password: array[0..19] of Char;
  end;

  C_RRegeister = record
    Head: TChatHead;
    Sign: Boolean;
    NickName: array[0..19] of Char;
    UserName: array[0..19] of Char;
    Password: array[0..19] of Char;
  end;

  C_RUserList = record
    Head: TChatHead;
  end;

  S_RUserList = record
    Head: TChatHead;
    Usercount: Integer;
    UserNameList: array[0..3, 0..20] of char;
    UserID: array[0..3, 0..20] of char;
  end;

  S_RRegeister = record
    Head: TChatHead;
    Sign: Boolean;
  end;

  S_RLogin = record
    Head: TChatHead;
    Sign: Boolean;
  end;

type
  TChat = record
    Head: TChatHead;
    DestID: Integer;
    SrcID: Integer;
    SrcName: array[0..19] of Char;
    UersName: array[0..19] of Char;
    Password: array[0..19] of Char;
    Sign: Boolean;
    UserInfoString: TStringList;
    Msg: array[0..255] of AnsiChar;
  end;

  TRecvCode = (nocode, Loginsuccess, Loginfail, Regeristersuccess, Regeristerfail);

  TListCode = (NoInfo, FinishList);

type
  TMessageRecv = class(TThread)
  public
    Consocket: TSocket;
    MessageInfo: TChat;
    recvmes: array[0..280] of Char;
    recvstring: AnsiString;
    procedure GetSock(Socked: TSocket);
    procedure MessageParse(recvmes: array of Char);
    procedure Execute; override;
    procedure RegeisterMessageParse;
    procedure LoginMessageParse;
    procedure UserListMessageParse;
  private
    FLock: TCriticalSection;
    Frecvsign: TRecvCode;
    headmes: TChatHead;
    loginrecvobj: S_RLogin;
    regerecvobj: S_RRegeister;
    FListCode: TListCode;
    FUserList: TStringList;
  public
    property recvsign: TRecvCode read Frecvsign;
    property ListCode: TListCode read FListCode;
    property UserList: TStringList read FUserList;
  end;

type
  TMessageSend = class(TThread)
  public
    Consocket: TSocket;
    MessageInfo: array[0..280] of TChat;
    SendOperator: Integer;
    procedure GetSock(Socked: TSocket);
    procedure MakeMessage(Operation_: Integer; DestID_: Integer; SrcID_: Integer; Msg_: AnsiString);
    procedure Execute; override;
    procedure SetOperator(SendOperator_: Integer);
    procedure SendLoginMsg;
    procedure SendRegisteredMsg;
    procedure SendGetUserInfo;
    procedure MesmesSend;
  private
    Loginmessage: C_RLOGIN;
    FLock: TCriticalSection;
  end;

const
  C_REGEISTER = 1;
  C_LOGIN = 2;
  C_CHAT = 3;
  C_OUT = 4;
  C_MODIFY_PASSWORD = 5;
  C_MODIFY_NICKNAME = 6;
  S_REGEISTER = 7;
  S_LOGIN = 8;
  S_USER_LIST = 9;
  S_BRODCAST_LOGIN = 10;
  S_CHAT = 11;
  S_BRODCAST_OUT = 12;
  S_MODIFY_PASSWORD = 13;
  S_MODIFY_NICKNAME = 14;
  C_GETONLINEUERS = 15;
  S_GETONLINEUERS = 16;

var
  MessagePos: Integer;
  sendbuf: array of Char;
  MessageInfoCount: Integer;
  infoobj: S_RUserList;
  LogSuccess: Boolean;
  UserInfoList: TStringList;

implementation

uses
  MinForm;


procedure TMessageRecv.Execute;
begin
  while terminated = False do
  begin
    recv(Consocket, recvmes, 10240, 0);
    CopyMemory(@headmes, @recvmes, 20);
    if headmes.Operation = S_REGEISTER then
    begin
      RegeisterMessageParse;
    end
    else if headmes.Operation = S_LOGIN then
    begin
      LoginMessageParse;
    end
    else if headmes.Operation = S_GETONLINEUERS then
    begin
      UserListMessageParse;
    end;
    Suspend;
  end;
end;

procedure TMessageRecv.GetSock(Socked: TSocket);
begin
  Consocket := Socked;
end;

procedure TMessageRecv.LoginMessageParse;
begin
  CopyMemory(@loginrecvobj, @recvmes, SizeOf(recvmes));
  if loginrecvobj.Sign = True then
  begin
    Frecvsign := Loginsuccess;
  end
  else
  begin
    Frecvsign := Loginfail;
  end;
end;

procedure TMessageRecv.MessageParse(recvmes: array of char);
begin

end;

procedure TMessageRecv.RegeisterMessageParse;
begin
  CopyMemory(@regerecvobj, @recvmes, SizeOf(recvmes));
  if regerecvobj.Sign = True then
  begin
    Frecvsign := Regeristersuccess;
  end
  else
  begin
    Frecvsign := Regeristerfail;
  end;
end;

procedure TMessageRecv.UserListMessageParse;
var
  I: Integer;
  J: Integer;
  tmpnamestring: AnsiString;
  tmpnodestring: AnsiString;
  count: Integer;
begin
  FUserList := TStringList.Create;
  CopyMemory(@infoobj, @recvmes, SizeOf(recvmes));
  count := infoobj.Usercount;
  FUserList.clear;
  for I := 0 to count - 1 do
  begin
    tmpnamestring := StrPas(@(infoobj.UserNameList[I]));
    FUserList.Add(tmpnamestring);
  end;
  FListCode := FinishList;
end;





{ MessageSend }

procedure TMessageSend.Execute;
begin

  while terminated = False do
  begin
    if SendOperator = C_LOGIN then
    begin
      SendLoginMsg;
    end
    else if SendOperator = C_REGEISTER then
    begin
      SendRegisteredMsg;
    end
    else if SendOperator = C_CHAT then
    begin
      MesmesSend;
    end
    else if SendOperator = C_MODIFY_PASSWORD then
    begin

    end
    else if SendOperator = C_GETONLINEUERS then
    begin
      SendGetUserInfo;
    end;
    Suspend;
  end;
end;

procedure TMessageSend.GetSock(Socked: TSocket);
begin
  Consocket := Socked;
end;

procedure TMessageSend.MakeMessage(Operation_: Integer; DestID_: Integer; SrcID_: Integer; Msg_: AnsiString);
begin

end;

procedure TMessageSend.MesmesSend;
begin

end;

procedure TMessageSend.SendGetUserInfo;
var
  Listmessage: S_RUserList;
begin
  Listmessage.Head.Flag := PACKAGE_FLAG;
  Listmessage.Head.Operation := C_GETONLINEUERS;
  Listmessage.Head.Size := SizeOf(Listmessage);
  send(Consocket, Listmessage, SizeOf(Listmessage), 0);
end;

procedure TMessageSend.SendLoginMsg;
var
  Loginmessage: C_RLOGIN;
begin
  Loginmessage.Head.Flag := PACKAGE_FLAG;
  Loginmessage.Head.Operation := C_LOGIN;
  Loginmessage.Head.Size := SizeOf(Loginmessage);
  Loginmessage.Sign := False;
  StrPCopy(Loginmessage.UserName, UserString.Strings[0]);
  StrPCopy(Loginmessage.Password, UserString.Strings[1]);
  send(Consocket, Loginmessage, SizeOf(Loginmessage), 0);
end;

procedure TMessageSend.SendRegisteredMsg;
var
  RegisterMessage: C_RRegeister;
begin
  RegisterMessage.Head.Flag := PACKAGE_FLAG;
  RegisterMessage.Head.Operation := C_REGEISTER;
  RegisterMessage.Head.Size := SizeOf(RegisterMessage);
  StrPCopy(RegisterMessage.UserName, UserString.Strings[0]);
  StrPCopy(RegisterMessage.Password, UserString.Strings[1]);
  send(Consocket, RegisterMessage, SizeOf(RegisterMessage), 0);
end;

procedure TMessageSend.SetOperator(SendOperator_: Integer);
begin
  self.SendOperator := SendOperator_;
end;

initialization
  MessagePos := 0;
  MessageInfoCount := 0;

end.


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

  RUserInfo = record
    ID: Integer;
    Name: array[0..19] of Char;
    Tcpsocked: TSocket;
  end;

  S_RUserList = record
    Head: TChatHead;
    UserListLength: Integer;
    UserList: array of RUserInfo;
  end;

  S_RRegeister = record
    Head: TChatHead;
    Sign: Boolean;
  end;

  S_RLogin = record
    Head: TChatHead;
    Name: array[0..19] of Char;
    Sign: Boolean;
  end;

  C_RScreen = record
    head: TChatHead;
    Pbuf: array[0..1023] of Byte;
  end;

  S_RScreen = record
    head: TChatHead;
    Pbuf: array[0..1023] of Byte;
  end;

type
  TChat = record
    Head: TChatHead;
    SrcID: Integer;
    UserID: Integer;
    SrcName: array[0..19] of Char;
    UserName: array[0..19] of Char;
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
  C_SCREEN = 17;
  S_SCREEN = 18;

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
  FUserList := TStringList.Create();
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

procedure TMessageSend.MesmesSend;
var
  ChatMessage: TChat;
begin
  ChatMessage.Head.Flag := PACKAGE_FLAG;
  ChatMessage.Head.Operation := C_CHAT;
  ChatMessage.SrcID := PosID;
  ChatMessage.UserID := MyID;
  StrPCopy(ChatMessage.UserName, MyName);
  StrPCopy(ChatMessage.SrcName, PosName);
  StrPCopy(ChatMessage.Msg, MessageString);
  send(Consocket, ChatMessage, SizeOf(ChatMessage), 0);
end;

procedure TMessageSend.SendGetUserInfo;
var
  Listmessage: C_RUserList;
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
//  Loginmessage.Sign := False;
//  StrPCopy(Loginmessage.NickName, UserString.Strings[0]);
  StrPCopy(Loginmessage.UserName, UserString.Strings[1]);
  StrPCopy(Loginmessage.Password, UserString.Strings[2]);
  send(Consocket, Loginmessage, SizeOf(Loginmessage), 0);
end;

procedure TMessageSend.SendRegisteredMsg;
var
  RegisterMessage: C_RRegeister;
begin
  RegisterMessage.Head.Flag := PACKAGE_FLAG;
  RegisterMessage.Head.Operation := C_REGEISTER;
  RegisterMessage.Head.Size := SizeOf(RegisterMessage);
  StrPCopy(RegisterMessage.NickName, UserString.Strings[0]);
  StrPCopy(RegisterMessage.UserName, UserString.Strings[1]);
  StrPCopy(RegisterMessage.Password, UserString.Strings[2]);
  send(Consocket, RegisterMessage, SizeOf(RegisterMessage), 0);
end;

procedure TMessageSend.SetOperator(SendOperator_: Integer);
begin
  self.SendOperator := SendOperator_;
end;

{ TReadUserInfo }

initialization
  MessagePos := 0;
  MessageInfoCount := 0;

end.


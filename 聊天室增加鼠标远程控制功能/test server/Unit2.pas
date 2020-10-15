unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinSock, DB, ZAbstractRODataset, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection, Unit1, ZLib, Tools;

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
  C_CONTROL = 19;
  S_CONTROL = 20;
  PACKAGE_FLAG = $FFEE8899;

type
  EventOperator = (NoEvent, MouseDownEvent, MouseUpEvent, MouseMoveEvent);

  TForm2 = class(TForm)
    bootServer: TButton;
    con1: TZConnection;
    zqry1: TZQuery;
    procedure bootServerClick(Sender: TObject);
  public
//    procedure bootServerClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PCharHead = ^TChatHead;

  TChatHead = record
    Flag: Integer;
    Size: Integer;
    Operation: Integer;
  end;

  RChat = record
    Head: TChatHead;
    DestID: Integer;
    SrcID: Integer;
    SrcName: array[0..19] of Char;
    DesName: array[0..19] of Char;
    Msg: array[0..255] of Char;
  end;

  C_RRegeister = record
    Head: TChatHead;
    Sign: Boolean;
    NickName: array[0..19] of Char;
    UserName: array[0..19] of Char;
    Password: array[0..19] of Char;
  end;

  S_RRegeister = record
    Head: TChatHead;
    Sign: Boolean;
  end;

  C_RLogin = record
    Head: TChatHead;
    UserName: array[0..19] of Char;
    Password: array[0..10] of Char;
  end;

  S_RLogin = record
    Head: TChatHead;
    Name: array[0..19] of Char;
    Sign: Boolean;
  end;

  RUserInfo = record
    ID: Integer;
    Name: array[0..19] of Char;
    tcpSocket: TSocket;
  end;

  C_RLogined = record
    Head: TChatHead;
  end;

  P_S_RLogined = ^S_RLogined;

  S_RLogined = record
    Head: TChatHead;
    UserListLength: Integer;
    UserList: array[0..0] of RUserInfo; //---------------------有疑问
  end;

  C_RScreen = record
    head: TChatHead;
    SrcID: Integer;
    UserID: Integer;
    SrcName: array[0..19] of Char;
    UserName: array[0..19] of Char;
    Last: Boolean;
    Crcs: Integer;
    Pbuf: array[0..32767] of Byte;
  end;

  S_RScreen = record
    head: TChatHead;
    Last: Boolean;
    Crcs: Integer;
    Pbuf: array[0..32767] of Byte;
  end;

  C_RControl = record
    head: TChatHead;
    PointX: Integer;
    PointY: Integer;
    FMouseButton: TMouseButton;
    EventType: EventOperator;
  end;

var
  Form2: TForm2;
  str: string = 'server connetted success from server!';
  waitstr: string = 'waiting';
  List: array of RUserInfo;
  fdsetNew: TFDSet;
  fdsetOld: TFDSet;
  count: Integer;
  maxcount: Integer;
  CStream: TMemoryStream;
  size: Integer;
  map: TBitmap;
  PStream: TMemoryStream;
  Rscreenmsg: C_RScreen;
  Sscreenmsg: S_RScreen;
  Rcontrolmsg: C_RControl;

function CheckSqlForRegeister(fregeister: C_RRegeister): Boolean;

function CheckSqlForLogin(LoginMsg: C_RLogin): RUserInfo;

function ReadQuire(sql: string): RUserInfo;

function WriteQuire(sql: string): Boolean;

procedure doLogin(sock: TSocket; LoginMsg: C_RLogin);

procedure doSendUserList(socket: TSocket);

procedure doChat(Msg: RChat);

procedure doScreen(Msg: C_RScreen; recvsize: Integer);

procedure DeleteUserListItem(Index: Integer);

procedure GetScreen;

procedure SendScreen(msg: C_RScreen; Tmpcrcs: Integer);

implementation

{$R *.dfm}

procedure SendScreen(msg: C_RScreen; Tmpcrcs: Integer);
var
  psize: Integer;
  sendcount: Integer;
  i: Integer;
  pMod: Integer;
  desSocket: TSocket;
begin
  for i := 0 to Length(List) - 1 do
  begin
    if List[i].ID = Rscreenmsg.SrcID then
    begin
      desSocket := List[i].tcpSocket;
      Break;
    end;
  end;
  psize := CStream.Size;
  sendcount := CStream.Size div 32768;
  Sscreenmsg.head.Flag := PACKAGE_FLAG;
  Sscreenmsg.head.Size := CStream.Size;
  Sscreenmsg.head.Operation := S_SCREEN;
  Sscreenmsg.Last := False;
  CStream.Seek(0, soFromBeginning);
  for i := 0 to sendcount - 1 do
  begin
    CStream.read(Sscreenmsg.Pbuf, 32768);
    Sscreenmsg.Crcs := CalCRC16(@(Sscreenmsg.Pbuf), 0, 32767);
    send(desSocket, Sscreenmsg, SizeOf(Sscreenmsg), 0);
  end;
  if (psize mod 32768) <> 0 then
  begin
    Sscreenmsg.Last := True;
    FillMemory(@Sscreenmsg.Pbuf[0], 32768, 0);
    pMod := psize mod 32768;
    CStream.read(Sscreenmsg.Pbuf, pMod);
    Sscreenmsg.Crcs := CalCRC16(@(Sscreenmsg.Pbuf), 0, pMod - 1);
    CStream.Clear;
    CStream.Seek(0, soFromBeginning);
    send(desSocket, Sscreenmsg, SizeOf(Sscreenmsg), 0);
  end;
end;

procedure SendControl(msg: C_RControl);
var
  desSocket: TSocket;
  i: Integer;
begin
  for i := 0 to Length(List) - 1 do
  begin
    if List[i].ID = Rscreenmsg.UserID then
    begin
      desSocket := List[i].tcpSocket;
      Break;
    end;
  end;
  msg.head.Operation := S_CONTROL;
  send(desSocket, msg, SizeOf(msg), 0);
end;

function CheckSqlForRegeister(fregeister: C_RRegeister): Boolean;
var
  sql: AnsiString;
  username: string;
  password: string;
  nickname: AnsiString;
  userInfo: RUserInfo;
begin
  username := StrPas(@(fregeister.UserName)[0]);
  password := StrPas(@(fregeister.Password)[0]);
  nickname := StrPas(@(fregeister.NickName)[0]);
//  nickname := StrPas(@(fregeister.SrcName)[0]);
  sql := 'select * from test where username=' + '"' + username + '"' + ' or nickname = ' + '"' + nickname + '";';
  userInfo := ReadQuire(sql);
  if userInfo.ID <> -1 then
  begin
    Result := False;
    Exit;
  end;

  sql := 'insert into test (username, password, nickname) values(' + '"' + username + '"' + ',' + '"' + password + '"' + ',' + '"' + nickname + '"' + ');';
  if WriteQuire(sql) then
    Result := True
  else
    Result := False;
end;

function CheckSqlForLogin(LoginMsg: C_RLogin): RUserInfo;
var
  sql: string;
  username: string;
  password: string;
  userInfo: RUserInfo;
begin
  username := StrPas(@(LoginMsg.UserName)[0]);
  password := StrPas(@(LoginMsg.Password)[0]);
  sql := 'select * from test where username=' + '"' + username + '"' + 'and password=' + '"' + password + '";';
  userInfo := ReadQuire(sql);
  Result := userInfo;
end;

function ReadQuire(sql: string): RUserInfo;
var
  userInfo: RUserInfo;
  nickname: string;
begin
  Form2.zqry1.Close;
  Form2.zqry1.SQL.Text := sql;
  Form2.zqry1.Open;
  if Form2.zqry1.RecordCount >= 1 then
  begin
    nickname := Form2.zqry1.FieldByName('nickname').AsString;
    userInfo.ID := Form2.zqry1.FieldByName('id').AsInteger;
    StrPCopy(@(userInfo.Name)[0], nickname);
  end
  else
  begin
    userInfo.ID := -1;
  end;
  Result := userInfo;
end;

function WriteQuire(sql: string): Boolean;
begin
  Form2.zqry1.Close;
  Form2.zqry1.SQL.Text := sql;
  Form2.zqry1.ExecSQL;
  if Form2.zqry1.RowsAffected <> 0 then
    Result := True
  else
    Result := False;
end;

procedure TForm2.bootServerClick(Sender: TObject);
var
  sockAddr: sockaddr_in;
  servSock: Tsocket;
  clntAddr: TSockAddr;
  clntSock: TSocket;
  wasData: TWSAData;
  nsize: Integer;
  ret: Integer;
  selectReturn: Integer;
  I: Integer;
  buf: array[0..32835] of byte;
  recvReturn: Integer;
  chatHead: TChatHead;
  R_C_Regeister: C_RRegeister;
  R_C_Login: C_RLogin;
  S_Rregeister_send: S_RRegeister;
  ChatMsg: RChat;
  ScreenMsg: C_RScreen;
  K: Integer;
  Pmod: Integer;
  PosCrcs: Integer;
begin
  WSAStartup(word((byte(2)) or (word(byte(2))) shl 8), wasData);
  servSock := socket(PF_INET, SOCK_STREAM, IPPROTO_TCP); //监听套接字
  if servSock < 0 then
    ShowMessage('failed to create servSock');
  sockAddr.sin_family := PF_INET;
//  sockAddr.sin_addr.S_addr := inet_addr('10.246.54.151');
  sockAddr.sin_addr.S_addr := inet_addr('10.246.54.171');
  sockAddr.sin_port := htons(1234);
  ret := bind(servSock, sockAddr, SizeOf(TSockAddr));
  if ret < 0 then
    ShowMessage('failed to bind socket');
  ret := listen(servSock, 20); // listen 函数 未完成和完成队列的等待数之和为 20
  if ret < 0 then
    ShowMessage('failed to listen socket');
  FillMemory(@fdsetOld, sizeof(TFDSet), 0);
  FD_SET(servSock, fdsetOld);
  while True do
  begin
    fdsetNew := fdsetOld;
    selectReturn := select(0, @fdsetNew, nil, nil, nil);
    if selectReturn <= 0 then
      ShowMessage('selectreturn something is wrong!');
    for I := 0 to fdsetOld.fd_count - 1 do
    begin
      if FD_ISSET(fdsetOld.fd_array[I], fdsetNew) <> False then
        if fdsetOld.fd_array[I] = servSock then //如果套接字是监听套接字
        begin
          nsize := SizeOf(clntAddr);
          clntSock := accept(servSock, PSOCKADDR(@clntAddr), @nsize); //建立通信连接字
          if fdsetOld.fd_count < FD_SETSIZE then
          begin
            FD_SET(clntSock, fdsetOld);
//            send(clntSock, Pointer(str)^, Length(str), 0);
          end
          else
          begin
            send(clntSock, Pointer(waitstr)^, Length(waitstr), 0);
            closesocket(clntSock);
          end;
          Continue;
        end
        else // 为通信套接字
        begin
          recvReturn := recv(fdsetOld.fd_array[I], buf, 32836, 0);
          if recvReturn < 0 then//返回值小于零说明客户端关闭了，则关闭fdOld集中中相应的通信套接字
          begin
            closesocket(fdsetOld.fd_array[I]);
            for K := 0 to Length(List) - 1 do
            begin
              if List[K].tcpSocket = fdsetOld.fd_array[I] then
              begin
                DeleteUserListItem(K);
                Break;
              end;
            end;
            //广播
            for K := 0 to fdsetOld.fd_count - 1 do
              doSendUserList(fdsetOld.fd_array[K]);
            FD_CLR(fdsetOld.fd_array[I], fdsetOld);
            Continue;
          end;
          CopyMemory(@chatHead, @buf[0], 12);
          case chatHead.Operation of
            C_REGEISTER:
              begin
                CopyMemory(@R_C_Regeister, @buf[0], recvReturn);
                if CheckSqlForRegeister(R_C_Regeister) then
                  S_Rregeister_send.Sign := True
                else
                  S_Rregeister_send.Sign := False;
//                userInfo := CheckSqlForRegeister(R_C_Regeister);
                S_Rregeister_send.Head.Flag := PACKAGE_FLAG;
                S_Rregeister_send.Head.Operation := S_REGEISTER;
                S_Rregeister_send.Head.Size := SizeOf(S_RRegeister);
                send(clntSock, S_Rregeister_send, S_Rregeister_send.Head.Size, 0);
              end;
            C_LOGIN:
              begin
                CopyMemory(@R_C_Login, @buf[0], recvReturn);
                doLogin(clntSock, R_C_Login);
              end;
            C_GETONLINEUERS:
              doSendUserList(clntSock);
            C_CHAT:
              begin
                CopyMemory(@ChatMsg, @buf[0], recvReturn);
                doChat(ChatMsg);
              end;
            C_Screen:
              begin
                CopyMemory(@Rscreenmsg, @buf[0], recvReturn);
                if Rscreenmsg.Last = False then
                begin
                  PosCrcs := CalCRC16(@(Rscreenmsg.Pbuf), 0, 32767);
                  if PosCrcs = Rscreenmsg.Crcs then
                  begin
                    CStream.Write(Rscreenmsg.Pbuf, 32768);
                  end;
                end
                else
                begin
                  Pmod := Rscreenmsg.head.Size mod 32768;
                  PosCrcs := CalCRC16(@(Rscreenmsg.Pbuf), 0, Pmod - 1);
                  if PosCrcs = Rscreenmsg.Crcs then
                  begin
                    CStream.Write(Rscreenmsg.Pbuf, Pmod);
                    if CStream.Size = Rscreenmsg.head.Size then
                      SendScreen(Rscreenmsg, PosCrcs)                      //GetScreen
                    else
                      CStream.Clear;
                  end;
                end;
              end;
            C_CONTROL:
              begin
                CopyMemory(@Rcontrolmsg, @buf[0],24);
                FillMemory(@buf, 32836, 0);
                SendControl(Rcontrolmsg);
              end
          end;
        end;
//      Application.ProcessMessages;
    end;
  end;
  closesocket(clntSock);
  closesocket(servSock);

  WSACleanup;
end;

procedure doLogin(sock: TSocket; LoginMsg: C_RLogin);
var
  S_Rlogin_send: S_RLogin;
  userInfo: RUserInfo;
  K: Integer;
begin
  userInfo := CheckSqlForLogin(LoginMsg);
  if userInfo.ID <> -1 then
  begin
    S_Rlogin_send.Sign := True;
//    S_Rlogin_send.Name := userInfo.Name;
    CopyMemory(@S_Rlogin_send.Name[0], @userInfo.Name[0], Length(userInfo.Name));
    SetLength(List, Length(List) + 1);
    List[High(List)].ID := userInfo.ID;
    List[High(List)].Name := userInfo.Name;
    List[High(List)].tcpSocket := sock;
  end
  else
  begin
    S_Rlogin_send.Sign := False;
  end;
  S_Rlogin_send.Head.Flag := PACKAGE_FLAG;
  S_Rlogin_send.Head.Operation := S_LOGIN;
  S_Rlogin_send.Head.Size := SizeOf(S_Rlogin_send);
  send(sock, S_Rlogin_send, S_Rlogin_send.Head.Size, 0);
  //广播
//  for K := 0 to fdsetOld.fd_count - 1 do
//    doSendUserList(fdsetOld.fd_array[k]);
  for K := 0 to Length(List) - 1 do
  begin
    if List[K].tcpSocket = sock then
      Continue;
    doSendUserList(List[K].tcpSocket);
  end;
end;

procedure doSendUserList(socket: TSocket);
var
  p: P_S_RLogined;
  K: Integer;
  I: Integer;
begin
  p := GetMemory(16 + Length(List) * SizeOf(RUserInfo));
  p^.UserListLength := Length(List);
  p^.Head.Flag := PACKAGE_FLAG;
  p^.Head.Operation := S_GETONLINEUERS;
  p^.Head.Size := 16 + p^.UserListLength * SizeOf(RUserInfo);
  for K := 0 to Length(List) - 1 do
  begin
    p^.UserList[K].ID := List[K].ID;
    for I := 0 to 19 do
    begin
      p^.UserList[K].Name[I] := List[K].Name[I];
    end;
//    p^.UserList[K].Name := List[K].Name;
    p^.UserList[K].tcpSocket := 0;
  end;
//  send(socket, p^, P^.Head.Size, 0); ---------------这个地方有问题
  send(socket, p^, p^.Head.Size, 0);
end;

procedure doChat(Msg: RChat);
var
  desSocket: TSocket;
  I: Integer;
begin
  for I := 0 to Length(List) - 1 do
  begin
    if List[I].ID = Msg.DestID then
    begin
      desSocket := List[I].tcpSocket;
      Break;
    end;
  end;
  Msg.Head.Operation := S_CHAT;
  send(desSocket, Msg, SizeOf(Msg), 0);
end;

procedure doScreen(Msg: C_RScreen; recvsize: Integer);
begin
//  CStream.Write(Msg.Pbuf, 1024);
//  size := size + 1024;
//  maxcount := Msg.head.Size div 1024;
//  if count = maxcount then
//  begin
//    if (Msg.head.Size mod 1024) = 0 then
//    begin
//      GetScreen;
//    end
//    else
//    begin
//      Exit;
//    end;
//  end
//  else if count > maxcount then
//  begin
//    FillMemory(@Msg.Pbuf[0], 1024, 0);
//    CStream.Write(Msg.Pbuf, recvsize);
//    CStream.Seek(0, soFromBeginning);
//    map.LoadFromStream(CStream);
//    map.SaveToFile('test.bmp');
//  end;
//   Inc(count);
end;

procedure GetScreen;
var
  Rect: TRect;
  ds: TDecompressionStream; {解压流}
  fs, ms: TMemoryStream;     {fs 是准备要解压的流; ms 是接受解压数据的流}
  num: Integer;
begin
  CStream.SaveToFile('bmp.zipx');
  CStream.Seek(0, soFromBeginning);
  fs := TMemoryStream.Create;
  fs.LoadFromStream(CStream);
  fs.Position := 0;
  fs.ReadBuffer(num, SizeOf(num));
  ms := TMemoryStream.Create;
  ms.SetSize(num);
  ds := TDecompressionStream.Create(fs);
  ds.Read(ms.Memory^, num);
  CStream.Seek(0, soFromBeginning);
  Map.LoadFromStream(ms);
 // SendScreen;
  CStream.Clear;
  CStream.Seek(0, soFromBeginning);
  Form1.Show;
end;

procedure DeleteUserListItem(Index: Integer);
var
  Count: Cardinal;
begin
  Count := Length(List);
  if (Count = 0) or (Index < 0) or (Index >= Count) then
    Exit;
  Move(List[Index + 1], List[Index], (Count - Index) * SizeOf(List[0]));
  SetLength(List, Count - 1);
end;

end.


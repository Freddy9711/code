unit server;

interface

  uses WinSock,StdCtrls,SysUtils,Variants,Classes,Controls,Dialogs,Windows;

const
  PACKAGE_FLAG = $FFEE8899;

type
 MYservers = class
   private

   public
    ServerSocked,NewSocked: TSocket;
    fdSocket,fdRead,fdReadNew:TFDSet;
    CName: AnsiString;
    CAddress: AnsiString;
    BindFlag: Integer;
    Sockaddr,addrRemote: sockaddr_in;
    Sockaddrsize: Integer;
    recvret: Integer;
    i:Integer;
    FDcount:Integer;
    recvmessage: array[0..292] of Char;
    sendbuf: array[0..256] of Char;
    ClientConnect: array[0..20] of TSocket;
    wsaData: TWSADATA;
    selectret : Integer;
    procedure start;
 end;

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

S_RUserList = record
    Head: TChatHead;
    Usercount:Integer;
    UserNameList: array[0..3,0..20] of char;
    UserID: array[0..3,0..20] of char;
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
  Flag: Integer;
  Size: Integer;
  Operation: Integer;
  DestID: Integer;
  SrcID: Integer;
  SrcName: array[0..19] of Char;
  UersName: array[0..19] of Char;
  Password: array[0..19] of Char;
  Sign:Boolean;
  UserInfoString: TStringList;
  Msg: array[0..255] of AnsiChar;
  end;
type
  UserInfo = record
  Flag: Integer;
  Size: Integer;
  operation:Integer;
  UserInfoString: TStringList;
end;

 MYthread = class(TThread)
  public
    PosSocket: TSocket;
    procedure GetTSocket(ClientSocked: TSocket);
  protected
    procedure Execute;override;
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


implementation

{ MYservers }
procedure DoEvent(ClientSocked :TSocket);
var
  SendMessage: array[0..256] of Char;
begin
   SendMessage := 'this is server';
   send(ClientSocked,SendMessage,256,0);
   while True do
   begin
    fillchar(SendMessage, sizeof(SendMessage), 0);
    Readln(SendMessage);
    send(ClientSocked,SendMessage,256,0);
    fillchar(SendMessage, sizeof(SendMessage),0);
   end;
end;




procedure MYservers.start;
var
  timeout: timeval;
  clientaddr: sockaddr_in;
  arrlength: Integer;
  RecvString: AnsiString;
  RecvFlag: Integer;
  I:Integer;
  J:Integer;
  cloginobj: C_RLogin;
  cregisterobj: C_RRegeister;
  loginobj: S_RLogin;
  registerobj: S_RRegeister;
  headobj: TChatHead;
  listobj: S_RUserList;
  Name: AnsiString;
  ID: AnsiString;
begin
    WSAStartup(MAKEWORD(2, 2), wsaData);
    ServerSocked := socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
    if ServerSocked = SOCKET_ERROR then
    begin
      ShowMessage('socket error!');
      Exit;
    end
    else
    begin
      Writeln('socket success!');
    end;
    Sockaddr.sin_family := PF_INET;
    Sockaddr.sin_port := htons(1777);
    Sockaddr.sin_addr.s_addr := inet_addr('127.0.0.1');

    bind(ServerSocked,Sockaddr,SizeOf(sockaddr));
    if BindFlag = SOCKET_ERROR  then
    begin
      Writeln('bind error!');
      Exit;
    end
    else
    begin
      Writeln('bind success!');
    end;
    listen(ServerSocked,20);
    FillMemory(@fdSocket, sizeof(TFDSet), 0);
    FD_SET(ServerSocked, fdSocket);
    timeout.tv_sec := 3;
    timeout.tv_usec :=0;
    while True do
    begin
      fdRead := fdSocket;
      FDcount := fdSocket.fd_count;
      selectret :=  select(0, @fdRead, nil, nil, nil);
      i := 0;
      if selectret > 0 then
      begin
        for I := 0 to FDcount - 1 do
        begin
          if FD_ISSET(fdSocket.fd_array[i], fdRead) then
          begin
            if fdSocket.fd_array[i] = ServerSocked  then
            begin
              Sockaddrsize := SizeOf(clientaddr);
              NewSocked := accept(ServerSocked,PSOCKADDR(@clientaddr),@Sockaddrsize);
              if fdSocket.fd_count < FD_SETSIZE then
              begin
                FD_SET(NewSocked,fdSocket);
                Writeln('接收到连接：'+strpas(inet_ntoa(clientaddr.sin_addr)));
                Continue;
              end
              else
              begin
                Writeln('连接太多，超出系统要求');
                closesocket(NewSocked);
              end;
            end
            else
            begin
            // SetLength(recvmessage,280);
              RecvFlag := recv(fdSocket.fd_array[i], recvmessage, 76, 0);
              CopyMemory(@headobj, @recvmessage, 20);
              if headobj.Operation = C_REGEISTER then
              begin
                CopyMemory(@cregisterobj, @recvmessage, 76);
                Writeln(cregisterobj.UserName);
                Writeln(cregisterobj.Password);
                registerobj.Sign := True;
                registerobj.Head.Operation := S_REGEISTER ;
                registerobj.Head.Flag :=  PACKAGE_FLAG;
                registerobj.Head.Size :=  SizeOf(registerobj);
                send(fdSocket.fd_array[i], registerobj, 300, 0);
              end
              else if headobj.Operation = C_LOGIN then
              begin
                CopyMemory(@cloginobj, @recvmessage, 76);
                Writeln(cloginobj.UserName);
                Writeln(cloginobj.Password);
                loginobj.Sign := True;
                loginobj.Head.Operation := S_LOGIN;
                loginobj.Head.Flag :=  PACKAGE_FLAG;
                loginobj.Head.Size := SizeOf(loginobj);
                send(fdSocket.fd_array[i], loginobj, 340, 0);
              end
             else if headobj.Operation = C_GETONLINEUERS then
              begin
                listobj.UserNameList[0] := '小明';
                listobj.UserID[0] := '574643313';
                listobj.UserNameList[1] := '小李';
                listobj.UserID[1] := '867941346';
                listobj.UserNameList[2] := '小林';
                listobj.UserID[2] :=  '9765656566';
                listobj.UserNameList[3] :='小王';
                listobj.UserID[3] := '46446464656';
                listobj.Head.Operation := S_GETONLINEUERS;
                listobj.Head.flag := PACKAGE_FLAG;
                listobj.head.Size := SizeOf(listobj);
                listobj.Usercount := 4;
                send(fdSocket.fd_array[i], listobj, SizeOf(listobj), 0);
              end;
              if RecvFlag < 0 then
              begin
                closesocket(fdSocket.fd_array[i]);
                FD_CLR(fdSocket.fd_array[i],&fdSocket);
                Continue;
              end;

             // Writeln(TChat(recvmessage).msgs);
            {  for j := 0 to FDcount - 1 do
              begin
                if fdSocket.fd_array[i] <> fdSocket.fd_array[j] then
                begin
                  sendbuf := #0;
                  StrPCopy(sendbuf,RecvString);
                  send(fdSocket.fd_array[j], sendbuf, 256, 0);
                end;
              end; }
            end;
          end;
          end;
        end;
      end;

    closesocket(ServerSocked);
    WSACleanup();
end;

{ MYthread }



{ MYthread }

procedure MYthread.Execute;

begin
  inherited;
  DoEvent(PosSocket);
end;

procedure MYthread.GetTSocket(ClientSocked: TSocket);
begin
  PosSocket := ClientSocked;
end;

end.

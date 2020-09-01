unit server;

interface

  uses WinSock,StdCtrls,SysUtils,Variants,Classes,Controls,Dialogs,Windows;

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
    recvmessage: array[0..256] of Char;
    sendbuf: array[0..256] of Char;
    ClientConnect: array[0..20] of TSocket;
    wsaData: TWSADATA;
    selectret : Integer;
    procedure start;

 end;

 MYthread = class(TThread)
  public
    PosSocket: TSocket;
    procedure GetTSocket(ClientSocked: TSocket);
  protected
    procedure Execute;override;
 end;
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
              recvmessage := #0;
              RecvFlag := recv(fdSocket.fd_array[i], recvmessage, 256, 0);
              if RecvFlag < 0 then
              begin
                closesocket(fdSocket.fd_array[i]);
                FD_CLR(fdSocket.fd_array[i],&fdSocket);
                Continue;
              end;
              
              RecvString := '用户' + IntToStr(i) + ':  '+recvmessage;
              Writeln(RecvString);
              for j := 0 to FDcount - 1 do
              begin
                if fdSocket.fd_array[i] <> fdSocket.fd_array[j] then
                begin
                  sendbuf := #0;
                  StrPCopy(sendbuf,RecvString);
                  send(fdSocket.fd_array[j], sendbuf, 256, 0);
                end;
              end;
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

unit cilent;

interface

  uses WinSock,StdCtrls,SysUtils,Variants,Classes,Controls,Dialogs;
type
  MYclient = class
  private

  public
    Socked: TSocket;
    Sockaddr_inc: sockaddr_in;
    Sockaddrsize: Integer;
    SendMessage: array[0..256] of Char;
    ConnectFlag: Integer;
    recvret: Integer;
    wsaData: WSADATA;
    procedure start;
    procedure SRMessage;
end;

  MessageThread = class(TThread)
  public
    RecvSocked: TSocket;
    procedure GetInfo(Socked: TSocket);
    procedure Execute; override;
  private
end;
implementation

{ MYclient }

procedure MYclient.SRMessage;
var
RecvThread : MessageThread;
begin
  RecvThread := MessageThread.Create(True);
  RecvThread.GetInfo(Socked);
  RecvThread.Resume;
  while True do
  begin
    Readln(SendMessage);
    send(Socked, SendMessage, 256, 0);
  end;


end;

procedure MYclient.start;
begin
  WSAStartup($0101, &wsaData);
  Socked := Socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
  if Socked = SOCKET_ERROR then
  begin
    ShowMessage('socket error!');
  end
  else
  begin
    Writeln('socket success');
  end;
  Sockaddr_inc.sin_family :=  PF_INET;
  Sockaddr_inc.sin_port := htons(1777);
  Sockaddr_inc.sin_addr.S_addr := inet_addr('127.0.0.1');
  ConnectFlag := connect(Socked,Sockaddr_inc,SizeOf(TSockAddr));
  if ConnectFlag < 0 then
  begin
    Writeln('connect error!');
  end
  else
  begin
    Writeln('connect success!');
  end;
  SRMessage;
end;

{ MessageThread }

procedure MessageThread.Execute;
var RecvMessage: array[0..256] of Char;
begin
  inherited;
  while True do
  begin
    if recv(RecvSocked, RecvMessage, 256,0) <= 0 then
    begin
      break;
    end;
    Writeln(RecvMessage);
  end;


end;

procedure MessageThread.GetInfo(Socked: TSocket);
begin
  RecvSocked := Socked;
end;

end.

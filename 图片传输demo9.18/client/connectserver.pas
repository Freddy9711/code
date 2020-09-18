unit connectserver;


interface
uses  Classes, SyncObjs, WinSock, Windows, sendrecv;


const
  PACKAGE_FLAG = $FFEE8899;

type
  PCharHead = ^TChatHead;
  TChatHead = record
    Flag: Cardinal;
    Size: Integer;
    Operation: Integer;
    ParamInt: Integer;
    ParamStr: array[0..63] of AnsiChar;
end;

type
  PDataNode = ^TDataNode;
  TDataNode = record
    Head: TChatHead;
    BufPtr: PByte;
    BufSize: Integer;
    NextPtr: PDataNode;
  end;

type
  TClientSign = (ClNone, ClConnect, CLConnected);

type
 Tcilent = class(TThread)
 public
  procedure SetIPPort(IP_: AnsiString; Port_: Integer);


 private
  FClientSign: TClientSign;
  Fsocked : TSocket;
  Sockaddr: sockaddr_in;
  Connectflag: Integer;
  FConnectFail: Boolean;
  FIP: AnsiString;
  Fport: Integer;
  FConnected: Boolean;
  FReadBuf: array[0..1024 * 100] of Byte;
  FReadBufSize: Integer;
  FReadOffset: Integer;
  FLock: TCriticalSection;
  FSendDatas: PDataNode;
  wsaData: WSADATA;
  procedure InitSocket;
  procedure DoProcessTransferData;

 protected
  procedure Execute; override;
 public
  LoginSign: Boolean;

  property ConnectFailed: Boolean read FConnectFail;
  property Connected: Boolean read FConnected;
  property socked: TSocket  read Fsocked;
 end;

var
  client: Tcilent;
  sendobj: TMessageSend;
  recvobj: TMessageRecv;

implementation

{ Tcilent }

procedure Tcilent.DoProcessTransferData;
var
  RecvSize, RemainSize: Integer;
  HeadPtr: PCharHead;
begin
  RecvSize := recv(Fsocked, FReadBuf[FReadOffset], 1024, 0);
  FReadBufSize := FReadBufSize + RecvSize;

  while FReadBufSize >= SizeOf(TChatHead) do
  begin
    HeadPtr := PCharHead(@FReadBuf[FReadOffset]);
    if HeadPtr^.Flag = PACKAGE_FLAG then
    begin
      if HeadPtr^.Size <= FReadBufSize then
      begin
        //DoProcessResponse();

        RemainSize := FReadBufSize - HeadPtr^.Size;;
        //FReadOffset :=
        //Copy(FReadBuf[0], FReadBufSize - RemainSize, RemainSize);
        FReadOffset := RemainSize;
        FReadBufSize := RemainSize;
      end;
    end
    else
    begin

    end;
  end;

  FLock.Enter;
  try
    FSendDatas := nil;
  finally
    FLock.Leave;
  end;

end;

procedure Tcilent.Execute;
begin
    while not Terminated do
    begin
      if FConnected = False then
       begin
        InitSocket;
       end
       else if LoginSign = True  then
       begin

       end;

    end;
  end;


procedure Tcilent.InitSocket;
begin
  WSAStartup(MAKEWORD(2, 2), wsaData);
  Fsocked := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Fsocked <0 then
  begin
    FConnectFail := True;
    Exit;
  end;
  Sockaddr.sin_family := PF_INET;
  Sockaddr.sin_port := htons(FPort);
  Sockaddr.sin_addr.s_addr := inet_addr(PAnsiChar(FIP));
  ConnectFlag := Connect(Fsocked, sockaddr, SizeOf(sockaddr_in));
  if ConnectFlag < 0  then
  begin
    FConnectFail := True;
    Exit;
  end
  else
  begin
    FConnected := True;
    FClientSign := CLConnected;
  end;
  end;



procedure Tcilent.SetIPPort(IP_: AnsiString; Port_: Integer);
begin
   if FClientSign = ClNone then
  begin
    FIP := IP_;
    Fport := port_;
  end;
end;

end.

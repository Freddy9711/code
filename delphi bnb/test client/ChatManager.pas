unit ChatManager;

interface

uses
  ChatProtocol, TCPClient, SyncObjs, Winapi.Windows;

type
//  const
//   PRESSW =

  TChatMgr = class(TTCPClient)
  private
    FServerMsgs: TLockChatMsgs;
    FAccount: AnsiString;
    FPlayerInfo: TPlayerInfo;
  protected
    procedure ProcessReadData; override;
  public
    procedure ReadResponse(Msgs: TChatMsgs);
    procedure WirtePlayerInfo(Player: PTPlayerInfo);
    function RequestRegister(Account: string; Password: string): Integer;
    function RequestLogin(Account: string; Password: string): Integer;
    function RequestMap: Integer;
    function RequestBotList: Integer;
    function RequestBoom: Integer;
    function RequestMove(Key: Word): Integer;
    function RequestStopMove(Key: Word): Integer;
    function ReadPlayerInfo: PTPlayerInfo;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Account: AnsiString read FAccount;
  end;

var
  ChatMgr: TChatMgr;

implementation

uses
  SysUtils;

{ TChatMgr }

constructor TChatMgr.Create;
begin
  FServerMsgs := TLockChatMsgs.Create;

  inherited Create;
end;

destructor TChatMgr.Destroy;
begin
  inherited;
  FServerMsgs.Free;
end;

procedure TChatMgr.ProcessReadData;
var
  BufPtr: PByte;
  BufSize, FetchSize: Integer;
  MsgPtr: PChatMsg;
begin
  LockReadBuffer(BufPtr, BufSize);

  FetchSize := 0;
  try
    if BufSize <= 0 then
      Exit;

    while BufSize >= SizeOf(TChatMsgHead) do
    begin
      while BufSize >= 4 do
      begin
        if PCardinal(BufPtr)^ <> PACK_FLAG then
        begin
          BufSize := BufSize - 1;
          BufPtr := Pointer(Integer(BufPtr) + 1);
          FetchSize := FetchSize + 1;
        end
        else
          break;
      end;

      if BufSize >= SizeOf(TChatMsgHead) then
      begin
        if PChatMsgHead(BufPtr)^.Size <= BufSize then
        begin
          FetchSize := FetchSize + PChatMsgHead(BufPtr)^.Size;

          GetMem(MsgPtr, PChatMsgHead(BufPtr)^.Size);
          System.Move(BufPtr^, MsgPtr^, PChatMsgHead(BufPtr)^.Size);

          BufSize := BufSize - MsgPtr^.Head.Size;
          BufPtr := Pointer(Integer(BufPtr) + MsgPtr^.Head.Size);

          FServerMsgs.AddTail(MsgPtr);
        end
        else
          break;
      end;
    end;

  finally
    UnlockReadBuffer(FetchSize);
  end;
end;

procedure TChatMgr.WirtePlayerInfo(Player: PTPlayerInfo);
begin
  FPlayerInfo := Player^;
end;

function TChatMgr.ReadPlayerInfo: PTPlayerInfo;
begin
  Result := @FPlayerInfo;
end;

procedure TChatMgr.ReadResponse(Msgs: TChatMsgs);
begin
  FServerMsgs.FetchTo(Msgs);
end;

function TChatMgr.RequestBoom: Integer;
var
  ReqBoom: TPlayerSetBoom;
begin
  //
  FillChar(ReqBoom, SizeOf(ReqBoom), 0);
  ReqBoom.head.Flag := PACK_FLAG;
  ReqBoom.head.Size := SizeOf(ReqBoom);
  ReqBoom.head.Command := C_BOOM;
  CopyMemory(@ReqBoom.PlayerName[0], Pointer(FAccount), Length(FAccount));

  if WriteSendData(@ReqBoom, SizeOf(ReqBoom)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestBotList: Integer;
var
  CBotList: TReqbotlist;
begin
  FillChar(CBotList, SizeOf(CBotList), 0);
  CBotList.head.Flag := PACK_FLAG;
  CBotList.head.Size := SizeOf(CBotList);
  CBotList.head.Command := C_REQBOTlIST;
  CBotList.head.Param := 10;
  if WriteSendData(@CBotList, SizeOf(CBotList)) < 0 then
    Result := -3;
//  OutputDebugString('������������б�');
end;

function TChatMgr.RequestLogin(Account, Password: string): Integer;
var
  CMLogin: TCMLogin;
begin
  if Length(Account) >= Length(CMLogin.UserName) then
  begin
    Result := -1;
    Exit;
  end;

  if Length(Password) >= Length(CMLogin.Password) then
  begin
    Result := -2;
    Exit;
  end;

  Result := 0;

  FAccount := Account;

  FillChar(CMLogin, SizeOf(CMLogin), 0);
  CMLogin.Head.Flag := PACK_FLAG;
  CMLogin.Head.Size := SizeOf(CMLogin);
  CMLogin.Head.Command := C_LOGIN;

  strpcopy(@CMLogin.UserName[0], AnsiString(Account));
  strpcopy(@CMLogin.Password[0], AnsiString(Password));

  if WriteSendData(@CMLogin, SizeOf(CMLogin)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestRegister(Account, Password: string): Integer;
var
  CMReg: TCMRegister;
begin
  if (Length(Account) >= Length(CMReg.UserName)) then
  begin
    Result := -1;
    Exit;
  end;

  if (Length(Password) >= Length(CMReg.Password)) then
  begin
    Result := -2;
    Exit;
  end;

  Result := 0;

  FillChar(CMReg, SizeOf(CMReg), 0);
  CMReg.Head.Flag := PACK_FLAG;
  CMReg.Head.Size := SizeOf(CMReg);
  CMReg.Head.Command := C_REGISTER;

  strpcopy(@CMReg.UserName[0], AnsiString(Account));
  strpcopy(@CMReg.Password[0], AnsiString(Password));

  if WriteSendData(@CMReg, SizeOf(CMReg)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestStopMove(Key: Word): Integer;
var
  CReqStopMove: TPlayerStopMove;
begin
  Result := 0;
  FillChar(CReqStopMove, SizeOf(TPlayerStopMove), 0);
  CReqStopMove.head.Flag := PACK_FLAG;
  CReqStopMove.head.Size := SizeOf(TPlayerStopMove);
  CReqStopMove.head.Command := C_STOPMOVE;
  CopyMemory(@CReqStopMove.PlayerName[0], Pointer(FAccount), Length(FAccount));

  if WriteSendData(@CReqStopMove, SizeOf(CReqStopMove)) < 0 then
    Result := -3;

end;

function TChatMgr.RequestMap: Integer;
var
  CReqMap: TCMap;
begin
  Result := 0;
  FillChar(CReqMap, SizeOf(CReqMap), 0);
  CReqMap.Head.Flag := PACK_FLAG;
  CReqMap.Head.Size := SizeOf(CReqMap);
  CReqMap.Head.Command := C_Map;

  if WriteSendData(@CReqMap, SizeOf(CReqMap)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestMove(Key: Word): Integer;
var
  CReqMove: TPlayerMove;
begin
  Result := 0;
  FillChar(CReqMove, SizeOf(CReqMove), 0);
  CReqMove.head.Flag := PACK_FLAG;
  CReqMove.head.Size := SizeOf(CReqMove);
  CReqMove.head.Command := C_MOVE;
  CopyMemory(@CReqMove.PlayerName[0], Pointer(FAccount), Length(FAccount));

  case Key of
    Word('A'):
      CReqMove.MoveType := MOVELEFT;
    Word('S'):
      CReqMove.MoveType := MOVEDOWN;
    Word('W'):
      CReqMove.MoveType := MOVEUP;
    Word('D'):
      CReqMove.MoveType := MOVERIGHT;
    Word('B'):
      begin
        CReqMove.head.Command := C_GETBOTINFO;
      end;
  end;

  if WriteSendData(@CReqMove, SizeOf(CReqMove)) < 0 then
    Result := -3;

end;

initialization
  ChatMgr := TChatMgr.Create;

finalization
  FreeAndNil(ChatMgr);

end.


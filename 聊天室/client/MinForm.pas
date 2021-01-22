unit MinForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinSock, sendrecv, SyncObjs, ExtCtrls, ZLib, Tools;

type
  TMintForm = class(TForm)
    MessageMemo: TMemo;
    Btsend: TButton;
    SendMemo: TMemo;
    btreaduser: TButton;
    Timer1: TTimer;
    userbox: TComboBox;
    btsharescreen: TButton;
    btrecvscreen: TButton;
    Timer2: TTimer;
    btstopshare: TButton;
    btcontrol: TButton;
    constructor Create(AOwner: TComponent); override;
    procedure BtsendClick(Sender: TObject);
    procedure AddMessageString;
    procedure btreaduserClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btsharescreenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btrecvscreenClick(Sender: TObject);
    procedure btstopshareClick(Sender: TObject);
    procedure btcontrolClick(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    FLock: TCriticalSection;
  public
    PrevMap: TBitmap;
    BackMap: TBitmap;
    PrevKeyStatus: TKeyboardState;
  end;

type
  TReadUserInfo = class(TThread)
  public
    Consocket: TSocket;
    recvmes: array[0..32787] of Byte;
    headmes: TChatHead;
    count: Integer;
    maxcount: Integer;
    FRrcvscreen: Boolean;
    procedure GetSock(Socked: TSocket);
    procedure RecvInfo;
    procedure GetScreen;
    procedure ParseMouseControlInfo(RecvControl: S_RControl_MOUSE);
    procedure ParseKeyControlInfo(RecvControl: S_RControl_KEY);
  private
    FEvent: TEvent;
    FStarted: Boolean;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
    procedure StartWork;
  protected
    procedure Execute; override;
  end;

  TSendScreenInfo = class(TThread)
  public
    Consocket: TSocket;
    BitMap: TBitmap;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  public
    procedure GetScreen;
    procedure CompressScreen;
    procedure SendScreen;
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

  TControlScreen = class(TThread)
  public
    Consocket: TSocket;
    SendEvent: EventOperator;
    MouseButton: TMouseButton;
    procedure SetPos(X: Integer; Y: integer);
  private
    PosX: Integer;
    PosY: Integer;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  protected
    procedure Execute; override;
  end;

var
  MintForm: TMintForm;
  userinfo: Tuserinfo;
  MessageString: AnsiString;
  ReadUserInfo: TReadUserInfo;
  SendScreenInfo: TSendScreenInfo;
  MessageInfo: TMessageInfo;
  RecvMessage: TChat;
  UserCount: Integer;
  UserList: array of RUserInfo;
  RecvUserList: array of RUserInfo;
  MessageStrings: AnsiString;
  BitMap: TBitmap;
  RevcBitMap: TBitmap;
  ScreenMessage: C_RScreen;
  PStream: TMemoryStream;
  CStream: TMemoryStream;
  Flist: Tlist;
  Fworklist: TList;
  RecvScreenCount: Integer;
  RecvScreen: S_RScreen;
  RecvControlMouse: S_RControl_MOUSE;
  RecvControlKey: S_RControl_KEY;
  FControlScreen: TControlScreen;
  EventMessageMouse: C_RControl_MOUSE;
  EventMessageKey: C_RControl_KEY;

implementation

{$R *.dfm}
uses
  connectserver, LoginForm, ScreenForm;

function FindListID(Name: AnsiString): Integer;
var
  I: Integer;
  TmpString: AnsiString;
begin
  for I := 0 to Length(UserList) - 1 do
  begin
    TmpString := UserList[I].Name;
    if SysUtils.CompareStr(TmpString, Name) = 0 then
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

procedure TMintForm.btcontrolClick(Sender: TObject);
begin
  FControlScreen := TControlScreen.Create(True);
  FControlScreen.SendEvent := NoEvent;
  FControlScreen.Resume;
  Timer2.Enabled := True;
end;

procedure TMintForm.btreaduserClick(Sender: TObject);
begin
  sendobj.GetSock(client.socked);
  sendobj.SetOperator(C_GETONLINEUERS);
  sendobj.Resume;
  if ReadUserInfo = nil then
    ReadUserInfo := TReadUserInfo.Create(True);
  ReadUserInfo.GetSock(client.socked);
  ReadUserInfo.StartWork;
  ReadUserInfo.Resume;
  Timer1.Enabled := True;

end;

procedure TMintForm.btrecvscreenClick(Sender: TObject);
begin
  if ReadUserInfo = nil then
  begin
    ShowMessage('请加载用户');
    Exit;
  end;
  ReadUserInfo.FRrcvscreen := True;
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
    if Length(PosName) = 0 then
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

procedure TMintForm.btsharescreenClick(Sender: TObject);
var
  i: Integer;
begin
  PosName := userBox.Text;
  if Length(PosName) = 0 then
  begin
    ShowMessage('请选择聊天用户');
    Exit;
  end;
  PosID := FindListID(PosName);
  MyID := FindListID(MyName);
  if SendScreenInfo = nil then
    SendScreenInfo := TSendScreenInfo.Create(True);
  SendScreenInfo.Resume;
end;

procedure TMintForm.btstopshareClick(Sender: TObject);
begin
  SendScreenInfo.Suspend;
end;

constructor TMintForm.Create(AOwner: TComponent);
begin
  inherited;
  Flist := TList.Create;
  FList := TList.Create;
  FWorkList := TList.Create;
  FLock := TCriticalSection.Create;
  PrevMap := TBitmap.Create;
  PrevMap.PixelFormat := pf24bit;
  BackMap := TBitmap.Create;
  BackMap.PixelFormat := pf24bit;
end;

procedure TMintForm.FormCreate(Sender: TObject);
begin
  userbox.Clear;
  MessageMemo.Clear;
  SendMemo.Clear;
  MintForm.Caption := MyName;
end;

procedure TMintForm.Timer1Timer(Sender: TObject);
begin
  userinfo.GetInfo(userbox);
  MessageInfo.GetMessage(MessageMemo);
end;

procedure TMintForm.Timer2Timer(Sender: TObject);
var
  KeyStatus: TKeyboardState;
  i: Integer;
  IfChange: Boolean;
begin
  IfChange := False;
  GetKeyboardState(KeyStatus);
  for i := 0 to 255 do
  begin
    if KeyStatus[i] <> PrevKeyStatus[i] then
    begin
      PrevKeyStatus[i] := KeyStatus[i];
      if (KeyStatus[i] = 1) or (KeyStatus[i] = 0) then
      begin
        EventMessageKey.EventType := KeyUpEvent;
      end
      else if KeyStatus[i] > 1 then
      begin
        EventMessageKey.EventType := KeyDownEvent;
      end;
      IfChange := True;
    end;
  end;

  if IfChange = True then
  begin
    EventMessageKey.head.Flag := PACKAGE_FLAG;
    EventMessageKey.head.Size := SizeOf(EventMessageKey);
    EventMessageKey.head.Operation := C_CONTROL_KEY;
    CopyMemory(@(EventMessageKey.KeyStatus), @KeyStatus, 256);
    send(client.socked, EventMessageKey, SizeOf(EventMessageKey), 0);
  end;
end;

constructor TReadUserInfo.Create(CreateSuspended: Boolean);
begin
  FEvent := TEvent.Create(nil, True, False, '');
  self.count := 0;
  inherited Create(True);
end;

destructor TReadUserInfo.Destroy;
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;
  inherited;
  FEvent.Free;
end;

procedure TReadUserInfo.Execute;
begin
  while not terminated do
    RecvInfo;
  Application.ProcessMessages;
end;

procedure TReadUserInfo.GetScreen;
var
  ds: TDecompressionStream; {解压流}
  fs, ms: TMemoryStream;     {fs 是准备要解压的流; ms 是接受解压数据的流}
  num: Integer;
begin
//  CStream.SaveToFile('bmp.zipx');
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
  RevcBitMap.LoadFromStream(ms);
  CStream.Clear;
  CStream.Seek(0, soFromBeginning);
  ScreenFor.show;
end;

procedure TReadUserInfo.GetSock(Socked: TSocket);
begin
  Consocket := Socked;
end;

procedure TReadUserInfo.ParseKeyControlInfo(RecvControl: S_RControl_KEY);
var
  NowKeyStatus: TKeyboardState;
  I: Integer;
begin
  for I := 0 to 255 do
  begin
    if NowKeyStatus[I] <> RecvControl.KeyStatus[I] then
    begin
      NowKeyStatus[I] := RecvControl.KeyStatus[I];
      if (NowKeyStatus[I] = 0) or (NowKeyStatus[I] = 1) then
      begin
        keybd_event(I, 0, KEYEVENTF_KEYUP, 0);
      end
      else if NowKeyStatus[I] > 1 then
      begin
        keybd_event(I, 0, 0, 0);
      end;
    end;
  end;

end;

procedure TReadUserInfo.ParseMouseControlInfo(RecvControl: S_RControl_MOUSE);
begin
  if RecvControl.EventType = MouseMoveEvent then
  begin
    SetCursorPos(RecvControl.PointX, RecvControl.PointY); //移动鼠标
    Mouse_event(MOUSEEVENTF_MOVE, 0, 0, 0, 0);
  end
  else if RecvControl.EventType = MouseDownEvent then
  begin
    SetCursorPos(RecvControl.PointX, RecvControl.PointY);
    if RecvControl.FMouseButton = mbLeft then
    begin
      Mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
    end
    else if RecvControl.FMouseButton = mbRight then
    begin
      Mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
    end
    else if RecvControl.FMouseButton = mbMiddle then
    begin
      Mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0);
    end;
  end
  else if RecvControl.EventType = MouseUpEvent then
  begin
    SetCursorPos(RecvControl.PointX, RecvControl.PointY);
    if RecvControl.FMouseButton = mbLeft then
    begin
      Mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    end
    else if RecvControl.FMouseButton = mbRight then
    begin
      Mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
    end
    else if RecvControl.FMouseButton = mbMiddle then
    begin
      Mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0);
    end;
  end;
end;

procedure TReadUserInfo.RecvInfo;
var
  i: Integer;
  TmpNameString: AnsiString;
  TmpIDString: AnsiString;
  RecvSize: Integer;
  SendName: AnsiString;
  msg: AnsiString;
  Pmod: integer;
  PosCrcs: Integer;
begin
  RecvSize := recv(Consocket, recvmes[0], 32788, 0);
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
  end
  else if (headmes.Operation = S_SCREEN) and (FRrcvscreen = True) then
  begin
    CopyMemory(@RecvScreen, @recvmes[0], RecvSize);
    if RecvScreen.Last = False then
    begin
      PosCrcs := CalCRC16(@(RecvScreen.Pbuf), 0, 32767);
      if PosCrcs = RecvScreen.Crcs then
      begin
        CStream.Write(RecvScreen.Pbuf, 32768);
      end;
    end
    else
    begin
      Pmod := RecvScreen.head.Size mod 32768;
      PosCrcs := CalCRC16(@(RecvScreen.Pbuf), 0, Pmod - 1);
      if PosCrcs = RecvScreen.Crcs then
      begin
        CStream.Write(RecvScreen.Pbuf, Pmod);
        if CStream.Size = RecvScreen.head.Size then
        begin
          GetScreen;
        end
        else
        begin
          CStream.Clear;
          CStream.Seek(0, soFromBeginning);
        end;
      end;
    end;
  end
  else if headmes.Operation = S_CONTROL_MOUSE then
  begin
    CopyMemory(@RecvControlMouse, @recvmes[0], RecvSize);
    ParseMouseControlInfo(RecvControlMouse);
  end
  else if headmes.Operation = S_CONTROL_KEY then
  begin
    CopyMemory(@RecvControlKey, @recvmes[0], RecvSize);
    ParseKeyControlInfo(RecvControlKey);
  end;
end;

procedure TReadUserInfo.StartWork;
begin
  FStarted := True;
  FEvent.SetEvent;
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

{ TSendScreen }

procedure TSendScreenInfo.CompressScreen;
var
  cs: TCompressionStream;
  fs, ms: TMemoryStream;
  num: Integer;
begin
  fs := TMemoryStream.Create;
  BitMap.SaveToStream(fs);
  num := fs.Size;
  ms := TMemoryStream.Create;
  ms.Write(num, SizeOf(num));
  cs := TCompressionStream.Create(clMax, ms);
  fs.SaveToStream(cs);
  cs.Free;
  PStream.LoadFromStream(ms);
  PStream.Seek(0, soFromBeginning);
  BitMap.Destroy;
end;

constructor TSendScreenInfo.Create(CreateSuspended: Boolean);
begin
  inherited Create(True);
  BitMap := TBitmap.Create;
end;

destructor TSendScreenInfo.Destroy;
begin
  Terminate;
  inherited;
end;

procedure TSendScreenInfo.Execute;
var
  fs: TMemoryStream;
begin
  while not terminated do
  begin
    GetScreen;
    CompressScreen;
    SendScreen;
  end;
end;

procedure TSendScreenInfo.GetScreen;
var
  sdc: HDC;
  shwnd: THandle;
begin
  BitMap := TBitmap.Create;
  BitMap.PixelFormat := pfDevice;
  BitMap.Width := 960;
  BitMap.Height := 540;
  shwnd := GetDesktopWindow;
  sdc := GetDC(shwnd);
  SetStretchBltMode(BitMap.Canvas.Handle, HALFTONE);
  StretchBlt(BitMap.Canvas.Handle, 0, 0, 960, 540, sdc, 0, 0, Screen.Width, Screen.Height, SRCCOPY);
  ReleaseDC(shwnd, sdc);
end;

procedure TSendScreenInfo.SendScreen;
var
  psize: Integer;
  sendcount: Integer;
  i: Integer;
  pMod: Integer;
begin
  psize := PStream.Size;
  sendcount := PStream.Size div 32768;
  ScreenMessage.head.flag := PACKAGE_FLAG;
  ScreenMessage.head.Size := PStream.Size;
  ScreenMessage.head.Operation := C_SCREEN;
  ScreenMessage.SrcID := PosID;
  ScreenMessage.UserID := MyID;
  ScreenMessage.Last := False;
  StrPCopy(ScreenMessage.UserName, MyName);
  StrPCopy(ScreenMessage.SrcName, PosName);
  PStream.Seek(0, soFromBeginning);
  for i := 0 to sendcount - 1 do
  begin
    PStream.read(ScreenMessage.Pbuf, 32768);
    Screenmessage.Crcs := CalCRC16(@(Screenmessage.Pbuf), 0, 32767);
    send(client.Socked, ScreenMessage, 32836, 0);
  end;
  if (psize mod 32768) <> 0 then
  begin
    ScreenMessage.Last := True;
    FillMemory(@ScreenMessage.Pbuf[0], 32768, 0);
    pMod := psize mod 32768;
    PStream.read(ScreenMessage.Pbuf, pMod);
    Screenmessage.Crcs := CalCRC16(@(Screenmessage.Pbuf), 0, pMod - 1);
    PStream.Clear;
    PStream.Seek(0, soFromBeginning);
    send(client.socked, ScreenMessage, 32836, 0);
  end;
  PStream.Clear;
  PStream.Seek(0, soFromBeginning);
end;

{ TControlScreen }

constructor TControlScreen.Create(CreateSuspended: Boolean);
begin
  inherited Create(True);
//  FillMemory(@PrevKeyStatus, 256, 0);
end;

destructor TControlScreen.Destroy;
begin

  inherited;
end;

procedure TControlScreen.Execute;
begin
  while not terminated do
  begin
    if SendEvent = NoEvent then
    begin
      Continue;
    end
    else if SendEvent = MouseDownEvent then
    begin
      EventMessageMouse.head.Flag := PACKAGE_FLAG;
      EventMessageMouse.head.Size := 24;
      EventMessageMouse.head.Operation := C_CONTROL_MOUSE;
      EventMessageMouse.PointX := PosX;
      EventMessageMouse.PointY := PosY;
      EventMessageMouse.EventType := MouseDownEvent;
      EventMessageMouse.FMouseButton := MouseButton;
      send(client.socked, EventMessageMouse, SizeOf(EventMessageMouse), 0);
      SendEvent := NoEvent;
    end
    else if SendEvent = MouseUpEvent then
    begin
      EventMessageMouse.head.Flag := PACKAGE_FLAG;
      EventMessageMouse.head.Size := 24;
      EventMessageMouse.head.Operation := C_CONTROL_MOUSE;
      EventMessageMouse.PointX := PosX;
      EventMessageMouse.PointY := PosY;
      EventMessageMouse.EventType := MouseUpEvent;
      EventMessageMouse.FMouseButton := MouseButton;
      send(client.socked, EventMessageMouse, SizeOf(EventMessageMouse), 0);
      SendEvent := NoEvent;
    end
    else if SendEvent = MouseMoveEvent then
    begin
      EventMessageMouse.head.Flag := PACKAGE_FLAG;
      EventMessageMouse.head.Size := 24;
      EventMessageMouse.head.Operation := C_CONTROL_MOUSE;
      EventMessageMouse.PointX := PosX;
      EventMessageMouse.PointY := PosY;
      EventMessageMouse.EventType := MouseMoveEvent;
      send(client.socked, EventMessageMouse, SizeOf(EventMessageMouse), 0);
      SendEvent := NoEvent;
    end;
  end;
end;

procedure TControlScreen.SetPos(X, Y: integer);
begin
  PosX := X;
  PosY := Y;
end;

end.


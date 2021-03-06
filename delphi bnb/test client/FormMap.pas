unit FormMap;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  ChatProtocol, Vcl.StdCtrls, ChatManager, GR32, GR32_Image, GR32_PNG,
  Vcl.ExtCtrls, System.DateUtils, Role;

type
  TFrmMap = class(TForm)
    pntbx: TPaintBox32;
    pnl1: TPanel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    lbl6: TLabel;
    lbl7: TLabel;
    lbl1: TLabel;
    lbl8: TLabel;
    tmr1: TTimer;
    btn1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure doWork(Sender: TObject);
    procedure processAni(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function FindInList(const UserList: TUserList; role: TPlayerInfo): Integer;
//    procedure RoleMoveOneStepY;
    procedure RoleMoveOneStepY(Role: TBitmap32; SrcX, SrcY, DesY, tick: Integer);
    procedure RoleMoveStepsY(Role: TBitmap32; SrcX, SrcY, DesY, tick: Integer);
//    procedure RoleMoveOneStepX;
    procedure RoleMoveOneStepX(Role: TBitmap32; SrcY, SrcX, DesX, tick: Integer);
    procedure DrawMap;
    procedure DrawPlayer;
    procedure DrawOnePlayer(PosX, PosY: Integer);
    procedure InitPlayerList;
    procedure SetShoes(Ptr: PTShoesInfo);
    procedure SetBomb(Ptr: PTBombSeted);
    procedure SetBombBoom(Ptr: PTBombBoom);
    procedure PlayerMove(DesPlayer: PTPlayerInfo);
    procedure DrawMapAndPlayer(Sender: TObject);
    procedure AddMoveList(MovePtr: PTOneMove);
    procedure AddBoomList(BoomPtr: PTBoomPic);
    procedure AddBoomFireList(FirePtr: PTBoomFirePic);
    procedure AddDeadPlayer(PlayerPtr: PTPlayerDead);
    procedure DeleteBoomFireListBegin;
    procedure processMove;
    procedure processDeadPlayer;
    procedure MoveCheckMap(X, Y: Integer);
    procedure DrawBoom;
    procedure DrawBoomFire;
    procedure CheckBoomRange(Ptr: PTBombBoom);
    procedure SetPlayerDead(Ptr: PTPlayerDeadEvent);
    procedure DeleteFromUserList(Ptr: PTPlayerDeadEvent);
    procedure DeleteDeadPlayerListBegin;
    procedure DeleteMoveListBegin;
    function FindUserFromList(Id: Integer): PTPlayerInfo;
    function AddUserToList(Ptr: PTPlayerInfo): Integer; // -1 失败 0 成功 1 用户列表已满
    function UpdateUserToList(Ptr: PTPlayerInfo): Integer; // -1 失败 0 成功  1 失败，没有找到要更新的用户
    function FindUseInfoFromList(PosX, PosY: Integer): PTPlayerInfo;
    function IsInMoveList(Id: Integer): Boolean;
    function IsMoveListEmpty: Boolean;
    function IsBoomListEmpty: Boolean;
    function IsBoomFireListEmpty: Boolean;
    function IsDeadPlayerListEmpty: Boolean;
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btn1Click(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
//    procedure tmr1Timer(Sender: TObject);
  private
    FBmpRole: TBitmap32;
    FBmpBoom: TBitmap32;
    FBmpShoe: TBitmap32;
    Fmsgs: TChatMsgs;
    FSrcX, FSrcY, FDesX, FDesY: Integer;
    FMovingRoleIndex: Integer;
    FNewTime, FOldTime: TDateTime;
    bmpRoleW, bmpRoleH, piceRoleW: Integer;
    bmpBoomW, bmpBoomH, piceBoomW: Integer;
    timer: TTimer;
    TickForRole: Integer;
    TickForBomb: Integer;
    FMsgNum: Integer;
    posX, posY: Integer;
    FOldMap: array of Integer;
//    FMap: array of Integer;
    FUsersChanged: Boolean;
    FPressed: Boolean;
    FUserListNew: TUserList; // array[0..4] of TPlayerInfo;
    FUserListOld: TUserList;
//    FUserList: TUserList;
    FMoveListBegin: PTOneMove;
    FMoveListEnd: PTOneMove;
    FBoomListBegin: PTBoomPic;
    FBoomListEnd: PTBoomPic;
    FBoomFireListBegin: PTBoomFirePic;
    FBoomFireListEnd: PTBoomFirePic;
    FPlayerDeadListBegin: PTPlayerDead;
    FplayerDeadListEnd: PTPlayerDead;
    { Private declarations }
  public
    { Public declarations }
  end;

  TRecv = class(TThread)
  protected
    procedure Execute; override;
  public
    procedure doRecvWork;
    constructor Create;
  private
    FMsgs: TChatMsgs;
  public
    FMsgNum: Integer;
  end;

var
  FrmMap: TFrmMap;
  RecvThread: TRecv;
  FMap: array of Integer;
  FUserList: TUserList;
  num : Integer;
implementation

{$R *.dfm}

const
  W = 40;

var
  bmp2, bmp3, bmp4: TBitmap32;
  bmpE, bmpWW, bmpS, bmpN: TBitmap32;
  tick: Integer;
  bmpFireE, bmpFireW, bmpFireN, bmpFireS: TBitmap32;
  bmpFireCenter, bmpFireEEnd, bmpFireWEnd, bmpFireNEnd, bmpFireSEnd, bmpPlayerDead: TBitmap32;
  p1, p2: TRole;
procedure TFrmMap.AddBoomList(BoomPtr: PTBoomPic);
begin
  if FBoomListBegin = nil then
  begin
    FBoomListBegin := BoomPtr;
    FBoomListEnd := BoomPtr;
  end
  else
  begin
    FBoomListEnd.Next := BoomPtr;
    FBoomListEnd := FBoomListEnd.Next;
  end;

end;

procedure TFrmMap.AddDeadPlayer(PlayerPtr: PTPlayerDead);
begin
  if FPlayerDeadListBegin = nil then
  begin
    FPlayerDeadListBegin := PlayerPtr;
    FplayerDeadListEnd := PlayerPtr;
  end
  else
  begin
    FplayerDeadListEnd.Next := PlayerPtr;
    FplayerDeadListEnd := FplayerDeadListEnd.Next;
  end;
end;

procedure TFrmMap.AddBoomFireList(FirePtr: PTBoomFirePic);
begin
  if FBoomFireListBegin = nil then
  begin
    FBoomFireListBegin := FirePtr;
    FBoomFireListEnd := FirePtr;
  end
  else
  begin
    FBoomFireListEnd.Next := FirePtr;
    FBoomFireListEnd := FBoomFireListEnd.Next;
  end;
end;

procedure TFrmMap.AddMoveList(MovePtr: PTOneMove);
begin
  if FMoveListBegin = nil then
  begin
    FMoveListBegin := MovePtr;
    FMoveListEnd := MovePtr;
  end
  else
  begin
    FMoveListEnd.Next := MovePtr;
    FMoveListEnd := FMoveListEnd.Next;
  end;
end;

function TFrmMap.AddUserToList(Ptr: PTPlayerInfo): Integer;
var
  I: Integer;
begin
  if Ptr = nil then
  begin
    Result := -1;
    Exit
  end;
  for I := 0 to Length(FUserList) - 1 do
  begin
    if FUserList[I].UserID = 0 then
    begin
      FUserList[I] := Ptr^;
      FMap[Ptr.UserPosX * 20 + Ptr.UserPosY] := 3;
      Result := 0;
      Exit
    end;
  end;
  if I = Length(FUserList) - 1 then
    Result := 1;
end;

procedure TFrmMap.btn1Click(Sender: TObject);
var
  x, y: Integer;
begin
                      p1 := TRole.Create(1, 1, 1, 50, '123456');
  x := 1 * 40;
  y := 1 * 40 - (p1.Bmp.Height - 40);
  p1.Bmp.DrawTo(pntbx.Buffer, rect(x, y, W + x, y + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
  p2 := TRole.Create(2, 1, 1, 100, '789');
  x := 1 * 40;
  y := 1 * 40 - (p1.Bmp.Height - 40);
  p2.Bmp.DrawTo(pntbx.Buffer, rect(x, y, W + x, y + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
//  bmp3.DrawTo(pntbx.Buffer, x, y);
  pntbx.Invalidate;
  tmr1.Enabled := True;
//  p1.Move(pntbx,1,1,1,2);
//  p1.Move(pntbx,1,1,2,1);
//  p1.Move(pntbx,3,2,3,1);
//  p1.Move(pntbx,3,2,2,2);
//  p1.Move(pntbx,1,1,1,2);
end;

procedure TFrmMap.CheckBoomRange(Ptr: PTBombBoom);
var
  I: Integer;
  DestoryArray: TArrayOfBoomDestroy;
  DestoryX, DestoryY: Integer;
begin
  DestoryArray := Ptr^.DestoryPos;
  for I := 0 to Length(DestoryArray) - 1 do
  begin
    if DestoryArray[I][0] <> -1 then
    begin
      DestoryX := DestoryArray[I][0];
      DestoryY := DestoryArray[I][1];
      FMap[DestoryX * 20 + DestoryY] := 0;
    end;
  end;
end;

procedure TFrmMap.DeleteBoomFireListBegin;
var
  Ptr: PTBoomFirePic;
begin
  Ptr := FBoomFireListBegin;
  FBoomFireListBegin := FBoomFireListBegin^.Next;
  FreeMem(Ptr);
end;

procedure TFrmMap.DeleteDeadPlayerListBegin;
var
  Ptr: PTPlayerDead;
begin
  Ptr := FPlayerDeadListBegin;
  FPlayerDeadListBegin := FPlayerDeadListBegin^.Next;
  FreeMem(Ptr);
end;

procedure TFrmMap.DeleteFromUserList(Ptr: PTPlayerDeadEvent);
var
  I: Integer;
begin
//
  for I := 0 to Length(FUserList) do
  begin
    if FUserList[I].UserName = Ptr^.UserName then
    begin
      FillMemory(@FUserList[I], SizeOf(TPlayerInfo), 0);
      Exit;
    end;
  end;
end;

procedure TFrmMap.DeleteMoveListBegin;
var
  Ptr: PTOneMove;
begin
  Ptr := FMoveListBegin;
  FMoveListBegin := FMoveListBegin.Next;
  FreeMem(Ptr);
end;

procedure TFrmMap.doWork(Sender: TObject);
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
  MapPtr: PTSMap;
  UserPtr: PTPlayerInfo;
  UserListPtr: PTPlayerInfoList;
  BoomFlor: PTBombBoom;
  ShoesPtr: PTShoesInfo;
  BombPtr: PTBombSeted;
  BombBoomPtr: PTBombBoom;
  PlayerDeadPtr: PTPlayerDeadEvent;
begin
  ChatMgr.ReadResponse(FMsgs);
//   FMsgNum := Fmsgs.MsgNum;
  
  while not FMsgs.IsEmpty do
  begin
    FMsgs.FetchNext(MsgPtr);
    if MsgPtr <> nil then
    begin
      ServerMsgPtr := PServerMessage(MsgPtr);
      try
        case ServerMsgPtr^.Head.Command of
          S_MAP:
            begin
              MapPtr := PTSMap(MsgPtr);
              CopyMemory(FMap, @MapPtr^.Map[0], 1600);
            end;
          S_USERLIST:
            begin
              UserListPtr := PTPlayerInfoList(MsgPtr);
              FUserList := UserListPtr^.UserList;
//              FUsersChanged := True;
            end;
          S_PlayerInfo:
            begin
              UserPtr := PTPlayerInfo(MsgPtr);
              AddUserToList(UserPtr);
            end;
          S_PLAYERMOVE:
            begin
              UserPtr := PTPlayerInfo(MsgPtr);
              PlayerMove(UserPtr); //以我现在写的move逻辑的话，多人同时动的话可能存在问题
              Inc(num);
              
              OutputDebugString(PWideChar(IntToStr(num)));
            end;
          S_SETSHOES:
            begin
              ShoesPtr := PTShoesInfo(MsgPtr);
              SetShoes(ShoesPtr);   //鞋子的动画还要加上
            end;
          S_SETBOME:
            begin
              BombPtr := PTBombSeted(MsgPtr);
              SetBomb(BombPtr);
            end;
          S_BOMBBOOM:
            begin
              BombBoomPtr := PTBombBoom(MsgPtr);
              SetBombBoom(BombBoomPtr);
            end;
          S_PLAYERDEAD:
            begin
              PlayerDeadPtr := PTPlayerDeadEvent(MsgPtr);
              SetPlayerDead(PlayerDeadPtr);
            end;
          S_BOTINFO:
            begin
              OutputDebugString('111111111111111111');
            end;
          S_BOTMOVE:
            begin
              OutputDebugString('2222222222222222');
            end;
        end;
        Inc(FMsgNum);
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
//  processAni(self);
  DrawMapAndPlayer(self);
end;

procedure TFrmMap.DrawBoom;
var
  Ptr: PTBoomPic;
  drawY, TickForBomb, x, y, bmpBombH: Integer;
begin
  Ptr := FBoomListBegin;
  while Ptr <> nil do
  begin
    TickForBomb := Ptr^.Tick;
    bmpBombH := FBmpBoom.Height;
    x := Ptr^.PosX * 40;
    y := Ptr^.PosY * 40;
    drawY := y - (bmp4.Height - 40);
    FBmpBoom.DrawTo(pntbx.Buffer, rect(x, drawY, piceBoomW + x, drawY + bmpBombH), Rect(piceBoomW * TickForBomb, 0, piceBoomW * (TickForBomb + 1), bmpBombH));
    Inc(Ptr^.Tick);
    if Ptr^.Tick = 4 then
      Ptr^.Tick := 0;
    Ptr := Ptr.Next;
  end;
end;

procedure TFrmMap.DrawBoomFire;
var
  Ptr, PtrNext: PTBoomFirePic;
  TickForBoomFire, x, y, bmpH, pice, I: Integer;
  PosX, PosY: Integer;
begin
  Ptr := FBoomFireListBegin;
  while Ptr <> nil do
  begin
    TickForBoomFire := Ptr^.Tick;
    //画中心的图
    bmpH := bmpFireCenter.Height;
    x := Ptr^.BombX * 40;
    y := Ptr^.BombY * 40;
    pice := bmpFireCenter.Width div 4;
    bmpFireCenter.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
    if Ptr^.BoomW - 1 > 0 then
    begin
       //画北面的图
      for I := 1 to Ptr^.BoomW - 1 do
      begin
        if I = Ptr^.BoomW - 1 then
        begin
              //画end
          PosX := Ptr^.BombX;
          PosY := Ptr^.BombY - I;
          bmpH := bmpFireNEnd.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireNEnd.Width div 4;
          bmpFireNEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end
        else
        begin
              //画中间
          PosX := Ptr^.BombX;
          PosY := Ptr^.BombY - I;
          bmpH := bmpFireN.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireN.Width div 4;
          bmpFireN.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end;
      end;
    end;
    if Ptr^.BoomA - 1 > 0 then
    begin
       //画西面的图
      for I := 1 to Ptr^.BoomA - 1 do
      begin
        if I = Ptr^.BoomA - 1 then
        begin
              //画end
          PosX := Ptr^.BombX - I;
          PosY := Ptr^.BombY;
          bmpH := bmpFireWEnd.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireWEnd.Width div 4;
          bmpFireWEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end
        else
        begin
              //画中间
          PosX := Ptr^.BombX - I;
          PosY := Ptr^.BombY;
          bmpH := bmpFireW.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireW.Width div 4;
          bmpFireW.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end;
      end;
    end;
    if Ptr^.BoomD - 1 > 0 then
    begin
       //画东面的图
      for I := 1 to Ptr^.BoomD - 1 do
      begin
        if I = Ptr^.BoomD - 1 then
        begin
              //画end
          PosX := Ptr^.BombX + I;
          PosY := Ptr^.BombY;
          bmpH := bmpFireEEnd.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireEEnd.Width div 4;
          bmpFireEEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end
        else
        begin
              //画中间
          PosX := Ptr^.BombX + I;
          PosY := Ptr^.BombY;
          bmpH := bmpFireE.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireE.Width div 4;
          bmpFireE.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end;
      end;
    end;
    if Ptr^.BoomS - 1 > 0 then
    begin
       //画南面的图
      for I := 1 to Ptr^.BoomS - 1 do
      begin
        if I = Ptr^.BoomS - 1 then
        begin
              //画end
          PosX := Ptr^.BombX;
          PosY := Ptr^.BombY + I;
          bmpH := bmpFireSEnd.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireSEnd.Width div 4;
          bmpFireSEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end
        else
        begin
              //画中间
          PosX := Ptr^.BombX;
          PosY := Ptr^.BombY + I;
          bmpH := bmpFireS.Height;
          x := PosX * 40;
          y := PosY * 40;
          pice := bmpFireS.Width div 4;
          bmpFireS.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * TickForBoomFire, 0, pice * (TickForBoomFire + 1), bmpH));
        end;
      end;
    end;
    PtrNext := Ptr^.Next;
    Inc(Ptr^.Tick);
    if Ptr^.Tick = 4 then
    begin
      DeleteBoomFireListBegin;
    end;
    Ptr := PtrNext;
  end;
end;

procedure TFrmMap.DrawMap;
var
  x, y, i, j, drawY, bmpBombH, PosX, PosY, RoleId: Integer;
begin
  x := 0;
  y := 0;
  while x < 800 do
  begin
    while y < 800 do
    begin
      bmp2.DrawTo(pntbx.Buffer, x, y);
      y := y + 40;
    end;
    x := x + 40;
    y := 0;
  end;

  //画地板
  x := 0;
  y := 0;
  while y < 800 do
  begin
    while x < 800 do
    begin
      i := x div 40;
      j := y div 40;
      if FMap[i * 20 + j] = 1 then //cookie//
      begin
        drawY := y - (bmp3.Height - 40);
        bmp3.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if FMap[i * 20 + j] = 2 then  //箱子
      begin
        drawY := y - (bmp4.Height - 40);
        bmp4.DrawTo(pntbx.Buffer, x, drawY);
      end
      else if FMap[i * 20 + j] = 3 then
      begin
        DrawOnePlayer(i, j);
      end
      else if FMap[i * 20 + j] = 5 then //鞋子
      begin
        drawY := y - (FBmpShoe.Height - 40);
        FBmpShoe.DrawTo(pntbx.Buffer, x, drawY);
      end;
      x := x + 40;
    end;
    y := y + 40;
    x := 0;
  end;
  if not IsBoomListEmpty then
    DrawBoom;
  if not IsBoomFireListEmpty then
    DrawBoomFire;
//  if not IsMoveListEmpty then
//    processMove;
  if not IsDeadPlayerListEmpty then
    processDeadPlayer;
end;

procedure TFrmMap.DrawMapAndPlayer(Sender: TObject);
begin
  DrawMap;
//  DrawPlayer;
//   if not IsMoveListEmpty then
//    processMove;
//  if not IsDeadPlayerListEmpty then
//    processDeadPlayer;
  pntbx.Invalidate;
end;

procedure TFrmMap.DrawOnePlayer(PosX, PosY: Integer);
var
  UserPtr: PTPlayerInfo;
  BmpRole, Role: TBitmap32;
  Ptr, PtrNext: PTOneMove;
  x, y: Integer;
begin
  UserPtr := FindUseInfoFromList(PosX, PosY);
  if UserPtr = nil then
    Exit;
  if UserPtr.UserID <> 0 then
  begin
    if not IsInMoveList(UserPtr.UserID) then
    begin
      case UserPtr.FaceTo of
        SOUTH:
          BmpRole := bmpS;
        NORTH:
          BmpRole := bmpN;
        EAST:
          BmpRole := bmpE;
        WEST:
          BmpRole := bmpWW;
      end;
      if UserPtr.UserID = ChatMgr.ReadPlayerInfo^.UserID then
      begin
        case UserPtr.FaceTo of
          SOUTH:
            lbl5.Caption := 'SOUTH';
          NORTH:
            lbl5.Caption := 'NORTH';
          EAST:
            lbl5.Caption := 'EAST';
          WEST:
            lbl5.Caption := 'WEST';
        end;
        lbl3.Caption := IntToStr(UserPtr.Speed);
        lbl7.Caption := IntToStr(UserPtr.UserID);
        if FMsgNum <> StrToInt(lbl8.Caption) then
          lbl8.Caption := IntToStr(FMsgNum);

      end;

      x := UserPtr.UserPosX * 40;
      y := UserPtr.UserPosY * 40 - (FBmpRole.Height - 40);
      BmpRole.DrawTo(pntbx.Buffer, rect(x, y, W + x, y + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
    end
    else
    begin
      Ptr := FMoveListBegin;
      while Ptr <> nil do
      begin
        if (Ptr.SrcX = PosX) and (Ptr.SrcY = PosY) then
        begin
          case Ptr^.FaceTo of
            NORTH:
              Role := bmpN;
            SOUTH:
              Role := bmpS;
            WEST:
              Role := bmpWW;
            EAST:
              Role := bmpE;
          end;
          if Ptr^.SrcX = Ptr^.DesX then
            RoleMoveOneStepY(Role, Ptr^.SrcX, Ptr^.SrcY, Ptr^.DesY, Ptr^.tick);
          if Ptr^.SrcY = Ptr^.DesY then
            RoleMoveOneStepX(Role, Ptr^.SrcY, Ptr^.SrcX, Ptr^.DesX, Ptr^.tick);
          Inc(Ptr^.tick);
        end;
        PtrNext := Ptr^.Next;
        if Ptr^.tick = 6 then
        begin
          MoveCheckMap(Ptr^.DesX, Ptr^.DesY);
          FMap[Ptr^.SrcX * 20 + Ptr^.SrcY] := 0;
          FMap[Ptr^.DesX * 20 + Ptr^.DesY] := 3;
          FindUserFromList(UserPtr.UserID).UserPosX := Ptr.DesX;
          FindUserFromList(UserPtr.UserID).UserPosY := Ptr.DesY;
          FindUserFromList(UserPtr.UserID).FaceTo := Ptr.FaceTo;
          DeleteMoveListBegin;
        end;
        Ptr := PtrNext;
      end;
    end;
  end;
end;

procedure TFrmMap.DrawPlayer;
var
  I: Integer;
  PosX, PosY: Integer;
  BmpRole: TBitmap32;
  tick: Integer;
begin
  for I := 0 to Length(FUserList) - 1 do
  begin
    if FUserList[I].UserID <> 0 then
    begin
      if not IsInMoveList(FUserList[I].UserID) then
      begin
        case FUserList[I].FaceTo of
          SOUTH:
            BmpRole := bmpS;
          NORTH:
            BmpRole := bmpN;
          EAST:
            BmpRole := bmpE;
          WEST:
            BmpRole := bmpWW;
        end;
        if FUserList[I].UserID = ChatMgr.ReadPlayerInfo^.UserID then
        begin
          case FUserList[I].FaceTo of
            SOUTH:
              lbl5.Caption := 'SOUTH';
            NORTH:
              lbl5.Caption := 'NORTH';
            EAST:
              lbl5.Caption := 'EAST';
            WEST:
              lbl5.Caption := 'WEST';
          end;
          lbl3.Caption := IntToStr(FUserList[I].Speed);
          lbl7.Caption := IntToStr(FUserList[I].UserID);
        end;

        PosX := FUserList[I].UserPosX * 40;
        PosY := FUserList[I].UserPosY * 40 - (FBmpRole.Height - 40);
        BmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
//        if FMap[FUserList[I].UserPosX  * 20 + FUserList[I].UserPosY + 1] <> 0 then
//        begin
//          case FMap[FUserList[I].UserPosX  * 20 + FUserList[I].UserPosY + 1] of
//            1:
//              bmp3.DrawTo(pntbx.Buffer, FUserList[I].UserPosX   * 40, (FUserList[I].UserPosY + 1) * 40 - (bmp3.Height - 40));
//            2:
//              bmp4.DrawTo(pntbx.Buffer, FUserList[I].UserPosX   * 40, (FUserList[I].UserPosY + 1) * 40 - (bmp4.Height - 40));
//          end;
//
//        end;
//         DrawMap;
      end;
    end;
  end;
  if not IsMoveListEmpty then
    processMove;
  if not IsDeadPlayerListEmpty then
    processDeadPlayer;
end;

function TFrmMap.FindInList(const UserList: TUserList; role: TPlayerInfo): Integer;
var
  i, j: Integer;
  tmpRole: TPlayerInfo;
begin
  Result := -1;
  for i := 0 to Length(UserList) do
  begin
    tmpRole := UserList[i];
    j := 0;
    while (tmpRole.UserName[j] = role.UserName[j]) and (j <= Length(role.UserName) - 1) do
      Inc(j);
    if j = Length(role.UserName) then
      Result := i;
  end;
end;

function TFrmMap.FindUserFromList(Id: Integer): PTPlayerInfo;
var
  I: Integer;
begin
  for I := 0 to Length(FUserList) - 1 do
  begin
    if FUserList[I].UserID = Id then
    begin
      Result := @FUserList[I];
      Exit
    end;
  end;
  if I = Length(FUserList) - 1 then
    Result := nil;
end;

function TFrmMap.FindUseInfoFromList(PosX, PosY: Integer): PTPlayerInfo;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Length(FUserList) - 1 do
  begin
    if (FUserList[I].UserPosX = PosX) and (FUserList[I].UserPosY = PosY) then
    begin
      Result := @FUserList[I];
      Exit;
    end;

  end;
end;

procedure TFrmMap.FormCreate(Sender: TObject);
begin
//


  FMsgs := TChatMsgs.Create;
  ChatMgr.RequestMap;
//  InitPlayerList;
//  AddUserToList(ChatMgr.ReadPlayerInfo);
  FBmpRole := TBitmap32.Create;
  bmpE := TBitmap32.Create;
  bmpWW := TBitmap32.Create;
  bmpN := TBitmap32.Create;
  bmpS := TBitmap32.Create;
  FBmpShoe := TBitmap32.Create;
  FBmpBoom := TBitmap32.Create;
  bmpFireE := TBitmap32.Create;
  bmpFireW := TBitmap32.Create;
  bmpFireN := TBitmap32.Create;
  bmpFireS := TBitmap32.Create;
  bmpFireEEnd := TBitmap32.Create;
  bmpFireWEnd := TBitmap32.Create;
  bmpFireNEnd := TBitmap32.Create;
  bmpFireSEnd := TBitmap32.Create;
  bmpFireCenter := TBitmap32.Create;
  bmpPlayerDead := TBitmap32.Create;
  FBmpRole.DrawMode := dmTransparent;
  bmpE.DrawMode := dmBlend;
  bmpN.DrawMode := dmBlend;
  bmpS.DrawMode := dmBlend;
  bmpWW.DrawMode := dmBlend;
  FBmpShoe.DrawMode := dmBlend;
  FBmpBoom.DrawMode := dmBlend;
  bmpPlayerDead.DrawMode := dmBlend;
  bmpFireCenter.DrawMode := dmBlend;
  bmpFireW.DrawMode := dmBlend;
  bmpFireN.DrawMode := dmBlend;
  bmpFireS.DrawMode := dmBlend;
  bmpFireE.DrawMode := dmBlend;
  bmpFireEEnd.DrawMode := dmBlend;
  bmpFireWEnd.DrawMode := dmBlend;
  bmpFireNEnd.DrawMode := dmBlend;
  bmpFireSEnd.DrawMode := dmBlend;
  LoadBitmap32FromPNG(FBmpRole, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpE, 'img/redp_m_east.png');
  LoadBitmap32FromPNG(bmpN, 'img/redp_m_north.png');
  LoadBitmap32FromPNG(bmpS, 'img/redp_m_south.png');
  LoadBitmap32FromPNG(bmpWW, 'img/redp_m_west.png');
  LoadBitmap32FromPNG(FBmpBoom, 'img/bomb.png');
  LoadBitmap32FromPNG(FBmpShoe, 'img/shoe.png');
  LoadBitmap32FromPNG(bmpFireCenter, 'img/bbf_center.png');
  LoadBitmap32FromPNG(bmpFireW, 'img/bbf_west.png');
  LoadBitmap32FromPNG(bmpFireWEnd, 'img/bbf_west_end.png');
  LoadBitmap32FromPNG(bmpFireN, 'img/bbf_north.png');
  LoadBitmap32FromPNG(bmpFireNEnd, 'img/bbf_north_end.png');
  LoadBitmap32FromPNG(bmpFireS, 'img/bbf_south.png');
  LoadBitmap32FromPNG(bmpFireSEnd, 'img/bbf_south_end.png');
  LoadBitmap32FromPNG(bmpFireE, 'img/bbf_east.png');
  LoadBitmap32FromPNG(bmpFireEEnd, 'img/bbf_east_end.png');
  LoadBitmap32FromPNG(bmpPlayerDead, 'img/grave.png');
  bmpRoleW := FBmpRole.Width;
  bmpRoleH := FBmpRole.Height;
  piceRoleW := bmpRoleW div 6;
  bmpBoomW := FBmpBoom.Width;
  bmpBoomH := FBmpBoom.Height;
  piceBoomW := bmpBoomW div 4;

  bmp2 := TBitmap32.Create;
  LoadBitmap32FromPNG(bmp2, 'img/floor1.png');

  bmp3 := TBitmap32.Create;
  bmp3.DrawMode := dmBlend;
  LoadBitmap32FromPNG(bmp3, 'img/cookie1.png');

  bmp4 := TBitmap32.Create;
  bmp4.DrawMode := dmBlend;
  LoadBitmap32FromPNG(bmp4, 'img/box1.png');

  PosX := 0;
  PosY := 0;

  SetLength(FMap, 400);
  FillMemory(FMap, 400, 0);

  timer := TTimer.Create(Self);
  timer.OnTimer := doWork;
  timer.Interval := 20;
  timer.Enabled := False;
  FMovingRoleIndex := -1;
  FOldTime := Now;
  FNewTime := Now;

//  RecvThread := TRecv.Create;

end;

procedure TFrmMap.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 32 then
  begin
    ChatMgr.RequestBoom;
    exit;
  end;
  FNewTime := Now;
  if (TickForRole = 0) and (FMovingRoleIndex = -1) and (SecondsBetween(FNewTime, FOldTime) > 0.1) and (not FPressed) then
  begin
    FPressed := True;
    ChatMgr.RequestMove(Key);
    FOldTime := Now;
  end;
end;

procedure TFrmMap.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  ChatMgr.RequestStopMove(Key);
  FPressed := False;
  OutputDebugString('stop111111111111');
end;

procedure TFrmMap.InitPlayerList;
var
  I: Integer;
begin
  for I := 0 to Length(FUserList) - 1 do
  begin
    FUserList[I].UserID := -1;
  end;

end;

function TFrmMap.IsInMoveList(Id: Integer): Boolean;
var
  ptr: PTOneMove;
begin
//
  Result := False;
  if FMoveListBegin = nil then
    Exit;
  ptr := FMoveListBegin;
  while ptr <> nil do
  begin
    if ptr^.UserId = Id then
    begin
      Result := True;
      Exit;
    end
    else
      ptr := ptr^.Next;
  end;
end;

function TFrmMap.IsMoveListEmpty: Boolean;
begin
  Result := False;
  if FMoveListBegin = nil then
    Result := True;
end;

procedure TFrmMap.MoveCheckMap(X, Y: Integer);
begin
  if FMap[X * 20 + Y] = 5 then
    FMap[X * 20 + Y] := 0;
end;

function TFrmMap.IsBoomFireListEmpty: Boolean;
begin
  Result := False;
  if FBoomFireListBegin = nil then
    Result := True;
end;

function TFrmMap.IsBoomListEmpty: Boolean;
begin
  Result := False;
  if FBoomListBegin = nil then
    Result := True;
end;

function TFrmMap.IsDeadPlayerListEmpty: Boolean;
begin
  Result := False;
  if FPlayerDeadListBegin = nil then
    Result := True;
end;

procedure TFrmMap.PlayerMove(DesPlayer: PTPlayerInfo);
var
  id: Integer;
  SrcPlayerPtr: PTPlayerInfo;
  SrcX, SrcY, DesX, DesY: Integer;
  MovePtr: PTOneMove;
begin
  id := DesPlayer^.UserID;
  SrcPlayerPtr := FindUserFromList(id);
  if (SrcPlayerPtr^.UserPosX = DesPlayer^.UserPosX) and (SrcPlayerPtr^.UserPosY = DesPlayer^.UserPosY) then
  begin
    UpdateUserToList(DesPlayer);
    Exit;
  end;

  MovePtr := AllocMem(SizeOf(TOneMove));
  MovePtr^.Next := nil;
  MovePtr^.UserId := id;
  MovePtr^.SrcX := SrcPlayerPtr^.UserPosX;
  MovePtr^.SrcY := SrcPlayerPtr^.UserPosY;
  MovePtr^.DesX := DesPlayer^.UserPosX;
  MovePtr^.DesY := DesPlayer^.UserPosY;
  MovePtr^.FaceTo := DesPlayer^.FaceTo;
  MovePtr^.tick := 0;
  AddMoveList(MovePtr);
  UpdateUserToList(DesPlayer);
end;

procedure TFrmMap.SetBomb(Ptr: PTBombSeted);
var
  PosX, PosY: Integer;
  BoomPtr: PTBoomPic;
begin
  BoomPtr := AllocMem(SizeOf(TBoomPic));
  BoomPtr^.Next := nil;
  BoomPtr^.PosX := Ptr^.BombPosX;
  BoomPtr^.PosY := Ptr^.BombPosY;
  BoomPtr^.tick := 0;
  AddBoomList(BoomPtr);
end;

procedure TFrmMap.RoleMoveOneStepY(Role: TBitmap32; SrcX, SrcY, DesY, tick: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY: Integer;
begin
  piceRoleW := Role.Width div 6;
  if SrcY < DesY then
  begin
    bmpRoleH := Role.Height;
    PosX := SrcX * 40;
    PosY := SrcY * 40 - (bmpRoleH - 40) + (tick + 1) * 40 div 6;
    Role.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * tick, 0, piceRoleW * (tick + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := Role.Height;
    PosX := SrcX * 40;
    PosY := SrcY * 40 - (bmpRoleH - 40) - (tick + 1) * 40 div 6;
    Role.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * tick, 0, piceRoleW * (tick + 1), bmpRoleH));
  end;
end;

procedure TFrmMap.RoleMoveStepsY(Role: TBitmap32; SrcX, SrcY, DesY, tick: Integer);
begin
//
//   if SrcY < DesY then
//   begin
//     RoleMoveStepsY(Role, SrcX, SrcY, srcy+1, tick);
//   end;

end;

procedure TFrmMap.RoleMoveOneStepX(Role: TBitmap32; SrcY, SrcX, DesX, tick: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY: Integer;
begin
  piceRoleW := Role.Width div 6;
  if SrcX < DesX then
  begin
    bmpRoleH := Role.Height;
    PosX := SrcX * 40 + (tick + 1) * 40 div 6;
    PosY := SrcY * 40 - (bmpRoleH - 40);
    Role.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * tick, 0, piceRoleW * (tick + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := Role.Height;
    PosX := SrcX * 40 - (tick + 1) * 40 div 6;
    PosY := SrcY * 40 - (bmpRoleH - 40);
    Role.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * tick, 0, piceRoleW * (tick + 1), bmpRoleH));
  end;
end;

procedure TFrmMap.SetBombBoom(Ptr: PTBombBoom);
var
  BoomPtr: PTBoomPic;
  BoomFirePtr: PTBoomFirePic;
begin
//炸弹消失
  BoomPtr := FBoomListBegin;
  FBoomListBegin := FBoomListBegin.Next;
  FreeMem(BoomPtr);
// 爆炸火花
  BoomFirePtr := AllocMem(SizeOf(TBoomFirePic));
  BoomFirePtr^.Next := nil;
  BoomFirePtr^.BombX := Ptr^.Bombx;
  BoomFirePtr^.BombY := Ptr^.BombY;
  BoomFirePtr^.BoomW := Ptr^.BoomW;
  BoomFirePtr^.BoomA := Ptr^.BoomA;
  BoomFirePtr^.BoomS := Ptr^.BoomS;
  BoomFirePtr^.BoomD := Ptr^.BoomD;
  BoomFirePtr^.tick := 0;
  AddBoomFireList(BoomFirePtr);
// 被炸到的箱子消失
  CheckBoomRange(Ptr);
end;

procedure TFrmMap.SetPlayerDead(Ptr: PTPlayerDeadEvent);
var
  PlayerDeadPtr: PTPlayerDead;
begin
// 列表移除玩家
  DeleteFromUserList(Ptr);
  PlayerDeadPtr := AllocMem(SizeOf(TPlayerDead));
  PlayerDeadPtr^.Next := nil;
  PlayerDeadPtr^.PlayerPosX := Ptr^.PlayerPosX;
  PlayerDeadPtr^.PlayerPosY := Ptr^.PlayerPosY;
//  PlayerDeadPtr^.PlayerName := ptr^.UserName;
  CopyMemory(@PlayerDeadPtr^.PlayerName[0], @Ptr^.UserName, Length(Ptr^.UserName));
  PlayerDeadPtr^.tick := 0;
  AddDeadPlayer(PlayerDeadPtr);
//播放死亡动画
end;

procedure TFrmMap.SetShoes(Ptr: PTShoesInfo);
var
  PosX, PosY: Integer;
begin
  PosX := Ptr^.ShoesPosX;
  PosY := Ptr^.ShoesPosY;
  FMap[PosX * 20 + PosY] := 5;
end;

procedure TFrmMap.tmr1Timer(Sender: TObject);
var desx, desy :Integer;
begin
  desx := 1;
  desy := 2;
  if (p1.x = desx) and (p1.y = desy) then
     Exit;
   p1.Move(pntbx, desx, desy);
   p1.Fmovetime := p1.Fmovetime + tmr1.Interval;

 desx := 2;
 desy := 2;
   p2.Move(pntbx, desx, desy);
   p2.Fmovetime := p2.Fmovetime + tmr1.Interval;
end;

function TFrmMap.UpdateUserToList(Ptr: PTPlayerInfo): Integer; // -1 失败 0 成功  1 失败，没有找到要更新的用户
var
  I: Integer;
begin
  if Ptr = nil then
  begin
    Result := -1;
    Exit
  end;
  for I := 0 to Length(FUserList) - 1 do
  begin
    if FUserList[I].UserID = Ptr^.UserID then
    begin
      FUserList[I].Speed := Ptr^.Speed;
      Result := 0;
      Exit
    end;
  end;
  if I = Length(FUserList) - 1 then
    Result := 1;
end;

procedure TFrmMap.processAni(Sender: TObject);
var
  x, y, i, j: Integer;
  drawX, drawY: Integer;
  RoleNew: TPlayerInfo;
  RoleOld: TPlayerInfo;
  indexRoleOld: Integer;
  indexRoleNew: Integer;
  steps: Integer;
begin
//  if FUsersChanged then
//  begin
  DrawMap;
  for i := 0 to Length(FUserListNew) do
  begin
    RoleNew := FUserListNew[i];
    if RoleNew.UserName[0] = #0 then
      Continue;
    indexRoleOld := FindInList(FUserListOld, RoleNew);
    if indexRoleOld = -1 then
    begin   //角色新建立
      FBmpRole := bmpS;
      PosX := RoleNew.UserPosX * 40;
      PosY := RoleNew.UserPosY * 40 - (FBmpRole.Height - 40);
      FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
      FUserListOld := FUserListNew;
    end
    else if (FUserListOld[indexRoleOld].UserPosX = RoleNew.UserPosX) and (FUserListOld[indexRoleOld].UserPosY = RoleNew.UserPosY) and ((FMovingRoleIndex = -1) or (indexRoleOld <> FMovingRoleIndex)) then
    begin //角色存在没有动作
      case RoleNew.FaceTo of
        NORTH:
          FBmpRole := bmpN;
        SOUTH:
          FBmpRole := bmpS;
        WEST:
          FBmpRole := bmpWW;
        EAST:
          FBmpRole := bmpE;
      end;
      PosX := RoleNew.UserPosX * 40;
      PosY := RoleNew.UserPosY * 40 - (FBmpRole.Height - 40);
      FBmpRole.DrawTo(pntbx.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(0, 0, piceRoleW, bmpRoleH));
    end
    else if (FUserListOld[indexRoleOld].UserPosX <> RoleNew.UserPosX) or (FUserListOld[indexRoleOld].UserPosY <> RoleNew.UserPosY) then
    begin
       //角色移动
      case RoleNew.FaceTo of
        NORTH:
          FBmpRole := bmpN;
        SOUTH:
          FBmpRole := bmpS;
        WEST:
          FBmpRole := bmpWW;
        EAST:
          FBmpRole := bmpE;
      end;
      if FMovingRoleIndex <> indexRoleOld then
        FMovingRoleIndex := indexRoleOld;

      if FUserListOld[indexRoleOld].UserPosX = RoleNew.UserPosX then
      begin
        FSrcX := FUserListOld[indexRoleOld].UserPosX;
        FSrcY := FUserListOld[indexRoleOld].UserPosY;
        FDesX := RoleNew.UserPosX;
        FDesY := RoleNew.UserPosY;
//        RoleMoveOneStepY;
        TickForRole := TickForRole + 1;
        if TickForRole = 6 then
        begin
          FUserListOld[indexRoleOld] := RoleNew;
          TickForRole := 0;
          FMovingRoleIndex := -1;
        end;
      end
      else if FUserListOld[indexRoleOld].UserPosY = RoleNew.UserPosY then
      begin
        FSrcX := FUserListOld[indexRoleOld].UserPosX;
        FSrcY := FUserListOld[indexRoleOld].UserPosY;
        FDesX := RoleNew.UserPosX;
        FDesY := RoleNew.UserPosY;
//        RoleMoveOneStepX;
        TickForRole := TickForRole + 1;
        if TickForRole = 6 then
        begin
          FUserListOld[indexRoleOld] := RoleNew;
          TickForRole := 0;
          FMovingRoleIndex := -1;
        end;
      end;
    end;
  end;
  for i := 0 to Length(FUserListOld) do
  begin
    RoleOld := FUserListOld[i];
    if RoleOld.UserName[0] = #0 then
      Continue;
    indexRoleNew := FindInList(FUserListNew, RoleOld);
    if indexRoleNew = -1 then
    begin
           //角色死亡
      FMap[RoleOld.UserPosX * 20 + RoleOld.UserPosY] := 0;
    end;
  end;
  pntbx.Invalidate;
end;

procedure TFrmMap.processDeadPlayer;
var
  Ptr: PTPlayerDead;
  PtrNext: PTPlayerDead;
  TickForDead: Integer;
  x, y: Integer;
begin
  Ptr := FPlayerDeadListBegin;
  while Ptr <> nil do
  begin
    TickForDead := Ptr^.tick;
    x := Ptr^.PlayerPosX * 40;
    y := Ptr^.PlayerPosY * 40;
    bmpPlayerDead.DrawTo(pntbx.Buffer, x + 5, y - 10);
    Inc(Ptr^.tick);
    PtrNext := Ptr^.Next;
    if Ptr^.tick = 60 then
      DeleteDeadPlayerListBegin;
    Ptr := PtrNext;
  end;

end;

procedure TFrmMap.processMove;
var
  Ptr: PTOneMove;
  Role: TBitmap32;
  PtrNext: PTOneMove;
begin
  Ptr := FMoveListBegin;
  while Ptr <> nil do
  begin
    case Ptr^.FaceTo of
      NORTH:
        Role := bmpN;
      SOUTH:
        Role := bmpS;
      WEST:
        Role := bmpWW;
      EAST:
        Role := bmpE;
    end;
    if Ptr^.SrcX = Ptr^.DesX then
      RoleMoveOneStepY(Role, Ptr^.SrcX, Ptr^.SrcY, Ptr^.DesY, Ptr^.tick);
    if Ptr^.SrcY = Ptr^.DesY then
      RoleMoveOneStepX(Role, Ptr^.SrcY, Ptr^.SrcX, Ptr^.DesX, Ptr^.tick);
    Inc(Ptr^.tick);
    PtrNext := Ptr^.Next;
    if Ptr^.tick = 6 then
    begin
      MoveCheckMap(Ptr^.DesX, Ptr^.DesY);
      FMap[Ptr^.SrcX * 20 + Ptr^.SrcY] := 0;
      FMap[Ptr^.DesX * 20 + Ptr^.DesY] := 3;
      DeleteMoveListBegin;
    end;
    Ptr := PtrNext;
  end;
end;

{ TRecv }

constructor TRecv.Create;
begin
  FMsgs := TChatMsgs.Create;
  SetLength(FMap, 400);
  FillMemory(FMap, 400, 0);
  inherited Create(False);
end;

procedure TRecv.doRecvWork;
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
  MapPtr: PTSMap;
  UserPtr: PTPlayerInfo;
  UserListPtr: PTPlayerInfoList;
  BoomFlor: PTBombBoom;
  ShoesPtr: PTShoesInfo;
  BombPtr: PTBombSeted;
  BombBoomPtr: PTBombBoom;
  PlayerDeadPtr: PTPlayerDeadEvent;
begin
  ChatMgr.ReadResponse(FMsgs);
//   FMsgNum := Fmsgs.MsgNum;
  while not FMsgs.IsEmpty do
  begin
    FMsgs.FetchNext(MsgPtr);
    if MsgPtr <> nil then
    begin
      ServerMsgPtr := PServerMessage(MsgPtr);
      try
        case ServerMsgPtr^.Head.Command of
          S_MAP:
            begin
              MapPtr := PTSMap(MsgPtr);
              CopyMemory(FMap, @MapPtr^.Map[0], 1600);
            end;
          S_USERLIST:
            begin
              UserListPtr := PTPlayerInfoList(MsgPtr);
              FUserList := UserListPtr^.UserList;
//              FUsersChanged := True;
            end;
          S_PlayerInfo:
            begin
              UserPtr := PTPlayerInfo(MsgPtr);
              FrmMap.AddUserToList(UserPtr);
            end;
          S_PLAYERMOVE:
            begin
              UserPtr := PTPlayerInfo(MsgPtr);
              FrmMap.PlayerMove(UserPtr); //以我现在写的move逻辑的话，多人同时动的话可能存在问题
              OutputDebugString('move');
            end;
          S_SETSHOES:
            begin
              ShoesPtr := PTShoesInfo(MsgPtr);
              FrmMap.SetShoes(ShoesPtr);   //鞋子的动画还要加上
            end;
          S_SETBOME:
            begin
              BombPtr := PTBombSeted(MsgPtr);
              FrmMap.SetBomb(BombPtr);
            end;
          S_BOMBBOOM:
            begin
              BombBoomPtr := PTBombBoom(MsgPtr);
              FrmMap.SetBombBoom(BombBoomPtr);
            end;
          S_PLAYERDEAD:
            begin
              PlayerDeadPtr := PTPlayerDeadEvent(MsgPtr);
              FrmMap.SetPlayerDead(PlayerDeadPtr);
            end;
          S_BOTINFO:
            begin
              OutputDebugString('111111111111111111');
            end;
          S_BOTMOVE:
            begin
              OutputDebugString('2222222222222222');
            end;
        end;
        Inc(FMsgNum);
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
//  processAni(self);
end;

procedure TRecv.Execute;
begin
//  inherited;
//
  while not Terminated do
  begin
    doRecvWork;
  end;
end;

end.


unit Moster;

interface

uses
  System.Classes, GR32, GR32_Image, GR32_PNG, ChatProtocol, System.SysUtils,
  System.DateUtils;

type
  TMoster = class
  private
    FId: Integer;
    FName: AnsiString;
    FPos: TPoint;
    FTurnTo: FaceOrientate;
    FState: RoleState;
    FBmp: TBitmap32;
    MbmpE, MbmpW, MbmpS, MbmpN: TBitmap32; //相当于这个类的图片资源，所以没有写在类的里面，而是根据不同的情况来选则不同的图片资源
  public
    function IsMoveListEmpty: Boolean;
    function GetSpeed: Integer;
    function GetBmp: TBitmap32;
    procedure AddMoveList(Move: PTRoleMove);
    procedure DelFirstMoveList;
    procedure HandleDeaing(Map: TPaintBox32);
    procedure SetState(const Value: RoleState);
    procedure SetPosX(x: Integer);
    procedure SetPosY(y: Integer);
    procedure Move(Map: TPaintBox32; DesX, DesY: Integer);
    procedure MoveOneStepX(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer); //W 为正方形格子的宽度
    procedure MoveOneStepY(Map: TPaintBox32; SrcX, SrcY, DesY: Integer; W: Integer);
    procedure SetTurnTo(const Dir: FaceOrientate);
    procedure SetSpeed(const Value: Integer);
    procedure SetBomb;
  public
    Fmovetime: Integer;
    FSpeed: Integer;
    FMoveList: PTRoleMove;
    FBeginMove: PTRoleMove;
    FEndMove: PTRoleMove;
    NowFrame: Integer;

     //test
    oldtime: TDateTime;
    newtime: TDateTime;
    actrolspeed: Integer;
    first: Boolean;
    constructor Create(PosX, PosY, Id, Speed: Integer; Name: AnsiString);
    property Id: Integer read FId;
    property Name: AnsiString read FName; //先暂时没有添加改名接口
    property X: Integer read FPos.x write SetPosX;
    property Y: Integer read FPos.y write SetPosY;
    property State: RoleState read FState write SetState;
    property TurnTo: FaceOrientate read FTurnTo write SetTurnTo;
    property Speed: Integer read GetSpeed write SetSpeed;
    property Bmp: TBitmap32 read GetBmp;
  end;

implementation

{ RolePlayer }

procedure TMoster.AddMoveList(Move: PTRoleMove);
begin
  if FBeginMove = nil then
  begin
    FBeginMove := Move;
    FEndMove := Move;
  end
  else
  begin
    FEndMove.Next := Move;
    FEndMove := FEndMove.Next;
  end;
end;

constructor TMoster.Create(PosX, PosY, Id, Speed: Integer; Name: AnsiString);
begin
  MbmpE := TBitmap32.Create;
  MbmpW := TBitmap32.Create;
  MbmpN := TBitmap32.Create;
  MbmpS := TBitmap32.Create;
  MbmpE.DrawMode := dmBlend;
  MbmpN.DrawMode := dmBlend;
  MbmpS.DrawMode := dmBlend;
  MbmpW.DrawMode := dmBlend;
//  LoadBitmap32FromPNG(MbmpE, 'img/yellowp_m_east.png');
//  LoadBitmap32FromPNG(MbmpN, 'img/yellowp_m_north.png');
//  LoadBitmap32FromPNG(MbmpS, 'img/yellowp_m_south.png');
//  LoadBitmap32FromPNG(MbmpW, 'img/yellowp_m_west.png');
  LoadBitmap32FromPNG(MbmpE, 'img/CaptionE.png');
  LoadBitmap32FromPNG(MbmpN, 'img/CaptionN.png');
  LoadBitmap32FromPNG(MbmpS, 'img/CaptionS.png');
  LoadBitmap32FromPNG(MbmpW, 'img/CaptionW.png');
  FPos.X := PosX;
  FPos.Y := PosY;
  FBmp := MbmpS;
  FId := Id;
  FSpeed := Speed;
  FTurnTo := SOUTH;
  FName := Name;
  NowFrame := 0;
  FState := ROLESTILL;
  //test
  first := True;
end;

procedure TMoster.SetTurnTo(const Dir: FaceOrientate);
begin
  FTurnTo := Dir;
  case Dir of
    EAST:
      FBmp := MbmpE;
    SOUTH:
      FBmp := MbmpS;
    WEST:
      FBmp := MbmpW;
    NORTH:
      FBmp := MbmpN;
  end;
end;

procedure TMoster.DelFirstMoveList;
var
  Ptr: PTRoleMove;
begin
  if FBeginMove = nil then
    Exit;
  Ptr := FBeginMove;
  FBeginMove := FBeginMove.Next;
  FreeMem(Ptr);
end;

function TMoster.GetBmp: TBitmap32;
var
  bmp: TBitmap32;
begin
  case FTurnTo of
    EAST:
      bmp := MbmpE;
    SOUTH:
      bmp := MbmpS;
    WEST:
      bmp := MbmpW;
    NORTH:
      bmp := MbmpN;
  end;
  Result := bmp;
end;

function TMoster.GetSpeed: Integer;
begin
  Result := (FSpeed - DEFAULT_SPEED) div SPEED_INTERVAL;
end;

procedure TMoster.HandleDeaing(Map: TPaintBox32);
var
  posx, posy: Integer;
begin
  posx := FPos.X * CELL_WIDTH + 5;
  posy := FPos.Y * CELL_WIDTH - 5;
end;

function TMoster.IsMoveListEmpty: Boolean;
begin
  Result := (FBeginMove = nil);
end;

procedure TMoster.Move(Map: TPaintBox32; DesX, DesY: Integer);
begin
//
  if (FPos.X = DesX) and (FPos.Y = DesY) then
    Exit;
  if FPos.X = DesX then
  begin
    if FPos.Y < DesY then
    begin
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y + 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin

      //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        ////////test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Inc(FPos.Y);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
    if FPos.Y > DesY then
    begin
      MoveOneStepY(Map, FPos.X, FPos.Y, FPos.Y - 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin
        //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        //test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Dec(FPos.Y);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
  end;
  if FPos.Y = DesY then
  begin
    if FPos.X < DesX then
    begin
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X + 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin
        //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        //test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Inc(FPos.X);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
    if FPos.X > DesX then
    begin
      MoveOneStepX(Map, FPos.Y, FPos.X, FPos.X - 1, CELL_WIDTH);
      if (FSpeed * 2 - 20) * Fmovetime div 1000 > CELL_WIDTH then
      begin
        //test
        if first then
        begin
          first := False;
          newtime := Now;
          oldtime := Now;
        end
        else
        begin
          newtime := Now;
          actrolspeed := 40 * 1000 div MilliSecondsBetween(newtime, oldtime);
          oldtime := newtime;
        end;
        //test
        NowFrame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
        Dec(FPos.X);
        Fmovetime := 0;
        DelFirstMoveList;
        State := ROLESTILL;
      end;
    end;
  end;
end;

procedure TMoster.MoveOneStepX(Map: TPaintBox32; SrcY, SrcX, DesX: Integer; W: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY, Distance, Frame: Integer;
begin
  piceRoleW := FBmp.Width div 6;
  Distance := (FSpeed * 2 - 20) * Fmovetime div 1000;
  Frame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
  if SrcX < DesX then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH + Distance;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH - Distance;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH);
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end;
  Map.Invalidate;
end;

procedure TMoster.MoveOneStepY(Map: TPaintBox32; SrcX, SrcY, DesY: Integer; W: Integer);
var
  piceRoleW, bmpRoleH: Integer;
  PosX, PosY, Distance, Frame: Integer;
begin
  piceRoleW := FBmp.Width div 6;
  Distance := (FSpeed * 2 - 20) * Fmovetime div 1000;
  Frame := (NowFrame + Fmovetime * FPS div 1000) mod 6;
  if SrcY < DesY then
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH) + Distance;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end
  else
  begin
    bmpRoleH := FBmp.Height;
    PosX := SrcX * CELL_WIDTH;
    PosY := SrcY * CELL_WIDTH - (bmpRoleH - CELL_WIDTH) - Distance;
    FBmp.DrawTo(Map.Buffer, rect(PosX, PosY, W + PosX, PosY + bmpRoleH), Rect(piceRoleW * Frame, 0, piceRoleW * (Frame + 1), bmpRoleH));
  end;
  Map.Invalidate;
end;

procedure TMoster.SetBomb;
begin
// 目前想的是bomb的创建不在role中创建，只是发消息在Map层实现创建和销毁。
end;

procedure TMoster.SetPosX(x: Integer);
begin
  FPos.X := x;
end;

procedure TMoster.SetPosY(y: Integer);
begin
  FPos.Y := y;
end;

procedure TMoster.SetSpeed(const Value: Integer);
begin
  FSpeed := DEFAULT_SPEED + Value * SPEED_INTERVAL;
end;

procedure TMoster.SetState(const Value: RoleState);
begin
  FState := Value;
end;

end.


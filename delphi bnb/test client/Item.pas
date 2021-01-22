unit Item;

interface

uses
  System.Classes, GR32, GR32_Png, ChatProtocol, GR32_Image;

type
  TItem = class
  public
    constructor Create(x, y, typeid: Integer);
  private
    FPos: TPoint;
    FType: Integer;
    FAutoFrame: Integer;
    FFloatDistance: Integer;
    FShowBmpType: Integer; //0 autoframe 1 floatframe
    FFloatDistanceOrder: Boolean;
    FPlayTime: Integer;
    FTickForBoomFire: Integer;
    FState: ItemState;
    FSpark: TBombBoom;
    BmpShoes: TBitmap32;
    BmpBomb: TBitmap32;
    bmpFireE, bmpFireW, bmpFireN, bmpFireS: TBitmap32;
    bmpFireCenter, bmpFireEEnd, bmpFireWEnd, bmpFireNEnd, bmpFireSEnd, bmpPlayerDead: TBitmap32;
  public
    function GetFloatBmp: TBitmap32;
    function GetAutoBmp: TBitmap32;
    function GetAutoBmpMaxFrame: Integer;
    procedure SetShowBmpType(ShowBmpTypeId: Integer);
    procedure SetFloatDistance(value: Integer);
    procedure SetFFloatDistanceOrder(value: Boolean);
    procedure SetAutoBmpFrame(value: Integer);
    procedure SetFloatTime(value: Integer);
    procedure SetItemState(value: ItemState);
    procedure SetBoomSpark(value: TBombBoom);
    procedure HandleBombBoom(pntbx: TPaintBox32);
    property FloatBmp: TBitmap32 read GetFloatBmp;
    property AutoBmp: TBitmap32 read GetAutoBmp;
    property X: Integer read FPos.X;
    property Y: Integer read FPos.Y;
    property ShowBmpType: Integer read FShowBmpType write SetShowBmpType;
    property FloatDistance: Integer read FFloatDistance write SetFloatDistance;
    property FloatDistanceOrder: Boolean read FFloatDistanceOrder write SetFFloatDistanceOrder;
    property AutoBmpFrame: Integer read FAutoFrame write SetAutoBmpFrame;
    property AutoBmpMaxFrame: Integer read GetAutoBmpMaxFrame;
    property ItemType: Integer read FType;
    property PlayTime: Integer read FPlayTime write SetFloatTime;
    property State: ItemState read FState write SetItemState;
    property BombSpark: TBombBoom read FSpark write SetBoomSpark;
  end;

implementation

{ TItem }

constructor TItem.Create(x, y, typeid: Integer);
begin
  BmpShoes := TBitmap32.Create;
  BmpShoes.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpShoes, 'img/shoe.png');
  BmpBomb := TBitmap32.Create;
  BmpBomb.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpBomb, 'img/bomb.png');
  BmpFireCenter := TBitmap32.Create;
  BmpFireCenter.DrawMode := dmBlend;
  LoadBitmap32FromPNG(BmpFireCenter, 'img/bbf_center.png');
  bmpFireE := TBitmap32.Create;
  bmpFireW := TBitmap32.Create;
  bmpFireN := TBitmap32.Create;
  bmpFireS := TBitmap32.Create;
  bmpFireEEnd := TBitmap32.Create;
  bmpFireWEnd := TBitmap32.Create;
  bmpFireNEnd := TBitmap32.Create;
  bmpFireSEnd := TBitmap32.Create;
  bmpFireCenter := TBitmap32.Create;
  bmpFireW.DrawMode := dmBlend;
  bmpFireN.DrawMode := dmBlend;
  bmpFireS.DrawMode := dmBlend;
  bmpFireE.DrawMode := dmBlend;
  bmpFireEEnd.DrawMode := dmBlend;
  bmpFireWEnd.DrawMode := dmBlend;
  bmpFireNEnd.DrawMode := dmBlend;
  bmpFireSEnd.DrawMode := dmBlend;
  LoadBitmap32FromPNG(bmpFireW, 'img/bbf_west.png');
  LoadBitmap32FromPNG(bmpFireWEnd, 'img/bbf_west_end.png');
  LoadBitmap32FromPNG(bmpFireN, 'img/bbf_north.png');
  LoadBitmap32FromPNG(bmpFireNEnd, 'img/bbf_north_end.png');
  LoadBitmap32FromPNG(bmpFireS, 'img/bbf_south.png');
  LoadBitmap32FromPNG(bmpFireSEnd, 'img/bbf_south_end.png');
  LoadBitmap32FromPNG(bmpFireE, 'img/bbf_east.png');
  LoadBitmap32FromPNG(bmpFireEEnd, 'img/bbf_east_end.png');
  FPos.X := x;
  FPos.Y := y;
  FType := typeid;
  FAutoFrame := 0;
  FFloatDistance := 0;
  FFloatDistanceOrder := True;
  FPlayTime := 0;
  FTickForBoomFire := 0;
//  FillMemory(@BoomSpark, SizeOf(TBombBoom), 0);
end;

function TItem.GetAutoBmp: TBitmap32;
begin
  Result := nil;
  case FType of
    4:
      Result := BmpBomb;
  end;
end;

function TItem.GetAutoBmpMaxFrame: Integer;
begin
  Result := 0;
  if AutoBmp <> nil then
    Result := AutoBmp.Width div CELL_WIDTH;
end;

function TItem.GetFloatBmp: TBitmap32;
var
  bmp: TBitmap32;
begin
  bmp := nil;
  case FType of
    5:
      bmp := BmpShoes;
  end;
  Result := bmp;
end;

procedure TItem.HandleBombBoom(pntbx: TPaintBox32);
var
  PtrNext: PTBoomFirePic;
  x, y, bmpH, pice, I: Integer;
  PosX, PosY: Integer;
begin
    //画中心的图
  bmpH := BmpFireCenter.Height;
  x := FPos.X * 40;
  y := FPos.Y * 40;
  pice := bmpFireCenter.Width div 4;
  bmpFireCenter.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
  if FSpark.BoomW - 1 > 0 then
  begin
       //画北面的图
    for I := 1 to FSpark.BoomW - 1 do
    begin
      if I = FSpark.BoomW - 1 then
      begin
              //画end
        PosX := FSpark.BombX;
        PosY := FSpark.BombY - I;
        bmpH := bmpFireNEnd.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireNEnd.Width div 4;
        bmpFireNEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end
      else
      begin
              //画中间
        PosX := FSpark.BombX;
        PosY := FSpark.BombY - I;
        bmpH := bmpFireN.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireN.Width div 4;
        bmpFireN.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end;
    end;
  end;
  if FSpark.BoomA - 1 > 0 then
  begin
       //画西面的图
    for I := 1 to FSpark.BoomA - 1 do
    begin
      if I = FSpark.BoomA - 1 then
      begin
              //画end
        PosX := FSpark.BombX - I;
        PosY := FSpark.BombY;
        bmpH := bmpFireWEnd.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireWEnd.Width div 4;
        bmpFireWEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end
      else
      begin
              //画中间
        PosX := FSpark.BombX - I;
        PosY := FSpark.BombY;
        bmpH := bmpFireW.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireW.Width div 4;
        bmpFireW.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end;
    end;
  end;
  if FSpark.BoomD - 1 > 0 then
  begin
       //画东面的图
    for I := 1 to FSpark.BoomD - 1 do
    begin
      if I = FSpark.BoomD - 1 then
      begin
              //画end
        PosX := FSpark.BombX + I;
        PosY := FSpark.BombY;
        bmpH := bmpFireEEnd.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireEEnd.Width div 4;
        bmpFireEEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end
      else
      begin
              //画中间
        PosX := FSpark.BombX + I;
        PosY := FSpark.BombY;
        bmpH := bmpFireE.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireE.Width div 4;
        bmpFireE.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end;
    end;
  end;
  if FSpark.BoomS - 1 > 0 then
  begin
       //画南面的图
    for I := 1 to FSpark.BoomS - 1 do
    begin
      if I = FSpark.BoomS - 1 then
      begin
              //画end
        PosX := FSpark.BombX;
        PosY := FSpark.BombY + I;
        bmpH := bmpFireSEnd.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireSEnd.Width div 4;
        bmpFireSEnd.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end
      else
      begin
              //画中间
        PosX := FSpark.BombX;
        PosY := FSpark.BombY + I;
        bmpH := bmpFireS.Height;
        x := PosX * 40;
        y := PosY * 40;
        pice := bmpFireS.Width div 4;
        bmpFireS.DrawTo(pntbx.Buffer, Rect(x, y, pice + x, bmpH + y), Rect(pice * FTickForBoomFire, 0, pice * (FTickForBoomFire + 1), bmpH));
      end;
    end;
  end;
//    Inc(FTickForBoomFire);
  FTickForBoomFire := FPlayTime div 100;
  if FTickForBoomFire = 4 then
    State := Dispear;
end;

procedure TItem.SetAutoBmpFrame(value: Integer);
begin
  FAutoFrame := value;
end;

procedure TItem.SetBoomSpark(Value: TBombBoom);
begin
  FSpark.BoomW := Value.BoomW;
  FSpark.BoomA := Value.BoomA;
  FSpark.BoomS := Value.BoomS;
  FSpark.BoomD := Value.BoomD;
  FSpark.Bombx := Value.Bombx;
  FSpark.BombY := Value.BombY;
end;

procedure TItem.SetFFloatDistanceOrder(value: Boolean);
begin
  FFloatDistanceOrder := value;
end;

procedure TItem.SetFloatDistance(value: Integer);
begin
  FFloatDistance := value;
end;

procedure TItem.SetFloatTime(value: Integer);
begin
  FPlayTime := value;
end;

procedure TItem.SetItemState(value: ItemState);
begin
  FState := value;
end;

procedure TItem.SetShowBmpType(ShowBmpTypeId: Integer);
begin
  FShowBmpType := ShowBmpTypeId;
end;

end.


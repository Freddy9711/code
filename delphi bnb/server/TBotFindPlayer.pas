unit TBotFindPlayer;

interface

uses
  System.SyncObjs, System.SysUtils, System.Classes, GameProtocol, Contnrs;

type

  //机器人寻路
  Attribute = (TStart, TEnd, TObstacles, TMove, Moved);

  MapInfo = class
    x: Integer;
    y: Integer;
    Px: Integer;
    Py: Integer;
    F: Integer;
    G: Integer;
    H: Integer;
    IfStartMoved: Boolean;
    PG: Integer;
    SAttri: Attribute;
    MAPF: Integer;
  end;

  TPathPos = class
  public
    posx: Integer;
    posy: Integer;
  end;

  TGameBotFindPlayer = class
  private
    Openlist: TList;
    Closelist: TList;
    FMaparray: array[0..19, 0..19] of MapInfo;
  public
    IfHaveNoPath: FindPathState;
    IfFindPath: FindPathState;
    FPathList: TList;
    constructor Create;
    destructor Destroy;
    procedure SetFMaparray(Fmap: TMap);
    procedure SetBotPos(X, Y: Integer);
    procedure SetPlayerPos(X, Y: Integer);
    function FindPlayer: MapInfo;
    function FindBot: MapInfo;
    procedure Start;
    procedure FindOutside(PosMap: Pointer);
    procedure InsertOpenList(Pos: MapInfo);
    procedure SetParentsPos;
    function NextSteps: MapInfo;
    procedure GetF(Startpos: MapInfo; Endpos: MapInfo; PosMap: MapInfo);
    procedure FindTObstacles;
    procedure CheckParent;
    procedure FindPath;
  end;

//机器人寻路

implementation

{ TGameBotFindPlayer }

function TListSortCompare(Item1, Item2: Pointer): integer;
var
  F: Integer;
begin
  F := MapInfo(Item1).F - MapInfo(Item2).F;
  Result := F;
  if F > 0 then
    Result := 1
  else if F < 0 then
    Result := -1
end;

procedure TGameBotFindPlayer.CheckParent;
var
  PosMap: MapInfo;
  X: Integer;
  y: Integer;
  G, PG, H: Integer;
  TmpList: TList;
  i: Integer;
  EndPos: MapInfo;
begin
  PosMap := CloseList.last;
  TmpList := TList.Create;
  X := PosMap.x;
  y := PosMap.y;
  if (X <> 0) and (y <> 0) and (X <> 19) and (y <> 19) then
  begin
    TmpList.Add(Fmaparray[X + 1][y]);
    TmpList.Add(Fmaparray[X][y + 1]);
    TmpList.Add(Fmaparray[X - 1][y]);
    TmpList.Add(Fmaparray[X][y - 1]);
  end;
  if X = 0 then
  begin
    if (X = 0) and (y = 0) then
    begin
      TmpList.add(FMaparray[X + 1][y]);
      TmpList.Add(Fmaparray[X][y + 1]);
    end
    else if (X = 0) and (y = 19) then
    begin
      TmpList.add(FMaparray[X + 1][y]);
      TmpList.Add(Fmaparray[X][y - 1]);
    end
    else
    begin
      TmpList.add(FMaparray[X][y - 1]);
      TmpList.Add(Fmaparray[X][y + 1]);
      TmpList.Add(Fmaparray[X + 1][y]);
    end;
  end
  else if (X = 19) then
  begin
    if (X = 19) and (y = 19) then
    begin
      TmpList.add(FMaparray[X - 1][y]);
      TmpList.Add(Fmaparray[X][y - 1]);
    end
    else if y = 0 then
    begin
      TmpList.add(FMaparray[X - 1][y]);
      TmpList.Add(Fmaparray[X][y + 1]);
    end
    else
    begin
      TmpList.add(FMaparray[X - 1][y]);
      TmpList.Add(Fmaparray[X][y - 1]);
      TmpList.Add(Fmaparray[X][y + 1]);
    end;
  end
  else if y = 0 then
  begin
    if (X <> 0) and (y <> 19) then
    begin
      TmpList.add(FMaparray[X + 1][y]);
      TmpList.Add(Fmaparray[X - 1][y]);
      TmpList.Add(Fmaparray[X][y + 1]);
    end;
  end
  else if y = 19 then
  begin
    TmpList.add(FMaparray[X + 1][y]);
    TmpList.Add(Fmaparray[X - 1][y]);
    TmpList.Add(Fmaparray[X][y - 1]);
  end;

  for i := 0 to TmpList.Count - 1 do
  begin
    if MapInfo(TmpList[i]).G <> 0 then
    begin
      if Abs(MapInfo(TmpList[i]).X + MapInfo(TmpList[i]).y - PosMap.x - PosMap.y) = 1 then
      begin
        if (PosMap.PG) > MapInfo(TmpList[i]).G then
        begin

          PosMap.px := MapInfo(TmpList[i]).X;
          PosMap.py := MapInfo(TmpList[i]).y;
          PosMap.PG := MapInfo(TmpList[i]).G;
          G := MapInfo(TmpList[i]).G;
          PG := PosMap.G;
          G := PG + 10;
          MapInfo(TmpList[i]).G := G;
          EndPos := FindPlayer;
          H := (Abs(EndPos.x - MapInfo(TmpList[i]).X) + Abs(EndPos.y - MapInfo(TmpList[i]).y)) * 10;
          MapInfo(TmpList[i]).F := MapInfo(TmpList[i]).H + MapInfo(TmpList[i]).G;
        end;
      end;
    end
    else
    begin
      if (PosMap.G + 14) <= MapInfo(TmpList[i]).G then
      begin
        PosMap.px := MapInfo(TmpList[i]).X;
        PosMap.py := MapInfo(TmpList[i]).y;
        G := MapInfo(TmpList[i]).G;
        PG := PosMap.G;
        G := PG + 14;
        MapInfo(TmpList[i]).G := G;
        EndPos := FindPlayer;
        H := (Abs(EndPos.x - MapInfo(TmpList[i]).X) + Abs(EndPos.y - MapInfo(TmpList[i]).y)) * 10;
        MapInfo(TmpList[i]).F := MapInfo(TmpList[i]).H + MapInfo(TmpList[i]).G;
      end;
    end;

  end;
end;

constructor TGameBotFindPlayer.Create;
var
  I: Integer;
  J: Integer;
begin
  inherited;
  for I := 0 to 19 do
  begin
    for J := 0 to 19 do
    begin
      FMaparray[I][J] := MapInfo.Create;
    end;
  end;

  Openlist := TList.Create;
  Closelist := TList.Create;
  FPathList := TList.Create;
end;

destructor TGameBotFindPlayer.Destroy;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to 19 do
  begin
    for J := 0 to 19 do
    begin
      FMaparray[I][J].Free;
    end;
  end;
  Openlist.Destroy;
  Closelist.Destroy;
  FPathList.Destroy;
end;

function TGameBotFindPlayer.FindBot: MapInfo;
var
  I, J: Integer;
begin
  for I := 0 to 19 do
    for J := 0 to 19 do
    begin
      if (FMaparray[I][J].SAttri = TStart) or (FMaparray[I][J].IfStartMoved = True) then
      begin
        Result := FMaparray[I][J];
        Exit;
      end;
    end;
end;

procedure TGameBotFindPlayer.FindOutside(PosMap: Pointer);
var
  X, Y: Integer;
begin
  X := MapInfo(PosMap).X;
  Y := MapInfo(PosMap).Y;
  if (X <> 0) and (Y <> 0) and (X <> 19) and (Y <> 19) then
  begin
    InsertOpenList(Fmaparray[X + 1][Y]);
    InsertOpenList(Fmaparray[X][Y + 1]);
    InsertOpenList(Fmaparray[X - 1][Y]);
    InsertOpenList(Fmaparray[X][Y - 1]);
  end;
  if X = 0 then
  begin
    if (X = 0) and (Y = 0) then
    begin
      InsertOpenList(FMaparray[X + 1][Y]);
      InsertOpenList(Fmaparray[X][Y + 1]);
    end
    else if (X = 0) and (Y = 19) then
    begin
      InsertOpenList(FMaparray[X + 1][Y]);
      InsertOpenList(Fmaparray[X][Y - 1]);
    end
    else
    begin
      InsertOpenList(FMaparray[X][Y - 1]);
      InsertOpenList(Fmaparray[X][Y + 1]);
      InsertOpenList(Fmaparray[X + 1][Y]);
    end;
  end
  else if X = 19 then
  begin
    if (X = 19) and (Y = 19) then
    begin
      InsertOpenList(FMaparray[X - 1][Y]);
      InsertOpenList(Fmaparray[X][Y - 1]);
    end
    else if Y = 0 then
    begin
      InsertOpenList(FMaparray[X - 1][Y]);
      InsertOpenList(Fmaparray[X][Y + 1]);
    end
    else
    begin
      InsertOpenList(FMaparray[X - 1][Y]);
      InsertOpenList(Fmaparray[X][Y - 1]);
      InsertOpenList(Fmaparray[X][Y + 1]);
    end;
  end
  else if Y = 0 then
  begin
    if (X <> 0) and (X <> 19) then
    begin
      InsertOpenList(FMaparray[X + 1][Y]);
      InsertOpenList(Fmaparray[X - 1][Y]);
      InsertOpenList(Fmaparray[X][Y + 1]);
    end;
  end
  else if (Y = 19) then
  begin
    begin
      if (X <> 0) and (X <> 19) then
      begin
        InsertOpenList(Fmaparray[X][Y - 1]);
        InsertOpenList(Fmaparray[X - 1][Y]);
        InsertOpenList(Fmaparray[X + 1][Y]);
      end;
    end
  end;
end;

procedure TGameBotFindPlayer.FindPath;
var
  EndPos: MapInfo;
  StartPos: MapInfo;
  Tmppos: MapInfo;
  FPathPos: TPathPos;
  i: Integer;
begin
  EndPos := FindPlayer;
  Tmppos := EndPos;
  StartPos := FindBot;
  FPathPos := TPathPos.Create;
  Tmppos := FMaparray[Tmppos.Px][Tmppos.Py];
  while FMaparray[Tmppos.x][Tmppos.y] <> StartPos do
  begin
    FPathPos := TPathPos.Create;
    if (Tmppos.x = 0) and (Tmppos.y = 1) then
    begin
      FPathPos.posx := Tmppos.x;
      FPathPos.posy := Tmppos.y;
      FPathList.Add(FPathPos);
      Tmppos := FMaparray[Tmppos.Px][Tmppos.Py];
    end
    else if (Tmppos.x = 1) and (Tmppos.y = 0) then
    begin
      FPathPos.posx := Tmppos.x;
      FPathPos.posy := Tmppos.y;
      FPathList.Add(FPathPos);
      Tmppos := FMaparray[Tmppos.Px][Tmppos.Py];
    end
    else if (Tmppos.x = 1) and (Tmppos.y = 1) then
    begin
      FPathPos.posx := Tmppos.x;
      FPathPos.posy := Tmppos.y;
      FPathList.Add(FPathPos);
      Tmppos := FMaparray[Tmppos.Px][Tmppos.Py];
    end
    else
    begin
      FPathPos.posx := Tmppos.x;
      FPathPos.posy := Tmppos.y;
      FPathList.Add(FPathPos);
      Tmppos := FMaparray[Tmppos.Px][Tmppos.Py];
    end;
  end;

end;

function TGameBotFindPlayer.FindPlayer: MapInfo;
var
  I, J: Integer;
begin
  for I := 0 to 19 do
    for J := 0 to 19 do
    begin
      if FMaparray[I][J].SAttri = Tend then
      begin
        Result := FMaparray[I][J];
        Exit;
      end;
    end;
end;

procedure TGameBotFindPlayer.FindTObstacles;
var
  i: Integer;
begin
  for i := Openlist.Count - 1 downto 0 do
  begin
    if MapInfo(Openlist[i]).SAttri = TObstacles then
    begin
      MapInfo(Openlist[i]).F := 0;
      MapInfo(Openlist[i]).G := 0;
      MapInfo(Openlist[i]).H := 0;
      Openlist.Delete(i);
    end
    else if MapInfo(Openlist[i]).SAttri = Moved then
    begin
      Openlist.Delete(i);
    end;
  end;
end;

procedure TGameBotFindPlayer.GetF(Startpos, Endpos, PosMap: MapInfo);
var
  F, G, H, PG: Integer;
begin
  PG := FMaparray[PosMap.Px][PosMap.Py].G;
  if (PosMap.G = 0) then
  begin
    if (PosMap.x = PosMap.Px) or (PosMap.y = PosMap.Py) then
    begin
      G := PG + 10;
    end
    else
    begin
      G := PG + 14;
    end;
    PosMap.G := G;
    H := (Abs(Endpos.x - PosMap.x) + Abs(Endpos.y - PosMap.y)) * 10;
    PosMap.H := H;
    F := G + H;
    PosMap.F := F;
  end;
end;

procedure TGameBotFindPlayer.InsertOpenList(Pos: MapInfo);
var
  i: Integer;
begin
  for i := 0 to Openlist.Count - 1 do
  begin
    if Openlist[i] = Pos then
    begin
      Exit;
    end;
  end;
  Openlist.Add(Pos);
end;

function TGameBotFindPlayer.NextSteps: MapInfo;
var
  PosMap, EndMap, StartMap: MapInfo;
  MinNode: MapInfo;
  I, J, MinNodePos: Integer;
begin
  MinNode := MapInfo.Create;
  PosMap := closelist.Last;
  EndMap := FindPlayer;
  StartMap := FindBot;
  if Openlist.Count = 0 then
  begin
    IfHaveNoPath := NOPATH;
  end;
  if PosMap.SAttri <> TEnd then
  begin
    for I := 0 to Openlist.Count - 1 do
    begin
      GetF(StartMap, EndMap, Openlist[I]);
    end;
    MinNode.F := 1000000;
    for I := 0 to Openlist.Count - 1 do
    begin
      if (MapInfo(Openlist.Items[I]).F) < MinNode.F then
      begin
        MinNode := Openlist.Items[I];
        MinNodePos := I;
      end;
    end;
    Closelist.Add(MinNode);
    if MapInfo(Closelist.Last).SAttri <> Tend then
    begin
      if MapInfo(Closelist.Last).SAttri = TStart then
      begin
        MapInfo(Closelist.Last).IfStartMoved := True;
      end;
      MapInfo(Closelist.Last).SAttri := MOVED;
    end;
    FindOutside(Closelist.Last);
    FindTObstacles;
    SetParentsPos;
    CheckParent;
  end
  else if PosMap.SAttri = TEnd then
  begin
    FindPath;
    IfHaveNoPath := HAVEPATH;
    IfFindPath := HAVEPATH;
  end;
end;

procedure TGameBotFindPlayer.SetBotPos(X, Y: Integer);
begin
  FMaparray[X][Y].SAttri := TStart;
end;

procedure TGameBotFindPlayer.SetFMaparray(Fmap: TMap);
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to MapLength do
  begin
    for J := 0 to MapWide do
    begin
      if (Fmap.Map[I][J] = 0) or (Fmap.Map[I][J] = 5) then
      begin
        FMaparray[I][J].SAttri := TMove;
      end
      else
      begin
        FMaparray[I][J].SAttri := TObstacles;
      end;
      FMaparray[I][J].X := I;
      FMaparray[I][J].y := J;
    end;
  end

end;

procedure TGameBotFindPlayer.SetParentsPos;
var
  i: Integer;
begin
  for i := 0 to Openlist.Count - 1 do
  begin
    if MapInfo(Openlist[i]).Px = 0 then
    begin
      MapInfo(Openlist[i]).Px := MapInfo(Closelist.Last).X;
      MapInfo(Openlist[i]).Py := MapInfo(Closelist.Last).y;
      MapInfo(Openlist[i]).PG := MapInfo(Closelist.Last).G;
    end;
  end;
end;

procedure TGameBotFindPlayer.SetPlayerPos(X, Y: Integer);
begin
  FMaparray[X][Y].SAttri := TEnd;
end;

procedure TGameBotFindPlayer.Start;
begin
  Closelist.Add(FindBot);
  FindOutside(Closelist.Last);
  FindTObstacles;
  SetParentsPos;
end;

end.


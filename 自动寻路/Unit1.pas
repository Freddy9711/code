unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,Dialogs,
  StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  Attribute = (TStart, TEnd, TObstacles, TMove, Moved, MYShape);

  MYmap = class(TCustomControl)
  private
    x: Integer;
    y: Integer;
    Px: Integer;
    Py: Integer;
    F:Integer;
    G:Integer;
    H:Integer;
    SAttri: Attribute;
    MAPF: Integer;
    procedure paint;override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetMapColour(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; HitTest: Integer; var MouseActivate: TMouseActivate);
  end;

  APath = class
  private
  public
    constructor Create;
    procedure Start;
    procedure NextSteps;
    procedure GetF(Startpos:MYmap;Endpos:MYmap;PosMap:MYmap);
    function FindStart:MYmap;
    function FindEnd:MYmap;
    procedure FindOutside(PosMap:Pointer);
    procedure ClearOpenlist;
    procedure SetPxy;
    procedure FindTObstacles;
    procedure FindPath;
    procedure CheckParent;
    procedure InsertOpenList(Pos:MYmap);
  end;
    procedure ChangeHandleColor(PosColor:TColor);

var
  Form1: TForm1;
  FMaparray:array[0..11,0..8] of MYmap;
  ColorHandle:TColor;
  Openlist:TList;
  Closelist:TList;
  APathoj:APath;
  StartFlag:BOOL;
  MYShapeMap:MYmap;
implementation

{$R *.dfm}

{ MYmap }

function TListSortCompare(Item1, Item2: Pointer): integer;
var F:Integer;
begin
  F := MYmap(Item1).F  - MYmap (Item2).F;
  Result := F;
  if F > 0 then
    Result := 1
  else if F < 0 then
    Result := -1
end;

 procedure ChangeHandleColor(PosColor:TColor);
begin
  ColorHandle := PosColor;
end;


constructor MYmap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
    Width := 50;
    Height := 50;
    Color := clGreen;
    OnMouseActivate := SetMapColour;
end;

procedure MYmap.paint;
var
  Spos:AnsiString;
  SGHvalue:AnsiString;
  Sparentpos:AnsiString;
begin
  with Canvas do begin
   if Self.SAttri = MYShape then
  begin
    Canvas.Brush.Color := clBtnFace;
    Canvas.Pen.Color := clblack ;
    Pen.Style := psSolid;  //实线
    Canvas.MoveTo(0, Height);
    Canvas.LineTo(0, 0);
    Canvas.LineTo(Width-1, 0);
    Canvas.LineTo(Width-1, Height-1);
    Canvas.LineTo(0, Height-1);
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(0,0,'本格坐标');
    Canvas.TextOut(0,70,'父节点坐标');
    Canvas.TextOut(1,35,'G值               F值');
  end
  else if Self.SAttri <>Moved  then
  begin
    Canvas.Brush.Color := clBtnFace;
    Canvas.Pen.Color := clblack ;
    Pen.Style := psSolid;  //实线
    Canvas.MoveTo(0, Height);
    Canvas.LineTo(0, 0);
    Canvas.LineTo(Width-1, 0);
    Canvas.LineTo(Width-1, Height-1);
    Canvas.LineTo(0, Height-1);
    Spos := '('+IntToStr(x)+','+IntToStr(y)+')';
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(0,0,Spos);
    Canvas.Brush.Style := bsClear;
  end
  else
  begin
    Canvas.Brush.Color := clBtnFace;
    Canvas.Pen.Color := clRed;
    Pen.Style := psSolid;  //实线
    Canvas.MoveTo(0, Height);
    Canvas.LineTo(0, 0);
    Canvas.LineTo(Width-1, 0);
    Canvas.LineTo(Width-1, Height-1);
    Canvas.LineTo(0, Height-1);
    Spos := '('+IntToStr(x)+','+IntToStr(y)+')';
    SGHvalue := IntToStr(Self.G)+'  '+IntToStr(Self.F);
    Sparentpos := '('+IntToStr(px)+','+IntToStr(py)+')';
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(0,0,Spos);
    Canvas.TextOut(0,35,SGHvalue);
    Canvas.TextOut(23,18,Sparentpos);
  end;
  end;
end;

procedure MYmap.SetMapColour(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; HitTest: Integer; var MouseActivate: TMouseActivate);
var i,j,p:Integer;
begin
  if (Color = clYellow) or (Color = clRed) then
  begin
    Exit;      //不可在起点和终点上加障碍物
  end;
  if ColorHandle = clYellow then
  begin
    for I := 0 to 9 - 1 do
      for J := 0 to 12 - 1 do
      begin
        if FMaparray[j][i].Color =clYellow then
        begin
          FMaparray[j][i].Color := clGreen;
          FMaparray[j][i].SAttri := TMove;
        end;
      end;
  end;
  if ColorHandle = clRed then
  begin
    for I := 0 to 9 - 1 do
      for J := 0 to 12 - 1 do
      begin
        if FMaparray[j][i].Color =clRed  then
        begin
          FMaparray[j][i].Color := clGreen;
          FMaparray[j][i].SAttri := TMove;
        end;
      end;
  end;
  Color := ColorHandle;
  if ColorHandle = clGreen then
  begin
    Self.SAttri := TMove;
  end
  else if  ColorHandle = clRed then
  begin
    Self.SAttri := TEnd;
  end
  else if ColorHandle = clBlue  then
  begin
    Self.SAttri := TObstacles;
  end
  else if ColorHandle = clYellow then
  begin
    Self.SAttri := TStart;
  end;
end;



procedure TForm1.Button1Click(Sender: TObject);
begin
   ChangeHandleColor(clGreen);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ChangeHandleColor(clBlue);
end;


procedure TForm1.Button3Click(Sender: TObject);
begin
  ChangeHandleColor(clYellow);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  ChangeHandleColor(clRed);
end;


procedure TForm1.Button5Click(Sender: TObject);
begin
   if StartFlag = True  then
   APathoj.NextSteps;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
   APathoj.Start;
   StartFlag := True;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  I, J: Integer;
  spos:AnsiString;

begin

 for I := 0 to 9 - 1 do
    for J := 0 to 12 - 1 do
    begin
      FMaparray[j][i] := MYmap.Create(Self);
      FMaparray[j][i].Parent := Self;
      FMaparray[j][i].Top := 50 * I;
      FMaparray[j][i].Left := 50 * J;
      FMaparray[j][i].Width := 50;
      FMaparray[j][i].Height := 50;
      FMaparray[j][i].Brush.Color := clGreen;
      FMaparray[j][i].SAttri := TMove;
      FMaparray[j][i].x := j;
      FMaparray[j][i].y := i;
      FMaparray[j][i].Visible := True;
    end;
  FMaparray[0][0].Color := clYellow;
  FMaparray[0][0].SAttri := TStart;
  FMaparray[0][0].G := 0;
  FMaparray[11][8].Color := clRed;
  FMaparray[11][8].SAttri := TEnd;
  Shape2.Brush.Color:= clGreen;
  Shape3.Brush.Color:= clBlue;
  Shape4.Brush.Color:= clYellow;
  Shape5.Brush.Color:= clRed;
  MYShapeMap := MYmap.Create(Self);
  MYShapeMap.Parent := Self;
  MYShapeMap.Top := 368;
  MYShapeMap.Left := 848;
  MYShapeMap.Width := 89;
  MYShapeMap.Height := 89;
  MYShapeMap.Brush.Color := clGreen;
  MYShapeMap.SAttri := MYShape;
  MYShapeMap.Visible := True;

end;


{ APath }

procedure APath.CheckParent;
var PosMap:MYmap;
    X:Integer;
    y:Integer;
    G,PG,H:Integer;
    TmpList:TList;
    i: Integer;
    EndPos:MYmap;
begin
  PosMap := CloseList.last;
  TmpList := TList.Create;
  X:= PosMap.x;
  Y:= PosMap.y;
  if (x<>0) and (y<>0) and (x<>11) and (y<>8)then
  begin
    TmpList.Add(FMaparray[x-1][y-1]);
    TmpList.Add(Fmaparray[x+1][y+1]);
    TmpList.Add(Fmaparray[x+1][y]);
    TmpList.Add(Fmaparray[x][y+1]);
    TmpList.Add(Fmaparray[x-1][y+1]);
    TmpList.Add(Fmaparray[x+1][y-1]);
    TmpList.Add(Fmaparray[x-1][y]);
    TmpList.Add(Fmaparray[x][y-1]);
  end;
    if (x=0) and (y<>8) then
    begin
    if (x = 0) and (y = 0) then
    begin
      TmpList.add(FMaparray[x+1][y]);
      TmpList.Add(Fmaparray[x][y+1]);
      TmpList.Add(Fmaparray[x+1][y+1]);
    end
    else
    begin
      TmpList.add(FMaparray[x][y-1]);
      TmpList.Add(Fmaparray[x][y+1]);
      TmpList.Add(Fmaparray[x+1][y]);
      TmpList.Add(Fmaparray[x+1][y+1]);
      TmpList.Add(Fmaparray[x+1][y-1]);
    end;
    end
    else if (x=11) and (y<>0) then
    begin
     if(x=11) and (y=8)then
    begin
      TmpList.add(FMaparray[x-1][y]);
      TmpList.Add(Fmaparray[x-1][y-1]);
      TmpList.Add(Fmaparray[x][y-1]);
    end
    else
    begin
      TmpList.add(FMaparray[x-1][y]);
      TmpList.Add(Fmaparray[x-1][y+1]);
      TmpList.Add(Fmaparray[x][y-1]);
      TmpList.Add(Fmaparray[x][y+1]);
      TmpList.Add(Fmaparray[x-1][y-1]);
    end;
    end
    else if y=0 then
    begin
     if (x= 0)and (y=8) then
    begin
      TmpList.add(FMaparray[x+1][y]);
      TmpList.Add(Fmaparray[x+1][y+1]);
      TmpList.Add(Fmaparray[x][y+1]);
    end
    else
    begin
      TmpList.add(FMaparray[x+1][y]);
      TmpList.Add(Fmaparray[x-1][y]);
      TmpList.Add(Fmaparray[x][y+1]);
      TmpList.Add(Fmaparray[x-1][y+1]);
      TmpList.Add(Fmaparray[x+1][y+1]);
    end;
    end
    else if (y=8) and (x<>0) then
    begin
    if (y=8)and (x=0) then
    begin
      TmpList.add(FMaparray[x+1][y-1]);
      TmpList.Add(Fmaparray[x+1][y]);
      TmpList.Add(Fmaparray[x][y-1]);
    end
    else
    begin
      TmpList.add(FMaparray[x-1][y-1]);
      TmpList.Add(Fmaparray[x][y-1]);
      TmpList.Add(Fmaparray[x+1][y-1]);
      TmpList.Add(Fmaparray[x-1][y]);
      TmpList.Add(Fmaparray[x+1][y]);
    end
    end;
    for i := 0 to TmpList.Count - 1 do
    begin
      if MYmap(TmpList[i]).G <> 0 then
      begin
      if (MYmap(TmpList[i]).x = PosMap.x) or (MYmap(TmpList[i]).y = PosMap.y) then
      begin
        if (PosMap.G+10) <= MYmap(TmpList[i]).G then
        begin
          MYmap(TmpList[i]).px := PosMap.x;
          MYmap(TmpList[i]).Py := PosMap.y;
          G := MYmap(TmpList[i]).G;
          PG :=  PosMap.G;
          G := PG+10;
          MYmap(TmpList[i]).G := G;
          EndPos := FindEnd;
          H := (Abs(Endpos.x -MYmap(TmpList[i]).x)+Abs(Endpos.y-MYmap(TmpList[i]).y))*10;
          MYmap(TmpList[i]).F:= MYmap(TmpList[i]).H + MYmap(TmpList[i]).G;
        end;
      end
        else
        begin
          if (PosMap.G+14) <= MYmap(TmpList[i]).G then
          begin
            MYmap(TmpList[i]).px := PosMap.x;
            MYmap(TmpList[i]).Py := PosMap.y;
            G := MYmap(TmpList[i]).G;
            PG :=  PosMap.G;
            G := PG+14;
           MYmap(TmpList[i]).G := G;
            EndPos := FindEnd;
            H := (Abs(Endpos.x -MYmap(TmpList[i]).x)+Abs(Endpos.y-MYmap(TmpList[i]).y))*10;
            MYmap(TmpList[i]).F:= MYmap(TmpList[i]).H + MYmap(TmpList[i]).G;
          end;
          end;

        end;
      end;
    end;


procedure APath.ClearOpenlist;
var
  I: Integer;
begin
  for I := Openlist.Count -1 downto 0  do
  begin
    Openlist.Delete(i);
  end;
end;



constructor APath.Create;
begin
  inherited;
  Openlist := TList.Create;
  Closelist := TList.Create;
end;

function APath.FindEnd: MYmap;
var
  I,J:Integer;
begin
  for I := 0 to 9 - 1 do
      for J := 0 to 12 - 1 do
      begin
        if FMaparray[j][i].SAttri = Tend then
        begin
          Result := FMaparray[j][i];
          Exit;
        end;
      end;
end;

procedure APath.FindOutside(PosMap:Pointer);
var
  OBjmap:MYmap;
  X,Y:Integer;
begin
  objmap := MYmap(PosMap);
  X := OBjmap.x;
  Y := OBjmap.y;
  if (x<>0) and (y<>0) and (x<>11) and (y<>8)then
  begin
    InsertOpenList(FMaparray[x-1][y-1]);
    InsertOpenList(Fmaparray[x+1][y+1]);
    InsertOpenList(Fmaparray[x+1][y]);
    InsertOpenList(Fmaparray[x][y+1]);
    InsertOpenList(Fmaparray[x-1][y+1]);
    InsertOpenList(Fmaparray[x+1][y-1]);
    InsertOpenList(Fmaparray[x-1][y]);
    InsertOpenList(Fmaparray[x][y-1]);
  end;
    if (x=0) and (y<>8) then
    begin
    if (x = 0) and (y = 0) then
    begin
      InsertOpenList(FMaparray[x+1][y]);
      InsertOpenList(Fmaparray[x][y+1]);
      InsertOpenList(Fmaparray[x+1][y+1]);
    end
    else
    begin
      InsertOpenList(FMaparray[x][y-1]);
      InsertOpenList(Fmaparray[x][y+1]);
      InsertOpenList(Fmaparray[x+1][y]);
      InsertOpenList(Fmaparray[x+1][y+1]);
      InsertOpenList(Fmaparray[x+1][y-1]);
    end;
    end
    else if x=11 then
    begin
     if(x=11) and (y=8)then
    begin
      InsertOpenList(FMaparray[x-1][y]);
      InsertOpenList(Fmaparray[x-1][y-1]);
      InsertOpenList(Fmaparray[x][y-1]);
    end
    else
    begin
      InsertOpenList(FMaparray[x-1][y]);
      InsertOpenList(Fmaparray[x-1][y+1]);
      InsertOpenList(Fmaparray[x][y-1]);
      InsertOpenList(Fmaparray[x][y+1]);
      InsertOpenList(Fmaparray[x-1][y-1]);
    end;
    end
    else if y=0 then
    begin
     if (x= 0)and (y=8) then
    begin
      InsertOpenList(FMaparray[x+1][y]);
      InsertOpenList(Fmaparray[x+1][y+1]);
      InsertOpenList(Fmaparray[x][y+1]);
    end
    else
    begin
      InsertOpenList(FMaparray[x+1][y]);
      InsertOpenList(Fmaparray[x-1][y]);
      InsertOpenList(Fmaparray[x][y+1]);
      InsertOpenList(Fmaparray[x-1][y+1]);
      InsertOpenList(Fmaparray[x+1][y+1]);
    end;
    end
    else if (y=8) and (X<>0) then
    begin
    begin
      InsertOpenList(FMaparray[x-1][y-1]);
      InsertOpenList(Fmaparray[x][y-1]);
      InsertOpenList(Fmaparray[x+1][y-1]);
      InsertOpenList(Fmaparray[x-1][y]);
      InsertOpenList(Fmaparray[x+1][y]);
    end
    end;

end;

procedure APath.FindPath;
var EndPos:MYmap;
    StartPos:MYmap;
    Tmppos:MYmap;
    i:Integer;
begin
  EndPos := FindEnd;
  Tmppos := EndPos;
  StartPos := FindStart;
  Tmppos :=  FMaparray[Tmppos.Px ][Tmppos.Py ];
  while FMaparray[Tmppos.x ][Tmppos.y ]<>StartPos  do
  begin
    if (Tmppos.x = 0)and (Tmppos.y = 1) then
    begin
      Tmppos.Color := clTeal;
      Exit
    end
    else if (Tmppos.x = 1)and (Tmppos.y = 0) then
    begin
      Tmppos.Color := clTeal;
      Exit
    end
    else if (Tmppos.x = 1)and (Tmppos.y = 1) then
    begin
      Tmppos.Color := clTeal;
      Exit
    end
    else
    begin
      Tmppos.Color := clTeal;
      Tmppos :=  FMaparray[Tmppos.Px ][Tmppos.Py ];
    end;
  end;

end;

function APath.FindStart: MYmap;
var
i,j:Integer;
begin
 for I := 0 to 9 - 1 do
      for J := 0 to 12 - 1 do
      begin
        if FMaparray[j][i].SAttri = TStart then
        begin
          Result := FMaparray[j][i];
          exit;
        end;
      end;
end;

procedure APath.FindTObstacles;
var i:Integer;
begin
for i := Openlist.Count - 1  downto 0  do
begin
  if MYmap(Openlist[i]).SAttri = TObstacles then
  begin
    MYmap(Openlist[i]).F := 0;
    MYmap(Openlist[i]).G := 0;
    MYmap(Openlist[i]).H := 0;
    Openlist.Delete(i);
  end
  else if MYmap(Openlist[i]).SAttri = Moved then
  begin
    Openlist.Delete(i);
  end;


end;

end;

procedure APath.GetF(Startpos:MYmap;Endpos:MYmap;PosMap:MYmap);
var F,G,H,PG:Integer;
begin
  PG := FMaparray[PosMap.Px ][PosMap.Py].G;
  if (PosMap.G=0) then
  begin
    if (PosMap.x=PosMap.Px) or (PosMap.y=PosMap.Py) then
    begin
      G := PG+10;
    end
    else
    begin
      G := PG+14;
    end;
    PosMap.G:= G;
    H := (Abs(Endpos.x -PosMap.x)+Abs(Endpos.y-PosMap.y))*10;
    PosMap.H := H;
    F := G+H;
    PosMap.F := F;
  end;

end;

procedure APath.InsertOpenList(Pos: MYmap);
var i:Integer;
begin
  for I := 0 to Openlist.Count - 1 do
  begin
    if Openlist[i] = Pos then
    begin
      Exit;
    end;
  end;
  Openlist.Add(Pos);
end;

procedure APath.NextSteps;
var PosMap,EndMap,StartMap:MYmap;
    I,J:Integer;
    Tmpstring:Ansistring;
begin
  PosMap := closelist.Last;
  EndMap := FindEnd;
  StartMap := FindStart;
  if PosMap.SAttri <> TEnd then
  begin
    for I := 0 to Openlist.Count - 1 do
    begin
      GetF(StartMap,EndMap,Openlist[i]);
    end;
    Openlist.Sort(@TListSortCompare);
    Form1.Memo1.Lines.Clear;
    for I := 0 to Openlist.Count - 1 do
    begin
      Tmpstring := Tmpstring +'['+IntToStr(MYmap(Openlist[i]).x)+','+IntToStr(MYmap(Openlist[i]).y)+'F' +':'
      +IntToStr(MYmap(Openlist[i]).F) +']'
    end;
    Closelist.Add(Openlist.First);
    Form1.Memo1.Lines.Add(Tmpstring);
    if MYmap(Closelist.Last).SAttri <> Tend then
    begin
      MYmap(Closelist.Last).SAttri := MOVED;
      MYmap(Closelist.Last).Invalidate;
    end;
    FindOutside(Closelist.Last);
    FindTObstacles;
    SetPxy;
    CheckParent;
  end
  else  if PosMap.SAttri  =TEnd then
  begin
    Form1.Button5.OnClick := nil;
    //ClearPos;
    FindPath;
  end;
end;


procedure APath.SetPxy;
var i:Integer;
begin
  for I := 0 to Openlist.Count - 1 do
  begin
    if MYmap(Openlist[i]).Px = 0 then
    begin
      MYmap(Openlist[i]).Px := MYmap(Closelist.Last).x;
      MYmap(Openlist[i]).Py := MYmap(Closelist.Last).y;
    end;
  end;
end;


procedure APath.Start;
var
  I: Integer;
begin
  Closelist.Add(FindStart);
  FindOutside(Closelist.Last);
  SetPxy;
  Form1.Button1.OnClick := nil;
  Form1.Button2.OnClick := nil;
  Form1.Button3.OnClick := nil;
  Form1.Button4.OnClick := nil;
end;

initialization
 ColorHandle := clGreen;
 APathoj := APath.Create;
 StartFlag := False;
end.

unit ScreenForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, WinSock, sendrecv, MinForm;

type
  TScreenFor = class(TForm)
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ScreenFor: TScreenFor;

implementation

uses
  connectserver;
{$R *.dfm}
//

procedure TScreenFor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ReadUserInfo.FRrcvscreen := False;
end;

procedure TScreenFor.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FControlScreen <> nil then
  begin
    FControlScreen.Suspend;
    FControlScreen.SetPos(2 * X, 2 * Y);
    FControlScreen.SendEvent := MouseDownEvent;
    FControlScreen.MouseButton := Button;
    FControlScreen.Resume;
  end;
end;

procedure TScreenFor.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FControlScreen <> nil then
  begin
    FControlScreen.Suspend;
    FControlScreen.SetPos(2 * X, 2 * Y);
    FControlScreen.SendEvent := MouseMoveEvent;
    FControlScreen.Resume;
  end;
end;

procedure TScreenFor.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FControlScreen <> nil then
  begin
    FControlScreen.Suspend;
    FControlScreen.SetPos(2 * X, 2 * Y);
    FControlScreen.SendEvent := MouseUpEvent;
    FControlScreen.MouseButton := Button;
    FControlScreen.Resume;
  end;
end;

procedure TScreenFor.Timer1Timer(Sender: TObject);
begin
  Canvas.Draw(0, 0, RevcBitMap);
end;

end.


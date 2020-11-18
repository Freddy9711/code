unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
uses
  Unit2;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Canvas.Draw(0, 0, map);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin

 
  Canvas.Draw(0, 0, map);
end;

end.


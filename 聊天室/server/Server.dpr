program Server;

uses
  Forms,
  Graphics,
  Classes,
  Unit2 in 'Unit2.pas' {Form2},
  Unit1 in 'Unit1.pas' {Form1},
  Tools in 'Tools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm1, Form1);
  CStream := TmemoryStream.Create;
  PStream := TmemoryStream.Create;
  map := TBitmap.Create;
  Map.PixelFormat := pf32bit;
  Application.Run;
end.

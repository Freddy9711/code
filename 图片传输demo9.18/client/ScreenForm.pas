unit ScreenForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, WinSock, sendrecv;

type
  TScreenFor = class(TForm)
    btstart: TButton;
    Timer1: TTimer;
    btsendscreen: TButton;
    btrecvscreen: TButton;
    btgetscreen: TButton;
    procedure btsendscreenClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ScreenFor: TScreenFor;

implementation

uses
  connectserver, MinForm;
{$R *.dfm}
//
procedure TScreenFor.btsendscreenClick(Sender: TObject);
begin
  MintForm.SendScreen;
end;

end.


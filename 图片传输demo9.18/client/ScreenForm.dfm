object ScreenFor: TScreenFor
  Left = 0
  Top = 0
  Caption = #23631#24149#20849#20139
  ClientHeight = 161
  ClientWidth = 642
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btstart: TButton
    Left = 272
    Top = 8
    Width = 75
    Height = 25
    Caption = #24320#22987
    TabOrder = 0
  end
  object btsendscreen: TButton
    Left = 40
    Top = 88
    Width = 75
    Height = 25
    Caption = #21457#36865#26700#38754
    TabOrder = 1
    OnClick = btsendscreenClick
  end
  object btrecvscreen: TButton
    Left = 272
    Top = 88
    Width = 75
    Height = 25
    Caption = #25509#25910#26700#38754
    TabOrder = 2
  end
  object btgetscreen: TButton
    Left = 496
    Top = 88
    Width = 75
    Height = 25
    Caption = #33719#21462#26700#38754
    TabOrder = 3
  end
  object Timer1: TTimer
    Left = 56
    Top = 8
  end
end

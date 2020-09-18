object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object bootServer: TButton
    Left = 544
    Top = 16
    Width = 75
    Height = 25
    Caption = #21551#21160#26381#21153#22120
    TabOrder = 0
    OnClick = bootServerClick
  end
  object con1: TZConnection
    ControlsCodePage = cGET_ACP
    AutoEncodeStrings = True
    ClientCodepage = 'gbk'
    Properties.Strings = (
      ''
      'codepage=gbk'
      'controls_cp=GET_ACP'
      'AutoEncodeStrings=ON')
    Connected = True
    HostName = '127.0.0.1'
    Port = 3306
    Database = 'test'
    User = 'root'
    Password = '123456'
    Protocol = 'mysql'
    Left = 16
    Top = 8
  end
  object zqry1: TZQuery
    Connection = con1
    Params = <>
    Left = 72
    Top = 8
  end
end

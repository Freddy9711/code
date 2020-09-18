object MintForm: TMintForm
  Left = 0
  Top = 0
  Caption = #32842#22825
  ClientHeight = 530
  ClientWidth = 724
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object MessageMemo: TMemo
    Left = 3
    Top = 80
    Width = 694
    Height = 273
    Lines.Strings = (
      'MessageMemo')
    ReadOnly = True
    TabOrder = 0
  end
  object SendMemo: TMemo
    Left = 8
    Top = 385
    Width = 627
    Height = 81
    Lines.Strings = (
      'SendMemo')
    TabOrder = 1
  end
  object Btsend: TButton
    Left = 641
    Top = 385
    Width = 75
    Height = 81
    Caption = #21457#36865
    TabOrder = 2
    OnClick = BtsendClick
  end
  object btreaduser: TButton
    Left = 457
    Top = 28
    Width = 75
    Height = 25
    Caption = #21152#36733#29992#25143
    TabOrder = 3
    OnClick = btreaduserClick
  end
  object userbox: TComboBox
    Left = 552
    Top = 30
    Width = 145
    Height = 21
    ItemHeight = 13
    TabOrder = 4
    Text = 'userbox'
  end
  object btsharescreen: TButton
    Left = 8
    Top = 480
    Width = 75
    Height = 25
    Caption = #23631#24149#20849#20139
    TabOrder = 5
    OnClick = btsharescreenClick
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 384
    Top = 24
  end
end

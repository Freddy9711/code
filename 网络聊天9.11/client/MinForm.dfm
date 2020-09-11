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
    Top = 56
    Width = 713
    Height = 297
    Lines.Strings = (
      'MessageMemo')
    ReadOnly = True
    TabOrder = 0
  end
  object SendMemo: TMemo
    Left = 8
    Top = 385
    Width = 708
    Height = 81
    Lines.Strings = (
      'SendMemo')
    TabOrder = 1
  end
  object Btsend: TButton
    Left = 632
    Top = 472
    Width = 75
    Height = 25
    Caption = #21457#36865
    TabOrder = 2
    OnClick = BtsendClick
  end
  object UserBox: TComboBox
    Left = 571
    Top = 8
    Width = 145
    Height = 21
    ItemHeight = 13
    TabOrder = 3
    Text = 'UserBox'
  end
end

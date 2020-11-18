object FormLogin: TFormLogin
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = #30331#24405
  ClientHeight = 270
  ClientWidth = 315
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 32
    Top = 105
    Width = 36
    Height = 13
    Caption = #29992#25143#21517
  end
  object Label3: TLabel
    Left = 44
    Top = 147
    Width = 24
    Height = 13
    Caption = #23494#30721
  end
  object Label1: TLabel
    Left = 44
    Top = 67
    Width = 24
    Height = 13
    Caption = #26165#31216
  end
  object UserIdEdit: TEdit
    Left = 74
    Top = 102
    Width = 169
    Height = 21
    TabOrder = 0
    Text = 'liweikang'
  end
  object PasswordEdit: TEdit
    Left = 74
    Top = 144
    Width = 169
    Height = 21
    TabOrder = 1
    Text = '123456'
  end
  object BtLogin: TButton
    Left = 8
    Top = 184
    Width = 75
    Height = 25
    Caption = #30331#24405
    TabOrder = 2
    OnClick = BtLoginClick
  end
  object BtRegeister: TButton
    Left = 112
    Top = 184
    Width = 75
    Height = 25
    Caption = #27880#20876
    TabOrder = 3
    OnClick = BtRegeisterClick
  end
  object BtEnd: TButton
    Left = 216
    Top = 184
    Width = 75
    Height = 25
    Caption = #21462#28040
    TabOrder = 4
    OnClick = BtEndClick
  end
  object UserNameEdit: TEdit
    Left = 74
    Top = 64
    Width = 169
    Height = 21
    TabOrder = 5
    Text = 'liweikang'
  end
end

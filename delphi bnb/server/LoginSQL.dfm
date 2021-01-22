object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 299
  ClientWidth = 443
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object sqlnaem: TLabel
    Left = 88
    Top = 40
    Width = 25
    Height = 17
    Caption = 'user'
  end
  object password: TLabel
    Left = 87
    Top = 80
    Width = 46
    Height = 13
    Caption = 'password'
  end
  object hostname: TLabel
    Left = 86
    Top = 192
    Width = 47
    Height = 13
    Caption = 'hostname'
  end
  object protocol: TLabel
    Left = 88
    Top = 155
    Width = 39
    Height = 13
    Caption = 'protocol'
  end
  object datebase: TLabel
    Left = 89
    Top = 120
    Width = 45
    Height = 13
    Caption = 'datebase'
  end
  object useredt: TEdit
    Left = 152
    Top = 37
    Width = 121
    Height = 21
    TabOrder = 0
    Text = 'root'
  end
  object passwordedt: TEdit
    Left = 152
    Top = 77
    Width = 121
    Height = 21
    TabOrder = 1
    Text = '123456'
  end
  object datebaseedt: TEdit
    Left = 152
    Top = 117
    Width = 121
    Height = 21
    TabOrder = 2
    Text = 'test'
  end
  object protocoledt: TEdit
    Left = 152
    Top = 152
    Width = 121
    Height = 21
    TabOrder = 3
    Text = 'mysql'
  end
  object hostnameedt: TEdit
    Left = 152
    Top = 189
    Width = 121
    Height = 21
    TabOrder = 4
    Text = '127.0.0.1'
  end
  object start: TButton
    Left = 168
    Top = 248
    Width = 75
    Height = 25
    Caption = 'start'
    TabOrder = 5
    OnClick = startClick
  end
end

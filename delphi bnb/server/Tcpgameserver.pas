unit Tcpgameserver;

interface

uses
  Tcpserver, System.Classes, GameProtocol, System.SysUtils, LogServer,
  GameSqlServer, TBotFindPlayer, System.Math, System.SyncObjs, DateUtils,
  Winapi.Windows, Vcl.ExtCtrls, Vcl.Dialogs;

type
  TGameClient = class
  private
    FClient: TTCPClient;
    FUsername: AnsiString;
    GamerPosX: Integer;
    GamerPosY: Integer;
  public
    procedure ChangeGamerPos(ChangeType: MoveDirect);
    constructor Create(UserName: AnsiString; AClient: TTCPClient);
  end;

  TTcpgameserver = class(TTcpServer)
  private
    FLock: TCriticalSection;
    IFFindNoPath: FindPathState;
    FindPlayerPos: array[0..3] of TFindUserPos;
    timer: TTimer;
    FDeadGamers: TStrings;
    FGamers: TStrings;
    FBots: TStrings;
    FBombList: TStrings;
    FMoveUserList: TStrings;
    ShoseTime: TDateTime;
    ShoseNum: Integer;
    FGameBotFindPlayer: TGameBotFindPlayer;
    FBotPathList: array[0..4] of TList;
  public
    FMap: TMap;
    FUserList: TPlayerInfoList;
    FBotList: TRoBotInfoList;
    procedure BotAutoMove(index: Integer);
    procedure ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure ProcessClientIO(AClient: TTCPClient); override;
    procedure ClientRemoved(AClient: TTCPClient); override;
    procedure CheckBombTime; override;
    procedure SetShoesProp; override;
    procedure SendMoveMessage; override;
    procedure BotFindMove; override;
  private
    procedure ControlBots;
    procedure BotFindPath;
    procedure BotMove(BotId: Integer);
    procedure FindPlayerBotMove(BotID: Integer);
    procedure DeleteUserList(Pos: Integer);
    function FindGamer(AClient: TTCPClient): TGameClient;
    function FindDeadGamer(AClient: TTCPClient): TGameClient;
    procedure InitGameMap;
    procedure InitBot;
    procedure SetGamerPos(AGamer: TGameClient);
    function RegisterNewUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
    function AddMoveUser(RequestPtr: PPlayerMove; AClient: TTCPClient): Integer;
    function PlayerMove(FMovePlayer: TMovePlayer): Integer;
    function RemoveUser(RequestPtr: PPlayerStopMove; AClient: TTCPClient): Integer;
    function PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
    function PlayerUseProp(RequestPtr: PUseProp; AClient: TTCPClient): Integer;
    function BombEvent(BomePos: Integer): Integer;
    function SendMap: Integer;
    function SendPlayerInfo(PlayerName: AnsiString): Integer;
    function SendPlayerMoveInfo(PlayerName: AnsiString): Integer;
    function SendSetBombInfo(BombX, BombY: Integer): Integer;
    function SendBombEvent(BombX: Integer; BombY: Integer; BoomW: Integer; BoomA: Integer; BoomS: Integer; BoomD: Integer; PosArray: Pointer): Integer;
    function PlayerDead(UserName: AnsiString; PlayerPosX: Integer; PlayerPosY: Integer): Integer;
    function SendShoesPos(x, y: Integer): Integer;
    function SendPlaverLeave(PlayerName: AnsiString): Integer;
    function FindKillerPlayerMelee(RequestPtr: PUseProp): Integer;
    function FindKillerPlayerRanged(RequestPtr: PUseProp): Integer;
    function SendRangedPropInfo(PropPosX: Integer; PropPosY: Integer; DestoryPos: DestoryTypes): Integer;
    function SendBotInfo(BotID: Integer; PosX: Integer; PosY: Integer; FaceTo: Integer): Integer;
    function SendBotMove(BotID, PosX, PosY, faceto: Integer): Integer;
    function CheckAndRemoveList(PlayerName: AnsiString): Integer;
    function SendAndAddBot: Integer;
    function SendBotList: Integer;
  end;

var
  FTcpgameserver: TTcpgameserver;
  LastTime: Int64;
  NowTime: Int64;

implementation


{ TTcpgameserver }

function TTcpgameserver.AddMoveUser(RequestPtr: PPlayerMove; AClient: TTCPClient): Integer;
var
  playername: AnsiString;
  FMovePlayer: TMovePlayer;
  MovePlayerSpeed: Integer;
begin
  FMovePlayer := TMovePlayer.Create;
  playername := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  MovePlayerSpeed := FUserList.UserList[FGamers.IndexOf(playername)].Speed;
  FMovePlayer.MoveSpeed := MovePlayerSpeed;
  FMovePlayer.UserName := playername;
  FMovePlayer.Timer := GetTickCount;
  FMovePlayer.MoveType := RequestPtr.MoveType;
  NowTime := GetTickCount;
  if Abs(LastTime - NowTime) > 250 then
  begin
    PlayerMove(FMovePlayer);
    LastTime := NowTime;
  end;

  FLock.Enter;
  try
    FMoveUserList.AddObject(playername, FMovePlayer);
  finally
    FLock.Leave;
  end;

end;

function TTcpgameserver.BombEvent(BomePos: Integer): Integer;
var
  BombX, BombY, PlayerX, PlayerY, I, J, Z: Integer;
  BoomW, BoomA, BoomD, BoomS: Integer;
  DestoryPos: array[0..3, 0..1] of Integer;
begin
  fillchar(DestoryPos, sizeof(DestoryPos), -1);
  BombX := TBomb(FBombList.Objects[BomePos]).FBombPosX;
  BombY := TBomb(FBombList.Objects[BomePos]).FBombPosY;

  for Z := 0 to FGamers.Count - 1 do
  begin
    if (BombX = TGameClient(FGamers.Objects[Z]).GamerPosX) and (BombY = TGameClient(FGamers.Objects[Z]).GamerPosY) then
    begin
      PlayerX := BombX + I;
      PlayerY := BombY;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          finally
            FLock.Leave;
          end;
          DeleteUserList(J);
        end;
      end;
    end;
  end;

  for I := 1 to BoomScope - 1 do   //判定是否爆破到人
  begin

    if FMap.Map[BombX + I][BombY] = 3 then
    begin
      PlayerX := BombX + I;
      PlayerY := BombY;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          finally
            FLock.Leave;
          end;

          DeleteUserList(J);
        end;
      end;
    end
    else if FMap.Map[BombX + I][BombY] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX + I][BombY] = 2 then
    begin
      FMap.Map[BombX + I][BombY] := 0;
      DestoryPos[0][0] := BombX + I;
      DestoryPos[0][1] := BombY;
      Inc(BoomD);
      Break;
    end
    else if FMap.Map[BombX + I][BombY] = 4 then
    begin
      for J := 0 to FBombList.Count - 1 do
      begin
        if (TBOMB(FBombList.Objects[J]).FBombPosX = BombX + I) and (TBOMB(FBombList.Objects[J]).FBombPosY = BombY) then
        begin
          if J > BomePos then
          begin
            BombEvent(J);
            FBombList.Delete(J);
            Break;
          end;
        end;
      end;
    end;
    Inc(BoomD);
  end;
  for I := 1 to BoomScope - 1 do
  begin
    if FMap.Map[BombX - I][BombY] = 3 then
    begin
      PlayerX := BombX - I;
      PlayerY := BombY;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          finally
            FLock.Leave;
          end;

          DeleteUserList(J);
        end;
      end;
    end
    else if FMap.Map[BombX - I][BombY] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX - I][BombY] = 2 then
    begin
      FMap.Map[BombX - I][BombY] := 0;
      DestoryPos[1][0] := BombX - I;
      DestoryPos[1][1] := BombY;
      Inc(BoomA);
      Break;
    end
    else if FMap.Map[BombX - I][BombY] = 4 then
    begin
      for J := 0 to FBombList.Count - 1 do
      begin
        if (TBOMB(FBombList.Objects[J]).FBombPosX = BombX - I) and (TBOMB(FBombList.Objects[J]).FBombPosY = BombY) then
        begin
          if J > BomePos then
          begin
            BombEvent(J);
            FBombList.Delete(J);
            Break;
          end;
        end;
      end;
    end;
    Inc(BoomA);
  end;
  for I := 1 to BoomScope - 1 do
  begin

    if FMap.Map[BombX][BombY + I] = 3 then
    begin
      PlayerX := BombX;
      PlayerY := BombY + I;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          finally
            FLock.Leave;
          end;

          DeleteUserList(J);
        end;
      end;
    end
    else if FMap.Map[BombX][BombY + I] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX][BombY + I] = 2 then
    begin
      FMap.Map[BombX][BombY + I] := 0;
      DestoryPos[2][0] := BombX;
      DestoryPos[2][1] := BombY + I;
      Inc(BoomS);
      Break;
    end
    else if FMap.Map[BombX][BombY + I] = 4 then
    begin
      for J := 0 to FBombList.Count - 1 do
      begin
        if (TBOMB(FBombList.Objects[J]).FBombPosX = BombX) and (TBOMB(FBombList.Objects[J]).FBombPosY = BombY + I) then
        begin
          if J > BomePos then
          begin
            BombEvent(J);
            FBombList.Delete(J);
            break;
          end;
        end;
      end;
    end;
    Inc(BoomS);
  end;

  for I := 1 to BoomScope - 1 do
  begin

    if FMap.Map[BombX][BombY - I] = 3 then
    begin
      PlayerX := BombX;
      PlayerY := BombY - I;
      for J := FGamers.Count - 1 downto 0 do
      begin
        if (TGameClient(FGamers.Objects[J]).GamerPosX = PlayerX) and (TGameClient(FGamers.Objects[J]).GamerPosy = PlayerY) then
        begin
          Log.Info(Format('玩家: %s 死亡', [TGameClient(FGamers.Objects[J]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[J]).FUsername, PlayerX, PlayerY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[J]).FUsername, TGameClient(FGamers.Objects[J]));
          finally
            FLock.Leave;
          end;
          DeleteUserList(J);
        end;
      end;
    end
    else if FMap.Map[BombX][BombY - I] = 1 then
    begin
      Break;
    end
    else if FMap.Map[BombX][BombY - I] = 2 then
    begin
      FMap.Map[BombX][BombY - I] := 0;
      DestoryPos[3][0] := BombX;
      DestoryPos[3][1] := BombY - I;
      Inc(BoomW);
      Break;
    end
    else if FMap.Map[BombX][BombY - I] = 4 then
    begin
      for J := 0 to FBombList.Count - 1 do
      begin
        if (TBOMB(FBombList.Objects[J]).FBombPosX = BombX) and (TBOMB(FBombList.Objects[J]).FBombPosY = BombY - I) then
        begin
          if J > BomePos then
          begin
            BombEvent(J);
            FBombList.Delete(J);
            Break;
          end;
        end;
      end;
    end;
    Inc(BoomW);
  end;
  Log.Info(Format('爆炸范围-> W:%d, A:%d, S:%d, D:%d', [BoomW, BoomA, BoomS, BoomD]));
  SendBombEvent(BombX, BombY, BoomW, BoomA, BoomS, BoomD, @DestoryPos);
  FMap.Map[BombX][BombY] := 0;
end;

procedure TTcpgameserver.ControlBots;
var
  I: Integer;
  PosX, PosY, FaceTo, BotID: Integer;
  MovePos: MapInfo;
  J: Integer;
begin

  if FBotList.BotNums <> 0 then
  begin
    for I := 0 to FBotList.BotNums - 1 do
    begin
      FindPlayerBotMove(I);
    end;
  end;
//  for J := 0 to FBotPathList[0].Count - 1 do
//  begin
//    Log.Info(Format('寻路坐标(%d, %d)', [TPathPos(FBotPathList[0].Items[J]).PosX, TPathPos(FBotPathList[0].Items[J]).PosY]));
//  end;
end;

procedure TTcpgameserver.BotAutoMove(index: Integer);
var
  PosX, PosY, I: Integer;
begin
  PosX := FBotList.BotList[index].BotPosX;
  PosY := FBotList.BotList[index].BotPosY;
  if FBotList.BotList[index].BotFaceTo = 0 then
  begin
    if FMap.Map[PosX][PosY - 1] = 0 then
    begin
      FBotList.BotList[index].BotPosY := PosY - 1;
    end
    else if FMap.Map[PosX][PosY - 1] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY - 1) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY - 1);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          finally
            FLock.Leave;
          end;
          DeleteUserList(I);
        end;

      end;
    end
    else
    begin
      FBotList.BotList[index].BotFaceTo := RandomRange(0, 4);
    end;
    Exit;
  end
  else if FBotList.BotList[index].BotFaceTo = 1 then
  begin
    if FMap.Map[PosX][PosY + 1] = 0 then
    begin
      FBotList.BotList[index].BotPosY := PosY + 1;
    end
    else if FMap.Map[PosX][PosY + 1] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY + 1) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY + 1);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          finally
            flock.Leave;
          end;
          DeleteUserList(I);
        end;
      end;
    end
    else
    begin
      FBotList.BotList[index].BotFaceTo := RandomRange(0, 4);
    end;
    Exit;
  end
  else if FBotList.BotList[index].BotFaceTo = 2 then
  begin
    if FMap.Map[PosX - 1][PosY] = 0 then
    begin
      FBotList.BotList[index].BotPosX := PosX - 1;
    end
    else if FMap.Map[PosX - 1][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX - 1) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX - 1, PosY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          finally
            FLock.Leave;
          end;

          DeleteUserList(I);
        end;
      end;
    end
    else
    begin
      FBotList.BotList[index].BotFaceTo := RandomRange(0, 4);
    end;
    Exit;
  end
  else if FBotList.BotList[index].BotFaceTo = 3 then
  begin
    if FMap.Map[PosX + 1][PosY] = 0 then
    begin
      FBotList.BotList[index].BotPosX := PosX + 1;
    end
    else if FMap.Map[PosX + 1][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX + 1) and (TGameClient(FGamers.Objects[I]).GamerPosy = PosY) then
        begin
          Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX + 1, PosY);
          FLock.Enter;
          try
            FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          finally
            FLock.Leave;
          end;

          DeleteUserList(I);
        end;
      end;
    end
    else
    begin
      FBotList.BotList[index].BotFaceTo := RandomRange(0, 4);
    end;
    Exit;
  end;
end;

procedure TTcpgameserver.BotFindMove;
var
  I, J: Integer;
begin
  nowbottime := GetTickCount;
  if nowbottime - lastbottime > 500 then
  begin
    if IFFindNoPath = HAVEPATH then
    begin
      for I := 0 to FBotList.BotNums - 1 do
      begin
        if (FBotPathList[I].Count <> 0) then
        begin
          BotMove(I);
          FBotPathList[I].Delete(0);
          SendBotMove(FBotList.BotList[I].RoBotID, FBotList.BotList[I].BotPosX, FBotList.BotList[I].BotPosY, FBotList.BotList[I].BotFaceTo);
          if (FindPlayerPos[I].FindPosX <> FUserList.UserList[I].UserPosX) or (FindPlayerPos[I].FindPosY <> FUserList.UserList[I].UserPosY) then
          begin
            for J := FBotPathList[I].Count - 1 downto 0 do
            begin
              FBotPathList[I].Delete(J);
            end;
            ControlBots;
          end;
        end
        else
        begin
          ControlBots;
        end;
      end;
    end
    else if IFFindNoPath = NOPATH then
    begin
    //找不到路，自动移动
      if FBotList.BotNums <> 0 then
      begin
        for I := 0 to FBotList.BotNums - 1 do
        begin
          BotAutoMove(I);
        end;
      end;
      if FBotList.BotNums <> 0 then
      begin
        for I := 0 to FBotList.BotNums - 1 do
        begin
          SendBotMove(FBotList.BotList[FBotList.BotNums - 1].RoBotID, FBotList.BotList[FBotList.BotNums - 1].BotPosX, FBotList.BotList[FBotList.BotNums - 1].BotPosY, FBotList.BotList[FBotList.BotNums - 1].BotFaceTo);
        end;
      end;
      ControlBots;
    end;
    lastbottime := nowbottime;
  end;
end;

procedure TTcpgameserver.BotFindPath;
var
  MovePos: MapInfo;
begin
  FGameBotFindPlayer.SetBotPos(FBotList.BotList[0].BotPosX, FBotList.BotList[0].BotPosY);
  FGameBotFindPlayer.SetPlayerPos(FUserList.UserList[0].UserPosX, FUserList.UserList[0].UserPosY);
  FGameBotFindPlayer.Start;
  MovePos := FGameBotFindPlayer.NextSteps;
end;

procedure TTcpgameserver.BotMove(BotId: Integer);
var
  BotPosX, BotPosY, PathPosX, PathPosY, I: Integer;
begin
  BotPosX := FBotList.BotList[BotId].BotPosX;
  BotPosY := FBotList.BotList[BotId].BotPosY;
  if FBotPathList[I].Count > 0 then
  begin
    PathPosX := TPathPos(FBotPathList[I].Items[0]).PosX;
    PathPosY := TPathPos(FBotPathList[I].Items[0]).PosY;
    if BotPosX = PathPosX then
    begin
      if PathPosY - BotPosY < 0 then
      begin
        //向北走
        if FMap.Map[BotPosX][BotPosY - 1] = 6 then
        begin
          ControlBots;
          Exit;
        end;
        FBotList.BotList[BotId].BotFaceTo := 0;
        FBotList.BotList[BotId].BotPosY := BotPosY - 1;
        Log.Info(Format('怪物移动至(%d, %d)', [FBotList.BotList[BotId].BotPosX, FBotList.BotList[BotId].BotPosY]));
        if FMap.Map[BotPosX][BotPosY - 1] = 3 then
        begin
          for I := 0 to FGamers.Count - 1 do
          begin
            if (TGameClient(FGamers.Objects[I]).GamerPosX = BotPosX) and (TGameClient(FGamers.Objects[I]).GamerPosy = BotPosY - 1) then
            begin
              Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
              PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, BotPosX, BotPosY - 1);
              FBotList.BotList[BotId].BotFaceTo := 0;
              FBotList.BotList[BotId].BotPosY := PathPosY;
              FLock.Enter;
              try
                FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
              finally
                FLock.Leave;
              end;

              DeleteUserList(I);
            end;
          end;
        end;
        if FMap.Map[BotPosX][BotPosY - 1] = 6 then
        begin
          ControlBots;
        end;
        Exit;
      end
      else if PathPosY - BotPosY > 0 then
      begin
        //向南走
        if FMap.Map[BotPosX][BotPosY - 1] = 6 then
        begin
          ControlBots;
          Exit;
        end;
        FBotList.BotList[BotId].BotFaceTo := 1;
        FBotList.BotList[BotId].BotPosY := PathPosY;
        Log.Info(Format('怪物移动至(%d, %d)', [FBotList.BotList[BotId].BotPosX, FBotList.BotList[BotId].BotPosY]));
        if FMap.Map[BotPosX][BotPosY + 1] = 3 then
        begin
          for I := 0 to FGamers.Count - 1 do
          begin
            if (TGameClient(FGamers.Objects[I]).GamerPosX = BotPosX) and (TGameClient(FGamers.Objects[I]).GamerPosy = BotPosY + 1) then
            begin
              Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
              PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, BotPosX, BotPosY + 1);
              FBotList.BotList[BotId].BotFaceTo := 1;
              FBotList.BotList[BotId].BotPosY := PathPosY;
              FLock.Enter;
              try
                FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
              finally
                flock.Leave;
              end;

              DeleteUserList(I);
            end;
          end;
        end;
        Exit;
      end;
    end
    else if PathPosY = BotPosY then
    begin
      if PathPosX - BotPosX < 0 then
      begin
        //向西走
        if FMap.Map[BotPosX][BotPosY - 1] = 6 then
        begin
          ControlBots;
          Exit;
        end;
        FBotList.BotList[BotId].BotFaceTo := 2;
        FBotList.BotList[BotId].BotPosX := PathPosX;
        Log.Info(Format('怪物移动至(%d, %d)', [FBotList.BotList[BotId].BotPosX, FBotList.BotList[BotId].BotPosY]));
        if FMap.Map[BotPosX - 1][BotPosY] = 3 then
        begin
          for I := 0 to FGamers.Count - 1 do
          begin
            if (TGameClient(FGamers.Objects[I]).GamerPosX = BotPosX - 1) and (TGameClient(FGamers.Objects[I]).GamerPosy = BotPosY) then
            begin
              Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
              PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, BotPosX - 1, BotPosY);
              FBotList.BotList[BotId].BotFaceTo := 2;
              FBotList.BotList[BotId].BotPosX := PathPosX;
              flock.Enter;
              try
                FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
              finally
                flock.Leave;
              end;

              DeleteUserList(I);
            end;
          end;
        end;
        Exit;
      end
      else if PathPosX - BotPosX > 0 then
      begin
        //向东走
        if FMap.Map[BotPosX][BotPosY - 1] = 6 then
        begin
          ControlBots;
          Exit;
        end;
        FBotList.BotList[BotId].BotFaceTo := 3;
        FBotList.BotList[BotId].BotPosX := PathPosX;
        Log.Info(Format('怪物移动至(%d, %d)', [FBotList.BotList[BotId].BotPosX, FBotList.BotList[BotId].BotPosY]));
        if FMap.Map[BotPosX + 1][BotPosY] = 3 then
        begin
          for I := 0 to FGamers.Count - 1 do
          begin
            if (TGameClient(FGamers.Objects[I]).GamerPosX = BotPosX + 1) and (TGameClient(FGamers.Objects[I]).GamerPosy = BotPosY) then
            begin
              Log.Info(Format('玩家: %s 被怪物杀死', [TGameClient(FGamers.Objects[I]).FUsername]));
              PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, BotPosX + 1, BotPosY);
              FBotList.BotList[BotId].BotFaceTo := 3;
              FBotList.BotList[BotId].BotPosX := PathPosX;
              FLock.Enter;
              try
                FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
              finally
                FLock.Leave;
              end;

              DeleteUserList(I);
            end;
          end;
        end;
        Exit;
      end;
    end;
  end;
end;

function TTcpgameserver.CheckAndRemoveList(PlayerName: AnsiString): Integer;
begin
  if FMoveUserList.IndexOf(PlayerName) <> -1 then
  begin
    FMoveUserList.Delete(FMoveUserList.IndexOf(PlayerName));
  end;
end;

procedure TTcpgameserver.CheckBombTime;
var
  i: Integer;
  nowtimer: Int64;
begin
  inherited;
  if FBombList.Count > 0 then
  begin
    for i := FBombList.Count - 1 downto 0 do
    begin
      nowtimer := GetTickCount;
      if nowtimer - (TBOMB(FBombList.Objects[i]).Timer) > BoomTime then
      begin
        Log.Info(Format('炸弹 %d 爆炸', [i]));
        BombEvent(i); //爆炸事件;
        FLock.Enter;
        try
          if FBombList.Objects[i] <> nil then
            FBombList.Delete(i);
        finally
          FLock.Leave;
        end;

      end;
    end;
  end;

end;

procedure TTcpgameserver.ClientRemoved(AClient: TTCPClient);
var
  Idx: Integer;
  DeletedChatter: TGameClient;
  DeletedDeadChatter: TGameClient;
  I: Integer;
begin
  DeletedChatter := FindGamer(AClient);
  DeletedDeadChatter := FindDeadGamer(AClient);

  if DeletedChatter <> nil then
  begin
    FMap.Map[DeletedChatter.GamerPosX][DeletedChatter.GamerPosY] := 0;
    Idx := FGamers.IndexOfObject(DeletedChatter);
    if Idx >= 0 then
    begin
      if FMoveUserList.Count <> 0 then
      begin
        CheckAndRemoveList(TGameClient(FGamers.Objects[Idx]).FUsername);
      end;
      FLock.Enter;
      try
        FGamers.Delete(Idx);
        DeleteUserList(Idx);
      finally
        FLock.Leave;
      end;

    end
    else
    begin
      if DeletedDeadChatter <> nil then
      begin
        FMap.Map[DeletedDeadChatter.GamerPosX][DeletedDeadChatter.GamerPosY] := 0;
        Idx := FGamers.IndexOfObject(DeletedDeadChatter);
        if Idx >= 0 then
        begin
          if FMoveUserList.Count <> 0 then
          begin
            CheckAndRemoveList(TGameClient(FGamers.Objects[Idx]).FUsername);
          end;
          FLock.Enter;
          try
            FDeadGamers.Delete(Idx);
            DeleteUserList(Idx);
          finally
            FLock.Leave;
          end;

        end
        else
        begin
          Exit;
        end;
        DeletedChatter.Free;
      end;
      Exit;
    end;
    DeletedChatter.Free;
  end;
end;

constructor TTcpgameserver.Create;
var
  I: Integer;
begin
  inherited Create;
  FGamers := TStringList.Create;
  FBombList := TStringList.Create;
  FDeadGamers := TStringList.Create;
  FMoveUserList := TStringList.Create;
  FLock := TCriticalSection.Create;
  InitGameMap;
  for I := 0 to 4 do
  begin
    FBotPathList[I] := TList.Create;
  end;
end;

procedure TTcpgameserver.DeleteUserList(Pos: Integer);
var
  i: Integer;
begin
  for i := Pos to Length(FUserList.UserList) - 1 do
  begin
    FLock.Enter;
    try
      FUserList.UserList[Pos] := FUserList.UserList[Pos + 1];
      FillMemory(@(FUserList.UserList[Pos + 1]), SizeOf(FUserList.UserList[Pos + 1]), 0);
    finally
      FLock.Leave;
    end;

  end;
end;

destructor TTcpgameserver.Destroy;
var
  i: Integer;
begin
  inherited;
//  for i := 0 to FGamers.Count - 1 do
//  begin
//    FGamers.Free;
//  end;
  FreeAndNil(FGamers);
  FreeAndNil(FDeadGamers);
  FreeAndNil(FBots);
  FreeAndNil(FBombList);
  FreeAndNil(FMoveUserList);
//  FGamers.Free;
  FLock.Free;
  timer.Free;
end;

procedure TTcpgameserver.Execute;
begin
  inherited;

end;

function TTcpgameserver.FindDeadGamer(AClient: TTCPClient): TGameClient;
var
  i: Integer;
begin
  Result := nil;
  FLock.Enter;
  try
    for i := 0 to FDeadGamers.Count - 1 do
    begin
      if TGameClient(FDeadGamers.Objects[i]).FClient = AClient then
      begin
        Result := TGameClient(FDeadGamers.Objects[i]);
        break;
      end;
    end;
  finally
    FLock.Leave;
  end;

end;

function TTcpgameserver.FindGamer(AClient: TTCPClient): TGameClient;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FGamers.Count - 1 do
  begin
    if TGameClient(FGamers.Objects[i]).FClient = AClient then
    begin
      Result := TGameClient(FGamers.Objects[i]);
      break;
    end;
  end;
end;

function TTcpgameserver.FindKillerPlayerMelee(RequestPtr: PUseProp): Integer;
var
  UserName: AnsiString;
  UserNumber: Integer;
  PosX, PosY, I: Integer;
begin
  UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  UserNumber := FGamers.IndexOf(UserName);
  if FUserList.UserList[UserNumber].FaceTo = NORTH then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY + 1;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end
  else if FUserList.UserList[UserNumber].FaceTo = SOUTH then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY - 1;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end
  else if FUserList.UserList[UserNumber].FaceTo = WEST then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX - 1;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end
  else if FUserList.UserList[UserNumber].FaceTo = EAST then
  begin
    PosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY;
    PosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX + 1;
    if FMap.Map[PosX][PosY] = 3 then
    begin
      for I := 0 to FGamers.Count - 1 do
      begin
        if (TGameClient(FGamers.Objects[I]).GamerPosX = PosX) and (TGameClient(FGamers.Objects[I]).GamerPosY = PosY) then
        begin
          PlayerDead(TGameClient(FGamers.Objects[I]).FUsername, PosX, PosY);
          Log.Info(Format('玩家 %s 被砍死', [TGameClient(FGamers.Objects[I]).FUsername]));
          FDeadGamers.AddObject(TGameClient(FGamers.Objects[I]).FUsername, TGameClient(FGamers.Objects[I]));
          FGamers.Delete(I);
          DeleteUserList(I);
        end;
      end;
    end;
  end;
end;

function TTcpgameserver.FindKillerPlayerRanged(RequestPtr: PUseProp): Integer;
var
  UserName: AnsiString;
  UserNumber: Integer;
  PosX, PosY, PropPosX, PropPosY, I: Integer;
begin
  UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  UserNumber := FGamers.IndexOf(UserName);
  PropPosX := TGameClient(FGamers.Objects[UserNumber]).GamerPosX;
  PropPosY := TGameClient(FGamers.Objects[UserNumber]).GamerPosY;
  if FUserList.UserList[UserNumber].FaceTo = NORTH then
  begin
    for I := PropPosY - 1 downto 0 do
    begin
      if FMap.Map[PropPosX][I] = 0 then
      begin
        Dec(PropPosY);
      end
      else if FMap.Map[PropPosX][I] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end
  else if FUserList.UserList[UserNumber].FaceTo = SOUTH then
  begin
    for I := PropPosY + 1 to 19 do
    begin
      if FMap.Map[PropPosX][I] = 0 then
      begin
        Inc(PropPosY);
      end
      else if FMap.Map[PropPosX][I] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[PropPosX][I] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end
  else if FUserList.UserList[UserNumber].FaceTo = WEST then
  begin
    for I := PropPosX - 1 downto 0 do
    begin
      if FMap.Map[I][PropPosY] = 0 then
      begin
        Dec(PropPosX);
      end
      else if FMap.Map[I][PropPosY] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end
  else if FUserList.UserList[UserNumber].FaceTo = EAST then
  begin
    for I := PropPosX + 1 to 19 do
    begin
      if FMap.Map[I][PropPosY] = 0 then
      begin
        Inc(PropPosX);
      end
      else if FMap.Map[I][PropPosY] = 1 then   //碰撞墙壁
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Block);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 2 then   //碰撞木箱
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Box);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 3 then   //碰撞人物
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Player);
        Exit;
      end
      else if FMap.Map[I][PropPosY] = 4 then    //碰撞炸弹
      begin
        SendRangedPropInfo(PropPosX, PropPosY, Bomb);
        Exit;
      end;
    end;
    SendRangedPropInfo(PropPosX, PropPosY, NoDestory);
  end;
end;

procedure TTcpgameserver.FindPlayerBotMove(BotID: Integer);
var
  BotposX, BotposY, PlayerPosX, PlayerPosY: Integer;
  I: Integer;
begin

  FGameBotFindPlayer := TGameBotFindPlayer.Create;
  BotposX := FBotList.BotList[BotID].BotposX;
  BotposY := FBotList.BotList[BotID].BotposY;
  PlayerPosX := FUserList.UserList[BotID].UserPosX;
  PlayerPosY := FUserList.UserList[BotID].UserPosY;
  FindPlayerPos[BotID].FindPosX := PlayerPosX;
  FindPlayerPos[BotID].FindPosY := PlayerPosY;
  if (BotposX = PlayerPosX) and (BotposY = PlayerPosY) then
  begin
    Exit;
  end;
  FGameBotFindPlayer.SetFMaparray(FMap);
  FGameBotFindPlayer.SetBotPos(BotposX, BotposY);
  FGameBotFindPlayer.SetPlayerPos(PlayerPosX, PlayerPosY);
//  Log.Info(Format('玩家位置: (%d, %d)', [PlayerPosX, PlayerPosY]));
  FGameBotFindPlayer.Start;
  while FGameBotFindPlayer.IfFindPath = NOSTATE do
  begin
    if FGameBotFindPlayer.IfHaveNoPath = NOPATH then
    begin
      IFFindNoPath := NOPATH;
      Break;
    end;
    FGameBotFindPlayer.NextSteps;
  end;

  if FGameBotFindPlayer.FPathList.Count > 0 then
  begin
    for I := FGameBotFindPlayer.FPathList.Count - 1 downto 0 do
    begin
      FLock.Enter;
      try
        FBotPathList[BotID].Add(FGameBotFindPlayer.FPathList[I]);
      finally
        FLock.Leave;
      end;
//    Log.Info('怪物寻路路径 :' + '(' + IntToStr(MapInfo(FGameBotFindPlayer.FPathList[I]).x) + ',' + IntToStr(MapInfo(FGameBotFindPlayer.FPathList[I]).y) + ')')
    end;
    IFFindNoPath := HAVEPATH;
    FLock.Enter;
    try
      FBotPathList[BotID].Add(FGameBotFindPlayer.FindPlayer);
    finally
      FLock.Leave;
    end;
  end;
  FGameBotFindPlayer.Destroy;
end;

procedure TTcpgameserver.InitBot;
var
  X, Y, I: Integer;
  Faceto: Integer;
begin
  if (FUserList.UserList[FBotList.BotNums].UserPosX = 0) and (FUserList.UserList[FBotList.BotNums].UserPosY = 0) then
  begin
    exit;
  end;

  repeat
    X := randomrange(0, 20);
    Y := RandomRange(0, 20);
  until FMap.Map[X][Y] = 0;
  Faceto := randomrange(0, 4);
  FBotList.BotList[FBotList.BotNums].RoBotID := FBotList.BotNums + 1;
  FBotList.BotList[FBotList.BotNums].BotPosX := X;
  FBotList.BotList[FBotList.BotNums].BotPosY := Y;
  FBotList.BotList[FBotList.BotNums].BotFaceTo := Faceto;
  Log.Info(format('怪物初始位置：(%d, %d)', [X, Y]));
  FMap.Map[X][Y] := 6;
  SendBotInfo(FBotList.BotList[FBotList.BotNums].RoBotID, X, Y, Faceto);
  Inc(FBotList.BotNums);
end;

procedure TTcpgameserver.InitGameMap;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to MapLength do
  begin
    for J := 0 to MapWide do
    begin
      if (I = 0) or (J = 0) or (I = MapLength) or (J = MapWide) then
      begin
        FMap.Map[I][J] := 1;
      end;
      if (I mod 2 = 0) and (J mod 2 = 0) then
      begin
        FMap.Map[I][J] := 1;
      end;
      if (I = 9) or (J = 9) then
      begin
        FMap.Map[I][J] := 2;
      end
    end;
    FMap.Map[9][3] := 0;
    FMap.Map[3][9] := 0;
    FMap.Map[13][9] := 0;
    FMap.Map[9][13] := 0

  end

end;

function TTcpgameserver.LoginUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
var
  AGameer: TGameClient;
  UserName, password, Error: AnsiString;
  sql: AnsiString;
  request: TServerMessage;
  UserInfo: TPlayerInfo;
begin
  UserName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  password := StrPas(PAnsichar(@(RequestPtr.Password)[0]));
  if (FGamers.IndexOf(UserName) = -1) and (FGamers.Count < 5) then
  begin
    sql := 'SELECT * from test where username=' + '"' + UserName + '"' + 'and password=' + '"' + password + '";';
    if SQLserver.SetSqlList(sql) = True then
    begin
      Log.Info('用户' + RequestPtr.UserName + '登录');
      AGameer := TGameClient.Create(RequestPtr.UserName, AClient);
      AGameer.FUsername := RequestPtr.UserName;
      SetGamerPos(AGameer);
      FGamers.AddObject(UserName, AGameer);
      Result := 0;
      FLock.Enter;
      try
        FUserList.UserList[FGamers.Count - 1].UserID := FGamers.Count;
        StrPCopy(FUserList.UserList[FGamers.Count - 1].UserName, UserName);
        FUserList.UserList[FGamers.Count - 1].UserPosX := AGameer.GamerPosX;
        FUserList.UserList[FGamers.Count - 1].UserPosY := AGameer.GamerPosY;
      finally
        FLock.Leave;
      end;

    end
    else
    begin
      Log.Error('用户名或密码错误！');
      Result := 1;
    end;
  end
  else if (FGamers.Count > 5) then
  begin
    Log.Error('用户已达上限！');
    Result := 2;
  end
  else
  begin
    Log.Error('用户已经在线！');
    Result := 3;
  end;
  FillChar(request, SizeOf(request), 0);
  request.head.Flag := PACK_FLAG;
  request.head.Size := SizeOf(request);
  request.head.Command := S_LOGIN;
  request.ErrorCode := Result;
  if Result = 1 then
  begin
    Error := '用户名或密码错误';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end
  else if Result = 2 then
  begin
    Error := '用户已达上限';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end
  else if Result = 3 then
  begin
    Error := '用户已经在线';
    StrLCopy(@request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end;

  AClient.SendData(@request, SizeOf(request));
  if Result = 0 then
  begin
    SendPlayerInfo(UserName);
  end;
  ShoseTime := Now;
end;

function TTcpgameserver.PlayerDead(UserName: AnsiString; PlayerPosX: Integer; PlayerPosY: Integer): Integer;
var
  I: Integer;
  PlayerDeadEvent: TPlayerDeadEvent;
begin
  PlayerDeadEvent.head.Flag := PACK_FLAG;
  PlayerDeadEvent.head.Size := SizeOf(PlayerDeadEvent);
  PlayerDeadEvent.head.Command := S_PlayerDead;
  FillMemory(@PlayerDeadEvent.UserName, Length(PlayerDeadEvent.UserName), 0);
  Move(Pointer(UserName)^, PlayerDeadEvent.UserName, Length(UserName));
  PlayerDeadEvent.PlayerPosX := PlayerPosX;
  PlayerDeadEvent.PlayerPosY := PlayerPosY;
  FMap.Map[PlayerPosX][PlayerPosY] := 0;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@PlayerDeadEvent, SizeOf(PlayerDeadEvent));
  end;

end;

function TTcpgameserver.PlayerMove(FMovePlayer: TMovePlayer): Integer;
var
  X, Y, I: Integer;
  PlayerName, ListPlayerName: AnsiString;
  SpeedToMove: Integer;
begin
  PlayerName := FMovePlayer.UserName;
  FLock.Enter;
  try
    if FDeadGamers.IndexOf(PlayerName) <> -1 then
    begin
      Exit;
    end;
  finally
    FLock.Leave;
  end;

  SpeedToMove := FUserList.UserList[FGamers.IndexOf(PlayerName)].Speed + 1;
  if FMovePlayer.MoveType = MOVEUP then
  begin

    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X][Y - 1] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X, Y - 1);
      FLock.Enter;
      try
        FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
        DeleteUserList(FGamers.IndexOf(PlayerName));
      finally
        FLock.Leave;
      end;
      Exit;
    end
    else if (FMap.Map[X][Y - 1] = 0) or (FMap.Map[X][Y - 1] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVEUP);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> NORTH then
          begin
            FLock.Enter;
            try
              FUserList.UserList[I].FaceTo := NORTH;
            finally
              FLock.Leave;
            end;
          end;
          FLock.Enter;
          try
            FUserList.UserList[I].UserPosX := X;
            FuserList.UserList[I].UserPosY := Y - 1;
          finally
            FLock.Leave;
          end;
          if FMap.Map[X][Y - 1] = 5 then
          begin
            if FUserList.UserList[I].Speed < 3 then
            begin
              FLock.Enter;
              try
                FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
              finally
                FLock.Leave;
              end;
              Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
              Dec(ShoseNum);
            end;
          end;
        end;
      end;
      FMap.Map[X][Y - 1] := 3;
      Log.Info(Format('玩家 %s 向北移动,当前坐标(%d, %d)', [PlayerName, X, Y - 1]));
    end;
  end
  else if FMovePlayer.MoveType = MOVEDOWN then
  begin

    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X][Y + 1] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X, Y + 1);
      FLock.Enter;
      try
        FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
        DeleteUserList(FGamers.IndexOf(PlayerName));
      finally
        FLock.Leave;
      end;
      Exit;
    end
    else if (FMap.Map[X][Y + 1] = 0) or (FMap.Map[X][Y + 1] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVEDOWN);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> SOUTH then
          begin
            FLock.Enter;
            try
              FUserList.UserList[I].FaceTo := SOUTH;
            finally
              FLock.Leave;
            end;
          end;
          FLock.Enter;
          try
            FUserList.UserList[I].UserPosX := X;
            FuserList.UserList[I].UserPosY := Y + 1;
          finally
            FLock.Leave;
          end;
          if FMap.Map[X][Y + 1] = 5 then
          begin
            if FUserList.UserList[I].Speed < 3 then
            begin
              FLock.Enter;
              try
                FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
              finally
                FLock.Leave;
              end;
              Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
              Dec(ShoseNum);
            end;
          end;
        end;
      end;
      FMap.Map[X][Y + 1] := 3;
      Log.Info(Format('玩家 %s 向南移动,当前坐标(%d, %d)', [PlayerName, X, Y + 1]));
    end;
  end
  else if FMovePlayer.MoveType = MOVELEFT then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X - 1][Y] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X - 1, Y);
      FLock.Enter;
      try
        FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
        DeleteUserList(FGamers.IndexOf(PlayerName));
      finally
        FLock.Leave;
      end;
      Exit;
    end
    else if (FMap.Map[X - 1][Y] = 0) or (FMap.Map[X - 1][Y] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVELEFT);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> WEST then
          begin
            FLock.Enter;
            try
              FUserList.UserList[I].FaceTo := WEST;
            finally
              FLock.Leave;
            end;
          end;
          FLock.Enter;
          try
            FUserList.UserList[I].UserPosX := X - 1;
            FuserList.UserList[I].UserPosY := Y;
          finally
            FLock.Leave;
          end;
          if FMap.Map[X - 1][Y] = 5 then
          begin
            if FUserList.UserList[I].Speed < 3 then
            begin
              FLock.Enter;
              try
                FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
              finally
                FLock.Leave;
              end;
              Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
              Dec(ShoseNum);
            end;
          end;
        end;
      end;
      FMap.Map[X - 1][Y] := 3;
      Log.Info(Format('玩家 %s 向西移动,当前坐标(%d, %d)', [PlayerName, X - 1, Y]));
    end;
  end
  else if FMovePlayer.MoveType = MOVERIGHT then
  begin
    X := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
    Y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
    if FMap.Map[X + 1][Y] = 6 then
    begin
      Log.Info(Format('玩家: %s 被怪物杀死', [PlayerName]));
      PlayerDead(PlayerName, X + 1, Y);
      FLock.Enter;
      try
        FDeadGamers.AddObject(PlayerName, TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]));
        DeleteUserList(FGamers.IndexOf(PlayerName));
      finally
        FLock.Leave;
      end;
      Exit;
    end
    else if (FMap.Map[X + 1][Y] = 0) or (FMap.Map[X + 1][Y] = 5) then
    begin
      TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).ChangeGamerPos(MOVERIGHT);
      if FMap.Map[X][Y] <> 4 then
      begin
        FMap.Map[X][Y] := 0;
      end;
      for I := 0 to FGamers.Count - 1 do
      begin
        ListPlayerName := StrPas(PAnsichar(@(FUserList.UserList[I].UserName)[0]));
        if (ListPlayerName = PlayerName) then
        begin
          if FUserList.UserList[I].FaceTo <> EAST then
          begin
            FLock.Enter;
            try
              FUserList.UserList[I].FaceTo := EAST;
            finally
              FLock.Leave;
            end;
          end;
          FLock.Enter;
          try
            FUserList.UserList[I].UserPosX := X + 1;
            FuserList.UserList[I].UserPosY := Y;
          finally
            FLock.Leave;
          end;

          if FMap.Map[X + 1][Y] = 5 then
          begin
            if FUserList.UserList[I].Speed < 3 then
            begin
              FLock.Enter;
              try
                FUserList.UserList[I].Speed := FUserList.UserList[I].Speed + 1;
              finally
                FLock.Leave;
              end;
              Log.Info(Format('玩家%s获得道具鞋子，速度变为%d', [PlayerName, FUserList.UserList[I].Speed]));
              Dec(ShoseNum);
            end;
          end;

        end;
      end;
      FMap.Map[X + 1][Y] := 3;
      Log.Info(Format('玩家 %s 向东移动,当前坐标(%d, %d)', [PlayerName, X + 1, Y]));
    end;
  end;
  SendPlayerMoveInfo(PlayerName);
end;

function TTcpgameserver.PlayerSetBomb(RequestPtr: PPlayerSetBoom; AClient: TTCPClient): Integer;
var
  x: Integer;
  y: Integer;
  ABomb: TBOMB;
  PlayerName: AnsiString;
begin
  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  FLock.Enter;
  try
    if FDeadGamers.IndexOf(PlayerName) <> -1 then
    begin
      Exit;
    end;
  finally
    FLock.Leave;
  end;

  x := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosX;
  y := TGameClient(FGamers.Objects[FGamers.IndexOf(PlayerName)]).GamerPosY;
  if FMap.Map[x][y] <> 4 then
  begin
    ABomb := TBOMB.Create(x, y);
    ABomb.BombID := FBombList.Count;
    FLock.Enter;
    try
      FBombList.AddObject(IntToStr(ABomb.BombID), ABomb);
    finally
      FLock.Leave;
    end;

    FMap.Map[x][y] := 4;
    SendSetBombInfo(x, y);
  end;
end;

function TTcpgameserver.PlayerUseProp(RequestPtr: PUseProp; AClient: TTCPClient): Integer;
begin
  case RequestPtr.PropType of
    NoProp:
      begin
        Exit;
      end;
    MeleeWeapon:
      begin
        FindKillerPlayerMelee(RequestPtr);
      end;
    RangedWeapon:
      begin
        FindKillerPlayerRanged(RequestPtr);
      end
  end;
end;

procedure TTcpgameserver.ProcessClientIO(AClient: TTCPClient);
var
  BufPtr: PByte;
  BufSize, FetchSize: Integer;
begin
  AClient.LockReadBuffer(BufPtr, BufSize);
  FetchSize := 0;
  try
    if BufSize = 0 then
    begin
      Exit;
    end;
    while BufSize > 4 do
    begin
      if PCardinal(BufPtr)^ <> PACK_FLAG then
      begin
        BufSize := BufSize - 1;
        BufPtr := Pointer(Integer(BufPtr) + 1);
        FetchSize := FetchSize + 1;
        Continue;
      end;
      if (BufSize >= SizeOf(TGameMsgHead)) and (PGameMsgHead(BufPtr)^.Size <= BufSize) then
      begin
        FetchSize := FetchSize + PGameMsgHead(BufPtr)^.Size;
        ProcessRequests(PLoginMsg(BufPtr), AClient);
        BufPtr := Pointer(Integer(BufPtr) + PGameMsgHead(BufPtr)^.Size);
        BufSize := BufSize - FetchSize;
      end;

    end;
  finally
    AClient.UnLockReadBuffer(FetchSize);
  end;
end;

procedure TTcpgameserver.ProcessRequests(RequestPtr: PLoginMsg; AClient: TTCPClient);
var
  nowtime: TDateTime;
begin
  case RequestPtr.Head.Command of
    C_REGISTER:
      begin
        RegisterNewUser(PLoginMsg(RequestPtr), AClient);
      end;
    C_LOGIN:
      begin
        LoginUser(PLoginMsg(RequestPtr), AClient);
      end;
    C_MAP:
      begin
        SendMap;
//        SendAndAddBot;
      end;
    C_GETBOTINFO:
      begin
        SendAndAddBot;
      end;
    C_REQBOTlIST:
      begin
        SendBotList;
      end;
    C_MOVE:
      begin
        AddMoveUser(PPlayerMove(RequestPtr), AClient);
      end;
    C_STOPMOVE:
      begin
        RemoveUser(PPlayerStopMove(RequestPtr), AClient);
      end;
    C_BOOM:
      begin
        PlayerSetBomb(PPlayerSetBoom(RequestPtr), AClient);
      end;
    C_USEPROP:
      begin
        PlayerUseProp(PUseProp(RequestPtr), AClient);
      end;

  end;
end;

function TTcpgameserver.RegisterNewUser(RequestPtr: PLoginMsg; AClient: TTCPClient): Integer;
var
  sql: AnsiString;
  username, password, Error: AnsiString;
  Request: TServerMessage;
begin
  username := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  password := StrPas(PAnsichar(@(RequestPtr.Password)[0]));
  sql := 'SELECT * from test where username=' + '"' + username + '"';
  if SQLserver.SetSqlList(sql) = False then
  begin
    sql := 'INSERT into test (username, password) values(' + '"' + username + '"' + ',' + '"' + password + '"' + ');';
    if SQLserver.SetSqlList(sql) then
    begin
      Log.Info('注册成功');
      Result := 0;
    end;
  end
  else
  begin
    Log.Warn('用户已存在，注册失败');
    Result := 1;
  end;

  FillChar(Request, SizeOf(Request), 0);
  Request.head.Flag := PACK_FLAG;
  Request.head.Size := SizeOf(Request);
  Request.head.Command := S_REGISTER;
  Request.ErrorCode := Result;
  if Result = 1 then
  begin
    Error := '用户已经存在';
    StrLCopy(@Request.ErrorInfo[0], PAnsiChar(Error), Length(Error));
  end;
  AClient.SendData(@Request, sizeof(Request));
end;

function TTcpgameserver.RemoveUser(RequestPtr: PPlayerStopMove; AClient: TTCPClient): Integer;
var
  PlayerName: AnsiString;
  index: integer;
begin
  PlayerName := StrPas(PAnsichar(@(RequestPtr.UserName)[0]));
  if FMoveUserList.Count > 0 then
  begin
    index := FMoveUserList.IndexOf(PlayerName);
    if index > -1 then
    begin
      FLock.Enter;
      try
        if FMoveUserList.Objects[index] <> nil then
        begin
          FMoveUserList.Delete(index);
        end;
      finally
        FLock.Leave;
      end;

    end;
  end;
end;

function TTcpgameserver.SendMap: Integer;
var
  UserName: AnsiString;
  i: integer;
begin
  FMap.head.Flag := PACK_FLAG;
  FMap.head.Size := SizeOf(FMap);
  FMap.head.Command := S_MAP;
  FUserList.head.Flag := PACK_FLAG;
  FUserList.head.Size := SizeOf(FUserList);
  FUserList.head.Command := S_USERLIST;
  TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@Fmap, SizeOf(FMap));
  TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@FUserList, SizeOf(FUserList));
  Result := 0;
end;

procedure TTcpgameserver.SendMoveMessage;
var
  I: Integer;
  nowtime: Int64;
  lasttime: TDate;
begin
  if FMoveUserList.Count > 0 then
  begin
    nowtime := GetTickCount;
    for I := 0 to FMoveUserList.Count - 1 do
    begin
      if (nowtime - TMovePlayer(FMoveUserList.Objects[I]).Timer) > (2000 div (4 + TMovePlayer(FMoveUserList.Objects[I]).MoveSpeed)) then
      begin
        PlayerMove(TMovePlayer(FMoveUserList.Objects[I]));
        TMovePlayer(FMoveUserList.Objects[I]).Timer := nowtime;
      end;
    end;
//    FGameBotFindPlayer := TGameBotFindPlayer.Create;
//    ControlBots;
  end;
end;

function TTcpgameserver.SendPlaverLeave(PlayerName: AnsiString): Integer;
var
  FPlayerLeave: TPlayerLeave;
  I: Integer;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    FPlayerLeave.head.Flag := PACK_FLAG;
    FPlayerLeave.head.Size := SizeOf(FPlayerLeave);
    FPlayerLeave.head.Command := S_PLAYERLEAVE;
    strpcopy(FPlayerLeave.UserName, PlayerName);
    TGameClient(FGamers.Objects[I]).FClient.SendData(@Fmap, SizeOf(FMap));
  end;
  Result := 0;
end;

function TTcpgameserver.SendPlayerInfo(PlayerName: AnsiString): Integer;
var
  I: Integer;
  FPlayerInfo: TPlayerInfo;
begin
  for I := 0 to 4 do
  begin
    if FUserList.UserList[I].UserName = PlayerName then
    begin
      FPlayerInfo.UserID := FUserList.UserList[I].UserID;
      FPlayerInfo.UserName := FUserList.UserList[I].UserName;
      FPlayerInfo.UserPosX := FUserList.UserList[I].UserPosX;
      FPlayerInfo.UserPosY := FUserList.UserList[I].UserPosY;
      FPlayerInfo.FaceTo := FUserList.UserList[I].FaceTo;
      FPlayerInfo.Speed := FUserList.UserList[I].Speed;
    end;
  end;
  for I := 0 to FGamers.Count - 1 do
  begin
    FPlayerInfo.head.Flag := PACK_FLAG;
    FPlayerInfo.head.Size := SizeOf(FPlayerInfo);
    FPlayerInfo.head.Command := S_PlayerInfo;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FPlayerInfo, SizeOf(FPlayerInfo));
  end;

end;

function TTcpgameserver.SendPlayerMoveInfo(PlayerName: AnsiString): Integer;
var
  I: Integer;
  FPlayerInfo: TPlayerInfo;
begin
  for I := 0 to 4 do
  begin
    if FUserList.UserList[I].UserName = PlayerName then
    begin
      FPlayerInfo.UserID := FUserList.UserList[I].UserID;
      FPlayerInfo.UserName := FUserList.UserList[I].UserName;
      FPlayerInfo.UserPosX := FUserList.UserList[I].UserPosX;
      FPlayerInfo.UserPosY := FUserList.UserList[I].UserPosY;
      FPlayerInfo.FaceTo := FUserList.UserList[I].FaceTo;
      FPlayerInfo.Speed := FUserList.UserList[I].Speed;
    end;
  end;
  for I := 0 to FGamers.Count - 1 do
  begin
    FPlayerInfo.head.Flag := PACK_FLAG;
    FPlayerInfo.head.Size := SizeOf(FPlayerInfo);
    FPlayerInfo.head.Command := S_PLAYERMOVE;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FPlayerInfo, SizeOf(FPlayerInfo));
  end;
end;

function TTcpgameserver.SendRangedPropInfo(PropPosX, PropPosY: Integer; DestoryPos: DestoryTypes): Integer;
var
  FRangedPropInfo: TRangedPropInfo;
  I: Integer;
begin
  FRangedPropInfo.head.Flag := PACK_FLAG;
  FRangedPropInfo.head.Size := SizeOf(FRangedPropInfo);
  FRangedPropInfo.head.Command := S_RANGEDPROP;
  FRangedPropInfo.DestoryType := DestoryPos;
  FRangedPropInfo.DestoryPosX := PropPosX;
  FRangedPropInfo.DestoryPosY := PropPosY;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FRangedPropInfo, SizeOf(FRangedPropInfo));
  end;
end;

function TTcpgameserver.SendSetBombInfo(BombX, BombY: Integer): Integer;
var
  I: Integer;
  FBombInfo: TBombSeted;
begin
  FBombInfo.head.Flag := PACK_FLAG;
  FBombInfo.head.Size := SizeOf(FBombInfo);
  FBombInfo.head.Command := S_SETBOME;
  FBombInfo.BombPosX := BombX;
  FBombInfo.BombPosY := BombY;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FBombInfo, SizeOf(FBombInfo));
  end;

end;

function TTcpgameserver.SendShoesPos(x, y: Integer): Integer;
var
  FShoesInfo: TShoesInfo;
  I: Integer;
begin
  FShoesInfo.head.Flag := PACK_FLAG;
  FShoesInfo.head.Size := SizeOf(FShoesInfo);
  FShoesInfo.head.Command := S_SETSHOES;
  FShoesInfo.ShoesPosX := x;
  FShoesInfo.ShoesPosY := y;
  for I := 0 to FGamers.Count - 1 do
  begin
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FShoesInfo, SizeOf(FShoesInfo));
  end;
end;

function TTcpgameserver.SendAndAddBot: Integer;
begin
  InitBot;
  ControlBots;
  IfStartBot := True;
end;

function TTcpgameserver.SendBombEvent(BombX: Integer; BombY: Integer; BoomW: Integer; BoomA: Integer; BoomS: Integer; BoomD: Integer; PosArray: Pointer): Integer;
var
  I: integer;
  BombEvent: TBombBoom;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    BombEvent.head.Flag := PACK_FLAG;
    BombEvent.head.Size := SizeOf(BombEvent);
    BombEvent.head.Command := S_BOMBBOOM;
    BombEvent.Bombx := BombX;
    BombEvent.BombY := BombY;
    BombEvent.BoomW := BoomW;
    BombEvent.BoomA := BoomA;
    BombEvent.BoomS := BoomS;
    BombEvent.BoomD := BoomD;
    CopyMemory(@(BombEvent.DestoryPos), PosArray, SizeOf(BombEvent.DestoryPos));
    TGameClient(FGamers.Objects[I]).FClient.SendData(@BombEvent, SizeOf(BombEvent));
  end;

end;

function TTcpgameserver.SendBotInfo(BotID: Integer; PosX: Integer; PosY: Integer; FaceTo: Integer): Integer;
var
  I: Integer;
  FBotInfo: TBotInfo;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    FBotInfo.head.Flag := PACK_FLAG;
    FBotInfo.head.Size := SizeOf(FBotInfo);
    FBotInfo.head.Command := S_BOTINFO;
    FBotInfo.BotID := BotID;
    FBotInfo.BotPosX := PosX;
    FBotInfo.BotPosY := PosY;
    FBotInfo.BotFaceTo := FaceTo;
    TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@FBotInfo, SizeOf(FBotInfo));
  end;

end;

function TTcpgameserver.SendBotList: Integer;
begin
  FBotList.head.Flag := PACK_FLAG;
  FBotList.head.Size := SizeOf(FBotList);
  FBotList.head.Command := S_BOTLIST;
  TGameClient(FGamers.Objects[FGamers.Count - 1]).FClient.SendData(@FBotList, SizeOf(FBotList));
end;

function TTcpgameserver.SendBotMove(BotID, PosX, PosY, faceto: Integer): Integer;
var
  I: Integer;
  FBotInfo: TBotInfo;
begin
  for I := 0 to FGamers.Count - 1 do
  begin
    FBotInfo.head.Flag := PACK_FLAG;
    FBotInfo.head.Size := SizeOf(FBotInfo);
    FBotInfo.head.Command := S_BOTMOVE;
    FBotInfo.BotID := BotID;
    FBotInfo.BotPosX := PosX;
    FBotInfo.BotPosY := PosY;
    FBotInfo.BotFaceTo := faceto;
    TGameClient(FGamers.Objects[I]).FClient.SendData(@FBotInfo, SizeOf(FBotInfo));
  end;
end;

procedure TTcpgameserver.SetGamerPos(AGamer: TGameClient);
var
  X, Y: Integer;
begin
  repeat
    X := randomrange(0, 20);
    Y := RandomRange(0, 20);
  until FMap.Map[X][Y] = 0;
  AGamer.GamerPosX := X;
  AGamer.GamerPosY := Y;
  FMap.Map[X][Y] := 3;
end;

procedure TTcpgameserver.SetShoesProp;
var
  X, Y: Integer;
  Prevtime: TDateTime;
  NowTime: TDateTime;
  PosTime: TDateTime;
begin
  inherited;
  NowTime := Now;
  if SecondsBetween(NowTime, ShoseTime) = 15 then
  begin
    repeat
      X := randomrange(0, 20);
      Y := RandomRange(0, 20);
    until FMap.Map[X][Y] = 0;
    if ShoseNum < 7 then
    begin
      FMap.Map[X][Y] := 5;
      SendShoesPos(X, Y);
      Inc(ShoseNum);
    end;
    ShoseTime := NowTime;
  end;
end;

{ TGameClient }

procedure TGameClient.ChangeGamerPos(ChangeType: MoveDirect);
begin
  if ChangeType = MOVEUP then
  begin
    GamerPosY := GamerPosY - 1;
  end
  else if ChangeType = MOVEDOWN then
  begin
    GamerPosY := GamerPosY + 1;
  end
  else if ChangeType = MOVELEFT then
  begin
    GamerPosX := GamerPosX - 1;
  end
  else if ChangeType = MOVERIGHT then
  begin
    GamerPosX := GamerPosX + 1;
  end;
end;

constructor TGameClient.Create(UserName: AnsiString; AClient: TTCPClient);
begin
  FUsername := UserName;
  FClient := AClient;
end;

initialization
  FTcpgameserver := TTcpgameserver.Create;

finalization
  FTcpgameserver.free;

end.


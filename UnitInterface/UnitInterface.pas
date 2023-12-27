unit UnitInterface;

interface

uses
  Windows, MMSYSTEM, UnitErrorHandler, UnitVisualization, UnitGameMechanics;

procedure MenuInterface;     stdcall;
procedure MainGameInterface; stdcall;
procedure GameEndInterface;  stdcall;

var FlagEndInteraction :boolean;
    FlagCheckOneInput, FlagCheckOnePausedFrame  :boolean;

implementation

type TDifficulty = (difNone, difEasy, difMedium, difHard);

const Q_KEY = $51;
      E_KEY = $45;
      W_KEY = $57;
      A_KEY = $41;
      S_KEY = $53;
      D_KEY = $44;
      P_KEY = $50;
//      GameOverTheme = 'D:\Delphi\Tetris\GameOverTheme.wav';
//      TitleTheme    = 'D:\Delphi\Tetris\TitleTheme.wav';
//      MainTheme     = 'D:\Delphi\Tetris\MainTheme.wav';

var NumberEvent, NumberRead :LongWord;
    MenuRecord :INPUT_RECORD;
    NewCursorCoord :COORD;
    TextDifficulty :byte;
    CurrDifficulty :TDifficulty;


procedure MenuInteraction;
begin
  if not GetNumberOfConsoleInputEvents(hStdIn, NumberEvent) then ShowError('MENU_INTERFACE');
  if NumberEvent > 0 then
  begin
    if not ReadConsoleInput(hStdIn, MenuRecord, sizeof (INPUT_RECORD), NumberRead) then ShowError('MENU_INTERFACE');
    if (MenuRecord.EventType = KEY_EVENT) then
    begin
      if (MenuRecord.Event.KeyEvent.bKeyDown = True) then
      begin
        case MenuRecord.Event.KeyEvent.wVirtualKeyCode of
          D_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X + 1;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y;
            if NewCursorCoord.X <= FrameRight then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          A_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X - 1;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y;
            if NewCursorCoord.X >= FrameLeft then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          W_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y - 1;
            if NewCursorCoord.Y >= FrameTop then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          S_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y + 1;
            if NewCursorCoord.Y <= FrameBottom then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          VK_RETURN:
          begin
            GetCurrentScreenBufferInfo;
            case ScreenBufferInfo.dwCursorPosition.Y of
              10:
              begin
                CurrDifficulty := difEasy;
                TextDifficulty := 1;
              end;
              11:
              begin
                CurrDifficulty := difMedium;
                TextDifficulty := 2;
              end;
              12:
              begin
                CurrDifficulty := difHard;
                TextDifficulty := 3;
              end;
              16: if (CurrDifficulty <> difNone) then FlagEndInteraction := True;
            end;
            if not FlagEndInteraction then MenuNewFrame(TextDifficulty);
          end;
          VK_ESCAPE: FreeConsole;
        end;
      end;
    end
    //else if (MenuRecord.EventType = WINDOW_BUFFER_SIZE_EVENT) then ShowError('DON''T_RESIZE_WINDOW_YOU,_SILLY_QA_!_!_!')
    else sleep(100);
  end;
end;

procedure MenuInterface;
begin
//  PlaySound(TitleTheme, 0, SND_ASYNC or SND_LOOP);
  MenuInitialization;
  MenuStartingFrame;
  CurrDifficulty := difNone;
  TextDifficulty := 0;
  FlagEndInteraction := False;
  FlushConsoleInputBuffer(hStdIn);

  while not FlagEndInteraction do
  begin
    MenuInteraction;
  end;
end;

procedure MainGameInteraction;
begin
  if not GetNumberOfConsoleInputEvents(hStdIn, NumberEvent) then ShowError('MAIN_GAME_INTERFACE');
  if NumberEvent > 0 then
  begin
    if not ReadConsoleInput(hStdIn, MenuRecord, sizeof (INPUT_RECORD), NumberRead) then ShowError('MAIN_GAME_INTERFACE');
    if (MenuRecord.EventType = KEY_EVENT) and (MenuRecord.Event.KeyEvent.bKeyDown = True) then
    begin
      if not FlagPause then
      begin
        case MenuRecord.Event.KeyEvent.wVirtualKeyCode of
          VK_LEFT, Q_KEY: RotateDirection := dirLeft;
          VK_RIGHT, E_KEY: RotateDirection := dirRight;
          A_KEY: MoveDirection   := dirLeft;
          D_KEY: MoveDirection   := dirRight;
          S_KEY: FlagHoldDown    := True;
          P_KEY: FlagPause       := True;
          VK_ESCAPE: FreeConsole;
        end;
        FlagCheckOneInput := True;
      end
      else if FlagPause then if MenuRecord.Event.KeyEvent.wVirtualKeyCode = P_KEY then FlagPause := False;
    end
    else if (MenuRecord.EventType = KEY_EVENT) and (MenuRecord.Event.KeyEvent.bKeyDown <> True) then
    begin
      if MenuRecord.Event.KeyEvent.wVirtualKeyCode = S_KEY then
        FlagHoldDown    := False;

      FlagCheckOneInput := True;
    end;
    //if not (MenuRecord.EventType = WINDOW_BUFFER_SIZE_EVENT) then ShowError('DON''T_RESIZE_WINDOW_YOU,_SILLY_QA_!_!_!');
  end;
end;

procedure MainGameInterface;
begin
//  PlaySound(MainTheme, 0, SND_ASYNC or SND_LOOP);
  if hStdOut = 0 then GetHandle;

  case CurrDifficulty of
    difEasy:   TetraminoSpeed   := 20;
    difMedium: TetraminoSpeed   := 15;
    difHard:   TetraminoSpeed   := 7;
  end;

  GameStartingValues;
  MainGameInitialization;
  FlagEndInteraction := False;
  FlagCheckOneInput  := False;


  while not FlagEndInteraction do
  begin
    if TickCount mod FrameSpeed = FrameSpeed-1 then
    begin
      FlagCheckOneInput       := False;
      FlagCheckOnePausedFrame := False;

      if not FlagTetramino then 
      begin
        CreateTetramino;
        //FlagHoldDown := False;
        ClearScreenAttribute;
      end;
      
      if (FrameCount mod TetraminoSpeed = TetraminoSpeed-1) or (FlagHoldDown and (FrameCount mod 2 = 1)) or (MoveDirection <> dirNone) or (RotateDirection <> dirNone) then
        ClearScreenAttribute;

      MoveTetramino;
      RotateTetramino;

      if (FrameCount mod TetraminoSpeed = TetraminoSpeed-1) or (FlagHoldDown and (FrameCount mod 2 = 1)) then
      begin
        //FlagHoldDown := False;
        MoveTetraminoDown;
      end;
      
      if FlagCollision then 
      begin
        AddTetraminoToMatrix;
        CheckLine;
        if FlagLine then DeleteLine;
        ClearScreenAttribute;
      end;

      CheckDefeat;
      CheckWin;
      if FlagWin or FlagDefeat then FlagEndInteraction := True;

      if not FlagEndInteraction then
      begin
        MainGameNewFrame;
        //FlushConsoleInputBuffer(hStdIn);
        TickCount := 0;
        Inc(FrameCount);
      end;
    end
    else if not FlagPause then
    begin
      if not FlagCheckOneInput then MainGameInteraction;
      Sleep(10);
      Inc(TickCount);
    end
    else if FlagPause then
    begin
      if not FlagCheckOnePausedFrame then MainGameNewFrame;
      FlagCheckOnePausedFrame := True;
      MainGameInteraction;
      Sleep(10);
    end;
  end;
  GameEndingValues;
end;

procedure GameEndInterface;
begin
//  PlaySound(GameOverTheme, 0, SND_ASYNC);
  GameEndInitialization;
  GameEndStartingFrame;
end;

end.

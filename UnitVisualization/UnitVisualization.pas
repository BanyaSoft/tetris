unit UnitVisualization;

interface

uses
  Windows, UnitErrorHandler, UnitGameMechanics;

const GlobalPositionX = 27;
      GamePositionX   = 27;
      GamePositionY   = 5;
      FrameRight   = GlobalPositionX + 93;
      FrameLeft    = GlobalPositionX;
      FrameTop     = 0;
      FrameBottom  = 28;

var hStdOut, hStdIn :THandle;
    ScreenBufferInfo :CONSOLE_SCREEN_BUFFER_INFO;

procedure GetHandle;                                                          stdcall;
procedure GetCurrentScreenBufferInfo;                                         stdcall;
procedure SetCursorPosition(CursorPositionY: byte; CursorPositionX: byte = 0) stdcall;
procedure ClearScreen;                                                        stdcall;
procedure ClearScreenAttribute;                                               stdcall;
procedure SetOldMode;                                                         stdcall;
procedure MenuInitialization;                                                 stdcall;
procedure MenuStartingFrame;                                                  stdcall;
procedure MenuNewFrame(TextDifficulty :byte);                                 stdcall;
procedure MainGameInitialization;                                             stdcall;
procedure MainGameNewFrame;                                                   stdcall;
procedure GameEndInitialization;                                              stdcall;
procedure GameEndStartingFrame;                                               stdcall;

implementation

const UTF_8 = 65001;
      MenuInMode      = ENABLE_WINDOW_INPUT;
      MenuOutMode     = ENABLE_WRAP_AT_EOL_OUTPUT or ENABLE_PROCESSED_OUTPUT;
      MainGameInMode  = ENABLE_WINDOW_INPUT;
      MainGameOutMode = ENABLE_WRAP_AT_EOL_OUTPUT or ENABLE_PROCESSED_OUTPUT;
      GameOverInMode  = ENABLE_WINDOW_INPUT;
      GameOverOutMode = ENABLE_WRAP_AT_EOL_OUTPUT or ENABLE_PROCESSED_OUTPUT;
//      MenuScreenSizeX      = 94;
//      MenuScreenSizeY      = 25;
//      MainGameScreenSizeX  = 33;
//      MainGameScreenSizeY  = 21;
//      GameEndScreenSizeX   = 94;
//      GameEndScreenSizeY   = 25;
      MenuCursorSize           = 100;
      MenuCursorVisibility     = True;
      MainGameCursorSize       = 1;
      MainGameCursorVisibility = False;
      GameEndCursorSize        = 1;
      GameEndCursorVisibility  = False;

type TTab = (tabMenu, tabMainGame, tabGameEnd);

var oldOutMode, oldInMode: LongWord;
    CurrentTab :TTab;
    FlagRepeatOnce :boolean;

procedure GetHandle;
begin
  hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if hStdOut = INVALID_HANDLE_VALUE then ShowError('STD_OUTPUT_HANDLE');

  hStdIn := GetSTDHandle(STD_INPUT_HANDLE);
  if hStdIn = INVALID_HANDLE_VALUE then ShowError('STD_INPUT_HANDLE');
end;

procedure GetOldMode;
begin
  if hStdOut = 0 then GetHandle;
  if not GetConsoleMode(hStdOut, OldOutMode) then ShowError('GET_OLD_MODE_OUTPUT');
  if not GetConsoleMode(hStdIn, OldInMode) then ShowError('GET_OLD_MODE_INPUT');
end;

procedure SetOldMode;
begin
  if hStdOut = 0 then GetHandle;
  if not SetConsoleMode(hStdOut, OldOutMode) then ShowError('SET_OLD_MODE_OUTPUT');
  if not SetConsoleMode(hStdIn, OldInMode) then ShowError('SET_OLD_MODE_INPUT');
end;

procedure SetNewMode;
var CurrOutMode, CurrInMode :LongWord;
begin
  CurrOutMode := MenuOutMode;
  CurrInMode  := MenuInMode;

  if (hStdOut = 0) or (hStdIn = 0) then GetHandle;
  case CurrentTab of
    tabMenu:
    begin
      CurrOutMode := MenuOutMode;
      CurrInMode  := MenuInMode;
    end;
    tabMainGame:
    begin
      CurrOutMode := MainGameOutMode;
      CurrInMode  := MainGameInMode;
    end;
    tabGameEnd:
    begin
      CurrOutMode := GameOverOutMode;
      CurrInMode  := GameOverInMode;
    end;
  end;
  if not SetConsoleMode(hStdOut, CurrOutMode) then ShowError('SET_CURRENT_MODE_OUTPUT');
  if not SetConsoleMode(hStdIn, CurrInMode) then ShowError('SET_CURRENT_MODE_INPUT');
end;

procedure SetTabTitle;
var TabTitle :PWideChar;
begin
  TabTitle := '';
  case CurrentTab of
    tabMenu:     TabTitle := 'Tetris\Menu';
    tabMainGame: TabTitle := 'Tetris\MainGame';
    tabGameEnd:  TabTitle := 'Tetris\GameEnd';
  end;
  if not SetConsoleTitle(TabTitle) then ShowError('SET_TAB_TITLE');
end;

procedure GetCurrentScreenBufferInfo;
begin
  if hStdOut = 0 then GetHandle;
  if not GetConsoleScreenBufferInfo(hStdOut, ScreenBufferInfo) then ShowError('GET_SCREEN_BUFFER_INFO');
end;

procedure SetCursorPosition(CursorPositionY: byte; CursorPositionX: byte = 0);
var GlobalCursorPosition: TCOORD;
begin
  GlobalCursorPosition.Y := CursorPositionY;
  GlobalCursorPosition.X := GlobalPositionX + CursorPositionX;

  SetConsoleCursorPosition(hStdOut, GlobalCursorPosition);
end;

procedure ClearScreen;
var ConsoleSize, NumWritten :LongWord;
    Origin : Coord;
begin
  if hStdOut = 0 then GetHandle;
  GetCurrentScreenBufferInfo;
  ConsoleSize := ScreenBufferInfo.dwSize.X * ScreenBufferInfo.dwSize.Y;
  Origin.X := 0;
  Origin.Y := 0;
  if not FillConsoleOutputCharacter(hStdOut, ' ', ConsoleSize, Origin, NumWritten) then ShowError('CLEAR_SCREEN');
  if not FillConsoleOutputAttribute(hStdOut, ScreenBufferInfo.wAttributes, ConsoleSize, Origin, NumWritten) then ShowError('CLEAR_SCREEN');
  if not SetConsoleCursorPosition(hStdOut, Origin) then ShowError('CLEAR_SCREEN');
end;

procedure ClearScreenAttribute;
var NumWritten :LongWord;
    ClearCoord : Coord;
    ClearAttribute :LongWord;
    StateCounter, RowCounter, ColumnCounter :byte;
begin
  if hStdOut = 0 then GetHandle;
  ClearAttribute := BACKGROUND_GREEN or BACKGROUND_RED or BACKGROUND_BLUE;

  for StateCounter := 1 to 4 do
  begin
    ClearCoord.Y := GamePositionY + (CurrentTetramino[StateCounter, 2] + Position[2]);

    ClearCoord.X := GlobalPositionX + GamePositionX + (CurrentTetramino[StateCounter, 1] + Position[1])*2;
    if not WriteConsoleOutputAttribute(hStdOut, @ClearAttribute, 1, ClearCoord, NumWritten) then ShowError('CLEAR_SCREEN_ATTRIBUTES');

    ClearCoord.X := GlobalPositionX + GamePositionX + (CurrentTetramino[StateCounter, 1] + Position[1])*2 + 1;
    if not WriteConsoleOutputAttribute(hStdOut, @ClearAttribute, 1, ClearCoord, NumWritten) then ShowError('CLEAR_SCREEN_ATTRIBUTES');
  end;

  if FlagNewNextTetr then
  begin
    for RowCounter := 1 to 5 do
    for ColumnCounter := 11 to 15 do
    begin
      ClearCoord.Y := GamePositionY + RowCounter;

      ClearCoord.X := GlobalPositionX + GamePositionX + ColumnCounter*2;
      if not WriteConsoleOutputAttribute(hStdOut, @ClearAttribute, 1, ClearCoord, NumWritten) then ShowError('CLEAR_SCREEN_ATTRIBUTES');

      ClearCoord.X := GlobalPositionX + GamePositionX + ColumnCounter*2 + 1;
      if not WriteConsoleOutputAttribute(hStdOut, @ClearAttribute, 1, ClearCoord, NumWritten) then ShowError('CLEAR_SCREEN_ATTRIBUTES');
    end;
  end;

  if FlagNewObstacle then
  begin
    for RowCounter := 0 to FieldWidth-1 do
    for ColumnCounter := 0 to FieldLength-1 do
    begin
      ClearCoord.Y := GamePositionY + RowCounter;

      ClearCoord.X := GlobalPositionX + GamePositionX + ColumnCounter*2;
      if not WriteConsoleOutputAttribute(hStdOut, @ClearAttribute, 1, ClearCoord, NumWritten) then ShowError('CLEAR_SCREEN_ATTRIBUTES');

      ClearCoord.X := GlobalPositionX + GamePositionX + ColumnCounter*2 + 1;
      if not WriteConsoleOutputAttribute(hStdOut, @ClearAttribute, 1, ClearCoord, NumWritten) then ShowError('CLEAR_SCREEN_ATTRIBUTES');
    end;
  end;
end;

procedure MenuInitialization;
var CurrCursorInfo :CONSOLE_CURSOR_INFO;
begin
  if hStdOut = 0 then GetHandle;
  GetOldMode;
  CurrentTab := tabMenu;
  SetNewMode;
  SetTabTitle;

  GetCurrentScreenBufferInfo;

  CurrCursorInfo.dwSize   := MenuCursorSize;
  CurrCursorInfo.bVisible := MenuCursorVisibility;
  if not SetConsoleCursorInfo(hStdOut, CurrCursorInfo) then ShowError('MENU_INITIALIZATION');
end;

procedure MenuStartingFrame;
var StartingCursorPosition :COORD;
    AttributeCoord :COORD;
    RowCount, NumberAttr :LongWord;
    TextAttribute :word;
    TempStr: string[255];
begin
  if hStdOut = 0 then GetHandle;

  TempStr := '';
  while Length(TempStr) < GlobalPositionX do
  begin
    TempStr := TempStr + ' ';
  end;

  writeln(TempStr,'╔═══════════════════════════════════════════════════════════════════════════════════════════╗');
  writeln(TempStr,'║     ╔═      ╗  ╔══════   ╔          ╗        ╔═════      ╔╗       ╔╗    ╔╗    ╔══════     ║');
  writeln(TempStr,'║     ║ ╚     ║  ║         ║          ║       ╔           ╔  ╗     ╔  ╗  ╔  ╗   ║           ║');
  writeln(TempStr,'║     ║  ╚    ║  ╠═════    ╚          ╝      ╔           ╔    ╗    ║   ╚╝   ║   ╠═════      ║');
  writeln(TempStr,'║     ║   ╚   ║  ║          ║   ╔╗   ║       ╚     ══╗  ╔══════╗  ╔          ╗  ║           ║');
  writeln(TempStr,'║     ║    ╚  ║  ║          ╚  ╔  ╗  ╝        ╚      ║  ║      ║  ║          ║  ║           ║');
  writeln(TempStr,'║     ╚     ╚═╝  ╚══════     ╚═    ═╝          ╚════╝   ╚      ╝  ╚          ╝  ╚══════     ║');
  writeln(TempStr,'╠═══════════════════════════════════════════════════════════════════════════════════════════╣');
  writeln(TempStr,'║                                                                                           ║');
  writeln(TempStr,'║  Choose Difficulty:                                                                       ║');
  writeln(TempStr,'║   1. Easy.                        Half   Speed.                                           ║');
  writeln(TempStr,'║   2. Medium.                      Full   Speed.                                           ║');
  writeln(TempStr,'║   3. Hard.                        Double Speed.                                           ║');
  writeln(TempStr,'║                                                                                           ║');
  writeln(TempStr,'║                                                                                           ║');
  writeln(TempStr,'║  Current Difficulty: None.                                                                ║');
  writeln(TempStr,'║  Confirm Selection...                                                                     ║');
  writeln(TempStr,'║                                                                                           ║');
  writeln(TempStr,'╠═════════════════════════════════════╗                                                     ║');
  writeln(TempStr,'║ Controls:                           ║                                                     ║');
  writeln(TempStr,'║  WASD - Move Cursor.                ║                                                     ║');
  writeln(TempStr,'║  A,D - Move. Q,E - Rotate.          ║                                                     ║');
  writeln(TempStr,'║  S - Increase Speed.                ║                                                     ║');
  writeln(TempStr,'║  Enter - Choose Option. Esc - Exit. ║                        Developed by Shevchenko A.D. ║');
  write  (TempStr,'╚═════════════════════════════════════╩═════════════════════════════════════════════════════╝');

  AttributeCoord.X := GlobalPositionX + 7;
  for RowCount := 10 to 12 do
  begin
    case RowCount of
      10:
      begin
        AttributeCoord.Y := RowCount;
        TextAttribute := FOREGROUND_GREEN;
        if not WriteConsoleOutputAttribute(hStdOut, @TextAttribute, 1, AttributeCoord, NumberAttr) then ShowError('MENU_STARTING_FRAME');
      end;
      11:
      begin
        AttributeCoord.Y := RowCount;
        TextAttribute := FOREGROUND_GREEN or FOREGROUND_RED;
        if not WriteConsoleOutputAttribute(hStdOut, @TextAttribute, 1, AttributeCoord, NumberAttr) then ShowError('MENU_STARTING_FRAME');
      end;
      12:
      begin
        AttributeCoord.Y := RowCount;
        TextAttribute := FOREGROUND_RED;
        if not WriteConsoleOutputAttribute(hStdOut, @TextAttribute, 1, AttributeCoord, NumberAttr) then ShowError('MENU_STARTING_FRAME');
      end;
    end;
  end;

  StartingCursorPosition.X := GlobalPositionX + 3;
  StartingCursorPosition.Y := 9;
  if not SetConsoleCursorPosition(hStdOut, StartingCursorPosition) then ShowError('MENU_STARTING_FRAME');
end;

procedure MenuNewFrame(TextDifficulty :byte);
var OriginalCursorPosition, WriteCoord :Coord;
    TextDif:string[7];
begin
  if hStdOut = 0 then GetHandle;

  GetCurrentScreenBufferInfo;
  case TextDifficulty of
  1:   TextDif := 'Easy.  ';
  2:   TextDif := 'Medium.';
  3:   TextDif := 'Hard.  ';
  else TextDif := 'None.  ';
  end;

  OriginalCursorPosition.X := ScreenBufferInfo.dwCursorPosition.X;
  OriginalCursorPosition.Y := ScreenBufferInfo.dwCursorPosition.Y;

  if TextDif <> 'None.  ' then
  begin
    WriteCoord.X := GlobalPositionX;
    WriteCoord.Y := 15;
    if not SetConsoleCursorPosition(hStdOut, WriteCoord) then ShowError('MENU_NEW_FRAME');
    Write('║  Current Difficulty: ', TextDif,  '                                                              ║');
  end;

  if not SetConsoleCursorPosition(hStdOut, OriginalCursorPosition) then ShowError('MENU_NEW_FRAME');
end;

procedure MainGameInitialization;
var CurrCursorInfo :CONSOLE_CURSOR_INFO;
    ClearAttributes: LongWord;
    CellCoord: TCoord;
    NumberAttr: Cardinal;
    RowCount, ColumnCount: byte;
begin
  if hStdOut = 0 then GetHandle;
  CurrentTab := tabMainGame;
  SetNewMode;
  SetTabTitle;

  GetCurrentScreenBufferInfo;

  CurrCursorInfo.dwSize   := MainGameCursorSize;
  CurrCursorInfo.bVisible := MainGameCursorVisibility;
  if not SetConsoleCursorInfo(hStdOut, CurrCursorInfo) then ShowError('MAIN_GAME_INITIALIZATION');

  ClearAttributes := BACKGROUND_GREEN or BACKGROUND_RED or BACKGROUND_BLUE;
  FlagRepeatOnce := False;

  for RowCount := 0 to FieldWidth - 1 do
  begin
    if (RowCount <= 5) and (RowCount >= 1) then
    begin
      for ColumnCount := 0 to FieldLength + 6 - 1 do
      begin
        if ColumnCount = 10 then write('  ')
        else
        begin
          CellCoord.Y := GamePositionY + RowCount;

          CellCoord.X := GlobalPositionX + GamePositionX + ColumnCount*2;
          if not WriteConsoleOutputAttribute(hStdOut, @ClearAttributes, 1, CellCoord, NumberAttr) then ShowError('MAIN_GAME_INITIALIZATION');

          CellCoord.X := GlobalPositionX + GamePositionX + ColumnCount*2+1;
          if not WriteConsoleOutputAttribute(hStdOut, @ClearAttributes, 1, CellCoord, NumberAttr) then ShowError('MAIN_GAME_INITIALIZATION');
        end;
      end;
    end
    else for ColumnCount := 0 to FieldLength - 1 do
    begin
      CellCoord.Y := GamePositionY + RowCount;

      CellCoord.X := GlobalPositionX + GamePositionX + ColumnCount*2;
      if not WriteConsoleOutputAttribute(hStdOut, @ClearAttributes, 1, CellCoord, NumberAttr) then ShowError('MAIN_GAME_INITIALIZATION');

      CellCoord.X := GlobalPositionX + GamePositionX + ColumnCount*2+1;
      if not WriteConsoleOutputAttribute(hStdOut, @ClearAttributes, 1, CellCoord, NumberAttr) then ShowError('MAIN_GAME_INITIALIZATION');
    end;
    writeln;
  end;
end;

procedure MainGameNewFrame;
var TileCoord :Coord;
    CurrentAttribute :LongWord;
    StateCounter, RowCounter, ColumnCounter :byte;
    NumWritten :cardinal;
begin
  if hStdOut = 0 then GetHandle;

  if FlagTetramino then
  begin
    for StateCounter := 1 to 4 do
    begin
      TileCoord.Y := GamePositionY + (CurrentTetramino[StateCounter, 2] + Position[2]);

      CurrentAttribute := CurrentTetraminoColour;

      TileCoord.X := GlobalPositionX + GamePositionX + (CurrentTetramino[StateCounter, 1] + Position[1])*2;
      if not WriteConsoleOutputAttribute(hStdOut, @CurrentAttribute, 1, TileCoord, NumWritten) then ShowError('MAIN_GAME_NEW_FRAME1');

      TileCoord.X := GlobalPositionX + GamePositionX + (CurrentTetramino[StateCounter, 1] + Position[1])*2 + 1;
      if not WriteConsoleOutputAttribute(hStdOut, @CurrentAttribute, 1, TileCoord, NumWritten) then ShowError('MAIN_GAME_NEW_FRAME1');
    end;
  end;
  

  if FlagNewNextTetr then
  begin
    for StateCounter := 1 to 4 do
    begin
      TileCoord.Y := GamePositionY + (NextTetramino[StateCounter, 2] + 3);

      CurrentAttribute := NextTetraminoColour;

      TileCoord.X := GlobalPositionX + GamePositionX + (NextTetramino[StateCounter, 1] + 13)*2;
      if not WriteConsoleOutputAttribute(hStdOut, @CurrentAttribute, 1, TileCoord, NumWritten) then ShowError('MAIN_GAME_NEW_FRAME2');

      TileCoord.X := GlobalPositionX + GamePositionX + (NextTetramino[StateCounter, 1] + 13)*2 + 1;
      if not WriteConsoleOutputAttribute(hStdOut, @CurrentAttribute, 1, TileCoord, NumWritten) then ShowError('MAIN_GAME_NEW_FRAME2');
    end;
    FlagNewNextTetr := False;
  end;

  if FlagNewObstacle then
  begin
    for RowCounter := 0 to FieldWidth-1 do
    for ColumnCounter := 0 to FieldLength-1 do
    if ObstacleMatrix[ColumnCounter, RowCounter] = 1 then
    begin
      TileCoord.Y := GamePositionY + RowCounter;

      CurrentAttribute := ColourMatrix[ColumnCounter, RowCounter];

      TileCoord.X := GlobalPositionX + GamePositionX + ColumnCounter*2;
      if not WriteConsoleOutputAttribute(hStdOut, @CurrentAttribute, 1, TileCoord, NumWritten) then ShowError('MAIN_GAME_NEW_FRAME3');

       TileCoord.X := GlobalPositionX + GamePositionX + ColumnCounter*2 + 1;
      if not WriteConsoleOutputAttribute(hStdOut, @CurrentAttribute, 1, TileCoord, NumWritten) then ShowError('MAIN_GAME_NEW_FRAME3');
    end;
    FlagNewObstacle := False;
  end;

  SetCursorPosition(FieldWidth + GamePositionY, GamePositionX);
//  write('FrameC: ', FrameCount, '  ');
  write('Score: ', CurrentScore, '  ');
  SetCursorPosition(FieldWidth + 1 + GamePositionY, GamePositionX);
  write('ScoreG: ', ScoreGoal);
  if FlagPause then write('  P')
  else write('  A');

end;

procedure GameEndInitialization;
var CurrCursorInfo :CONSOLE_CURSOR_INFO;
begin
  if hStdOut = 0 then GetHandle;
  CurrentTab := tabGameEnd;
  SetNewMode;
  SetTabTitle;

  CurrCursorInfo.dwSize   := GameEndCursorSize;
  CurrCursorInfo.bVisible := GameEndCursorVisibility;
  if not SetConsoleCursorInfo(hStdOut, CurrCursorInfo) then ShowError('GAME_END_INITIALIZATION');
end;

procedure GameEndStartingFrame;
var StartingCursorPosition :COORD;
    TextAttribute, ConsoleSize :Word;
    NumWritten :Cardinal;
    TempStr: string[255];
begin
  if hStdOut = 0 then GetHandle;

  StartingCursorPosition.X := 0;
  StartingCursorPosition.Y := 0;
  if not SetConsoleCursorPosition(hStdOut, StartingCursorPosition) then ShowError('GAME_END_STARTING_FRAME');

  TextAttribute := FOREGROUND_GREEN;

  TempStr := '';
  while Length(TempStr) < GlobalPositionX do
  begin
    TempStr := TempStr + ' ';
  end;

  if FlagWin then
  begin
    writeln(TempStr,'╔════════════════════════════════════════════════════════════════════════════════════════╗');
    writeln(TempStr,'║                  ╔          ╗  ╔═══╦═══╗  ╔═      ╗   ╔╦╦╗  ╔╦╦╗  ╔╦╦╗                 ║');
    writeln(TempStr,'║                  ║          ║      ║      ║ ╚     ║   ╠╬╬╣  ╠╬╬╣  ╠╬╬╣                 ║');
    writeln(TempStr,'║                  ╚          ╝      ║      ║  ╚    ║   ╠╬╬╣  ╠╬╬╣  ╠╬╬╣                 ║');
    writeln(TempStr,'║                   ║   ╔╗   ║       ║      ║   ╚   ║    ╠╣    ╠╣    ╠╣                  ║');
    writeln(TempStr,'║                   ╚  ╔  ╗  ╝       ║      ║    ╚  ║    ╚╝    ╚╝    ╚╝                  ║');
    writeln(TempStr,'║                    ╚═    ═╝    ╚═══╩═══╝  ╚     ╚═╝    ╚╝    ╚╝    ╚╝                  ║');
    writeln(TempStr,'╚════════════════════════════════════════════════════════════════════════════════════════╝');
    TextAttribute := BACKGROUND_GREEN;
  end;

  if FlagDefeat then
  begin
    writeln(TempStr,'╔════════════════════════════════════════════════════════════════════════════════════════╗');
    writeln(TempStr,'║               ╔════╗    ╔══════     ╔╗     ╔════╗    ╔╦╦╗  ╔╦╦╗  ╔╦╦╗                  ║');
    writeln(TempStr,'║               ║     ╗   ║          ╔  ╗    ║     ╗   ╠╬╬╣  ╠╬╬╣  ╠╬╬╣                  ║');
    writeln(TempStr,'║               ║      ╗  ╠═════    ╔    ╗   ║      ╗  ╠╬╬╣  ╠╬╬╣  ╠╬╬╣                  ║');
    writeln(TempStr,'║               ║      ╝  ║        ╔══════╗  ║      ╝   ╠╣    ╠╣    ╠╣                   ║');
    writeln(TempStr,'║               ║     ╝   ║        ║      ║  ║     ╝    ╚╝    ╚╝    ╚╝                   ║');
    writeln(TempStr,'║               ╚════╝    ╚══════  ╚      ╝  ╚════╝     ╚╝    ╚╝    ╚╝                   ║');
    writeln(TempStr,'╚════════════════════════════════════════════════════════════════════════════════════════╝');
    TextAttribute := BACKGROUND_RED;
  end;

  writeln;
  writeln(TempStr,'Your Settings: ');

  write(TempStr,' Difficulty: ');
  case TetraminoSpeed of
  20: writeln('Easy.   ');
  15: writeln('Medium. ');
  7:  writeln('Hard.   ');
  end;

  writeln;
  writeln(TempStr,'Your Results:');
  writeln(TempStr,' Score: ', CurrentScore);

  if hStdOut = 0 then GetHandle;
  GetCurrentScreenBufferInfo;
  ConsoleSize := ScreenBufferInfo.dwSize.X * 8;
  StartingCursorPosition.X := 0;
  StartingCursorPosition.Y := 0;
  if not FillConsoleOutputAttribute(hStdOut, TextAttribute, ConsoleSize, StartingCursorPosition, NumWritten) then ShowError('GAME_END_STARTING_FRAME');
end;

end.

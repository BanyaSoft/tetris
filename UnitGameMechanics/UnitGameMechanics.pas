unit UnitGameMechanics;

interface

uses
  Windows, System.SysUtils, UnitErrorHandler;

type TTile         = array[1..2] of integer;
     TState        = array[1..4] of TTile;
     TShape        = (shaI, shaL, shaJ, shaO, shaZ, shaT, shaS);
     TRotation     = (rotLeft, rotNormal, rotRight, rotUpDown);
     TDirection    = (dirLeft, dirRight, dirNone);
     TSetOfStates  = array[TShape, TRotation] of TState;
     TColour       = word;
     TSetOfColours = array[1..6] of TColour;
     TMatrix       = array of array of word;

var FieldLength, FieldWidth,  TetraminoSpeed, FrameSpeed, RotateSpeed :byte;
    TickCount, CurrentScore, LinesCleared, FrameCount, ScoreGoal :cardinal;
    FlagTetramino, FlagNextTetramino, FlagHoldDown, FlagPause,
    FlagLine, FlagCollision, FlagWin, FlagDefeat, FlagNewObstacle, FlagNewNextTetr :boolean;
    CurrentTetraminoColour, NextTetraminoColour :TColour;
    CurrentTetramino, NextTetramino :TState;
    Position  :TTile;
    Rotation  :TRotation;
    MoveDirection, RotateDirection :TDirection;
    CurrentShape, NextShape :TShape;
    SetOfStates :TSetOfStates;
    SetOfColours :TSetOfColours;
    ObstacleMatrix, ColourMatrix :TMatrix;

procedure GameStartingValues;   stdcall;
procedure CreateTetramino;      stdcall;
procedure MoveTetramino;        stdcall;
procedure MoveTetraminoDown;    stdcall;
procedure RotateTetramino;      stdcall;
procedure AddTetraminoToMatrix; stdcall;
procedure CheckLine;            stdcall;
procedure DeleteLine;           stdcall;
procedure CheckDefeat;          stdcall;
procedure CheckWin;             stdcall;
procedure GameEndingValues;     stdcall;

implementation

procedure DefineSetOfStates;
var BasicSetOfStates :TSetOfStates;
const shaI_Left   :TState = ((-1,+0),(+1,+0),(+2,+0),(+0,+0));
      shaI_Normal :TState = ((+0,-1),(+0,+1),(+0,+2),(+0,+0));
      shaI_Right  :TState = ((-2,+0),(-1,+0),(+1,+0),(+0,+0));
      shaI_UpDown :TState = ((+0,+1),(+0,-1),(+0,-2),(+0,+0));

      shaL_Left   :TState = ((-1,+0),(+1,+0),(+1,-1),(+0,+0));
      shaL_Normal :TState = ((+0,-1),(+0,+1),(+1,+1),(+0,+0));
      shaL_Right  :TState = ((+1,+0),(-1,+0),(-1,+1),(+0,+0));
      shaL_UpDown :TState = ((+0,+1),(+0,-1),(-1,-1),(+0,+0));

      shaJ_Left   :TState = ((-1,+0),(+1,+0),(+1,+1),(+0,+0));
      shaJ_Normal :TState = ((+0,-1),(+0,+1),(-1,+1),(+0,+0));
      shaJ_Right  :TState = ((-1,+0),(+1,+0),(-1,-1),(+0,+0));
      shaJ_UpDown :TState = ((+0,+1),(+0,-1),(+1,-1),(+0,+0));

      shaO_Left   :TState = ((+1,+0),(+1,+1),(+0,+1),(+0,+0));
      shaO_Normal :TState = ((+1,+0),(+1,+1),(+0,+1),(+0,+0));
      shaO_Right  :TState = ((+1,+0),(+1,+1),(+0,+1),(+0,+0));
      shaO_UpDown :TState = ((+1,+0),(+1,+1),(+0,+1),(+0,+0));

      shaZ_Left   :TState = ((+0,+1),(+1,+0),(+1,-1),(+0,+0));
      shaZ_Normal :TState = ((-1,+0),(+0,+1),(+1,+1),(+0,+0));
      shaZ_Right  :TState = ((+0,+1),(+1,+0),(+1,-1),(+0,+0));
      shaZ_UpDown :TState = ((-1,+0),(+0,+1),(+1,+1),(+0,+0));

      shaT_Left   :TState = ((+0,-1),(+0,+1),(-1,+0),(+0,+0));
      shaT_Normal :TState = ((-1,+0),(+1,+0),(+0,-1),(+0,+0));
      shaT_Right  :TState = ((+0,-1),(+0,+1),(+1,+0),(+0,+0));
      shaT_UpDown :TState = ((-1,+0),(+1,+0),(+0,+1),(+0,+0));

      shaS_Left   :TState = ((-1,+0),(-1,-1),(+0,+1),(+0,+0));
      shaS_Normal :TState = ((+1,+0),(+0,+1),(-1,+1),(+0,+0));
      shaS_Right  :TState = ((-1,+0),(-1,-1),(+0,+1),(+0,+0));
      shaS_UpDown :TState = ((+1,+0),(+0,+1),(-1,+1),(+0,+0));

begin
  BasicSetOfStates[shaI, rotLeft]   := shaI_Left;
  BasicSetOfStates[shaI, rotNormal] := shaI_Normal;
  BasicSetOfStates[shaI, rotRight]  := shaI_Right;
  BasicSetOfStates[shaI, rotUpDown] := shaI_UpDown;

  BasicSetOfStates[shaL, rotLeft]   := shaL_Left;
  BasicSetOfStates[shaL, rotNormal] := shaL_Normal;
  BasicSetOfStates[shaL, rotRight]  := shaL_Right;
  BasicSetOfStates[shaL, rotUpDown] := shaL_UpDown;

  BasicSetOfStates[shaJ, rotLeft]   := shaJ_Left;
  BasicSetOfStates[shaJ, rotNormal] := shaJ_Normal;
  BasicSetOfStates[shaJ, rotRight]  := shaJ_Right;
  BasicSetOfStates[shaJ, rotUpDown] := shaJ_UpDown;

  BasicSetOfStates[shaO, rotLeft]   := shaO_Left;
  BasicSetOfStates[shaO, rotNormal] := shaO_Normal;
  BasicSetOfStates[shaO, rotRight]  := shaO_Right;
  BasicSetOfStates[shaO, rotUpDown] := shaO_UpDown;

  BasicSetOfStates[shaZ, rotLeft]   := shaZ_Left;
  BasicSetOfStates[shaZ, rotNormal] := shaZ_Normal;
  BasicSetOfStates[shaZ, rotRight]  := shaZ_Right;
  BasicSetOfStates[shaZ, rotUpDown] := shaZ_UpDown;

  BasicSetOfStates[shaT, rotLeft]   := shaT_Left;
  BasicSetOfStates[shaT, rotNormal] := shaT_Normal;
  BasicSetOfStates[shaT, rotRight]  := shaT_Right;
  BasicSetOfStates[shaT, rotUpDown] := shaT_UpDown;

  BasicSetOfStates[shaS, rotLeft]   := shaS_Left;
  BasicSetOfStates[shaS, rotNormal] := shaS_Normal;
  BasicSetOfStates[shaS, rotRight]  := shaS_Right;
  BasicSetOfStates[shaS, rotUpDown] := shaS_UpDown;

  SetOfStates := BasicSetOfStates;
end;

procedure DefineSetOfColours;
const BasicSetOfColours: TSetOfColours =
(BACKGROUND_RED, BACKGROUND_BLUE, BACKGROUND_GREEN,
 BACKGROUND_RED  or BACKGROUND_GREEN,
 BACKGROUND_BLUE or BACKGROUND_GREEN,
 BACKGROUND_RED  or BACKGROUND_BLUE);

begin
  SetOfColours := BasicSetOfColours;
end;

procedure DefineObstacleMatrix;
var RowCounter, ColumnCounter :byte;
begin
  for RowCounter := 0 to FieldWidth-1 do for ColumnCounter := 0 to FieldLength-1 do
  ObstacleMatrix[ColumnCounter, RowCounter] := 0;
end;

procedure DefineColourMatrix;
var RowCounter, ColumnCounter :byte;
begin
  for RowCounter := 0 to FieldWidth-1 do for ColumnCounter := 0 to FieldLength-1 do
  ColourMatrix[ColumnCounter, RowCounter] := 0;
end;

procedure GameStartingValues;
begin
  FlagWin           := False;
  FlagDefeat        := False;
  FlagCollision     := False;
  FlagTetramino     := False;
  FlagNextTetramino := False;
  FlagLine          := False;
  FlagHoldDown      := False;
  FlagNewObstacle   := False;
  FlagNewNextTetr   := False;
  FlagPause         := False;

  FieldLength   := 10;
  FieldWidth    := 22;
  FrameSpeed    := 2;
  RotateSpeed   := 1;

  TickCount     := 0;
  CurrentScore  := 0;
  LinesCleared  := 0;
  FrameCount    := 0;
  ScoreGoal     := 2000;

  SetLength(ObstacleMatrix, FieldLength, FieldWidth);
  SetLength(ColourMatrix, FieldLength, FieldWidth);
  DefineObstacleMatrix;
  DefineColourMatrix;
  DefineSetOfStates;
  DefineSetOfColours;
end;

procedure CreateTetramino;
begin
  Randomize;
  Rotation        := rotNormal;
  MoveDirection   := dirNone;
  RotateDirection := dirNone;
  Position[1] := 4;
  Position[2] := 2;
  FlagTetramino   := True;
  FlagCollision   := False;
  FlagNewNextTetr := True;

  if not FlagNextTetramino then
  begin
    FlagNextTetramino := True;

    case Random(7) of
      0: NextShape := shaI;
      1: NextShape := shaL;
      2: NextShape := shaJ;
      3: NextShape := shaO;
      4: NextShape := shaZ;
      5: NextShape := shaT;
      6: NextShape := shaS;
    end;

    case Random(7) of
      0: CurrentShape := shaI;
      1: CurrentShape := shaL;
      2: CurrentShape := shaJ;
      3: CurrentShape := shaO;
      4: CurrentShape := shaZ;
      5: CurrentShape := shaT;
      6: CurrentShape := shaS;
    end;

    NextTetraminoColour    := SetOfColours[Random(6)+1];
    CurrentTetraminoColour := SetOfColours[Random(6)+1];

    NextTetramino    := SetOfStates[NextShape, Rotation];
    CurrentTetramino := SetOfStates[CurrentShape, Rotation];
  end
  else
  begin
    CurrentShape           := NextShape;
    CurrentTetramino       := NextTetramino;
    CurrentTetraminoColour := NextTetraminoColour;

    case Random(7) of
    0: NextShape := shaI;
    1: NextShape := shaL;
    2: NextShape := shaJ;
    3: NextShape := shaO;
    4: NextShape := shaZ;
    5: NextShape := shaT;
    6: NextShape := shaS;
    end;

    NextTetraminoColour := SetOfCOlours[Random(6)+1];
    NextTetramino       := SetOfStates[NextShape, Rotation];
  end;
end;

procedure MoveTetramino;
var LostPosition :TTile;
    StateCounter :byte;
begin
  LostPosition := Position;
  case MoveDirection of
    dirLeft:  Dec(Position[1]);
    dirRight: inc(Position[1]);
  end;
  MoveDirection := dirNone;

  for StateCounter := 1 to 4 do
  begin
    if ((CurrentTetramino[StateCounter, 1] + Position[1]) <= -1) or
       ((CurrentTetramino[StateCounter, 1] + Position[1]) >= FieldLength)
    then Position := LostPosition;

    if ObstacleMatrix[CurrentTetramino[StateCounter, 1] + Position[1],
                      CurrentTetramino[StateCounter, 2] + Position[2]] = 1
    then
    begin
      Position := LostPosition;
      FlagCollision := True;
    end;
  end;
end;

procedure MoveTetraminoDown;
var LostPosition :TTile;
    StateCounter :byte;
begin
  LostPosition := Position;
  Inc(Position[2]);

  for StateCounter := 1 to 4 do
  begin
    if ((CurrentTetramino[StateCounter, 2] + Position[2]) >= FieldWidth) or
       (ObstacleMatrix[CurrentTetramino[StateCounter, 1] + Position[1],
                       CurrentTetramino[StateCounter, 2] + Position[2]] = 1)
    then
    begin
      Position := LostPosition;
      FlagCollision := True;
    end;
  end;
end;

procedure RotateTetramino;
var LostRotation :TRotation;
    StateCounter :byte;
begin
  LostRotation := Rotation;
  case RotateDirection of
    dirLeft:
    begin
      if Rotation <> rotLeft then Rotation := Pred(Rotation)
      else Rotation := rotUpDown;
    end;
    dirRight:
    begin
      if Rotation <> rotUpDown then Rotation := Succ(Rotation)
      else Rotation := rotLeft;
    end;
  end;
  RotateDirection := dirNone;

  CurrentTetramino := SetOfStates[CurrentShape, Rotation];

  for StateCounter := 1 to 4 do
  begin
    if ((CurrentTetramino[StateCounter, 1] + Position[1]) <= -1) or
       ((CurrentTetramino[StateCounter, 1] + Position[1]) >= FieldLength) or
       ((CurrentTetramino[StateCounter, 2] + Position[2]) >= FieldWidth)
    then
    begin
      Rotation := LostRotation;
      CurrentTetramino := SetOfStates[CurrentShape, Rotation];
    end;

    if ObstacleMatrix[CurrentTetramino[StateCounter, 1] + Position[1],
                      CurrentTetramino[StateCounter, 2] + Position[2]] = 1
    then
    begin
      Rotation := LostRotation;
      CurrentTetramino := SetOfStates[CurrentShape, Rotation];
      FlagCollision := True;
    end;
  end;
end;

procedure AddTetraminoToMatrix;
var StateCounter :byte;
begin
  FlagTetramino   := False;
  FlagCollision   := False;
  FlagNewObstacle := True;

  for StateCounter := 1 to 4 do
  begin
    ObstacleMatrix[CurrentTetramino[StateCounter, 1] + Position[1],
                   CurrentTetramino[StateCounter, 2] + Position[2]] := 1;
    ColourMatrix[CurrentTetramino[StateCounter, 1] + Position[1],
                 CurrentTetramino[StateCounter, 2] + Position[2]] := CurrentTetraminoColour;
  end;
end;

procedure CheckLine;
var RowCounter, ColumnCounter :byte;
begin
  RowCounter := 0;
  FlagLine := False;
  while (RowCounter <= FieldWidth-1) and not FlagLine do
  begin
    FlagLine := True;
    for ColumnCounter := 0 to FieldLength-1 do
    if ObstacleMatrix[ColumnCounter, RowCounter] = 0 then FlagLine := False;
    Inc(RowCounter);
  end;
end;

procedure DeleteLine;
var RowCounter, RowCounterDelete, ColumnCounter, LineCounter :byte;
    FlagDelete :boolean;
begin
  FlagLine        := False;
  FlagNewObstacle := True;
  LineCounter := 0;

  RowCounter := 0;
  while RowCounter <= FieldWidth-1 do
  begin
    FlagDelete := True;
    for ColumnCounter := 0 to FieldLength-1 do
    if ObstacleMatrix[ColumnCounter, RowCounter] = 0 then FlagDelete := False;

    if FlagDelete then
    begin
      for RowCounterDelete := RowCounter downto 1 do
      for ColumnCounter := 0 to FieldLength-1 do
      begin
        ObstacleMatrix[ColumnCounter, RowCounterDelete] := ObstacleMatrix[ColumnCounter, RowCounterDelete-1];
        ColourMatrix[ColumnCounter, RowCounterDelete]   := ColourMatrix[ColumnCounter, RowCounterDelete-1];
      end;

      Inc(LineCounter);
    end
    else Inc(RowCounter);
  end;

  case LineCounter of
    1: Inc(CurrentScore, 100);
    2: Inc(CurrentScore, 300);
    3: Inc(CurrentScore, 500);
    4: Inc(CurrentScore, 800);
  end;
end;

procedure CheckDefeat;
var RowCounter, ColumnCounter :byte;
begin
  RowCounter := 4;
  for ColumnCounter := 0 to FieldLength-1 do
  if ObstacleMatrix[ColumnCounter, RowCounter] = 1 then FlagDefeat := True;
end;

procedure CheckWin;
begin
  if CurrentScore >= ScoreGoal then FlagWin := True;
end;

procedure GameEndingValues;
begin
  SetLength(ObstacleMatrix, 0, 0);
end;

end.

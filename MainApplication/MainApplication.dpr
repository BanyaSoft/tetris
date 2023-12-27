program MainApplication;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Windows,
  UnitVisualization in '..\UnitVisualization\UnitVisualization.pas',
  UnitInterface     in '..\UnitInterface\UnitInterface.pas',
  UnitGameMechanics in '..\UnitGameMechanics\UnitGameMechanics.pas',
  UnitErrorHandler  in '..\UnitErrorHandler\UnitErrorHandler.pas';

var
  FlagContinue: boolean = True;
  basicInput: string[10];

begin
  writeln('Toggle FullScreen!!!');
  writeln('Press Enter to Run Application.');
  readln;
  while FlagContinue do
  begin
    ClearScreen;

    MenuInterface;
    ClearScreen;

    MainGameInterface;
    ClearScreen;

    GameEndInterface;
    SetOldMode;

    SetCursorPosition(20);
    writeln('Again? [1/0]');
    SetCursorPosition(21);
    readln(BasicInput);

    if BasicInput[1] = '0' then
      FlagContinue := False;
  end;
end.

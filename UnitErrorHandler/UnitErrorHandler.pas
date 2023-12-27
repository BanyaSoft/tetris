unit UnitErrorHandler;

interface

uses
  Windows;

procedure ShowError(ErrorText :string); stdcall;

implementation

procedure ShowError(ErrorText :string);
var CountDown :byte;
    hStdOut :THandle;
    TextAttributes: Cardinal;
    ScreenInfo :CONSOLE_SCREEN_BUFFER_INFO;
var ConsoleSize, NumWritten :LongWord;
    Origin : Coord;
begin
  hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(hStdOut, ScreenInfo);
  ConsoleSize := ScreenInfo.dwSize.X * ScreenInfo.dwSize.Y;
  Origin.X := 0;
  Origin.Y := 0;
  FillConsoleOutputCharacter(hStdOut, ' ', ConsoleSize, Origin, NumWritten);
  SetConsoleCursorPosition(hStdOut, Origin);

  TextAttributes := BACKGROUND_RED;
  SetConsoleTextAttribute(hStdOut, TextAttributes);
  writeln('Error has occured: ', ErrorText);
  writeln('Wait 10 seconds');
  for CountDown := 10 downto 1 do
  begin
    writeln(CountDown);
    sleep(1000);
  end;
  FreeConsole;
end;

end.

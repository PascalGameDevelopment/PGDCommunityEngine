(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CELog.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE logger)
The unit contains main logger interface and several default appenders

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CELog;

interface

uses
  CEBaseTypes;

type
  // Log level prefix string type
  TCELogPrefix = string;
  // Log level class
  TCELogLevel = (llVerbose, llDebug, llInfo, llWarning, llError, llFatalError);
  // Tag used to filter log messages on subsystem basis
  TCELogTag = AnsiString;

type
  // Method pointer which formats
  TCELogFormatDelegate = function(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel): string of object;

  // Log appender metaclass
  CCEAppender = class of TCEAppender;
  // Abstract log appender
  TCEAppender = class(TObject)
  public
    // Format pattern for log timestamp. If empty no timestamps will be appended.
    TimeFormat: string;
    { Default appender constructor.
      Creates the appender of the specified log levels, initializes TimeFormat and Formatter to default values
      and registers the new appender in log system. }
    constructor Create(Level: TCELogLevel);
  protected
    // Should be overridden to actually append log
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel); virtual; abstract;
  private
    FFormatter: TCELogFormatDelegate;
    FLogLevel: TCELogLevel;
    function GetPreparedStr(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel): string;
    procedure SetLevel(Level: TCELogLevel);
  public
    // Set of levels which to include in the log
    property LogLevel: TCELogLevel read FLogLevel write SetLevel;
    // String formatter delegate. It's recommended for descendant classes to use it.
    property Formatter: TCELogFormatDelegate read FFormatter write FFormatter;
  end;
    
    // Filters by tag and calls all registered appenders to log the string with source location information
  procedure Log(const Tag: TCELogTag; const Str: string; const CodeLoc: TCodeLocation; Level: TCELogLevel); overload;
    // Calls all registered appenders to log the string with default log level
  procedure Log(const Str: string); overload;
    // Calls all registered appenders to log the verbose message
  procedure Verbose(const Str: string); overload;
    // Calls all registered appenders to log the debug message
  procedure Debug(const Str: string); overload;
    // Calls all registered appenders to log the info
  procedure Info(const Str: string); overload;
    // Calls all registered appenders to log the warning
  procedure Warning(const Str: string); overload;
    // Calls all registered appenders to log the error
  procedure Error(const Str: string); overload;
    // Calls all registered appenders to log the fatal error
  procedure Fatal(const Str: string); overload;
    // Calls all registered appenders to log the string with default log level
  procedure Log(const Tag: TCELogTag; const Str: string); overload;
    // Calls all registered appenders to log the verbose message
  procedure Verbose(const Tag: TCELogTag; const Str: string); overload;
    // Calls all registered appenders to log the debug message
  procedure Debug(const Tag: TCELogTag; const Str: string); overload;
    // Calls all registered appenders to log the info
  procedure Info(const Tag: TCELogTag; const Str: string); overload;
    // Calls all registered appenders to log the warning
  procedure Warning(const Tag: TCELogTag; const Str: string); overload;
    // Calls all registered appenders to log the error
  procedure Error(const Tag: TCELogTag; const Str: string); overload;
    // Calls all registered appenders to log the fatal error
  procedure Fatal(const Tag: TCELogTag; const Str: string); overload;

  // Prints to log the specified stack trace which can be obtained by some of BaseDebug unit routines
  procedure LogStackTrace(const StackTrace: TBaseStackTrace);

  { A special function-argument. Should be called ONLY as Assert() argument.
    Allows to log source file name and line number at calling location.
    Doesn't require any debug information to be included in binary module.
    The only requirement is inclusion of assertions code.
    Tested in Delphi 7+ and FPC 2.4.2+.

    Suggested usage:

    Assert(_Log(lkInfo), 'Log message');

    This call will log the message with source filename and Line number
    Always returns False. }
  function _Log(Level: TCELogLevel): Boolean; overload;
  function _Log(): Boolean; overload;

  // Adds an appender to list of registered appenders. All registered appenders will be destroyed on shutdown.
  procedure AddAppender(Appender: TCEAppender);
  // Removes an appender from list of registered appenders. Doesn't destroy the appender.
  procedure RemoveAppender(Appender: TCEAppender);
  // Returns a registered appender of the specified class
  function FindAppender(AppenderClass: CCEAppender): TCEAppender;

  { Initializes default appenders:
    TConsoleAppender if current application is a console application
    TWinDebugAppender for Delphi applications running under debugger in Windows OS
  }
  procedure AddDefaultAppenders();

  // Removes all appenders added by AddDefaultAppenders() if any
  procedure RemoveDefaultAppenders();

type
  // Appends log messages to a system console. Application should be a console application.
  TCESysConsoleAppender = class(TCEAppender)
  protected
    // Prints the log string to a system console
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel); override;
  end;

  // Use OutputsDebugString() for loging. Works only in Windows.
  TCEWinDebugAppender = class(TCEAppender)
  protected
    // Prints the log string with OutputsDebugString()
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel); override;
  end;

  // Appends log messages to a file.
  TCEFileAppender = class(TCEAppender)
  public
    // Creates the appender with the specified file name and log levels
    constructor Create(const Filename: string; ALevel: TCELogLevel);
  protected
    // Appends file with the log string
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel); override;
  private
    LogFile: Text;
  end;


implementation

uses
  {$IFDEF MULTITHREADLOG}
    CEConcurrent,
    {$IFDEF UNIX}
    {$ENDIF}
  {$ENDIF}
  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    {$IFDEF NAMESPACED_UNITS} Winapi.Windows, {$ELSE} Windows, {$ENDIF}
  {$ENDIF}{$ENDIF}
  SysUtils;

const
  // Default level prefixes
  Prefix: array[TCELogLevel] of string = (' (v)    ', ' (d)    ', ' (i)  ', '(WW)  ', '(EE)  ', '(!!)  ');

{ TAppender }

constructor TCEAppender.Create(Level: TCELogLevel);
begin
  TimeFormat := 'dd"/"mm"/"yyyy hh":"nn":"ss"."zzz  ';
  LogLevel  := Level;
  FFormatter := GetPreparedStr;
  AddAppender(Self);
  Log('Appender of class ' + ClassName + ' initialized');
end;

function TCEAppender.GetPreparedStr(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel): string;
begin
  Result := FormatDateTime(TimeFormat, Now()) + Prefix[Level] + Str;
  if (CodeLoc <> nil) then
    Result := Concat(Result, ' --- ', CodeLocToStr(CodeLoc^));
end;

procedure TCEAppender.SetLevel(Level: TCELogLevel);
begin
  FLogLevel := Level;
end;

{ Logger }

var
  FAppenders: array of TCEAppender;
  {$IFDEF MULTITHREADLOG}
    Mutex: TCEMutex;
  {$ENDIF}
//  LogLevelCount: array[TLogLevel] of Integer;

procedure Lock();
begin
  {$IFDEF MULTITHREADLOG}
    MutexEnter(Mutex);
  {$ENDIF}
end;

procedure UnLock();
begin
  {$IFDEF MULTITHREADLOG}
    MutexLeave(Mutex);
  {$ENDIF}
end;

const EmptyCodeLoc: TCodeLocation = (Address: nil; SourceFilename: ''; UnitName: ''; ProcedureName: ''; LineNumber: -1);

procedure Log(const Tag: TCELogTag; const Str: string; const CodeLoc: TCodeLocation; Level: TCELogLevel); overload;
{$IFDEF LOGGING} var i: Integer; Time: TDateTime; SrcLocPtr: PCodeLocation; {$ENDIF}
begin
  {$IFDEF LOGGING}
  Lock();

  if CodeLoc.LineNumber = -1 then
    SrcLocPtr := nil
  else
    SrcLocPtr := @CodeLoc;

  Time := Now;

  for i := 0 to High(FAppenders) do
    if Level >= FAppenders[i].LogLevel then
      FAppenders[i].AppendLog(Time, Str, SrcLocPtr, Level);

  UnLock();

//  Inc(LogLevelCount[Level]);
  {$ENDIF}
end;

procedure Log(const Str: string);
begin
  Log('', Str, EmptyCodeLoc, llInfo);
end;

procedure Log(const Tag: TCELogTag; const Str: string); overload;
begin
  Log(Tag, Str, EmptyCodeLoc, llInfo);
end;

procedure Verbose(const Str: string);
begin
  {$IFDEF LOGGING} Log('', Str, EmptyCodeLoc, llVerbose); {$ENDIF}
end;

procedure Verbose(const Tag: TCELogTag; const Str: string); overload;
begin
  {$IFDEF LOGGING} Log(Tag, Str, EmptyCodeLoc, llVerbose); {$ENDIF}
end;

procedure Debug(const Str: string);
begin
  {$IFDEF LOGGING} Log('', Str, EmptyCodeLoc, llDebug); {$ENDIF}
end;

procedure Debug(const Tag: TCELogTag; const Str: string); overload;
begin
  {$IFDEF LOGGING} Log(Tag, Str, EmptyCodeLoc, llDebug); {$ENDIF}
end;

procedure Info(const Str: string);
begin
  {$IFDEF LOGGING} Log('', Str, EmptyCodeLoc, llInfo); {$ENDIF}
end;

procedure Info(const Tag: TCELogTag; const Str: string); overload;
begin
  {$IFDEF LOGGING} Log(Tag, Str, EmptyCodeLoc, llInfo); {$ENDIF}
end;

procedure Warning(const Str: string);
begin
  {$IFDEF LOGGING} Log('', Str, EmptyCodeLoc, llWarning); {$ENDIF}
end;

procedure Warning(const Tag: TCELogTag; const Str: string); overload;
begin
  {$IFDEF LOGGING} Log(Tag, Str, EmptyCodeLoc, llWarning); {$ENDIF}
end;

procedure Error(const Str: string);
begin
  {$IFDEF LOGGING} Log('', Str, EmptyCodeLoc, llError); {$ENDIF}
end;

procedure Error(const Tag: TCELogTag; const Str: string); overload;
begin
  {$IFDEF LOGGING} Log(Tag, Str, EmptyCodeLoc, llError); {$ENDIF}
end;

procedure Fatal(const Str: string);
begin
  {$IFDEF LOGGING} Log('', Str, EmptyCodeLoc, llFatalError); {$ENDIF}
end;

procedure Fatal(const Tag: TCELogTag; const Str: string); overload;
begin
  {$IFDEF LOGGING} Log(Tag, Str, EmptyCodeLoc, llFatalError); {$ENDIF}
end;

procedure LogStackTrace(const StackTrace: TBaseStackTrace);
var i: Integer;
begin
  for i := 0 to High(StackTrace) do
    Log(' --- ' + IntToStr(i) + '. ' + CodeLocToStr(StackTrace[i]));
end;

var
  AssertLogLevel: TCELogLevel;

{$IFDEF FPC}
  procedure LogAssert(const Message, Filename: ShortString; LineNumber: LongInt; ErrorAddr: Pointer);
{$ELSE}
  procedure LogAssert(const Message, Filename: string; LineNumber: Integer; ErrorAddr: Pointer);
{$ENDIF}
var CodeLocation: TCodeLocation;
begin
  AssertRestore();

  CodeLocation := GetCodeLoc(Filename, '', '', LineNumber, ErrorAddr);

  Log('', Message, CodeLocation, AssertLogLevel);
end;

function _Log(Level: TCELogLevel): Boolean; overload;
begin
  if AssertHook(@LogAssert) then begin
    AssertLogLevel := Level;
    Result := False;
  end else
    Result := True;  // Prevent assertion error if hook failed
end;

function _Log(): Boolean; overload;
begin
  Result := _Log(LLInfo);
end;

// Returns index of the appender or -1 if not found
function IndexOfAppender(Appender: TCEAppender): Integer;
begin
  Result := High(FAppenders);
  while (Result >= 0) and (FAppenders[Result] <> Appender) do Dec(Result);
end;

procedure AddAppender(Appender: TCEAppender);
begin
  if not Assigned(Appender) then Exit;
  if IndexOfAppender(Appender) >= 0 then begin
    Warning('CELog', 'Duplicate appender of class "' + Appender.ClassName + '"');
    Exit;
  end;
  Lock();
  try
    SetLength(FAppenders, Length(FAppenders)+1);
    // Set default formatter
    if @Appender.Formatter = nil then
      Appender.Formatter := Appender.GetPreparedStr;
    FAppenders[High(FAppenders)] := Appender;
  finally
    Unlock();
  end;
end;

procedure RemoveAppender(Appender: TCEAppender);
var i: Integer;
begin
  i := IndexOfAppender(Appender);
  // if found, replace it with last and resize array
  if i >= 0 then begin
    Lock();
    try
      FAppenders[i] := FAppenders[High(FAppenders)];
      SetLength(FAppenders, Length(FAppenders)-1);
    finally
      Unlock();
    end;
  end;
end;

function FindAppender(AppenderClass: CCEAppender): TCEAppender;
var i: Integer;
begin
  i := High(FAppenders);
  while (i >= 0) and (FAppenders[i].ClassType <> AppenderClass) do Dec(i);

  if i >= 0 then
    Result := FAppenders[i]
  else
    Result := nil;
end;

{$WARN SYMBOL_PLATFORM OFF}
procedure AddDefaultAppenders();
begin
  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    if DebugHook > 0 then
      TCEWinDebugAppender.Create(llVerbose);
  {$ENDIF}{$ENDIF}

  if IsConsole then begin
    if Length(FAppenders) = 0 then
      TCESysConsoleAppender.Create(llVerbose)
    else
      TCESysConsoleAppender.Create(llWarning)
  end;
end;

procedure RemoveDefaultAppenders();
begin
  if IsConsole then
    RemoveAppender(FindAppender(TCESysConsoleAppender));

  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    if DebugHook > 0 then
      RemoveAppender(FindAppender(TCEWinDebugAppender));
  {$ENDIF}{$ENDIF}
end;

procedure DestroyAppenders();
var i: Integer;
begin
  Lock();
  try
    for i := 0 to High(FAppenders) do begin
      FAppenders[i].Free;
    end;
    SetLength(FAppenders, 0);
  finally
    Unlock();
  end;
end;

{ TConsoleAppender }

procedure TCESysConsoleAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel);
begin
  if IsConsole then
  begin
    Writeln(Formatter(Time, Str, CodeLoc, Level));
    Flush(Output);
  end;
end;

{ TWinDebugAppender }

procedure TCEWinDebugAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel);
begin
  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    if DebugHook > 0 then
      {$IFDEF UNICODE}
        OutputDebugString(PWideChar(Formatter(Time, Str, CodeLoc, Level)));
      {$ELSE}
        OutputDebugStringA(PAnsiChar(Formatter(Time, Str, CodeLoc, Level)));
      {$ENDIF}
  {$ENDIF}{$ENDIF}
end;

{ TFileAppender }

constructor TCEFileAppender.Create(const Filename: string; ALevel: TCELogLevel);
begin
  if (Pos(':', Filename) > 0) or (Pos('/', Filename) = 1) then
    AssignFile(LogFile, Filename)
  else
    AssignFile(LogFile, ExtractFilePath(ParamStr(0)) + Filename);

  {$I-}
  Rewrite(LogFile);
  CloseFile(LogFile);
  //if IOResult <> 0 then LogLevels := [];

  inherited Create(ALevel);
end;

procedure TCEFileAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel);
begin
  {$I-}
  Append(LogFile);
  if IOResult <> 0 then Exit;
  WriteLn(LogFile, Formatter(Time, Str, CodeLoc, Level));
  Flush(LogFile);
  CloseFile(LogFile);
end;

initialization
  {$IFDEF MULTITHREADLOG}
    MutexCreate(Mutex);
  {$ENDIF}
//  FillChar(LogLevelCount, SizeOf(LogLevelCount), 0);
  AddDefaultAppenders();
finalization
  Info('Log session shutdown');
{  Log('Logged fatal errors: ' + IntToStr(LogLevelCount[lkFatalError])
    + ', errors: ' + IntToStr(LogLevelCount[lkError])
    + ', warnings: ' + IntToStr(LogLevelCount[lkWarning])
    + ', titles: ' + IntToStr(LogLevelCount[lkNotice])
    + ', infos: ' + IntToStr(LogLevelCount[lkInfo])
    + ', debug info: ' + IntToStr(LogLevelCount[lkDebug]) );}
  DestroyAppenders();
  {$IFDEF MULTITHREADLOG}
    MutexDelete(Mutex)
  {$ENDIF}
end.


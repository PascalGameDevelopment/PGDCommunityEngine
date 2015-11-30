(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEAndroidLog.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Android logger)
The unit contains log appender for Android platform

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEAndroidLog;

interface

uses
  CELog, CEBaseTypes;

const
  libname = 'liblog.so';

  ANDROID_LOG_UNKNOWN = 0;
  ANDROID_LOG_DEFAULT = 1;
  ANDROID_LOG_VERBOSE = 2;
  ANDROID_LOG_DEBUG = 3;
  ANDROID_LOG_INFO = 4;
  ANDROID_LOG_WARN = 5;
  ANDROID_LOG_ERROR = 6;
  ANDROID_LOG_FATAL = 7;
  ANDROID_LOG_SILENT = 8;

  AndroidLogLevels: array[TCELogLevel] of Integer =
    (ANDROID_LOG_VERBOSE, ANDROID_LOG_DEBUG, ANDROID_LOG_INFO, ANDROID_LOG_WARN, ANDROID_LOG_ERROR, ANDROID_LOG_FATAL);

type
  // Log appender which works with Android system logger viewable by Logcat utility
  TCELogcatAppender = class(TCEAppender)
  protected
    // Prints the log string to a system console
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel); override;
  end;

  function __android_log_write(prio: longint; tag, text: PAnsiChar): longint; cdecl; external libname name '__android_log_write';

implementation

{ TCELogcatAppender }

procedure TCELogcatAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TCELogLevel);
begin
  __android_log_write(AndroidLogLevels[Level], '', PAnsiChar(Formatter(Time, Str, CodeLoc, Level)));
end;

begin
  // Remove default appenders as them not work on Android
  CELog.RemoveDefaultAppenders();
  TCELogcatAppender.Create(llVerbose);
end.
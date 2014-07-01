(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CE2D.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Logging)

Simple class with auto-initialize/finalize that allows logging 4 kind of messages
      *  loNormal    no error, just information
	  *  loStatus    for statuses of any kind
	  *  loWarning   for warnings
	  *  loError     if something wrong happens
On start it creates a text file with the name of the application with .log as extension

@author(Pitfiend (pitfiend@gmail.com))
}

unit logger;

interface

uses
  Classes,
  SysUtils;

type
  TLogOperation = (loNormal, loStatus, loWarning, loError);

  TLogger = class
  private
    FFileHandle : TextFile;
    FApplicationName : string;
    FApplicationPath : string;
  public
    constructor Create;
    destructor Destroy; override;
    function GetApplicationName: string;
    function GetApplicationPath: string;
    procedure Log( MessageStr : string; Location : string; Operation: TLogOperation = loNormal );
    property ApplicationName : string read GetApplicationName;
    property ApplicationPath : string read GetApplicationPath;
  end;

var
  Log : TLogger;

implementation

{ TLogger }
constructor TLogger.Create;
var
  FileName : string;
begin
    FApplicationName := ChangeFileExt( ExtractFileName( ParamStr(0) ), '' );
    FApplicationPath := ExtractFilePath( ParamStr(0) );
    FileName := FApplicationPath + FApplicationName + '.log';
    AssignFile( FFileHandle, FileName );
    if FileExists( FileName ) then
        Append( FFileHandle )
    else
        ReWrite( FFileHandle );
end;

destructor TLogger.Destroy;
begin
    Writeln( FFileHandle );
    CloseFile( FFileHandle );
    inherited;
end;

function TLogger.GetApplicationName: string;
begin
    result := FApplicationName;
end;

function TLogger.GetApplicationPath: string;
begin
    result := FApplicationPath;
end;

procedure TLogger.Log(MessageStr, Location: string; Operation: TLogOperation = loNormal );
var
    mstr : string;
begin
    case Operation of
        loNormal:  mstr := '                ';
        loError:   mstr := '***  ERROR  *** ';
        loWarning: mstr := '=== WARNING === ';
        loStatus:  mstr := '--- STATUS  --- ';
    end;
    mstr := TimeToStr(Time) + ' ' + mstr + Location + ' ' + MessageStr;
    WriteLn( FFileHandle,  mstr );
    Flush( FFileHandle );
end;

initialization
begin
    Log := TLogger.Create;
    Log.Log( 'Starting Application', 'Initialization', loStatus );
end;

finalization
begin
    Log.Log( 'Terminating Application', 'Finalization', loStatus );
    Log.Free;
end;

end.

(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOSUtils.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE operating system utilities)

The unit contains operating system specific routines. Platform specific.

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$I PGDCE.inc}
unit CEOSUtils;

interface

{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}
{$IFDEF UNIX}
uses
  unix;
{$ENDIF}

// Obtains mouse cursor position relative to screen and fills X and Y with the position
procedure GetMouseCursorPos(out X, Y: Integer);
// Sets mouse cursor position relative to screen
procedure SetMouseCursorPos(X, Y: Integer);
// Adjust mouse cursor visibility counter. The cursor will be visible if the counter >= 0. Initial value of the counter is zero.
function AdjustMouseCursorVisibility(Show: Boolean): Integer;
// Returns current time in milliseconds (precision is up to 1/20 of second)
function GetCurrentMs(): Int64;
// Returns value of high-frequency counter
function GetPerformanceCounter(): Int64;
// Returns frequency of high-frequency counter
function GetPerformanceFrequency(): Int64;

implementation

var
  PerformanceFrequency: Int64;

function GetPerformanceFrequency(): Int64;
begin
  Result := PerformanceFrequency;
end;

{$IFDEF UNIX}
function GetCurrentMs(): Int64;
var
  tm: TimeVal;
begin
  fpGetTimeOfDay(@tm, nil);
  Result := tm.tv_sec * Int64(1000) + tm.tv_usec div 1000;
end;
{$ENDIF}

{$IFDEF WINDOWS}

function GetCurrentMs: Int64;
begin
  Result := Windows.GetTickCount();
end;

procedure GetMouseCursorPos(out X, Y: Integer);
var
  Pnt: TPoint;
begin
  Windows.GetCursorPos(Pnt);
  X := Pnt.X; Y := Pnt.Y;
end;

procedure SetMouseCursorPos(X, Y: Integer);
begin
  Windows.SetCursorPos(X, Y);
end;

function AdjustMouseCursorVisibility(Show: Boolean): Integer;
begin
  Result := Windows.ShowCursor(Show);
end;

procedure ObtainPerformanceFrequency;
begin
  if not Windows.QueryPerformanceFrequency(PerformanceFrequency) then
    PerformanceFrequency := 0;
end;

function GetPerformanceCounter: Int64;
begin
  Windows.QueryPerformanceCounter(Result);
end;

{$ENDIF}

initialization
  ObtainPerformanceFrequency();
finalization
end.

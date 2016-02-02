(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is BaseTest.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(Base routines tests)

This is test for base units

@author(George Bakhtadze (avagames@gmail.com))
}
program BaseTest;
{$Include PGDCE.inc}

{$APPTYPE CONSOLE}

uses
  SysUtils, CEBaseTypes, CECommon, CEStrUtils, CELog, Tester;

type
  // Base class for all entity classes tests
  TBaseTest = class(TTestSuite)
  private
  published
    {$IFDEF FLOAT_IEEE}
    procedure TestFloatEqual();
    {$ENDIF}
    procedure TestJoinStr();
    procedure TestJoinPath();
    procedure TestInvSqrt();
  end;

{ TBaseTest }

function GetSingle(i: Integer): Single;
begin
  Result := Single((@i)^);
end;

function GetInt32(v: Single): Integer;
begin
  Result := Integer((@v)^);
end;

function GetDouble(i: Int64): Double;
begin
  Result := Double((@i)^);
end;

function GetInt64(v: Double): Int64;
begin
  Result := Int64((@v)^);
end;

{$IFDEF FLOAT_IEEE}
procedure TestSingle(v: Single);
var
  num: Integer;
  f: Single;
begin
  num := GetInt32(v);
  f := GetSingle(num);
  Assert(_Check(FloatEquals(f, GetSingle(num + 1))), Format('TestSingle: %g <> %g', [f, GetSingle(num + 1)]));
  Assert(_Check(FloatEquals(f, GetSingle(num + 2))), Format('TestSingle: %g <> %g', [f, GetSingle(num + 2)]));
  Assert(_Check(not FloatEquals(f, GetSingle(num + MAX_ULPS+1))), Format('TestSingle: %g <> %g', [f, GetSingle(num + MAX_ULPS+1)]));
end;

procedure TestDouble(v: Double);
var
  num: Int64;
  f: Double;
begin
  num := GetInt64(v);
  f := GetDouble(num);
  Assert(_Check(FloatEquals(f, GetDouble(num + 1))), Format('TestDouble: %g <> %g', [f, GetDouble(num + 1)]));
  Assert(_Check(FloatEquals(f, GetDouble(num + 2))), Format('TestDouble: %g <> %g', [f, GetDouble(num + 2)]));
  Assert(_Check(not FloatEquals(f, GetDouble(num + MAX_ULPS+1))), Format('TestDouble: %g <> %g', [f, GetDouble(num + MAX_ULPS+1)]));
end;

procedure TBaseTest.TestFloatEqual;
var
  i: Integer;
begin
  for i := 0 to 10 do
  begin
    TestSingle(1000.5 * i*i);
    TestDouble(1000000.1333 * i*i);
  end;
  Assert(_Check(not FloatEquals(GetSingle(0)-GetSingle(1), GetSingle(0))), '-0 = 0');
end;
{$ENDIF}

procedure TBaseTest.TestJoinStr();
var
  Strs: TAnsiStringArray;
  i: Integer;
  Joined: AnsiString;
begin
  SetLength(Strs, 4);
  for i := 0 to High(Strs) do
    Strs[i] := 'Str #' + IntToStr(i);
  Joined := JoinStrArray(Strs, ', ');
  CELog.Log('Joined: ' + Joined);
  Assert(_Check(Joined = 'Str #0, Str #1, Str #2, Str #3'), 'String join');
  Assert(_Check(JoinStrArray(Strs, '') = 'Str #0Str #1Str #2Str #3'), 'String join w/o separator');
  Strs[0] := '';
  Assert(_Check(JoinStrArray(Strs, ', ') = 'Str #1, Str #2, Str #3'), 'String join with empty');
  Strs[2] := '';
  Assert(_Check(JoinStrArray(Strs, ', ') = 'Str #1, , Str #3'), 'String join with 2 empty');
  Strs[3] := '';
  Assert(_Check(JoinStrArray(Strs, ', ') = 'Str #1, , '), 'String join with 3 empty');
end;

procedure TBaseTest.TestJoinPath();
begin
end;

procedure TBaseTest.TestInvSqrt();
const
  COUNT = 100;
var
  i: Integer;
  x, invx2: Single;

function GetApproximationError(value, approx: Single): Single;
begin
  Result := abs(value - approx) / MaxS(0.0000001, value);
end;

procedure CheckValue(x: Single);
var
  TrueVal: Single;
  CheckVal: Single;
begin
  TrueVal := 1 / Sqrt(x);
  CheckVal := InvSqrt(x);
  Assert(_Check(GetApproximationError(TrueVal, CheckVal) < 0.00175), 'InvSqrt() error too big for value ' + FloatToStr(x));
end;

begin
  for i := 1 to COUNT do
    CheckValue(i * i);
  {$IFDEF FLOAT_IEEE}
  Assert(_Check(GetApproximationError(19817753709685768200.0, InvSqrt(0)) < 0.00175), 'InvSqrt() wrong value for 0');
  {$ENDIF}
end;

begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
   {$IFEND}
  RegisterSuites([TBaseTest]);
  Tester.RunTests();
  Readln;
end.

(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CECore.pas

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
  SysUtils, CEBaseTypes, CECommon, Tester;

type
  // Base class for all entity classes tests
  TBaseTest = class(TTestSuite)
  private
  published
    procedure TestFloatEqual();
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

begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  RegisterSuites([TBaseTest]);
  Tester.RunTests();
  Readln;
end.

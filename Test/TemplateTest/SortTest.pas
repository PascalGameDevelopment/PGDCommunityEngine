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
@abstract(Template sort test)

This is test for template sorting algorithms

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit SortTest;
interface

uses
  Tester, SysUtils, CETemplate;

type
  TIndArray = array of Integer;
  TAnsiStringArray = array of AnsiString;

  // Generic sort algorithm test class
  TTestGenericSort = class(TTestSuite)
  private
    arr, OArr, ind: TIndArray;
    strarr, strarr2: TAnsiStringArray;
    crc32: Integer;
  protected
    procedure InitSuite(); override;
    procedure InitTest(); override;
  public

    procedure PrepareArray;

    procedure testSortStr();

  published
    procedure TestSortAcc();
    procedure TestSortDsc();
    procedure TestSortInd();
  end;

implementation

uses CECommon;

var
  Rnd: TRandomGenerator;

const
  TESTCOUNT = 1024*8*4;//*256;//*1000*10;

procedure SortStr(const Count: Integer; const Data: TAnsiStringArray);
//  const _SortOptions = [soBadData];
  type _SortDataType = AnsiString;
  {$MESSAGE 'Instantiating sort algorithm <AnsiString>'}
  {$I tpl_algo_quicksort.inc}
end;

procedure SortDsc(const Count: Integer; const Data: TIndArray);
  const _SortOptions = [soDescending];
  type _SortDataType = Integer; _SortValueType = Integer;
  function _SortGetValue2(const V: _SortDataType): _SortValueType; {$I inline.inc}
  begin
    Result := V;
  end;
  {.$DEFINE _SORTBADDATA}
  {.$DEFINE _SORTDESCENDING}
  {$MESSAGE 'Instantiating sort algorithm <Integer>'}
  {$I tpl_algo_quicksort.inc}
end;

// Initialize array and fill it with random values
procedure ShuffleArray(data: TIndArray); overload;
var i: Integer;
begin
  Randomize;
  for i := 0 to TESTCOUNT-1 do data[i] := Random(TESTCOUNT);
//  for i := 0 to TESTCOUNT-1 do data[i] := Round(Sin(i/TESTCOUNT*pi*3.234)*TESTCOUNT);
(*  v := TESTCOUNT div 2;
  vi := Random(2)*2-1;
  for i := 0 to TESTCOUNT-1 do begin

    data[i] := v;
    v := v + vi;
    if i mod (TESTCOUNT div 50) = 0 then vi := Random(2)*2-1;

  end;*)
end;

function GetCRC32(data: TIndArray): Integer; overload;
var v, i: Integer;
begin
  Result := 0;
  for i := 0 to High(data) do Result := Result + data[i];
//  for i := 0 to TESTCOUNT-1 do data[i] := Round(Sin(i/TESTCOUNT*pi*3.234)*TESTCOUNT);
(*  v := TESTCOUNT div 2;
  vi := Random(2)*2-1;
  for i := 0 to TESTCOUNT-1 do begin

    data[i] := v;
    v := v + vi;
    if i mod (TESTCOUNT div 50) = 0 then vi := Random(2)*2-1;

  end;*)
end;

// Initialize array and fill it with random values
procedure ShuffleArray(data: TAnsiStringArray); overload;
var i, j: Integer;
begin
  Randomize;
  for i := 0 to TESTCOUNT-1 do begin
    SetLength(data[i], 3 + Random(10));
    for j := 1 to Length(data[i]) do data[i] := AnsiChar(Ord('0') + Random(Ord('z')-Ord('0')));
  end;
end;

// Checks if the array is sorted in ascending order
function isArraySortedAcc(arr: TIndArray; crc32: Integer): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] <= arr[i+1]) do Dec(i);
  Result := (i < 0) and (crc32 = GetCRC32(arr));
end;

// Checks if the indexed array is sorted in ascending order
function isIndArraySortedAcc(arr, oarr, ind: TIndArray; crc32: Integer): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  if arr[i+1] = OArr[i+1] then
    while (i >= 0) and (arr[ind[i]] <= arr[ind[i+1]])
      and (arr[i] = OArr[i]) do Dec(i);
  Result := (i < 0) and (crc32 = GetCRC32(arr));
end;

// Checks if the array is sorted in ascending order
function isArraySortedStr(arr: TAnsiStringArray): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] <= arr[i+1]) do Dec(i);
  Result := i < 0;
end;

// Checks if the array is sorted in descending order
function isArraySortedDsc(arr: TIndArray; crc32: Integer): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] >= arr[i+1]) do Dec(i);
  Result := (i < 0) and (crc32 = GetCRC32(arr));
end;

{ TTestGenericSort }

procedure TTestGenericSort.InitSuite();
var i: Integer;
begin
  if Length(OArr) <> TESTCOUNT then SetLength(OArr, TESTCOUNT);
  ShuffleArray(OArr);
  crc32 := GetCRC32(OArr);
  if Length(ind) <> TESTCOUNT then SetLength(ind, TESTCOUNT);
  for i := 0 to High(ind) do ind[i] := i;
//  if Length(strarr2) <> TESTCOUNT then SetLength(strarr2, TESTCOUNT);
//  ShuffleArray(strarr2);
end;

procedure TTestGenericSort.InitTest;
begin
  PrepareArray();
end;

procedure TTestGenericSort.PrepareArray;
begin
  arr := Copy(OArr, 0, Length(OArr));
  strarr := Copy(strarr2, 0, Length(strarr2));
end;

procedure TTestGenericSort.testSortAcc;

  procedure Sort(const Count: Integer; const Data: TIndArray);
  //  const _SortOptions = [soBadData];
    type _SortDataType = Integer;
    function _SortCompare(const V1, V2: _SortDataType): Integer; {$I inline.inc}
    begin
      Result := (V1 - V2);         // As usual
    end;
    {$MESSAGE 'Instantiating sort algorithm <Integer>'}
    {$I tpl_algo_quicksort.inc}
  end;

begin
  Sort(TESTCOUNT, arr);
  Assert(_Check(isArraySortedAcc(arr, crc32)), GetName + ':Sort failed');
end;

procedure TTestGenericSort.testSortInd;

  procedure Sort(const Count: Integer; var Data: TIndArray; var Index: array of Integer);
  //  const _SortOptions = [soBadData];
    type _SortDataType = Integer;
    {$MESSAGE 'Instantiating sort algorithm <Integer> indexed'}
    {$I tpl_algo_quicksort.inc}
  end;

begin
  Sort(TESTCOUNT, arr, ind);
  Assert(_Check(isIndArraySortedAcc(arr, OArr, ind, crc32)), GetName + ':Sort failed');
end;

procedure TTestGenericSort.testSortStr;
begin
  SortStr(TESTCOUNT, strarr);
  Assert(_Check(isArraySortedStr(strarr)), GetName + ':Sort failed');
end;

procedure TTestGenericSort.testSortDsc;
begin
  SortDsc(TESTCOUNT, arr);
  Assert(_Check(isArraySortedDsc(arr, crc32)), GetName + ':Sort failed');
end;

initialization
  Rnd := TRandomGenerator.Create();
  RegisterSuites([TTestGenericSort]);

finalization
  Rnd.Free();
end.


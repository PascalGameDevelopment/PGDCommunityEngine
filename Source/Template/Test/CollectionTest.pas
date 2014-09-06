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
@abstract(Template collections test)

This is test for template collections

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CollectionTest;

interface

uses
  SysUtils, CETemplate, CECommon, Tester;

type
  _HashMapKeyType = Integer;
  _HashMapValueType = AnsiString;
  {$MESSAGE 'Instantiating TIntStrHashMap interface'}
  {$I tpl_coll_hashmap.inc}
  TIntStrHashMap = class(_GenHashMap) end;
  TIntStrHashMapKeyIterator = object(_GenHashMapKeyIterator) end;

  TKeyArray = array of _HashMapKeyType;

  _VectorValueType = Integer;
  {$MESSAGE 'Instantiating TIntVector interface'}
  {$I tpl_coll_vector.inc}
  TIntVector = _GenVector;

  // Base class for all template classes tests
  TTestTemplates = class(TTestSuite)
  end;

  TTestCollections = class(TTestTemplates)
  protected
    function ForCollEl(const e: Integer; Data: Pointer): Boolean;
  end;

  TTestHash = class(TTestCollections)
  private
    procedure ForPair(const Key: Integer; const Value: String; Data: Pointer);
  published
    procedure TestHashMap();
  end;

  TTestVector = class(TTestCollections)
  private
    procedure TestList(Coll: TIntVector);
  published
    procedure TestVector();
  end;

implementation

  const _HashMapOptions = [];
  {$MESSAGE 'Instantiating TIntStrHashMap'}
  {$I tpl_coll_hashmap.inc}

  const _VectorOptions = [];
  {$MESSAGE 'Instantiating TIntVector'}
  {$I tpl_coll_vector.inc}

var
  Rnd: TRandomGenerator;

const
  TESTCOUNT = 1024*8*4;//*256;//*1000*10;
  HashMapElCnt = 500;//1024*8;
  CollElCnt = 1024*8;

{ TTestCollections }

function TTestCollections.ForCollEl(const e: Integer; Data: Pointer): Boolean;
begin
  Assert(_Check(e = Rnd.RndI(CollElCnt)), 'Value check in for each fail');
  Result := True;
end;

{ TTestHash }

procedure TTestHash.ForPair(const Key: Integer; const Value: String; Data: Pointer);
begin
//  Writeln(Key, ' = ', Value);
  Assert(_Check((Key) = StrToInt(Value)), 'Value check in for each fail');
end;

procedure TTestHash.TestHashMap;
var
  i: Integer;
  cnt, t: NativeInt;
  Map: TIntStrHashMap;
  Iter: _GenHashMapKeyIterator;
begin
  Map := TIntStrHashMap.Create(1);

  cnt := 0;
  for i := 0 to HashMapElCnt-1 do
  begin
    t := Random(HashMapElCnt);

    if not Map.ContainsKey(t) then Inc(cnt);

    Map[t] := IntToStr(t);
    Assert(_Check(Map.ContainsKey(t) and Map.ContainsValue(IntToStr(t))));
  end;

  Map.ForEach(ForPair, nil);

  Assert(_Check(Map.Count = cnt));

  Iter := Map.GetKeyIterator();

//  Log('Iterator count: ' + IntToStr(Map.Count));

  for i := 0 to Map.Count-1 do
  begin
    Assert(_Check(Iter.HasNext), 'iterator HasNext() failed');
    t := Iter.Next;
    Assert(_Check(Map.ContainsKey(t)), 'iterator value not found');
    //Log('Iterator next: ' + IntToStr(t));
  end;

  Assert(_Check(not Iter.HasNext), 'iterator HasNext() false positive');

  Map.Clear;
  Assert(_Check(Map.IsEmpty));

  Map[t] := IntToStr(t);
  Assert(_Check(Map.ContainsKey(t) and Map.ContainsValue(IntToStr(t))));

  Map.Free;
end;

{ TTestVector }

procedure TTestVector.TestList(Coll: TIntVector);
var
  i, cnt, t: Integer;
begin
  cnt := 0;
  Rnd.InitSequence(1, 0);
  for i := 0 to CollElCnt-1 do
  begin
    t := Rnd.RndI(CollElCnt);
    Coll.Add(t);
    Inc(cnt);
    Assert(_Check(Coll.Contains(t)), GetName + ': Conntains failed');
  end;

  Rnd.InitSequence(1, 0);
  Coll.ForEach(ForCollEl, nil);

  for i := 0 to CollElCnt div 2-1 do
  begin
    t := Rnd.RndI(CollElCnt);
    while Coll.Remove(t) do Dec(cnt);
    Assert(_Check(not Coll.Contains(t)), GetName + ': Not conntains failed');
  end;

  for i := 0 to CollElCnt div 2-1 do
  begin
    t := Rnd.RndI(Coll.Count);
    Coll.Put(i, CollElCnt);
    Assert(_Check(Coll.Get(i) = CollElCnt), GetName + ': Put/Get failed');
    Coll.Insert(t, CollElCnt+1);
    Assert(_Check((Coll.Get(t) = CollElCnt+1) and Coll.Contains(CollElCnt+1)),
           GetName + ': Conntains inserted failed');
    Coll.RemoveBy(t);
    Assert(_Check(not Coll.Contains(CollElCnt+1)), GetName + ': Not conntains removed failed');
  end;

  Assert(_Check(Coll.Count = cnt), GetName + ': Count failed');

  Coll.Clear;
  Assert(_Check(Coll.IsEmpty), GetName + ': IsEmpty failed');
  Coll.Free;
end;

procedure TTestVector.TestVector;
var Coll: TIntVector;
begin
  Coll := TIntVector.Create();
  TestList(Coll);
end;

initialization
  Rnd := TRandomGenerator.Create();
  RegisterSuites([TTestCollections, TTestHash, TTestVector]);
finalization  
  Rnd.Free();
end.

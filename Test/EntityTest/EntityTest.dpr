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
program EntityTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, CEBaseTypes, CEEntity, CECommon, CEProperty, CEIO, Tester;

type
  TTestEnum = (tteOpt1, tteOpt2, tteOpt3);
  TTestRange = 0..31;
  TTestSet = set of TTestRange;

  TTestEntity = class(TCEBaseEntity)
  private
    FBoolProp: Boolean;
    FEnumProp: TTestEnum;
    FSetProp: TTestSet;
    FDoubleProp: Double;
    FInt64Prop: Int64;
    FIntProp: Integer;
    FSingleProp: Single;
    FAnsiStringProp: AnsiString;
    FStringProp: UnicodeString;
    FShortStringProp: ShortString;
    FUTF8Str: UTF8String;
    FUnicodeStr: UnicodeString;
    FWStr: WideString;
    FBinary: TDynamicArray;
    FPointerProp: TPointerData;
  public
    function GetProperties(): TCEProperties; override;
    procedure SetProperties(const Properties: TCEProperties); override;
  published
    property BoolProp: Boolean read FBoolProp write FBoolProp;
    property EnumProp: TTestEnum read FEnumProp write FEnumProp;
    property SetProp: TTestSet read FSetProp write FSetProp;
    property DoubleProp: Double read FDoubleProp write FDoubleProp;
    property Int64Prop: Int64 read FInt64Prop write FInt64Prop;
    property IntProp: Integer read FIntProp write FIntProp;
    property SingleProp: Single read FSingleProp write FSingleProp;
    property AnsiStringProp: AnsiString read FAnsiStringProp write FAnsiStringProp;
    property StringProp: UnicodeString read FStringProp write FStringProp;
    property ShortStringProp: ShortString read FShortStringProp write FShortStringProp;
    property UTF8Str: UTF8String read FUTF8Str write FUTF8Str;
    property WStr: WideString read FWStr write FWStr;
    property UnicodeStr: UnicodeString read FUnicodeStr write FUnicodeStr;
    property Binary: TDynamicArray read FBinary write FBinary;
    property PointerProp: TPointerData read FPointerProp write FPointerProp;
  end;

  TEntity1 = class(TCEBaseEntity)
  private
    fInt: Integer;
    fStr: string;
  published
    property Int: Integer read fInt write fInt;
    property Str: string read fStr write fStr;
  end;

  TEntity2 = class(TCEBaseEntity)
  private
    fDbl: Double;
    fBigInt: Int64;
  published
    property Dbl: Double read fDbl write fDbl;
    property BigInt: Int64 read fBigInt write fBigInt;
  end;

  // Base class for all entity classes tests
  TEntityTest = class(TTestSuite)
  private
  published
    procedure TestPropsGetSet();
    procedure TestWriteRead();
    procedure TestSaveLoad;
  end;

const
  TEST_DATA: array[0..10] of Byte = (10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);

function BinaryDataEqual(p1, p2: Pointer; size1, Size2: Integer): Boolean;
begin
  Result := False;
  if size1 <> size2 then Exit;
  Result := CompareMem(p1, p2, size1);
end;

function CreateTestEntity(): TTestEntity;
var
  i: Integer;
begin
  Result := TTestEntity.Create();
  Result.BoolProp := True;
  Result.EnumProp := tteOpt2;
  Result.SetProp := [5, 8, 3, 17];
  Result.DoubleProp := 287.54;
  Result.Int64Prop := Int64($FFFFFFFF) + Int64(1000000);
  Result.IntProp := 10;
  Result.SingleProp := 11.8;
  Result.AnsiStringProp := 'Ansi string!';
  Result.StringProp := 'Default стринг!';
  Result.ShortStringProp := 'Short string!';
  Result.UTF8Str := 'UTF8 стринг!';
  Result.WStr := 'Wide стринг!';
  Result.UnicodeStr := 'Unicode стринг!';

  Result.Binary := TDynamicArray.Create();
  SetLength(Result.Binary.Data, Length(TEST_DATA));
  for i := 0 to High(Result.Binary.Data) do Result.Binary.Data[i] := TEST_DATA[i];

  Result.PointerProp := TPointerData.Create();
  Result.PointerProp.Allocate(SizeOf(TEST_DATA));
  Move(TEST_DATA, Result.PointerProp.Data^, SizeOf(TEST_DATA));
end;

procedure CheckEqual(e1, e2: TTestEntity; const Lbl: string);
begin
  WriteLn('String: ' + e1.StringProp + ' = ' + e2.StringProp);
  WriteLn('UString: ' + e1.UnicodeStr + ' = ' + e2.UnicodeStr);
  WriteLn('WString: ' + e1.WStr + ' = ' + e2.WStr);
  WriteLn('UTF8String: ' + e1.UTF8Str + ' = ' + e2.UTF8Str);

  Assert(_Check(e1.FIntProp = e2.FIntProp),       Lbl + 'Int fail');
  Assert(_Check(e1.FSingleProp = e2.FSingleProp), Lbl + 'Single fail');

  Assert(_Check(e1.FBoolProp = e2.FBoolProp),     Lbl + 'Bool fail');
  Assert(_Check(e1.FEnumProp = e2.FEnumProp),     Lbl + 'Enum fail');

  Assert(_Check(e1.FSetProp = e2.FSetProp),       Lbl + 'Set fail');
  Assert(_Check(e1.FDoubleProp = e2.FDoubleProp), Lbl + 'Double fail');
  Assert(_Check(e1.FInt64Prop = e2.FInt64Prop),   Lbl + 'Int64 fail');

  Assert(_Check(e1.FAnsiStringProp = e2.FAnsiStringProp),   Lbl + 'Ansi fail');
  Assert(_Check(e1.FStringProp = e2.FStringProp),           Lbl + 'String fail');
  Assert(_Check(e1.FShortStringProp = e2.FShortStringProp), Lbl + 'Short fail');
  Assert(_Check(e1.FUTF8Str = e2.FUTF8Str),                 Lbl + 'UTF8 fail');
  Assert(_Check(e1.FWStr = e2.FWStr),                       Lbl + 'Wide fail');
  Assert(_Check(e1.FUnicodeStr = e2.FUnicodeStr),           Lbl + 'Unicode fail');

  Assert(_Check(BinaryDataEqual(@e1.Binary.Data[0], @e2.Binary.Data[0], Length(e1.Binary.Data), Length(e2.Binary.Data))), Lbl + 'DynArray fail');
  Assert(_Check(BinaryDataEqual(e1.PointerProp.Data, e2.PointerProp.Data, e1.PointerProp.Size, e2.PointerProp.Size)), Lbl + 'Pointer fail');
end;

{ TestEntity }

function TTestEntity.GetProperties(): TCEProperties;
begin
  Result := inherited GetProperties();
end;

procedure TTestEntity.SetProperties(const Properties: TCEProperties);
begin
  inherited SetProperties(Properties);
end;

{ TEntityTest }

procedure TEntityTest.TestPropsGetSet;
var
  e1, e2: TTestEntity;
  Props: TCEProperties;
begin
  e1 := CreateTestEntity();
  e2 := TTestEntity.Create();

  Props := e1.GetProperties();
  e2.SetProperties(Props);
  Props.Free();

  CheckEqual(e1, e2, 'Get/Set ');

  e1.Free();
  e2.Free();
end;

procedure TEntityTest.TestWriteRead;
var
  e1, e2: TTestEntity;
  Props1, Props2: TCEProperties;
  outs: TCEFileOutputStream;
  ins: TCEFileInputStream;
  Filer: TCEPropertyFilerBase;
begin
  e1 := CreateTestEntity();
  e2 := TTestEntity.Create();
  Filer := TCESimplePropertyFiler.Create;

  Props1 := e1.GetProperties();
  outs := TCEFileOutputStream.Create('props.p');
  Filer.Write(outs, Props1);
  Props1.Free();
  outs.Free();

  ins := TCEFileInputStream.Create('props.p');
  Props2 := e2.GetProperties();
  Filer.Read(ins, Props2);
  ins.Free();

  Filer.Free();
  e2.SetProperties(Props2);

  Props2.Free();

  CheckEqual(e1, e2, 'Read/Write ');

  e1.Free();
  e2.Free();
end;

procedure TEntityTest.TestSaveLoad;
var
  Parent: TEntity1;
  Child: TEntity2;
  Manager: TCEEntityManager;
  Filer: TCESimpleEntityFiler;
  outs: TCEFileOutputStream;
  ins: TCEFileInputStream;
  Loaded: TCEBaseEntity;
begin
  Parent := TEntity1.Create();
  Parent.Int := 1000;
  Parent.Str := 'parent.Str';
  Parent.Name := 'Parent';
  Child := TEntity2.Create();
  Child.Dbl := 0.800;
  Child.BigInt := 1000000000000;
  Child.Name := 'Child';
  Parent.AddChild(Child);

  Manager := TCEEntityManager.Create();
  Manager.RegisterEntityClasses([TEntity1, TEntity2]);

  Filer := TCESimpleEntityFiler.Create(Manager);
  outs := TCEFileOutputStream.Create('entity.pce');
  Filer.WriteEntity(outs, Parent);
  outs.Free();

  ins := TCEFileInputStream.Create('entity.pce');
  Loaded := Filer.ReadEntity(ins);
  ins.Free();

  Filer.Free();

  Writeln('Full name: ' + Loaded.Childs[0].GetFullName());

  Assert(_Check(Loaded is TEntity1), 'Load fail');
  Assert(_Check(Loaded.Childs.Count = 1), 'Childs fail');
  Assert(_Check(Loaded.Childs[0].Parent = Loaded), 'Parent fail');
  Assert(_Check(((Loaded as TEntity1).Int = Parent.Int) and ((Loaded as TEntity1).Str = Parent.Str)), 'Props1 fail');
  Assert(_Check(((Loaded.Childs[0] as TEntity2).Dbl = Child.Dbl) and ((Loaded.Childs[0] as TEntity2).fBigInt = Child.BigInt)), 'Props2 fail');

  Manager.Root := Parent;
  Assert(_Check(Manager.Find('/Parent/Child') = Child), 'Find fail');

  Loaded.Free();
  Parent.Free();
  Manager.Free();
end;

begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  RegisterSuites([TEntityTest]);
  Tester.RunTests();
  Readln;
end.

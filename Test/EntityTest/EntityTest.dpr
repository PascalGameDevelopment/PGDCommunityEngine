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
program EntityTest;
{$IFDEF FPC}{$codepage CP1251}{$ENDIF}
{$Include PGDCE.inc}

{$APPTYPE CONSOLE}

uses
  SysUtils, CEBaseTypes, CEEntity, CECommon, CEProperty, CEIO, Tester, CEResource, CEImageResource;

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
    fInt: TCEFormat;
    fStr: string;
  published
    property Int: TCEFormat read fInt write fInt;
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

  TLinkingEntity = class(TCEBaseEntity)
  private
    FLinked: TEntity2;
    function GetLinked: TEntity2;
  published
    property Linked: TEntity2 read GetLinked write FLinked;
  end;

  // Base class for all entity classes tests
  TEntityTest = class(TTestSuite)
  private
  published
    procedure TestPropsGetSet();
    procedure TestWriteRead();
    procedure TestSaveLoad();
    procedure TestBackBuffer();
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
  WriteLn('String: ' + UTF8Encode(e1.StringProp) + ' = ' + UTF8Encode(e2.StringProp));
  WriteLn('UString: ' + UTF8Encode(e1.UnicodeStr) + ' = ' + UTF8Encode(e2.UnicodeStr));
  WriteLn('WString: ' + UTF8Encode(e1.WStr) + ' = ' + UTF8Encode(e2.WStr));
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
  with CreateRefcountedContainer() do
  begin
    e1 := CreateTestEntity();
    Managed.AddObject(e1);
    e2 := TTestEntity.Create();
    Managed.AddObject(e2);

    Props := e1.GetProperties();
    Managed.AddObject(Props);
    e2.SetProperties(Props);

    CheckEqual(e1, e2, 'Get/Set ');
  end;
end;

procedure TEntityTest.TestWriteRead;
var
  e1, e2: TTestEntity;
  Props1, Props2: TCEProperties;
  outs: TCEFileOutputStream;
  ins: TCEFileInputStream;
  Filer: TCEPropertyFilerBase;
begin
  with CreateRefcountedContainer() do
  begin
    e1 := CreateTestEntity();
    Managed.AddObject(e1);
    e2 := TTestEntity.Create();
    Managed.AddObject(e2);
    Filer := TCESimplePropertyFiler.Create;
    Managed.AddObject(Filer);

    Props1 := e1.GetProperties();
    Managed.AddObject(Props1);

    outs := TCEFileOutputStream.Create('props.p');
    Managed.AddObject(outs);
    Filer.Write(outs, Props1);
    outs.Close();

    ins := TCEFileInputStream.Create('props.p');
    Managed.AddObject(ins);
    Props2 := e2.GetProperties();
    Managed.AddObject(Props2);
    Filer.Read(ins, Props2);

    e2.SetProperties(Props2);

    CheckEqual(e1, e2, 'Read/Write ');
  end;
end;

procedure TEntityTest.TestSaveLoad;
var
  Parent: TEntity1;
  Child: TEntity2;
  Linking: TLinkingEntity;
  Manager, Manager2: TCEEntityManager;
  Filer, Filer2: TCESimpleEntityFiler;
  outs: TCEFileOutputStream;
  ins: TCEFileInputStream;
  Loaded: TCEBaseEntity;
  TextRes: TCETextResource;
  Entity: TCEBaseEntity;
begin
  with CreateRefcountedContainer() do
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

    Linking := TLinkingEntity.Create();
    Linking.Name := 'Linking';
    Linking.Linked := Child;
    Parent.AddChild(Linking);

    TextRes := TCETextResource.Create();
    TextRes.Name := 'Text resource';
    TextRes.Text := 'Text resource data';
    Parent.AddChild(TextRes);

    Manager := TCEEntityManager.Create();
    Managed.AddObject(Manager);
    Manager.RegisterEntityClasses([TEntity1, TEntity2, TLinkingEntity, TCETextResource]);

    Manager.Root := Parent;
    Assert(_Check(Manager.Find('/Parent/Child') = Child), 'Find fail');

    Filer := TCESimpleEntityFiler.Create(Manager);
    Managed.AddObject(Filer);
    outs := TCEFileOutputStream.Create('entity.pce');
    Managed.AddObject(outs);
    Assert(_Check(Filer.WriteEntity(outs, Parent)), 'Write fail');

    outs.Close();

    Manager2 := TCEEntityManager.Create();
    Managed.AddObject(Manager2);
    Manager2.RegisterEntityClasses([TEntity1, TEntity2, TLinkingEntity, TCETextResource]);
    Filer2 := TCESimpleEntityFiler.Create(Manager2);
    Managed.AddObject(Filer2);

    ins := TCEFileInputStream.Create('entity.pce');
    Managed.AddObject(ins);
    Loaded := Filer2.ReadEntity(ins);

    Manager2.Root := Loaded;

    Writeln('Full name: ' + Loaded.Childs[0].GetFullName());

    Assert(_Check(Loaded is TEntity1), 'Load fail');
    Assert(_Check(Loaded.Childs.Count = 3), 'Childs fail');
    Assert(_Check(Loaded.Childs[0].Parent = Loaded), 'Parent fail');
    Assert(_Check(((Loaded as TEntity1).Int = Parent.Int) and ((Loaded as TEntity1).Str = Parent.Str)), 'Props1 fail');
    Assert(_Check(((Loaded.Childs[0] as TEntity2).Dbl = Child.Dbl) and ((Loaded.Childs[0] as TEntity2).fBigInt = Child.BigInt)), 'Props2 fail');

    Assert(_Check(Manager2.Find('/Parent/Child') = TLinkingEntity(Manager2.Find('/Parent/Linking')).Linked), 'Link fail');

    Entity := Manager2.Find('/Parent/Text resource');
    Assert(_Check(Entity is TCETextResource), 'Type check fail');
    Assert(_Check(TCETextResource(Entity).Text = 'Text resource data'), 'Text resource fail');
  end;
end;

procedure TEntityTest.TestBackBuffer;
var
  BB: TCEBackBuffer;
  i1: Integer;
  d1: Double;
  i2: Int64;
  r1: record
    f1, f2: Single;
    i: int64;
  end;
begin
  BB := TCEBackBuffer.Create(4, 4+8+8+SizeOf(r1));
  i1 := 100;
  BB.WriteProperty(@i1, SizeOf(i1), i1);
  d1 := 100.01;
  BB.WriteProperty(@d1, SizeOf(d1), d1);
  i2 := 1000;
  BB.WriteProperty(@i2, SizeOf(i2), i2);
  r1.f1 := 1.0;
  r1.f2 := -200.0003;
  BB.WriteProperty(@r1, SizeOf(r1), r1);

  BB.WriteProperty(@i1, SizeOf(i1), i1);
  BB.WriteProperty(@d1, SizeOf(d1), d1);
  i1 := 0;
  d1 := 0;
  i2 := 0;
  r1.f1 := 0;
  r1.f2 := 0;

  BB.Flush();
  BB.Free();
  Assert(_Check(i1 = 100),                Format('BackBuffer: i1: expected 100,    actual: %d', [i1]));
  Assert(_Check(FloatEquals(d1, 100.01)), Format('BackBuffer: d1: expected 100.01, actual: %g', [d1]));
  Assert(_Check(i2 = 1000),               Format('BackBuffer: i2: expected 1000,   actual: %d', [i2]));
  Assert(_Check(FloatEquals(r1.f1, 1.0) and FloatEquals(r1.f2, -200.0003)), Format('BackBuffer: r1: expected (1.0, -200.0003), actual: (%g, %g)', [r1.f1, r1.f2]));
end;

{ TLinkingEntity }

function TLinkingEntity.GetLinked: TEntity2;
begin
  if not Assigned(FLinked) then
    FLinked := ResolveObjectLink('Linked') as TEntity2;
  Result := FLinked;
end;

begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  RegisterSuites([TEntityTest]);
  Tester.RunTests();
  Readln;
end.

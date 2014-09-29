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
  TTestEntity = class(TCEBaseEntity)
  private
    FIntProp: Integer;
    FSingleProp: Single;
    FAnsiStringProp: AnsiString;
    FStringProp: UnicodeString;
    FShortStringProp: ShortString;
    FUTF8Str: UTF8String;
    FUnicodeStr: UnicodeString;
    FWStr: WideString;
  public
    function GetProperties(): TCEProperties; override;
    procedure SetProperties(const Properties: TCEProperties); override;
  published
    property IntProp: Integer read FIntProp write FIntProp;
    property SingleProp: Single read FSingleProp write FSingleProp;
    property AnsiStringProp: AnsiString read FAnsiStringProp write FAnsiStringProp;
    property StringProp: UnicodeString read FStringProp write FStringProp;
    property ShortStringProp: ShortString read FShortStringProp write FShortStringProp;
    property UTF8Str: UTF8String read FUTF8Str write FUTF8Str;
    property WStr: WideString read FWStr write FWStr;
    property UnicodeStr: UnicodeString read FUnicodeStr write FUnicodeStr;
  end;

  // Base class for all entity classes tests
  TEntityTest = class(TTestSuite)
  published
    procedure TestPropsGetSet();
    procedure TestWriteRead();
  end;

function CreateTestEntity(): TTestEntity;
begin
  Result := TTestEntity.Create();
  Result.IntProp := 10;
  Result.SingleProp := 11.8;
  Result.AnsiStringProp := 'Ansi string!';
  Result.StringProp := 'Default стринг!';
  Result.ShortStringProp := 'Short string!';
  Result.FUTF8Str := 'UTF8 стринг!';
  Result.WStr := 'Wide стринг!';
  Result.UnicodeStr := 'Unicode стринг!';
end;

procedure CheckEqual(e1, e2: TTestEntity; const  Lbl: string);
begin
  Assert(_Check(e1.FIntProp = e2.FIntProp) and (e1.FSingleProp = e2.FSingleProp)), Lbl + 'Get/Set fail');

  Assert(_Check(e1.FAnsiStringProp = e2.FAnsiStringProp),     Lbl + 'Ansi fail');
  Assert(_Check(e1.FStringProp = e2.FStringProp),             Lbl + 'String fail');
  Assert(_Check(e1.FShortStringProp = e2.FShortStringProp),   Lbl + 'Short fail');
  Assert(_Check(e1.FUTF8Str = e2.FUTF8Str),                   Lbl + 'UTF8 fail');
  Assert(_Check(e1.FWStr = e2.FWStr),                         Lbl + 'Wide fail');
  Assert(_Check(e1.FUnicodeStr = e2.FUnicodeStr),             Lbl + 'Unicode fail');
end;

{ TestEntity }

function TTestEntity.GetProperties(): TCEProperties;
begin
  Result := inherited GetProperties();
{  Result := TCEProperties.Create();
  Result.AddInt('IntProp', IntProp);
  Result.AddSingle('SingleProp', SingleProp);
  Result.AddAnsiString('AnsiStringProp', AnsiStringProp);
  Result.AddString('StringProp', StringProp);}
end;

procedure TTestEntity.SetProperties(const Properties: TCEProperties);
begin
//  inherited SetProperties(Properties);
{  IntProp := Properties['IntProp']^.AsInteger;
  SingleProp := Properties['SingleProp']^.AsSingle;
  AnsiStringProp := Properties['AnsiStringProp']^.AsAnsiString;
  StringProp := Properties['StringProp']^.AsUnicodeString;
  ShortStringProp := Properties['ShortStringProp']^.AsShortString;
  UTF8Str := Properties['UTF8Str']^.AsUnicodeString;
  WStr := Properties['WStr']^.AsUnicodeString;
  UnicodeStr := Properties['UnicodeStr']^.AsUnicodeString;}
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
  outs := TCEFileOutputStream.Create('0test.p');
  Filer.Write(outs, Props1);
  Props1.Free();
  outs.Free();

  ins := TCEFileInputStream.Create('0test.p');
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

begin
  RegisterSuites([TEntityTest]);
  Tester.RunTests();
  Readln;
end.

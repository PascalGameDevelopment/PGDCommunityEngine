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
  public
    function GetProperties(): TCEProperties; override;
    procedure SetProperties(const Properties: TCEProperties); override;
  published
    property IntProp: Integer read FIntProp write FIntProp;
    property SingleProp: Single read FSingleProp write FSingleProp;
    property AnsiStringProp: AnsiString read FAnsiStringProp write FAnsiStringProp;
    property StringProp: UnicodeString read FStringProp write FStringProp;
    property ShortStringProp: ShortString read FShortStringProp write FShortStringProp;
  end;

  // Base class for all entity classes tests
  TEntityTest = class(TTestSuite)
  published
    procedure TestPropsGetSet();
    procedure TestWriteRead();
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
  IntProp := Properties['IntProp']^.AsInteger;
  SingleProp := Properties['SingleProp']^.AsSingle;
  AnsiStringProp := Properties['AnsiStringProp']^.AsAnsiString;
  StringProp := Properties['StringProp']^.AsUnicodeString;
  ShortStringProp := Properties['ShortStringProp']^.AsShortString;
end;

{ TEntityTest }

procedure TEntityTest.TestPropsGetSet;
var
  e1, e2: TTestEntity;
  Props: TCEProperties;
begin
  e1 := TTestEntity.Create();
  e1.IntProp := 10;
  e1.SingleProp := 11.8;
  e1.AnsiStringProp := 'Ansi string!';
  e1.StringProp := '”никодный string!';
  e1.ShortStringProp := 'Short string!';
  e2 := TTestEntity.Create();

  Props := e1.GetProperties();
  e2.SetProperties(Props);
  Props.Free();
  Assert(_Check((e1.FIntProp = e2.FIntProp) and (e1.FSingleProp = e2.FSingleProp)), GetName + ': Get/Set fail');
  Assert(_Check((e1.FAnsiStringProp = e2.FAnsiStringProp) and (e1.FStringProp = e2.FStringProp) and (e1.FShortStringProp = e2.FShortStringProp)), GetName + ': Get/Set string fail');
end;

procedure TEntityTest.TestWriteRead;
var
  e1, e2: TTestEntity;
  Props1, Props2: TCEProperties;
  outs: TCEFileOutputStream;
  ins: TCEFileInputStream;
  Filer: TCEPropertyFilerBase;
begin
  e1 := TTestEntity.Create();
  e1.IntProp := 20;
  e1.SingleProp := 21.8;
  e1.AnsiStringProp := 'Ansi string!';
  e1.StringProp := '”никодный string!';
  e1.ShortStringProp := 'Short string!';
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
  Assert(_Check((e1.FIntProp = e2.FIntProp) and (e1.FSingleProp = e2.FSingleProp)), GetName + ': Read/Write fail');
  Assert(_Check((e1.FAnsiStringProp = e2.FAnsiStringProp) and (e1.FStringProp = e2.FStringProp)), GetName + ': Get/Set string fail');
end;

begin
  RegisterSuites([TEntityTest]);
  Tester.RunTests();
  Readln;
end.

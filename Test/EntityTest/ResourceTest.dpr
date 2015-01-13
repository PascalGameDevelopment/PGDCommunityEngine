(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is ResourceTest.dpr

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2015 of these individuals.

******************************************************************************)

{
@abstract(Resources related tests)

This is a test suite for resource entities and mechanisms

@author(George Bakhtadze (avagames@gmail.com))
}
{$Include PGDCE.inc}
program ResourceTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, Tester, CEBaseTypes, CEEntity, CECommon, CEProperty, CEIO, CEResource, CEImageResource, CEDataLoader, CEDataDecoder;

type
  TBaseLoader = class(TCEDataLoader)
  protected
    function DoGetInputStream(const AURL: string): TCEInputStream; override;
  public
    function GetResourceModificationTime(const AURL: string): TDateTime; override;
  end;

  TLoader1 = class(TBaseLoader)
  protected
    procedure Init; override;
  end;

  TDecoder1 = class(TCEDataDecoder)
  protected
    function DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity; const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean; override;
    procedure Init; override;
  end;

  TDecoder2 = class(TCEDataDecoder)
  protected
    function DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity; const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean; override;
    procedure Init; override;
  end;

  TTest = class(TTestSuite)
  private
  published
    procedure TestLoaders();
    procedure TestDecoders();
  end;

const
  TEST_URL: array[0..4] of string = ('c:\file.txt', '/home/file.bmp', 'file://path/to/file.snd', 'protocol1://some/data', 'proto2://some/data.unk');
  LOADER_CLASS: array[0..4] of TClass = (TCELocalFileLoader, TCELocalFileLoader, TCELocalFileLoader, TLoader1, TLoader1);
  DECODER_CLASS: array[0..4] of TClass = (TDecoder1, TDecoder1, TDecoder2, TDecoder2, nil);

{ TBaseLoader }

function TBaseLoader.DoGetInputStream(const AURL: string): TCEInputStream;
begin
  Result := nil;
end;

function TBaseLoader.GetResourceModificationTime(const AURL: string): TDateTime;
begin
  Result := 0;
end;

{ TLoader1 }

procedure TLoader1.Init;
begin
  SetLength(FProtocols, 2);
  FProtocols[0] := 'protocol1';
  FProtocols[1] := 'proto2';
end;

function GetClass(Obj: TObject): TClass;
begin
  Result := nil;
  if Assigned(Obj) then Result := Obj.ClassType;
end;

function GetClassName(Obj: TObject): string;
begin
  Result := '<none>';
  if Assigned(Obj) then Result := Obj.ClassName;
end;

{ TTest }

procedure TTest.TestLoaders;
var
  i: Integer;
  Ldr: TCEDataLoader;
begin
  RegisterDataLoader(TLoader1.Create());
  for i := 0 to High(TEST_URL) do begin
    Ldr := GetDataLoader(CEIO.GetProtocolFromUrl(TEST_URL[i]));
    Assert(_Check(Assigned(Ldr)), 'No loader found for URL: ' + TEST_URL[i]);
    Assert(_Check(Ldr.ClassType = LOADER_CLASS[i]), 'Wrong loader class for URL: ' + TEST_URL[i]);
    Writeln('Loader for URL ', TEST_URL[i], ': ', Ldr.ClassName)
  end;
end;

procedure TTest.TestDecoders;
var
  i: Integer;
  Dcd: TCEDataDecoder;
begin
  RegisterDataDecoder(TDecoder1.Create());
  RegisterDataDecoder(TDecoder2.Create());
  for i := 0 to High(TEST_URL) do begin
    Dcd := GetDataDecoder(CEIO.GetDataTypeIDFromUrl(TEST_URL[i]));
    Assert(_Check(not Assigned(DECODER_CLASS[i]) or Assigned(Dcd)), 'No decoder found for URL: ' + TEST_URL[i]);
    Assert(_Check(GetClass(Dcd) = DECODER_CLASS[i]), 'Wrong decoder class for URL: ' + TEST_URL[i] +
        '. Expected: ' + DECODER_CLASS[i].ClassName + ', actual: ' + GetClassName(Dcd));
  end;
end;

{ TDecoder1 }

function TDecoder1.DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity; const Target: TCELoadTarget; MetadataOnly: Boolean): Boolean;
begin
  Result := False;
end;

procedure TDecoder1.Init;
begin
  SetLength(FLoadingTypes, 2);
  FLoadingTypes[0] := GetSignature(UpperCase('.txt'));
  FLoadingTypes[1] := GetSignature(UpperCase('.bmp'));
end;

{ TDecoder2 }

function TDecoder2.DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity; const Target: TCELoadTarget; MetadataOnly: Boolean): Boolean;
begin
  Result := False;
end;

procedure TDecoder2.Init;
begin
  SetLength(FLoadingTypes, 2);
  FLoadingTypes[0] := GetSignature(UpperCase('.snd'));
  FLoadingTypes[1] := GetSignature(UpperCase('.   '));
end;

begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  RegisterSuites([TTest]);
  Tester.RunTests();
  Readln;
end.

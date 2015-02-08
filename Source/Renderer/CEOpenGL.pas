(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOpenGL.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE OpenGL common classes and utilities)

The unit contains OpenGL related classes and utilities which will be used in more specific renderers

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$Include PGDCE.inc}
unit CEOpenGL;

interface

uses
  CEBaseTypes, CEEntity, CEBaseRenderer, CEMesh, CEMaterial,
  CETemplate, CELog, CEIO, CEDataDecoder;

type
  TGLSLIdentKind = (gliAttribute, gliUniform, gliVarying, gliSampler);

  TCEGLSLShader = class
  private
    procedure AddIdent(Kind: TCEShaderIdentKind; const Name: TCEShaderSource; const TypeName: TCEShaderSource);
    function Parse(const src: TCEShaderSource): Integer;
  protected
  public
    VertexShader, FragmentShader, ShaderProgram: Integer;
    Idents: array[TGLSLIdentKind] of PCEShaderIdentList;
    Capacities, Counts: array[TGLSLIdentKind] of Integer;
    constructor Create();
    destructor Destroy(); override;
    procedure SetVertexShader(ShaderId: Integer; const Source: TCEShaderSource);
    procedure SetFragmentShader(ShaderId: Integer; const Source: TCEShaderSource);
  end;

  TCEDataDecoderGLSL = class(TCEDataDecoder)
  protected
    function DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity; const Target: TCELoadTarget;
                      MetadataOnly: Boolean): Boolean; override;
    procedure Init; override;
  end;

  _VectorValueType = TCEGLSLShader;
  {$MESSAGE 'Instantiating TGLSLShaderList interface'}
  {$I tpl_coll_vector.inc}
  // GLSL shader list
  TGLSLShaderList = _GenVector;

implementation

uses
  SysUtils, CECommon, CEStrUtils, CEResource;

const
  SAMPLER_PREFIX = 'SAMPLER';
  GROW_STEP = 1;

{$MESSAGE 'Instantiating TGLSLShaderList'}
{$I tpl_coll_vector.inc}

function GetIdentKind(const word: TCEShaderSource): TCEShaderIdentKind;
begin
  if word = 'UNIFORM' then
    Result := ikUNIFORM
  else if word = 'ATTRIBUTE' then
    Result := ikATTRIBUTE
  else if word = 'VARYING' then
    Result := ikVARYING
  else
    Result := ikINVALID;
end;

function isPrecision(const word: TCEShaderSource): Boolean;
begin
  Result := (word = 'LOWP') or (word = 'MEDIUMP') or (word = 'HIGHP');
end;

procedure TCEGLSLShader.AddIdent(Kind: TCEShaderIdentKind; const Name: TCEShaderSource; const TypeName: TCEShaderSource);
var
  glKind: TGLSLIdentKind;
begin
  case Kind of
    ikUNIFORM:
      if StartsWith(UpperCase(TypeName), SAMPLER_PREFIX) then
        glKind := gliSampler
      else
        glKind := gliUniform;
    ikATTRIBUTE: glKind := gliAttribute;
    ikVARYING: glKind := gliVarying;
    else
      raise ECEInvalidArgument.Create('Invalid shader ident kind');
  end;
  if Capacities[glKind] <= Counts[glKind] then
  begin
    Inc(Capacities[glKind], GROW_STEP);
    ReallocMem(Idents[glKind], Capacities[glKind] * SizeOf(TCEShaderIdent));
    Initialize(Idents[glKind]^[Capacities[glKind] - GROW_STEP], Capacities[glKind]);
  end;
  Idents[glKind]^[Counts[glKind]].Kind    := Kind;
  Idents[glKind]^[Counts[glKind]].TypeStr := TypeName;
  Idents[glKind]^[Counts[glKind]].Name    := Name;
  Inc(Counts[glKind]);
end;

function TCEGLSLShader.Parse(const src: TCEShaderSource): Integer;
var
  i, j, LineCount, wc: Integer;
  Lines, Words: TStringArray;
  Kind: TCEShaderIdentKind;
begin
  Kind := ikINVALID;
  Result := 0;
  LineCount := Split(src, ';', Lines, False);
  for i := 0 to LineCount-1 do
  begin
    wc := Split(Lines[i], ' ', Words, False);
    j := 0;
    while j < wc-2 do
    begin
      Kind := GetIdentKind(UpperCase(Trim(Words[j])));
      if Kind <> ikINVALID then
        Break;
      Inc(j);
    end;
    if j < wc-2 then
    begin
      if isPrecision(UpperCase(Trim(Words[j+1]))) then
      begin
        Inc(j);
      end;
      if j < wc-2 then
      begin
        AddIdent(Kind, Trim(Words[j+2]), Trim(Words[j+1]));
        Inc(Result);
      end;
    end;
  end;
end;

constructor TCEGLSLShader.Create;
begin
  VertexShader   := ID_NOT_INITIALIZED;
  FragmentShader := ID_NOT_INITIALIZED;
  ShaderProgram  := ID_NOT_INITIALIZED;
end;

destructor TCEGLSLShader.Destroy;
var
  i: TGLSLIdentKind;
begin
  for i := Low(TGLSLIdentKind) to High(TGLSLIdentKind) do
    if Counts[i] > 0 then begin
      Finalize(Idents[i]^[0], Capacities[i]);
      FreeMem(Idents[i]);
    end;
  inherited;
end;

procedure TCEGLSLShader.SetVertexShader(ShaderId: Integer; const Source: TCEShaderSource);
begin
  if VertexShader <> ID_NOT_INITIALIZED then Exit;
  VertexShader := ShaderId;
  Parse(Source);
end;

procedure TCEGLSLShader.SetFragmentShader(ShaderId: Integer; const Source: TCEShaderSource);
begin
  if FragmentShader <> ID_NOT_INITIALIZED then Exit;
  FragmentShader := ShaderId;
  Parse(Source);
end;

{ TCEDataDecoderGLSL }

function TCEDataDecoderGLSL.DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity; const Target: TCELoadTarget;
  MetadataOnly: Boolean): Boolean;
const
  BufSize = 1024;
var
  Buf: array[0..BufSize-1] of AnsiChar;
  Len: Integer;
  Res: TCETextResource;
  Str: UnicodeString;
begin
  Result := False;
  if not Assigned(Entity) then
    Entity := TCETextResource.Create();
  if not (Entity is TCETextResource) then
    raise ECEInvalidArgument.Create('Entity must be TCETextResource descendant');

  Res := TCETextResource(Entity);
  Res.Text := '';
  Len := Stream.Read(Buf, BufSize);
  while Len > 0 do
  begin
    if Res.Text = '' then
      Res.SetBuffer(PAnsiChar(@Buf[0]), Len)
    else begin
      SetString(Str, PAnsiChar(@Buf[0]), Len div SizeOf(Buf[0]));
      Res.Text := Res.Text + Str;
    end;
    Len := Stream.Read(Buf, BufSize);
  end;
end;

procedure TCEDataDecoderGLSL.Init;
begin
  SetLength(FLoadingTypes, 1);
  FLoadingTypes[0] := GetDataTypeFromExt('glsl');
end;

initialization
  CEDataDecoder.RegisterDataDecoder(TCEDataDecoderGLSL.Create());
end.

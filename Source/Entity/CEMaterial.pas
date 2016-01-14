(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEMaterial.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE render material unit)

The unit contains render material related classes and routines

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEMaterial;

interface

uses
  CEEntity, CEResource, CEImageResource;

const
  MAX_TEXTURES = 32;
  // Special value indicating that the ID is not initialized
  ID_NOT_INITIALIZED = -1;

type
  TTextureSetup = record
    // Private to renderer
    TextureId: Integer;
  end;
  TTextureSetups = array[0..MAX_TEXTURES - 1] of TTextureSetup;

  // Encapsulates render state, texture and shader settings
  TCERenderPass = class(TCEBaseEntity)
  private
    // Shader program ID used by a renderer
    ProgramId: Integer;
    TextureSetups, _TextureSetups: TTextureSetups;
    FTexture0: TCEImageResource;
    FVertexShader: TCETextResource;
    FFragmentShader: TCETextResource;
    FAlphaBlending: Boolean;

    function GetTexture0: TCEImageResource;
    procedure SetTexture0(const Value: TCEImageResource);
  protected
    procedure DoInit(); override;
  published
    property Texture0: TCEImageResource read GetTexture0 write SetTexture0;
    property VertexShader: TCETextResource read FVertexShader write FVertexShader;
    property FragmentShader: TCETextResource read FFragmentShader write FFragmentShader;
    property AlphaBlending: Boolean read FAlphaBlending write FAlphaBlending;
  end;

  // Set of render passes, represents render technique
  TCERenderTechnique = class(TCEBaseEntity)
  private
    FTotalPasses: Integer;
    PassesCache: array of TCERenderPass;
    FValid: Boolean;
    procedure SetTotalPasses(const Value: Integer);
    function GetPass(Index: Integer): TCERenderPass;
    procedure SetPass(Index: Integer; const Value: TCERenderPass);
  public
    LOD: Single;
    property TotalPasses: Integer read FTotalPasses write SetTotalPasses;
    property Pass[Index: Integer]: TCERenderPass read GetPass write SetPass; default;
    property Valid: Boolean read FValid write FValid;
  end;

  // Set of techniques
  TCEMaterial = class(TCEBaseEntity)
  private
    FTotalTechniques: Integer;
    procedure SetTotalTechniques(const Value: Integer);
    function GetTechnique(Index: Integer): TCERenderTechnique;
    procedure SetTechnique(Index: Integer; const Value: TCERenderTechnique);
  public
    function GetTechniqueByLOD(Lod: Single): TCERenderTechnique;
    property TotalTechniques: Integer read FTotalTechniques write SetTotalTechniques;
    property Technique[Index: Integer]: TCERenderTechnique read GetTechnique write SetTechnique; default;
  end;

  // Creates a render pass with the specified settings
  function CreateRenderPass(EntityManager: TCEEntityManager; AlphaBlend: Boolean;
                            const TextureUrl: string; const VSUrl: string; const PSUrl: string): TCERenderPass;
  // Destroys resources associated with render pass such as texture and shaders
  procedure DestroyRenderPassResources(Pass: TCERenderPass);
  function _GetTextureId(Pass: TCERenderPass; Index: Integer): Integer;
  procedure _SetTextureId(Pass: TCERenderPass; Index: Integer; Id: Integer);
  function _GetProgramId(Pass: TCERenderPass): Integer;
  procedure _SetProgramId(Pass: TCERenderPass; Id: Integer);

implementation

uses
  CEBaseTypes;

function CreateRenderPass(EntityManager: TCEEntityManager; AlphaBlend: Boolean;
                          const TextureUrl: string; const VSUrl: string; const PSUrl: string): TCERenderPass;
var
  Image: TCEImageResource;
begin
  Result := TCERenderPass.Create(EntityManager);
  if TextureUrl <> '' then
  begin
    Image := TCEImageResource.CreateFromUrl(TextureUrl);
    Result.Texture0 := Image;
  end;
  if VSUrl <> '' then
    Result.VertexShader := TCETextResource.CreateFromUrl(VSUrl);
  if PSUrl <> '' then
    Result.FragmentShader := TCETextResource.CreateFromUrl(PSUrl);
  Result.AlphaBlending := AlphaBlend;
end;

procedure DestroyRenderPassResources(Pass: TCERenderPass);
begin
  if not Assigned(Pass) then Exit;
  Pass.VertexShader.Free();
  Pass.FragmentShader.Free();
  Pass.Texture0.Free();
end;

function _GetTextureId(Pass: TCERenderPass; Index: Integer): Integer;
begin
  Result := Pass.TextureSetups[Index].TextureId;
end;

procedure _SetTextureId(Pass: TCERenderPass; Index: Integer; Id: Integer);
begin
  Pass.TextureSetups[Index].TextureId := Id;
end;

function _GetProgramId(Pass: TCERenderPass): Integer;
begin
  Result := Pass.ProgramId;
end;

procedure _SetProgramId(Pass: TCERenderPass; Id: Integer);
begin
  Pass.ProgramId := Id;
end;

function TCERenderPass.GetTexture0: TCEImageResource;
begin
  if not Assigned(FTexture0) then
    FTexture0 := ResolveObjectLink('Texture0') as TCEImageResource;
  Result := FTexture0;
end;

procedure TCERenderPass.SetTexture0(const Value: TCEImageResource);
begin
  FTexture0 := Value;
end;

procedure TCERenderPass.DoInit();
var
  i: Integer;
begin
  ProgramId := ID_NOT_INITIALIZED;
  for i := 0 to MAX_TEXTURES - 1 do
    TextureSetups[i].TextureId := ID_NOT_INITIALIZED;
end;

{ TCERenderTechnique }

function PassPropertyName(Index: Integer): string;
begin
  Result := 'Pass ' + IntToStr(Index);
end;

procedure TCERenderTechnique.SetTotalPasses(const Value: Integer);
begin
  FTotalPasses := Value;
  SetLength(PassesCache, FTotalPasses);
end;

function TCERenderTechnique.GetPass(Index: Integer): TCERenderPass;
begin
  Assert(Index < TotalPasses);
  Assert(Length(PassesCache) = TotalPasses, ClassName() + '("' + string(GetFullName()) + '")');
  if Assigned(PassesCache[Index]) then
    Result := PassesCache[Index]
  else begin
    PassesCache[Index] := ResolveObjectLink(PassPropertyName(Index)) as TCERenderPass;
    Result := PassesCache[Index]
  end;
end;

procedure TCERenderTechnique.SetPass(Index: Integer; const Value: TCERenderPass);
begin
  if Assigned(Value) then
    SetObjectLink(PassPropertyName(Index), Value.GetFullName)
  else
    SetObjectLink(PassPropertyName(Index), '')
end;

{ TCEMaterial }

function TechPropertyName(Index: Integer): string;
begin
  Result := 'Tech ' + IntToStr(Index);
end;

procedure TCEMaterial.SetTotalTechniques(const Value: Integer);
begin
  FTotalTechniques := Value;
end;

function TCEMaterial.GetTechnique(Index: Integer): TCERenderTechnique;
begin
  Result := ResolveObjectLink(TechPropertyName(Index)) as TCERenderTechnique;
end;

procedure TCEMaterial.SetTechnique(Index: Integer; const Value: TCERenderTechnique);
begin
  if Assigned(Value) then
    SetObjectLink(TechPropertyName(Index), Value.GetFullName)
  else
    SetObjectLink(TechPropertyName(Index), '');
end;

function TCEMaterial.GetTechniqueByLOD(Lod: Single): TCERenderTechnique;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (i < TotalTechniques) and
        ( {not (isVisible in Technique[i].State) or }not Technique[i].Valid or (Technique[i].LOD > Lod) ) do Inc(i);
  if i < TotalTechniques then Result := Technique[i];
end;

end.

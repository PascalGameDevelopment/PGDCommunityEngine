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
  CEBaseTypes, CEEntity, CEImageResource;

const
  MAX_TEXTURES = 32;

type

  TTextureSetup = record
    // Private to renderer
    TextureId: Integer;
  end;
  TTextureSetups = array[0..MAX_TEXTURES-1] of TTextureSetup;

  // Representing render pass setup
  TCERenderPass = class(TCEBaseEntity)
  private
    TextureSetups, _TextureSetups: TTextureSetups;
    FTexture0: TCEImageResource;
    function GetTexture0: TCEImageResource;
    procedure SetTexture0(const Value: TCEImageResource);
  public
  published
    constructor Create();
    property Texture0: TCEImageResource read GetTexture0 write SetTexture0;
  end;

  function _GetTextureId(Pass: TCERenderPass; Index: Integer): Integer;
  procedure _SetTextureId(Pass: TCERenderPass; Index: Integer; Id: Integer);

implementation

function _GetTextureId(Pass: TCERenderPass; Index: Integer): Integer;
begin
  Result := Pass.TextureSetups[Index].TextureId;
end;

procedure _SetTextureId(Pass: TCERenderPass; Index: Integer; Id: Integer);
begin
  Pass.TextureSetups[Index].TextureId := Id;
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

constructor TCERenderPass.Create;
var i: Integer;
begin
  for i := 0 to MAX_TEXTURES-1 do
    TextureSetups[i].TextureId := -1;
end;

end.


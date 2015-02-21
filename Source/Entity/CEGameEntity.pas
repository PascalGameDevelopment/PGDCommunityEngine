(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEGameEntity.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE game entity)

Game entity class which implements component-based approach

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEGameEntity;

interface

uses
  CEBaseTypes, CETemplate,
  CEEntity, CEMaterial, CEMesh, CELocation;

type
  {
   Represents game entity with its components and logic.
   Update method is called each frame with delta time since last call.
  }
  TCEGameEntity = class(TCEBaseEntity)
  private
    FLocation: TCELocation;
    FMesh: TCEMesh;
    FMaterial: TCEMaterial;
    procedure SetLocation(const Value: TCELocation);
    procedure SetMesh(const Value: TCEMesh);
    procedure SetMaterial(const Value: TCEMaterial);
  protected
  public
    // Called each frame
    procedure Update(const DeltaT: Single); virtual; abstract;
  published
    // Location component
    property Location: TCELocation read FLocation write SetLocation;
    // Mesh component
    property Mesh: TCEMesh read FMesh write SetMesh;
    // Material
    property Material: TCEMaterial read FMaterial write SetMaterial;
  end;

implementation

uses
  CELog, CECommon, sysutils;


{ TCEGameEntity }

procedure TCEGameEntity.SetLocation(const Value: TCELocation);
begin
end;

procedure TCEGameEntity.SetMesh(const Value: TCEMesh);
begin

end;

procedure TCEGameEntity.SetMaterial(const Value: TCEMaterial);
begin
  FMaterial := Value;
end;

end.

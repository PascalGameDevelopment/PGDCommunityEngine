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
    procedure SetManager(const Value: TCEEntityManager); override;
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

  TCEGameEntityManager = class(TCEEntityManager)
  private
    FUpdateList: TCEEntityList;
    procedure MapRenderable(const OldMaterial, NewMaterial: TCEMaterial; Mesh: TCEMesh);
    procedure RegisterGameEntity(const Entity: TCEGameEntity);
  public
    constructor Create();
    destructor Destroy(); override;
    // Returns list of entities which should be updated
    function GetUpdateList(): TCEEntityList;
  end;

implementation

{ TCEGameEntity }

procedure TCEGameEntity.SetLocation(const Value: TCELocation);
begin
  FLocation := Value;
end;

procedure TCEGameEntity.SetMesh(const Value: TCEMesh);
begin
  FMesh := Value;
  if Assigned(Manager) then TCEGameEntityManager(Manager).MapRenderable(nil, FMaterial, FMesh);
end;

procedure TCEGameEntity.SetMaterial(const Value: TCEMaterial);
begin
  if Assigned(Manager) then TCEGameEntityManager(Manager).MapRenderable(FMaterial, Value, FMesh);
  FMaterial := Value;
end;

procedure TCEGameEntity.SetManager(const Value: TCEEntityManager);
begin
  if Manager = Value then Exit;
  inherited;
  TCEGameEntityManager(Manager).RegisterGameEntity(Self);
end;

procedure TCEGameEntityManager.MapRenderable(const OldMaterial, NewMaterial: TCEMaterial; Mesh: TCEMesh);
begin

end;

procedure TCEGameEntityManager.RegisterGameEntity(const Entity: TCEGameEntity);
begin
  FUpdateList.Add(Entity);
end;

constructor TCEGameEntityManager.Create();
begin
  FUpdateList := TCEEntityList.Create();
end;

destructor TCEGameEntityManager.Destroy();
begin
  FUpdateList.Free();
  inherited Destroy();
end;

function TCEGameEntityManager.GetUpdateList(): TCEEntityList;
begin
  Result := FUpdateList;
end;

end.

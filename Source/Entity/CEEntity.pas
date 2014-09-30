(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEEntity.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE base entity)

Base entity class for PGDCE

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEEntity;

interface

uses
  CEBaseTypes, CETemplate, CEProperty, CEIO;

type
  {$TYPEINFO ON}
  TCEBaseEntity = class;
  {$TYPEINFO OFF}

  CCEEntity = class of TCEBaseEntity;

  _VectorValueType = TCEBaseEntity;
  {$MESSAGE 'Instantiating TEntityList interface'}
  {$I tpl_coll_vector.inc}
  // Entity list
  TCEEntityList = _GenVector;

  TCEBaseEntityManager = class
  public
    function GetEntityClass(const Name: string): CCEEntity; virtual; abstract;
  end;

  // Abstract class responsible for entities serialization / deserialization
  TCEBaseEntityFiler = class
  protected
    FManager: TCEBaseEntityManager;
  public
    constructor Create(AManager: TCEBaseEntityManager);
    // Reads and fills values of specified in Properties list of properties from input stream and returns True if success.
    function ReadEntity(IStream: TCEInputStream): TCEBaseEntity; virtual; abstract;
    // Writes properties to output stream and returns True if success.
    function WriteEntity(OStream: TCEOutputStream; Entity: TCEBaseEntity): Boolean; virtual; abstract;
  end;

  // Simple implementation
  TCESimpleEntityFiler = class(TCEBaseEntityFiler)
  private
    FPropertyFiler: TCESimplePropertyFiler;
  public
    constructor Create(AManager: TCEBaseEntityManager);
    function ReadEntity(IStream: TCEInputStream): TCEBaseEntity; override;
    function WriteEntity(OStream: TCEOutputStream; Entity: TCEBaseEntity): Boolean; override;
  end;

  { @Abstract(Base entity class)
    Responsible for hierarchy and serialization
    }
  TCEBaseEntity = class
  private
    procedure SetName(const Value: TCEEntityName);
    procedure SetParent(const Value: TCEBaseEntity);
  protected
    fName: TCEEntityName;
    fParent: TCEBaseEntity;
    fChilds: TCEEntityList;
  public
    class function GetClass: CCEEntity;
    { Copies all data and properties from ASource to the item.
      Descendants should override this method in order to handle specific fields if any. }
    procedure Assign(ASource: TCEBaseEntity); virtual;
    // Creates and returns a clone of the item with all data and properties having the same value as in source.
    function Clone: TCEBaseEntity;

    { Retrieves a set of entity's properties and their values.
      The basic implementation retrieves published properties using RTTI.
      Descendant classes may override this method and modify the set of properties.
      The set of properties should be constant during entity's lifecycle. }
    function GetProperties(): TCEProperties; virtual;
    { Sets values of entity's properties.
      The basic implementation sets published properties using RTTI.
      Descendant classes may override this method to handle more properties. }
    procedure SetProperties(const Properties: TCEProperties); virtual;

    property Parent: TCEBaseEntity read fParent write SetParent;
    property Childs: TCEEntityList read fChilds;
  published
    // Name used for references to the entity
    property Name: TCEEntityName read fName write SetName;
  end;

implementation

{$MESSAGE 'Instantiating TEntityList'}
{$I tpl_coll_vector.inc}

{ TCEBaseEntityFiler }

constructor TCEBaseEntityFiler.Create(AManager: TCEBaseEntityManager);
begin
  FManager := AManager;
end;

{ TCEBaseEntity }

procedure TCEBaseEntity.SetName(const Value: TCEEntityName);
begin
  fName := Value;
end;

procedure TCEBaseEntity.SetParent(const Value: TCEBaseEntity);
begin
  fParent := Value;
end;

class function TCEBaseEntity.GetClass: CCEEntity;
begin
  Result := Self;
end;

procedure TCEBaseEntity.Assign(ASource: TCEBaseEntity);
var
  Props: TCEProperties;
begin
  try
    Props := ASource.GetProperties();
    SetProperties(Props);
  finally
    Props.Free();
  end;
end;

function TCEBaseEntity.Clone: TCEBaseEntity;
begin
  Result := GetClass.Create();
  Result.Assign(Self);
end;

function TCEBaseEntity.GetProperties(): TCEProperties;
begin
  Result := CEProperty.GetClassPropertiesAndValues(ClassType, Self);
end;

procedure TCEBaseEntity.SetProperties(const Properties: TCEProperties);
begin
  CEProperty.SetClassPropertiesAndValues(Self, Properties);
end;

{ TCESimpleEntityFiler }

constructor TCESimpleEntityFiler.Create(AManager: TCEBaseEntityManager);
begin
  FPropertyFiler := TCESimplePropertyFiler.Create();
end;

function TCESimpleEntityFiler.ReadEntity(IStream: TCEInputStream): TCEBaseEntity;
var
  s: AnsiString;
  EntityClass: CCEEntity;
  Props: TCEProperties;
  i, TotalChilds: Integer;
  Child: TCEBaseEntity;
begin
  Result := nil;
  if not CEIO.ReadAnsiString(IStream, s) then Exit;

  EntityClass := FManager.GetEntityClass(s);
  if EntityClass = nil then
  begin
//    Log(ClassName + '.LoadItem: Unknown item class "' + s + '". Substitued by TItem', lkError);
    EntityClass := TCEBaseEntity;  // TPropertyEntity;
  end;

  Result := EntityClass.Create();

  Props := CEProperty.GetClassProperties(EntityClass);
  try
    if not FPropertyFiler.Read(IStream, Props) then Exit;
    Result.SetProperties(Props);
  finally
    Props.Free;
  end;

  if not IStream.ReadCheck(TotalChilds, SizeOf(TotalChilds)) then Exit;

  for i := 0 to TotalChilds-1 do
  begin
    Child := ReadEntity(IStream);
    if Child = nil then Exit;
    Result.AddChild(Child);
  end;
end;

function TCESimpleEntityFiler.WriteEntity(OStream: TCEOutputStream; Entity: TCEBaseEntity): Boolean;
var
  Props: TCEProperties;
  i, Count: Integer;
begin
  Result := False;
  if not CEIO.WriteAnsiString(OStream, AnsiString(Entity.ClassName)) then Exit;

  Entity.GetProperties();
  try
    if not FPropertyFiler.Write(OStream, Props) then Exit;
//    Count := Entity.ChildCount;
    if not OStream.WriteCheck(Count, SizeOf(Count)) then Exit;

    for i := 0 to Count-1 do if Assigned(Entity.Childs[i]) then
      if not WriteEntity(OStream, Entity.Childs[i]) then Exit;
  finally
    Props.Free();
  end;
end;

end.

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

const
  // Entity hierarchy delimiter
  HIERARCHY_DELIMITER = '/';

type
  {$TYPEINFO ON}
  TCEBaseEntity = class;
  // Binary data record
  {$TYPEINFO OFF}

  CCEEntity = class of TCEBaseEntity;

  _VectorValueType = TCEBaseEntity;
  {$MESSAGE 'Instantiating TEntityList interface'}
  {$I tpl_coll_vector.inc}
  // Entity list
  TCEEntityList = _GenVector;

{  TObjectLinkFlag = (lfAbsolute);
  // @Exclude()
  TObjectLinkFlags = set of TObjectLinkFlag;
  // @Exclude() Item link property data
  TObjectLink = record
    Flags: TObjectLinkFlags;
    PropName, ObjectName: AnsiString;
    Item: TItem;
    BaseClass: CItem;
  end;}

  TCEBaseEntityManager = class
  private
    FEntityClasses: array of CCEEntity;
  public
    // Registers an entity class. Only entities of registered classes can be saved/loaded or be linked to via an object link property.
    procedure RegisterEntityClass(NewClass: CCEEntity);
    // Registers an array of entity classes. Only entities of registered classes can be saved/loaded or be linked to via an object link property.
    procedure RegisterEntityClasses(NewClasses: array of TClass);
    // Returns an entity class by its name or nil if not registered
    function GetEntityClass(const Name: TCEEntityClassName): CCEEntity;
  end;

  TCEEntityManager = class(TCEBaseEntityManager)
  private
    FRoot: TCEBaseEntity;
  public
    // Returns an entity in hierarchy by its full absolute (starting with "/") name or nil if not found
    function Find(const FullName: TCEEntityName): TCEBaseEntity;
    property Root: TCEBaseEntity read FRoot write FRoot;
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
    destructor Destroy; override;
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
    // Destroys all childs recursively
    procedure DestroyChilds;
    // Destroys all published binary data properties
    procedure CleanupBinaryData;
  protected
    FName: TCEEntityName;
    FParent: TCEBaseEntity;
    FChilds: TCEEntityList;
  public
    class function GetClass: CCEEntity;
    // Creates an empty property collection
    constructor Create(); overload;
    // Destroys the property collection
    destructor Destroy; override;
    { Copies all data and properties from ASource to the item.
      Descendants should override this method in order to handle specific fields if any. }
    procedure Assign(ASource: TCEBaseEntity); virtual;
    // Creates and returns a clone of the item with all data and properties having the same value as in source.
    function Clone: TCEBaseEntity;

    // Returns entities name with its full path in hierarchy
    function GetFullName: TCEEntityName;
    // Adds the specified entity as a child to this entity
    procedure AddChild(AEntity: TCEBaseEntity);
    // Returns child with the given name or nil if there is no such child
    function FindChild(const Name: TCEEntityName): TCEBaseEntity;

    { Retrieves a set of entity's properties and their values.
      The basic implementation retrieves published properties using RTTI.
      Descendant classes may override this method and modify the set of properties.
      The set of properties should be constant during entity's lifecycle. }
    function GetProperties(): TCEProperties; virtual;
    { Sets values of entity's properties.
      The basic implementation sets published properties using RTTI.
      Descendant classes may override this method to handle more properties. }
    procedure SetProperties(const Properties: TCEProperties); virtual;

    property Parent: TCEBaseEntity read FParent write SetParent;
    property Childs: TCEEntityList read FChilds;
  published
    // Name used for references to the entity
    property Name: TCEEntityName read FName write SetName;
  end;

implementation

uses CERttiUtil, TypInfo, SysUtils;

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
  FName := Value;
end;

procedure TCEBaseEntity.SetParent(const Value: TCEBaseEntity);
begin
  FParent := Value;
end;

procedure TCEBaseEntity.CleanupBinaryData();
var
  PropInfos: PPropList;
  PropInfo: PPropInfo;
  Count, i: Integer;
  BinaryData: TCEBinaryData;
begin
  Count := CERttiUtil.GetClassPropList(ClassType, PropInfos, [tkClass]);
  try
    for i := 0 to Count - 1 do
    begin
      PropInfo := PropInfos^[i];
      if PropInfo^.PropType^.Kind = tkClass then
      begin
        if CERttiUtil.GetObjectPropClass(ClassType, PropInfo).InheritsFrom(TCEBinaryData) then
        begin
          BinaryData := TCEBinaryData(TypInfo.GetObjectProp(Self, PropInfo));
          if Assigned(BinaryData) then
            BinaryData.Free();
        end;
      end;
    end;
  finally
    FreeMem(PropInfos);
  end;
end;

procedure TCEBaseEntity.DestroyChilds;
var i: Integer;
begin
  if not Assigned(FChilds) then Exit;
  i := Childs.Count - 1;
  while i >= 0 do begin
    if Assigned(Childs[i]) then FChilds[i].Free();
    Dec(i);
  end;
end;

class function TCEBaseEntity.GetClass: CCEEntity;
begin
  Result := Self;
end;

constructor TCEBaseEntity.Create;
begin
end;

destructor TCEBaseEntity.Destroy;
begin
  DestroyChilds();
  CleanupBinaryData();
  FChilds.Free();
  FChilds := nil;
  inherited;
end;

procedure TCEBaseEntity.Assign(ASource: TCEBaseEntity);
var
  Props: TCEProperties;
begin
  Props := ASource.GetProperties();
  try
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

function TCEBaseEntity.GetFullName: TCEEntityName;
var Entity: TCEBaseEntity;
begin
  Result := HIERARCHY_DELIMITER + Name;
  Entity := Self.Parent;
  while Entity <> nil do begin
    Result := HIERARCHY_DELIMITER + Entity.Name + Result;
    Entity := Entity.Parent;
  end;
end;

procedure TCEBaseEntity.AddChild(AEntity: TCEBaseEntity);
begin
  Assert(Self <> nil);
  Assert(AEntity <> nil);
  Assert(not Assigned(AEntity.Parent), 'TCEBaseEntity.AddChild: entity "' + AEntity.GetFullName + '" already has a parent');
  if not Assigned(FChilds) then FChilds := TCEEntityList.Create();

  AEntity.Parent := Self;
  FChilds.Add(AEntity);
end;

function TCEBaseEntity.FindChild(const Name: TCEEntityName): TCEBaseEntity;
var i: Integer;
begin
  Result := nil;
  i := FChilds.Count-1;
  while (i >= 0) and (FChilds[i].Name <> Name) do Dec(i);
  if i >= 0 then Result := FChilds[i];
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
  inherited Create(AManager);
end;

destructor TCESimpleEntityFiler.Destroy();
begin
  if Assigned(FPropertyFiler) then FPropertyFiler.Free();
end;

function TCESimpleEntityFiler.ReadEntity(IStream: TCEInputStream): TCEBaseEntity;
var
  s: TCEEntityClassName;
  EntityClass: CCEEntity;
  Props: TCEProperties;
  i, TotalChilds: Integer;
  Child: TCEBaseEntity;
begin
  Result := nil;
  {$IFDEF UNICODE_ONLY}
  if not CEIO.ReadUnicodeString(IStream, s) then Exit;
  {$ELSE}
  if not CEIO.ReadAnsiString(IStream, s) then Exit;
  {$ENDIF}

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
  {$IFDEF UNICODE_ONLY}
  if not CEIO.WriteUnicodeString(OStream, TCEEntityClassName(Entity.ClassName)) then Exit;
  {$ELSE}
  if not CEIO.WriteAnsiString(OStream, TCEEntityClassName(Entity.ClassName)) then Exit;
  {$ENDIF}

  Props := Entity.GetProperties();
  try
    if not FPropertyFiler.Write(OStream, Props) then Exit;
    if Assigned(Entity.Childs) then
      Count := Entity.Childs.Count
    else
      Count := 0;
    if not OStream.WriteCheck(Count, SizeOf(Count)) then Exit;

    for i := 0 to Count-1 do if Assigned(Entity.Childs[i]) then
      if not WriteEntity(OStream, Entity.Childs[i]) then Exit;
  finally
    Props.Free();
  end;
end;

{ TCEBaseEntityManager }

procedure TCEBaseEntityManager.RegisterEntityClass(NewClass: CCEEntity);
begin
  if GetEntityClass(TCEEntityClassName(NewClass.ClassName)) <> nil then
  begin
    //Log(ClassName + '.RegisterEntityClass: Class "' + NewClass.ClassName + '" already registered', lkWarning);
    Exit;
  end;
  SetLength(FEntityClasses, Length(FEntityClasses) + 1);
  FEntityClasses[High(FEntityClasses)] := NewClass;
end;

procedure TCEBaseEntityManager.RegisterEntityClasses(NewClasses: array of TClass);
var i: Integer;
begin
  for i := 0 to High(NewClasses) do if NewClasses[i].InheritsFrom(TCEBaseEntity) then
  begin
    RegisterEntityClass(CCEEntity(NewClasses[i]));
  end;
end;

function TCEBaseEntityManager.GetEntityClass(const Name: TCEEntityClassName): CCEEntity;
var i: Integer;
begin
  Result := nil;
  i := High(FEntityClasses);
  while (i >= 0) and (TCEEntityClassName(FEntityClasses[i].ClassName) <> Name) do Dec(i);
  if i >= 0 then Result := FEntityClasses[i];
end;

function CharPos(const ch: AnsiChar; const s: AnsiString; const Start: Integer ): Integer;
begin       // TODO: optimize
  Result := Pos(ch, Copy(s, Start, Length(s)));
  if Result >= STRING_INDEX_BASE then
    Result := Result + Start
  else
    Result := -1;
end;

function GetNextIndex(const s: TCEEntityName; PrevI, len: Integer): Integer; {$I inline.inc}
begin
  Result := CharPos(HIERARCHY_DELIMITER, s, PrevI);
  if Result < 0 then Result := len;
end;

function TCEEntityManager.Find(const FullName: TCEEntityName): TCEBaseEntity;
var
  Cur: TCEBaseEntity;
  pi, ni, len: Integer;
begin
  Result := FRoot;
  if not Assigned(FRoot) then Exit;
  pi := STRING_INDEX_BASE + 1 + Length(FRoot.Name) + 1;
  {$IFDEF DEBUG}
  if Copy(FullName, STRING_INDEX_BASE, pi - STRING_INDEX_BASE - 1) <> HIERARCHY_DELIMITER + FRoot.Name then
    raise ECEInvalidArgument.Create('Absolute name should start with "' + HIERARCHY_DELIMITER + '<root entity name>"');
  {$ENDIF}
  len := Length(FullName) + STRING_INDEX_BASE;
  ni := GetNextIndex(FullName, pi, len);
  while ni < len do
  begin
    Result := Result.FindChild(Copy(FullName, pi, ni - pi));
    if Result = nil then Exit;

    pi := ni + 1;
    ni := GetNextIndex(FullName, pi, len);
  end;
  Result := Result.FindChild(Copy(FullName, pi, ni - pi));
end;

end.


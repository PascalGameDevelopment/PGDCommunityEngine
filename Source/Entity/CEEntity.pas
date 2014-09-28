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
  CEBaseTypes, CETemplate, CEProperty;

type
  {$TYPEINFO ON}
  TCEBaseEntity = class;
  {$TYPEINFO OFF}

  _VectorValueType = TCEBaseEntity;
  {$MESSAGE 'Instantiating TEntityList interface'}
  {$I tpl_coll_vector.inc}
  // Entity list
  TCEEntityList = _GenVector;

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
    { Retrieves a set of entity's properties and their values.
      The basic implementation retrieves published properties using RTTI.
      Descendant classes may override this method to add more properties.
      The set of properties should be constant during entity's lifecycle. }
    function GetProperties(): TCEProperties; virtual;
    { Sets values of entity's properties.
      The basic implementation sets published properties using RTTI.
      Descendant classes may override this method to handle more properties. }
    procedure SetProperties(const Properties: TCEProperties); virtual;

    property Childs: TCEEntityList read fChilds;
    property Parent: TCEBaseEntity read fParent write SetParent;
  published
    // Name used for references to the entity
    property Name: TCEEntityName read fName write SetName;
  end;

implementation

uses TypInfo;

{$MESSAGE 'Instantiating TEntityList'}
{$I tpl_coll_vector.inc}

{ TCEBaseEntity }

procedure TCEBaseEntity.SetName(const Value: TCEEntityName);
begin
  fName := Value;
end;

procedure TCEBaseEntity.SetParent(const Value: TCEBaseEntity);
begin
  fParent := Value;
end;

function TCEBaseEntity.GetProperties(): TCEProperties;
var
  i: Integer;
  Prop: PCEProperty;
  Value: PCEPropertyValue;
begin
  Result := CEProperty.GetClassProperties(ClassType);
  for i := 0 to Result.Count-1 do
  begin
    Prop := Result.PropByIndex[i];
    Value := Result[Prop.Name];
//    Writeln('Prop name: ', Prop^.Name, ', type: ', Prop^.TypeId);
    case Prop^.TypeId of
      ptBoolean:     Value^.AsBoolean := TypInfo.GetOrdProp(Self, Prop^.Name) = Ord(True);
      ptInteger:     Value^.AsInteger := TypInfo.GetOrdProp(Self, Prop^.Name);
      ptInt64:       Value^.AsInt64 := TypInfo.GetInt64Prop(Self, Prop^.Name);
      ptSingle:      Value^.AsSingle := TypInfo.GetFloatProp(Self, Prop^.Name);
      ptDouble:      Value^.AsDouble := TypInfo.GetFloatProp(Self, Prop^.Name);
      ptShortString: Value^.AsShortString := TypInfo.GetStrProp(Self, Prop^.Name);
      {$IFDEF UNICODE}
        {$IFDEF FPC}
        ptAnsiString:  Value^.AsAnsiString := TypInfo.GetStrProp(Self, Prop^.Name);
        {$ELSE}
        ptAnsiString:  Value^.AsAnsiString := TypInfo.GetAnsiStrProp(Self, Prop^.Name);
        {$ENDIF}
      ptString:      Value^.AsUnicodeString := TypInfo.GetStrProp(Self, Prop^.Name);
      {$ELSE}
      ptAnsiString:  Value^.AsAnsiString := TypInfo.GetStrProp(Self, Prop^.Name);
      ptString:      Value^.AsUnicodeString := TypInfo.GetWideStrProp(Self, Prop^.Name);
      {$ENDIF}
      ptColor: ;
      ptEnumeration: Value^.AsInteger := TypInfo.GetOrdProp(Self, Prop^.Name);
      ptSet: Value^.AsInteger := TypInfo.GetOrdProp(Self, Prop^.Name);
      ptPointer: ;
      ptObjectLink: ;
      ptBinary: ;
      ptObject: ;
      ptClass: ;
    end;
  end;
end;

procedure TCEBaseEntity.SetProperties(const Properties: TCEProperties);
begin

end;

end.


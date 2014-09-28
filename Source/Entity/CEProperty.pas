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
@abstract(PGDCE entity property)

Entity property, collection of properties

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEProperty;

interface

uses
  CEBaseTypes, CETemplate, CERttiUtil, CEIO;

type
  // Type for property names
  TPropertyName = AnsiString;

   // Possible property types
  TCEPropertyType = (
    // Boolean value
    ptBoolean,
    // 32-bit integer value
    ptInteger,
    // 64-bit integer value
    ptInt64,
    // Single-precision floating-point value
    ptSingle,
    // Double-precision floating-point value
    ptDouble,
    // Short string value
    ptShortString,
    // Ansi string value
    ptAnsiString,
    // Unicode string value
    ptString,
    // ARGB color value
    ptColor,
    // Enumerated value
    ptEnumeration,
    // Set of numbers [0..31]
    ptSet,
    // Pointer value
    ptPointer,
    // A link to an object
    ptObjectLink,
    // Bynary data
    ptBinary,
    // Object value
    ptObject,
    // Class value
    ptClass
  );

  PCEPropertyValue = ^TCEPropertyValue;
  // Data structure representing a property value
  TCEPropertyValue = packed record
    AsUnicodeString: UnicodeString;
    AsAnsiString: AnsiString;
    // Property value as various type
    case t: TCEPropertyType of
      ptBoolean: (AsBoolean: Boolean);
      ptInteger, ptEnumeration, ptSet: (AsInteger: Integer);
      ptInt64: (AsInt64: Int64);
      ptSingle: (AsSingle: Single);
      ptDouble: (AsDouble: Double);
      ptShortString: (AsShortString: ShortString);
      ptObject: (AsObject: TObject);
      //ptClassRef: (AsClass: TClass);
      ptPointer: (AsPointer: Pointer);
//        ptAnsiString: (AsPAnsiChar: PAnsiChar);
//        ptString: (AsPUnicodeString: PUnicodeString);
      ptObjectLink: (Linked: TObject; FQN: PCEEntityName);
      ptBinary: (Data: Pointer; Size: Integer);
      //ptDynArray, ptMethod, ptVariant, ptArray, ptRecord, ptInterface, ptProcedure: ();
  end;

  PCEProperty = ^TCEProperty;
  // Data structure representing a property description
  TCEProperty = packed record
    // Property name
    Name: TPropertyName;
    // Property type information
    TypeId: TCEPropertyType;
  end;

  _VectorValueType = TCEProperty;
  _PVectorValueType = PCEProperty;
  {$MESSAGE 'Instantiating TCEPropertyList interface'}
  {$I tpl_coll_vector.inc}
  // Property list
  TCEPropertyList = class(_GenVector)
  private
    function IndexOfName(const Name: TPropertyName): Integer; {$I inline.inc}
  end;

  { @Abstract(Property collection)    }
  TCEProperties = class
  protected
    FProperties: TCEPropertyList;
    FValues: array of TCEPropertyValue;
    function GetIndex(const Name: TPropertyName): Integer;
    function GetPropByIndex(Index: Integer): PCEProperty;
    function GetValueByIndex(Index: Integer): PCEPropertyValue;
    function GetProperty(const Name: TPropertyName): TCEProperty;
    procedure SetProperty(const Name: TPropertyName; const Prop: TCEProperty);
    function GetValue(const Name: TPropertyName): PCEPropertyValue;
    procedure SetValue(const Name: TPropertyName; const Value: PCEPropertyValue);
    function GetCount: Integer;
  public
    // Creates an empty property collection
    constructor Create(); overload;
    // Destroys the property collection
    destructor Destroy; override;

    // Add property description
    procedure AddProp(const Name: TPropertyName; TypeId: TCEPropertyType);

    procedure AddString(const Name: TPropertyName; const Value: string);
    procedure AddAnsiString(const Name: TPropertyName; const Value: AnsiString);
    procedure AddInt(const Name: TPropertyName; const Value: Integer);
    procedure AddSingle(const Name: TPropertyName; const Value: Single);

    // Property definitions
    property Prop[const Name: TPropertyName]: TCEProperty read GetProperty write SetProperty;
    // Property values
    property Value[const Name: TPropertyName]: PCEPropertyValue read GetValue write SetValue; default;
    // Property definition by index
    property PropByIndex[Index: Integer]: PCEProperty read GetPropByIndex;
    // Number of properties
    property Count: Integer read GetCount;
  end;

  // Abstract class responsible for properties serialization / deserialization
  TCEPropertyFilerBase = class
  public
    { Reads arbitrary list of property definitions and values from input stream and returns it.
      Returns nil if error occured.
      May raise TCEUnsupportedOperation if filer format doesn't support storage of property definitions. }
    function ReadArbitrary(IStream: TCEInputStream): TCEProperties; virtual; abstract;
    // Reads and fills values of specified in Properties list of properties from input stream and returns True if success.
    function Read(IStream: TCEInputStream; Properties: TCEProperties): Boolean; virtual; abstract;
    // Writes properties to output stream and returns True if success.
    function Write(OStream: TCEOutputStream; Properties: TCEProperties): Boolean; virtual; abstract;
  end;

  { Simple property filer implementation.
    Doesn't store property definitions but only values and therefore doesn't support read of arbitrary list of properties. }
  TCESimplePropertyFiler = class(TCEPropertyFilerBase)
  public
    function ReadArbitrary(IStream: TCEInputStream): TCEProperties; override;
    function Read(IStream: TCEInputStream; Properties: TCEProperties): Boolean; override;
    function Write(OStream: TCEOutputStream; Properties: TCEProperties): Boolean; override;
  end;

  ECEPropertyError = class(ECEError);

  // Builds list of property definitions for the given class using RTTI
  function GetClassProperties(AClass: TClass): TCEProperties;

implementation

uses SysUtils, TypInfo;

type
  TSignature = array[0..3] of AnsiChar;

const
  SIMPLE_PROPERTIES_BEGIN_SIGNATURE: TSignature = 'SP_B';
  SIMPLE_PROPERTIES_END_SIGNATURE: TSignature = 'SP_E';

function _VectorEquals(const v1, v2: TCEProperty): Boolean; {$I inline.inc}
begin
  Result := v1.Name = v2.Name;
end;

{ TCEPropertyList }

function TCEPropertyList.IndexOfName(const Name: TPropertyName): Integer;
begin
  Result := FCount;
  while (Result >= 0) and (FValues[Result].Name <> Name) do Dec(Result);
end;

{$MESSAGE 'Instantiating TCEPropertyList'}
{$I tpl_coll_vector.inc}

{ TCEProperties }

function TCEProperties.GetIndex(const Name: TPropertyName): Integer;
begin
  Result := FProperties.Count-1;
  while (Result >= 0) and (FProperties[Result].Name <> Name) do Dec(Result);
end;

function TCEProperties.GetPropByIndex(Index: Integer): PCEProperty;
begin
  Result := FProperties.GetPtr(Index); //TODO: handle non existing name
end;

function TCEProperties.GEtValueByIndex(Index: Integer): PCEPropertyValue;
begin
  Result := @FValues[Index]; //TODO: handle non existing name
end;

function TCEProperties.GetProperty(const Name: TPropertyName): TCEProperty;
begin
  Result := GetPropByIndex(GetIndex(Name))^;
end;

procedure TCEProperties.SetProperty(const Name: TPropertyName; const Prop: TCEProperty);
begin

end;

function TCEProperties.GetValue(const Name: TPropertyName): PCEPropertyValue;
begin
  Result := GetValueByIndex(GetIndex(Name));
end;

procedure TCEProperties.SetValue(const Name: TPropertyName; const Value: PCEPropertyValue);
begin

end;

function TCEProperties.GetCount: Integer;
begin
  Result := FProperties.GetCount();
end;

constructor TCEProperties.Create;
begin
  FProperties := TCEPropertyList.Create();
end;

destructor TCEProperties.Destroy;
begin
  FProperties.Free();
  FProperties := nil;
  inherited;
end;

procedure TCEProperties.AddProp(const Name: TPropertyName; TypeId: TCEPropertyType);
begin
  if GetIndex(Name) = -1 then begin
    FProperties.Count := FProperties.Count+1;
    SetLength(FValues, FProperties.Count);
    FProperties.ValuesPtr[FProperties.Count-1].Name := Name;
    FProperties.ValuesPtr[FProperties.Count-1].TypeId := TypeId;
  end;
end;

procedure TCEProperties.AddString(const Name: TPropertyName; const Value: string);
begin
  AddProp(Name, ptString);
  FValues[FProperties.Count-1].AsUnicodeString := Value;
end;

procedure TCEProperties.AddAnsiString(const Name: TPropertyName; const Value: AnsiString);
begin
  AddProp(Name, ptAnsiString);
  FValues[FProperties.Count-1].AsAnsiString := Value;
end;

procedure TCEProperties.AddInt(const Name: TPropertyName; const Value: Integer);
begin
  AddProp(Name, ptInteger);
  FValues[FProperties.Count-1].AsInteger := Value;
end;

procedure TCEProperties.AddSingle(const Name: TPropertyName; const Value: Single);
begin
  AddProp(Name, ptSingle);
  FValues[FProperties.Count-1].AsSingle := Value;
end;


{ TCEPropertyFiler }

function TCESimplePropertyFiler.ReadArbitrary(IStream: TCEInputStream): TCEProperties;
begin
  Result := nil;
  raise ECEUnsupportedOperation.Create('Arbitrary properties deserialization isn''t supported');
end;

function TCESimplePropertyFiler.Read(IStream: TCEInputStream; Properties: TCEProperties): Boolean;
var
  i: Integer;
  Sign: TSignature;
  Prop: PCEProperty;
  Value: PCEPropertyValue;
begin
  if Properties = nil then raise ECEInvalidArgument.Create('Properties argument is nil');
  Result := false;

  if not IStream.ReadCheck(Sign, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE)) then Exit;
  if Sign <> SIMPLE_PROPERTIES_BEGIN_SIGNATURE then Exit;

  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.GetPropByIndex(i);
    Value := Properties.GetValueByIndex(i);
    case Prop^.TypeId of
      ptInteger: if not IStream.ReadCheck(Value^.AsInteger, SizeOf(Value^.AsInteger)) then Exit;
      ptSingle: if not IStream.ReadCheck(Value^.AsSingle, SizeOf(Value^.AsSingle)) then Exit;
      ptShortString: if not CEIO.ReadShortString(IStream, Value^.AsShortString) then Exit;
      ptAnsiString: if not CEIO.ReadAnsiString(IStream, Value^.AsAnsiString) then Exit;
      ptString: if not CEIO.ReadUnicodeString(IStream, Value^.AsUnicodeString) then Exit;
      else Assert(False, 'Invalid property type');
    end;
  end;

  if not IStream.ReadCheck(Sign, SizeOf(SIMPLE_PROPERTIES_END_SIGNATURE)) then Exit;
  if Sign <> SIMPLE_PROPERTIES_END_SIGNATURE then Exit;

  Result := True;
end;

function TCESimplePropertyFiler.Write(OStream: TCEOutputStream; Properties: TCEProperties): Boolean;
var
  i: Integer;
  Prop: PCEProperty;
  Value: PCEPropertyValue;
begin
  Result := OStream.WriteCheck(SIMPLE_PROPERTIES_BEGIN_SIGNATURE, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE));
  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.GetPropByIndex(i);
    Value := Properties.GetValueByIndex(i);
    case Prop^.TypeId of
      ptInteger: Result := Result and OStream.WriteCheck(Value^.AsInteger, SizeOf(Value^.AsInteger));
      ptSingle: Result := Result and OStream.WriteCheck(Value^.AsSingle, SizeOf(Value^.AsSingle));
      ptShortString: Result := Result and CEIO.WriteShortString(OStream, Value^.AsShortString);
      ptAnsiString: Result := Result and CEIO.WriteAnsiString(OStream, Value^.AsAnsiString);
      ptString: Result := Result and CEIO.WriteUnicodeString(OStream, Value^.AsUnicodeString);
      else Assert(False, 'Invalid property type');
    end;
  end;
  Result := Result and OStream.WriteCheck(SIMPLE_PROPERTIES_END_SIGNATURE, SizeOf(SIMPLE_PROPERTIES_END_SIGNATURE));
end;

function GetClassProperties(AClass: TClass): TCEProperties;
var
  PropInfos: PPropList;
  PropInfo: PPropInfo;
  Count, i: Integer;
  td: PTypeData;
begin
  Result := TCEProperties.Create();
  Count := CERttiUtil.GetClassPropList(AClass, PropInfos);

  try
    for i := 0 to Count - 1 do
    begin
      PropInfo := PropInfos^[i];
      case PropInfo^.PropType^.Kind of
        tkInteger: Result.AddProp(PropInfo^.Name, ptInteger);
        tkFloat:
          if PropInfo^.PropType^.Name = 'Single' then
            Result.AddProp(PropInfo^.Name, ptSingle)
          else if PropInfo^.PropType^.Name = 'Double' then
            Result.AddProp(PropInfo^.Name, ptDouble)
          else
            raise ECEPropertyError.Create('Unsupported property type');
        tkLString {$IFDEF FPC}, tkAString{$ENDIF}: Result.AddProp(PropInfo^.Name, ptAnsiString);
        tkString:
        begin
          if PropInfo^.PropType^.Name = 'ShortString' then
          begin
            Result.AddProp(PropInfo^.Name, ptShortString);
          end
          else
          begin
            {$IFDEF UNICODE}
            Result.AddProp(PropInfo^.Name, ptString);
            {$ELSE}
            Result.AddProp(PropInfo^.Name, ptAnsiString);
            {$ENDIF}
          end;
        end;
        {$IF Declared(tkUString)}tkUString, {$IFEND}tkWString: Result.AddProp(PropInfo^.Name, ptString);
        tkClass: Result.AddProp(PropInfo^.Name, ptClass);
        tkEnumeration: Result.AddProp(PropInfo^.Name, ptEnumeration);
        tkSet: Result.AddProp(PropInfo^.Name, ptSet);
        tkInt64: Result.AddProp(PropInfo^.Name, ptInt64);
        else begin
          raise ECEPropertyError.Create('Unsupported property type: ' + string(PropInfo^.PropType^.Name));
        end;
      end;
    end;
  finally
    FreeMem(PropInfos);
  end;
end;

end.

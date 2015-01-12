(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEProperty.pas

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

  { Type for serializable binary data.
    Published properties of descendant types will be included during serialization and deserialization.
    Actual type of such property should be always equal to its declared type.
    During destruction of an entity destructors of all published properties of descendant types will be called. }
  TCEBinaryData = class
  private
    // Indicates whether this instance is bound to an entity or must be destroyed by containing TCEProperties instance
    Bound: Boolean;
  public
    // Init instance with data from the given instance
    procedure Assign(AData: TCEBinaryData); virtual; abstract;
    // Reads binary data from input stream and returns True if success.
    function Read(IStream: TCEInputStream): Boolean; virtual; abstract;
    // Writes binary data to output stream and returns True if success.
    function Write(OStream: TCEOutputStream): Boolean; virtual; abstract;
    // Returns pointer to data
    function GetData(): Pointer; virtual; abstract;
  end;
  // Serializable binary data metaclass
  CCEBinaryData = class of TCEBinaryData;

  // Dynamic array if byte based binary data implementation
  TDynamicArray = class(TCEBinaryData)
  public
    Data: array of Byte;
    destructor Destroy(); override;
    procedure Assign(AData: TCEBinaryData); override;
    function Read(IStream: TCEInputStream): Boolean; override;
    function Write(OStream: TCEOutputStream): Boolean; override;
    function GetData(): Pointer; override;
  end;

  // Pointer based binary data implementation
  TPointerData = class(TCEBinaryData)
  public
    Data: Pointer;
    Size: Integer;
    destructor Destroy(); override;
    procedure Assign(AData: TCEBinaryData); override;
    function Read(IStream: TCEInputStream): Boolean; override;
    function Write(OStream: TCEOutputStream): Boolean; override;
    function GetData(): Pointer; override;
    procedure Allocate(ASize: Integer);
  end;

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
      ptClass: (AsClass: TClass);
      ptPointer: (AsPointer: Pointer);
      ptObjectLink: (Linked: TObject; LinkedClass: CCEAbstractEntity);
      ptBinary: (AsData: TCEBinaryData; BinDataClass: CCEBinaryData);
      //, ptMethod, ptVariant, ptInterface: ();
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

    // Add a property or reset an existing one
    function AddProp(const Name: TPropertyName; TypeId: TCEPropertyType): PCEPropertyValue;

    procedure AddString(const Name: TPropertyName; const Value: string);
    procedure AddAnsiString(const Name: TPropertyName; const Value: AnsiString);
    procedure AddInt(const Name: TPropertyName; const Value: Integer);
    procedure AddInt64(const Name: TPropertyName; const Value: Int64);
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
  // Builds list of property definitions for the given class using RTTI and fills values in the given object instance
  function GetClassPropertiesAndValues(AClass: TClass; AObj: TObject): TCEProperties;
  // Sets property values of the specified instance from the Properties
  procedure SetClassPropertiesAndValues(AObj: TObject; Properties: TCEProperties);

implementation

uses SysUtils, TypInfo;

const
  SIMPLE_PROPERTIES_BEGIN_SIGNATURE: TSignature = (Bytes: (Ord('S'), Ord('P'), Ord('_'), Ord('B')));
  SIMPLE_PROPERTIES_END_SIGNATURE: TSignature = (Bytes: (Ord('S'), Ord('P'), Ord('_'), Ord('E')));

function _VectorEquals(const v1, v2: TCEProperty): Boolean; {$I inline.inc}
begin
  Result := v1.Name = v2.Name;
end;

{ TDynamicArray }

destructor TDynamicArray.Destroy;
begin
  SetLength(Data, 0);
  Data := nil;
  inherited;
end;

procedure TDynamicArray.Assign(AData: TCEBinaryData);
begin
  if AData <> nil then Data := TDynamicArray(AData).Data;
end;

function TDynamicArray.Read(IStream: TCEInputStream): Boolean;
var DataSize: Integer;
begin
  Result := False;
  if not IStream.ReadCheck(DataSize, SizeOf(DataSize)) then Exit;
  SetLength(Data, DataSize);
  if DataSize > 0 then
    if not IStream.ReadCheck(Data[0], Length(Data)) then Exit;
  Result := True;
end;

function TDynamicArray.Write(OStream: TCEOutputStream): Boolean;
var DataSize: Integer;
begin
  Result := False;
  DataSize := Length(Data);
  if not OStream.WriteCheck(DataSize, SizeOf(DataSize)) then Exit;
  if DataSize > 0 then
    if not OStream.WriteCheck(Data[0], DataSize) then Exit;
  Result := True;
end;

function TDynamicArray.GetData: Pointer;
begin
  if Data <> nil then
    Result := @Data[0]
  else
    Result := nil;
end;

{ TPointerData }

destructor TPointerData.Destroy;
begin
  if Assigned(Data) then FreeMem(Data, Size);
  Data := nil;
  inherited;
end;

procedure TPointerData.Assign(AData: TCEBinaryData);
begin
  if AData <> nil then
  begin
    Allocate(TPointerData(AData).Size);
    Move(TPointerData(AData).Data^, Data^, Size);
  end;
end;

function TPointerData.Read(IStream: TCEInputStream): Boolean;
begin
  Result := False;
  if not IStream.ReadCheck(Size, SizeOf(Size)) then Exit;
  Allocate(Size);
  if Size > 0 then
    if not IStream.ReadCheck(Data^, Size) then Exit;
  Result := True;
end;

function TPointerData.Write(OStream: TCEOutputStream): Boolean;
begin
  Result := False;
  if not OStream.WriteCheck(Size, SizeOf(Size)) then Exit;
  if Size > 0 then
    if not OStream.WriteCheck(Data^, Size) then Exit;
  Result := True;
end;

function TPointerData.GetData: Pointer;
begin
  Result := Data;
end;

procedure TPointerData.Allocate(ASize: Integer);
begin
  if Assigned(Data) then FreeMem(Data, Size);
  Data := nil;
  Size := ASize;
  if Size > 0 then
    GetMem(Data, Size);
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
var i: Integer;
begin
  for i := 0 to FProperties.Count-1 do
    if (FProperties[i].TypeId = ptBinary) and Assigned(FValues[i].AsData) and not FValues[i].AsData.Bound then
      FValues[i].AsData.Free();
  FProperties.Free();
  FProperties := nil;
  inherited;
end;

function TCEProperties.AddProp(const Name: TPropertyName; TypeId: TCEPropertyType): PCEPropertyValue;
var
  Index: Integer;
begin
  Index := GetIndex(Name);
  if Index = -1 then begin
    Index := FProperties.Count;
    FProperties.Count := Index + 1;
    SetLength(FValues, FProperties.Count);
  end else
    Finalize(FValues[Index]);               // reset existing values
  Result := @FValues[Index];
  FProperties.ValuesPtr[Index].Name := Name;
  FProperties.ValuesPtr[Index].TypeId := TypeId;
end;

procedure TCEProperties.AddString(const Name: TPropertyName; const Value: string);
begin
  AddProp(Name, ptString)^.AsUnicodeString := Value;
end;

procedure TCEProperties.AddAnsiString(const Name: TPropertyName; const Value: AnsiString);
begin
  AddProp(Name, ptAnsiString)^.AsAnsiString := Value;
end;

procedure TCEProperties.AddInt(const Name: TPropertyName; const Value: Integer);
begin
  AddProp(Name, ptInteger)^.AsInteger := Value;
end;

procedure TCEProperties.AddInt64(const Name: TPropertyName; const Value: Int64);
begin
  AddProp(Name, ptInt64)^.AsInt64 := Value;
end;

procedure TCEProperties.AddSingle(const Name: TPropertyName; const Value: Single);
begin
  AddProp(Name, ptSingle)^.AsSingle := Value;
end;


{ TCEPropertyFiler }

function TCESimplePropertyFiler.ReadArbitrary(IStream: TCEInputStream): TCEProperties;
begin
  Result := nil;
  raise ECEUnsupportedOperation.Create('Arbitrary properties deserialization not supported');
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

  if not IStream.ReadCheck(Sign.DWord, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE.DWord)) then Exit;
  if Sign.DWord <> SIMPLE_PROPERTIES_BEGIN_SIGNATURE.DWord then Exit;

  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.GetPropByIndex(i);
    Value := Properties.GetValueByIndex(i);
    case Prop^.TypeId of
      ptBoolean, ptInteger,
      ptEnumeration, ptSet: if not IStream.ReadCheck(Value^.AsInteger, SizeOf(Value^.AsInteger)) then Exit;
      ptInt64: if not IStream.ReadCheck(Value^.AsInt64, SizeOf(Value^.AsInt64)) then Exit;
      ptSingle: if not IStream.ReadCheck(Value^.AsSingle, SizeOf(Value^.AsSingle)) then Exit;
      ptDouble: if not IStream.ReadCheck(Value^.AsDouble, SizeOf(Value^.AsDouble)) then Exit;
      ptShortString: if not CEIO.ReadShortString(IStream, Value^.AsShortString) then Exit;
      ptAnsiString: if not CEIO.ReadAnsiString(IStream, Value^.AsAnsiString) then Exit;
      ptString: if not CEIO.ReadUnicodeString(IStream, Value^.AsUnicodeString) then Exit;
      ptBinary: begin
        if not Assigned(Value^.AsData) or Value^.AsData.Bound then
          Value^.AsData := Value^.BinDataClass.Create();
        if not Value^.AsData.Read(IStream) then Exit;
      end;
      ptObjectLink: if not CEIO.ReadAnsiString(IStream, Value^.AsAnsiString) then Exit;
      else Assert(False, 'Invalid property type: ' + TypInfo.GetEnumName(TypeInfo(TCEPropertyType), Ord(Prop.TypeId)));
    end;
  end;

  if not IStream.ReadCheck(Sign.DWord, SizeOf(SIMPLE_PROPERTIES_END_SIGNATURE.DWord)) then Exit;
  if Sign.DWord <> SIMPLE_PROPERTIES_END_SIGNATURE.DWord then Exit;

  Result := True;
end;

function TCESimplePropertyFiler.Write(OStream: TCEOutputStream; Properties: TCEProperties): Boolean;
var
  i: Integer;
  Prop: PCEProperty;
  Value: PCEPropertyValue;
begin
  if Properties = nil then raise ECEInvalidArgument.Create('Properties argument is nil');
  Result := False;
  if not OStream.WriteCheck(SIMPLE_PROPERTIES_BEGIN_SIGNATURE.DWord, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE.DWord)) then Exit;
  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.GetPropByIndex(i);
    Value := Properties.GetValueByIndex(i);
    case Prop^.TypeId of
      ptBoolean, ptInteger,
      ptEnumeration, ptSet: if not OStream.WriteCheck(Value^.AsInteger, SizeOf(Value^.AsInteger)) then Exit;
      ptInt64: if not OStream.WriteCheck(Value^.AsInt64, SizeOf(Value^.AsInt64)) then Exit;
      ptSingle: if not OStream.WriteCheck(Value^.AsSingle, SizeOf(Value^.AsSingle)) then Exit;
      ptDouble: if not OStream.WriteCheck(Value^.AsDouble, SizeOf(Value^.AsDouble)) then Exit;
      ptShortString: if not CEIO.WriteShortString(OStream, Value^.AsShortString) then Exit;
      ptAnsiString: if not CEIO.WriteAnsiString(OStream, Value^.AsAnsiString) then Exit;
      ptString: if not CEIO.WriteUnicodeString(OStream, Value^.AsUnicodeString) then Exit;
      ptBinary: if not Value^.AsData.Write(OStream) then Exit;
      ptObjectLink: if not CEIO.WriteAnsiString(OStream, Value^.AsAnsiString) then Exit;
      else Assert(False, 'Invalid property type: ' + TypInfo.GetEnumName(TypeInfo(TCEPropertyType), Ord(Prop.TypeId)));
    end;
  end;
  if not OStream.WriteCheck(SIMPLE_PROPERTIES_END_SIGNATURE.DWord, SizeOf(SIMPLE_PROPERTIES_END_SIGNATURE.DWord)) then Exit;
  Result := True;
end;

function GetClassProperties(AClass: TClass): TCEProperties;
begin
  Result := GetClassPropertiesAndValues(AClass, nil);
end;

function GetClassPropertiesAndValues(AClass: TClass; AObj: TObject): TCEProperties;
var
  PropInfos: PPropList;
  PropInfo: PPropInfo;
  Count, i: Integer;
  Value: PCEPropertyValue;
  OClass: TClass;
begin
  Assert((AObj = nil) or (AObj.ClassType = AClass));
  Result := TCEProperties.Create();
  Count := CERttiUtil.GetClassPropList(AClass, PropInfos);

  try
    for i := 0 to Count - 1 do
    begin
      PropInfo := PropInfos^[i];
      WriteLn('Prop: ', PropInfo^.Name, ', type: ', TypInfo.GetEnumName(TypeInfo(TTypeKind), Ord(PropInfo^.PropType^.Kind)), ', type name: ', PropInfo^.PropType^.Name);
      case PropInfo^.PropType^.Kind of
        {$IF Declared(tkBool)}
        tkBool,
        {$IFEND}
        tkInteger:
        if PropInfo^.PropType^.Name = 'Boolean' then
        begin
          Value := Result.AddProp(PropInfo^.Name, ptBoolean);
          if Assigned(AObj) then
            Value^.AsBoolean := TypInfo.GetOrdProp(AObj, PropInfo) = Ord(True);
        end else begin
          Value := Result.AddProp(PropInfo^.Name, ptInteger);
          if Assigned(AObj) then
            Value^.AsInteger := TypInfo.GetOrdProp(AObj, PropInfo);
        end;
        tkInt64: begin
          Value := Result.AddProp(PropInfo^.Name, ptInt64);
          if Assigned(AObj) then
            Value^.AsInt64 := TypInfo.GetInt64Prop(AObj, PropInfo);
        end;
        tkFloat:
          if PropInfo^.PropType^.Name = 'Single' then
          begin
            Value := Result.AddProp(PropInfo^.Name, ptSingle);
            if Assigned(AObj) then
              Value^.AsSingle := TypInfo.GetFloatProp(AObj, PropInfo);
          end
          else if PropInfo^.PropType^.Name = 'Double' then
          begin
            Value := Result.AddProp(PropInfo^.Name, ptDouble);
            if Assigned(AObj) then
              Value^.AsDouble := TypInfo.GetFloatProp(AObj, PropInfo);
          end else
            raise ECEPropertyError.Create('Unsupported property type: ' + string(PropInfo^.PropType^.Name));
        tkEnumeration: begin
          Value := Result.AddProp(PropInfo^.Name, ptEnumeration);
          if Assigned(AObj) then
            Value^.AsInteger := TypInfo.GetOrdProp(AObj, PropInfo);
        end;
        tkSet: begin
          Value := Result.AddProp(PropInfo^.Name, ptSet);
          if Assigned(AObj) then
            Value^.AsInteger := TypInfo.GetOrdProp(AObj, PropInfo);
        end;
        {$IF Declared(tkAString)}tkAString, {$IFEND}
        tkLString: begin
          if PropInfo^.PropType^.Name = 'UTF8String' then
          begin
            Value := Result.AddProp(PropInfo^.Name, ptString);
            if Assigned(AObj) then
              Value^.AsUnicodeString := UnicodeString(GetAnsiStrProp(AObj, PropInfo));
          end else begin
            Value := Result.AddProp(PropInfo^.Name, ptAnsiString);
            if Assigned(AObj) then
              Value^.AsAnsiString := GetAnsiStrProp(AObj, PropInfo);
          end;
        end;
        {$IF Declared(tkUString)}tkUString, {$IFEND}
        tkString: begin
          if PropInfo^.PropType^.Name = 'ShortString' then
          begin
            Value := Result.AddProp(PropInfo^.Name, ptShortString);
            if Assigned(AObj) then
              Value^.AsShortString := ShortString(TypInfo.GetStrProp(AObj, PropInfo));
          end else begin
            {$IFDEF UNICODE}
              Value := Result.AddProp(PropInfo^.Name, ptString);
              if Assigned(AObj) then
                Value^.AsUnicodeString := TypInfo.GetStrProp(AObj, PropInfo);
            {$ELSE}
              Value := Result.AddProp(PropInfo^.Name, ptAnsiString);
              if Assigned(AObj) then
                Value^.AsAnsiString := GetAnsiStrProp(AObj, PropInfo);
            {$ENDIF}
          end;
        end;
        tkWString: begin
          Value := Result.AddProp(PropInfo^.Name, ptString);
          if Assigned(AObj) then
            Value^.AsUnicodeString := TypInfo.GetWideStrProp(AObj, PropInfo);
        end;

        tkClass: begin
          OClass := CERttiUtil.GetObjectPropClass(AClass, PropInfo);
          if OClass.InheritsFrom(TCEBinaryData) then                    // Binary data case
          begin
            Value := Result.AddProp(PropInfo^.Name, ptBinary);
            Value^.BinDataClass := CCEBinaryData(OClass);
            if Assigned(AObj) then
            begin
              Value^.AsData := Value^.BinDataClass.Create();
              Value^.AsData.Assign(TCEBinaryData(TypInfo.GetObjectProp(AObj, PropInfo)));
            end;
          end else if OClass.InheritsFrom(TCEAbstractEntity) then       // Object link case
          begin
            Value := Result.AddProp(PropInfo^.Name, ptObjectLink);
            Value^.LinkedClass := CCEAbstractEntity(OClass);
            if Assigned(AObj) then
            begin
              Value^.Linked := TypInfo.GetObjectProp(AObj, PropInfo);
              Value^.AsAnsiString := TCEAbstractEntity(Value^.Linked).GetFullName();
            end;
          end else
            raise ECEPropertyError.Create('Property of unsupported class: ' + string(OClass.ClassName));
        end;
        else
          raise ECEPropertyError.Create('Unsupported property type: ' + string(PropInfo^.PropType^.Name));
      end;
    end;
  finally
    FreeMem(PropInfos);
  end;
end;

{$WARNINGS OFF}
procedure SetClassPropertiesAndValues(AObj: TObject; Properties: TCEProperties);
var
  i: Integer;
  Prop: TCEProperty;
  Value: TCEPropertyValue;
begin
  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.PropByIndex[i]^;
    Value := Properties.GetValueByIndex(i)^;
    case Prop.TypeId of
      ptBoolean, ptInteger,
      ptEnumeration, ptSet: TypInfo.SetOrdProp(AObj, Prop.Name, Value.AsInteger);
      ptInt64: TypInfo.SetInt64Prop(AObj, Prop.Name, Value.AsInt64);
      ptSingle: TypInfo.SetFloatProp(AObj, Prop.Name, Value.AsSingle);
      ptDouble: TypInfo.SetFloatProp(AObj, Prop.Name, Value.AsDouble);

      ptShortString: TypInfo.SetStrProp(AObj, Prop.Name, Value.AsShortString);
      ptAnsiString: TypInfo.SetStrProp(AObj, Prop.Name, Value.AsAnsiString);
      ptString: TypInfo.SetStrProp(AObj, Prop.Name, Value.AsUnicodeString);

      ptPointer: ;
      ptObjectLink: begin
        if ((Value.LinkedClass <> nil) and (Value.Linked is Value.LinkedClass)) or (Value.Linked is TCEAbstractEntity) then
          TypInfo.SetObjectProp(AObj, Prop.Name, Value.Linked)
        else
          if AObj is TCEAbstractEntity then
            TCEAbstractEntity(AObj).SetObjectLink(Prop.Name, Value.AsAnsiString)
          else
            raise ECEPropertyError.Create('Class doesn''t support object links: ' + string(AObj.ClassName));
      end;
      ptBinary: begin
        TypInfo.SetObjectProp(AObj, Prop.Name, Value.AsData);
        Value.AsData.Bound := True;
      end;
      ptObject: ;
      ptClass: ;
      else
        raise ECEPropertyError.Create('Unsupported property type: ' + TypInfo.GetEnumName(TypeInfo(TCEPropertyType), Ord(Prop.TypeId)));
    end;
  end;
end;
{$WARNINGS ON}

end.

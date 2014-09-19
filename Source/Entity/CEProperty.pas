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
  CEBaseTypes, CETemplate, CERttiUtil;

type
  // Type for property names
  TPropertyName = AnsiString;

     // Possible property types
    TCEPropertyType = (
      // Boolean value
      ptBoolean,
      // Unsigned 32-bit integer (natural) value
      ptNatural,
      // 32-bit integer value
      ptInteger,
      // 64-bit integer value
      ptInt64,
      // Single-precision floating-point value
      ptSingle,
      // Double-precision floating-point value
      ptDouble,
      // Unicode character
      ptChar,
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
      ptObject
    );

    PCEPropertyValue = ^TCEPropertyValue;
    // Data structure representing a property value
    TCEPropertyValue = packed record
      AsUnicodeString: UnicodeString;
      asAnsiString: AnsiString;
      // Property value as various type
      case t: TCEPropertyType of
        ptInteger, ptEnumeration, ptSet: (AsInteger: Integer);
        ptInt64: (AsInt64: Int64);
        ptChar: (AsChar: Char);
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
    function PropByIndex(Index: Integer): PCEProperty;
    function ValueByIndex(Index: Integer): PCEPropertyValue;
    function GetProperty(const Name: TPropertyName): TCEProperty;
    procedure SetProperty(const Name: TPropertyName; const Prop: TCEProperty);
    function GetValue(const Name: TPropertyName): TCEPropertyValue;
    procedure SetValue(const Name: TPropertyName; const Value: TCEPropertyValue);
    function GetCount: Integer;
  public
    // Creates an empty property collection
    constructor Create(); overload;
    // Destroys the property collection
    destructor Destroy; override;

    // Add property description
    procedure AddProp(const Name: TPropertyName; TypeId: TCEPropertyType);

    procedure AddString(const Name: TPropertyName; const Value: string);
    procedure AddInt(const Name: TPropertyName; const Value: Integer);
    procedure AddSingle(const Name: TPropertyName; const Value: Single);

    // Property definitions
    property Prop[const Name: TPropertyName]: TCEProperty read GetProperty write SetProperty;
    // Property values
    property Value[const Name: TPropertyName]: TCEPropertyValue read GetValue write SetValue; default;
    // Number of properties
    property Count: Integer read GetCount;
  end;

  TFiler = class
  private
    F: file;
    Opened: Boolean;
  public
    destructor Destroy(); override;
  end;

  TWriter = class(TFiler)
  private
    function WriteCheck(const Buffer; const Count: Cardinal): Boolean;
  public
    constructor Create(const FileName: string);
    // Writes the properties to a stream and return True if success
    function Write(Properties: TCEProperties): Boolean; virtual;
  end;

  TReader = class(TFiler)
  private
    function ReadCheck(out Buffer; const Count: Cardinal): Boolean;
  public
    constructor Create(const FileName: string);
    // Reads the properties from a stream and return True if success
    function Read(Properties: TCEProperties): Boolean; virtual;
  end;

implementation

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

function TCEProperties.PropByIndex(Index: Integer): PCEProperty;
begin
  Result := FProperties.GetPtr(Index); //TODO: handle non existing name
end;

function TCEProperties.ValueByIndex(Index: Integer): PCEPropertyValue;
begin
  Result := @FValues[Index]; //TODO: handle non existing name
end;

function TCEProperties.GetProperty(const Name: TPropertyName): TCEProperty;
begin
  Result := PropByIndex(GetIndex(Name))^;
end;

procedure TCEProperties.SetProperty(const Name: TPropertyName; const Prop: TCEProperty);
begin

end;

function TCEProperties.GetValue(const Name: TPropertyName): TCEPropertyValue;
begin
  Result := ValueByIndex(GetIndex(Name))^;
end;

procedure TCEProperties.SetValue(const Name: TPropertyName; const Value: TCEPropertyValue);
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

procedure TCEProperties.AddInt(const Name: TPropertyName; const Value: Integer);
begin
  AddProp(Name, ptInteger);
end;

procedure TCEProperties.AddSingle(const Name: TPropertyName; const Value: Single);
begin
  AddProp(Name, ptSingle);
end;

{ TFiler }

destructor TFiler.Destroy;
begin
  if Opened then CloseFile(F);
  inherited;
end;

{ TWriter }

function TWriter.WriteCheck(const Buffer; const Count: Cardinal): Boolean;
var b: Integer;
begin
//  if not Opened then if not ErrorHandler(TStreamError.Create('File stream is not opened')) then Exit;
  BlockWrite(F, Buffer, Count, b);
  Result := b = Count;
end;

constructor TWriter.Create(const FileName: string);
begin
  AssignFile(F, FileName);
  Rewrite(F, 1);
  Opened := True;
end;

function TWriter.Write(Properties: TCEProperties): Boolean;
var
  i: Integer;
  Prop: PCEProperty;
  Value: PCEPropertyValue;
begin
  Result := WriteCheck(SIMPLE_PROPERTIES_BEGIN_SIGNATURE, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE));
  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.PropByIndex(i);
    Value := Properties.ValueByIndex(i);
    case Prop^.TypeId of
      ptInteger: Result := Result and WriteCheck(Value^.AsInteger, SizeOf(Value^.AsInteger));
      ptSingle: Result := Result and WriteCheck(Value^.AsSingle, SizeOf(Value^.AsSingle));
//      ptString: Result := Result and SaveString(Stream, Properties[i].Value);
      else Assert(False, 'Invalid property type');
    end;
  end;
  Result := Result and WriteCheck(SIMPLE_PROPERTIES_BEGIN_SIGNATURE, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE));
end;

{ TReader }

function TReader.ReadCheck(out Buffer; const Count: Cardinal): Boolean;
var b: Integer;
begin
  BlockRead(F, Buffer, Count, b);
  Result := b = Count;
end;

constructor TReader.Create(const FileName: string);
begin
  AssignFile(F, FileName);
  Reset(F);
  Opened := True;
end;

function TReader.Read(Properties: TCEProperties): Boolean;
var
  i: Integer;
  Sign: TSignature;
  Prop: PCEProperty;
  Value: PCEPropertyValue;
begin
  Result := False;
  if not ReadCheck(Sign, SizeOf(SIMPLE_PROPERTIES_BEGIN_SIGNATURE)) then Exit;
  if Sign <> SIMPLE_PROPERTIES_BEGIN_SIGNATURE then Exit;

  for i := 0 to Properties.Count-1 do
  begin
    Prop := Properties.PropByIndex(i);
    Value := Properties.ValueByIndex(i);
    case Prop^.TypeId of
      ptInteger: if not ReadCheck(Value^.AsInteger, SizeOf(Value^.AsInteger)) then Exit;
      ptSingle: if not ReadCheck(Value^.AsSingle, SizeOf(Value^.AsSingle)) then Exit;
//      ptString: Result := Result and SaveString(Stream, Properties[i].Value);
      else Assert(False, 'Invalid property type');
    end;
  end;

  if not ReadCheck(Sign, SizeOf(SIMPLE_PROPERTIES_END_SIGNATURE)) then Exit;
  if Sign <> SIMPLE_PROPERTIES_END_SIGNATURE then Exit;
  Result := True;
end;

end.

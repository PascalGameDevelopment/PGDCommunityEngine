(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEDataConverter.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE resource carrier unit)

The unit contains resource converters support facility

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEDataConverter;

interface

uses
  CEBaseTypes, CEEntity, CEResource, CEIO;

type
  // Variables of this type specifies resource format conversion
  TCEDataConversion = record
    // Source format
    SrcFormat: TCEFormat;
    // Destination format
    DestFormat: TCEFormat;
  end;

  // Package containing all information necessary to perform conversion
  TCEDataPackage = record
    // Data format
    Format: TCEFormat;
    // Pointer to actual data
    Data: Pointer;
    // Data size in bytes
    Size: Integer;
    // Various metadata
    Metadata: Pointer;
  end;

  // Abstract class descendants of which should convert resources
  TCEDataConverter = class
  protected
    // List of supported conversions
    FConversions: array of TCEDataConversion;
    // Should perform actual conversion
    function DoConvert(const Source: TCEDataPackage; var Destination: TCEDataPackage): Boolean; virtual; abstract;
    // Should fill FConversions
    procedure Init; virtual;
  public
    // Calls Init() and logs supported conversions
    constructor Create;
    // Returns True if the converter can perform the specified conversion
    function CanConvert(const Conversion: TCEDataConversion): Boolean;
    { Checks if the converter can perform the specified conversion and calls DoConvert.
      Returns True on success. }
    function Convert(const Source: TCEDataPackage; var Destination: TCEDataPackage): Boolean;
  end;

  // Returns class which can perform the specified conversion or nil if such a class was not registered
  function GetDataConverter(const Conversion: TCEDataConversion): TCEDataConverter;
  // Register a data converter class. The latter registered converters will override previously registered ones if those can handle same resource types.
  procedure RegisterDataConverter(const Converter: TCEDataConverter);

  // Creates a data package record
  function GetDataPackage(const Format: TCEFormat; Data: Pointer; Size: Integer; Metadata: Pointer = nil): TCEDataPackage;

implementation

uses
  SysUtils, CECommon, CETemplate;

type
  _VectorValueType = TCEDataConverter;
  _VectorSearchType = TCEDataConversion;
  {$MESSAGE 'Instantiating TCEDataConverters interface'}
  {$I tpl_coll_vector.inc}
  TCEDataConverters = _GenVector;

  const _VectorOptions = [];

  // Search callback. Returns True if the given converter can perform the specified conversion
  function _VectorFound(const v: TCEDataConverter; const Conversion: TCEDataConversion): Boolean; {$I inline.inc}
  begin
     Result := v.CanConvert(Conversion);
  end;
  {$MESSAGE 'Instantiating TCEDataConverters'}
  {$I tpl_coll_vector.inc}

function GetDataPackage(const Format: TCEFormat; Data: Pointer; Size: Integer; Metadata: Pointer = nil): TCEDataPackage;
begin
  Result.Format   := Format;
  Result.Data     := Data;
  Result.Size     := Size;
  Result.Metadata := Metadata;
end;

var
  LConverters: TCEDataConverters;

function GetDataConverter(const Conversion: TCEDataConversion): TCEDataConverter;
var i: Integer;
begin
  i := LConverters.FindLast(Conversion);
  if i >= 0 then
    Result := LConverters.Get(i)
  else
    Result := nil;  // TODO: log warning
end;

procedure RegisterDataConverter(const Converter: TCEDataConverter);
begin
  LConverters.Add(Converter);
end;

{ TCEDataConverter }

procedure TCEDataConverter.Init;
begin
  FConversions := nil;
end;

constructor TCEDataConverter.Create;
begin
  Init();
  // TODO: log types
end;

function TCEDataConverter.CanConvert(const Conversion: TCEDataConversion): Boolean;
var i: Integer;
begin
  i := High(FConversions);
  while (i >= 0) and
       ((FConversions[i].SrcFormat <> Conversion.SrcFormat) or (FConversions[i].DestFormat <> Conversion.DestFormat)) do
    Dec(i);
  Result := i >= 0;
end;

function TCEDataConverter.Convert(const Source: TCEDataPackage; var Destination: TCEDataPackage): Boolean;
begin
  Result := DoConvert(Source, Destination);
end;

end.


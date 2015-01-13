(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEDataDecoder.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE data decoder main unit)

The unit contains data decoder facility

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEDataDecoder;

interface

uses
  CEBaseTypes, CEEntity, CEIO;

type
    // Load target. In future it will be a structure to support multiple targets.
  TCELoadTarget = Pointer;

  // Array of resource type IDs
  TDataTypeList = array of TCEDataTypeID;

  // Abstract class descendants of which should decode data o various types
  TCEDataDecoder = class
  protected
    // List of types the carrier can load
    FLoadingTypes: TDataTypeList;
    { Should perform actual resource decoding.
      If Entity is specified and its class is not supported by decoder an exception should be raised. }
    function DoDecode(Stream: TCEInputStream; var Entity: TCEBaseEntity;
                      const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean; virtual; abstract;
    // Should fill LoadingTypes
    procedure Init; virtual;
  public
    // Calls Init() and logs supported formats
    constructor Create;
    // Returns True if the carrier can load resources of the specified type
    function CanHandle(ResType: TCEDataTypeID): Boolean;
    { Decodes data in input stream and fills in entity metadata and binary data.
      If Entity is not specified the method creates a new instance of appropriate class.
      Some streams can contain multiple entities (e.g. mesh file).
      If MetadataOnly is True only metadata is loaded and binary data is not loaded.
      Returns True on success. }
    function Decode(Stream: TCEInputStream; var Entity: TCEBaseEntity;
                    const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean;
  end;

  // Returns class which can load resources of the specified type or nil if such a class was not registered
  function GetDataDecoder(const DataType: TCEDataTypeID): TCEDataDecoder;
  // Register a resource loader class. The latter registered carriers will override previously registered ones if those can handle same resource types.
  procedure RegisterDataDecoder(DataDecoder: TCEDataDecoder);

implementation

uses
  SysUtils, CECommon, CETemplate;

type
  _VectorValueType = TCEDataDecoder;
  _VectorSearchType = TCEDataTypeID;
  {$MESSAGE 'Instantiating TDataDecoders interface'}
  {$I tpl_coll_vector.inc}
  TDataDecoders = _GenVector;

  const _VectorOptions = [];

  // Search callback. Returns True if the given carrier can load resouces specified by Data.
  function _VectorFound(const v: TCEDataDecoder; const DataTypeID: TCEDataTypeID): Boolean; {$I inline.inc}
  begin
     Result := v.CanHandle(DataTypeID);
  end;

  {$MESSAGE 'Instantiating TDataDecoders'}
  {$I tpl_coll_vector.inc}

{ Resource linker }

var
  LDataDecoders: TDataDecoders;

function GetDataDecoder(const DataType: TCEDataTypeID): TCEDataDecoder;
var i: Integer;
begin
  i := LDataDecoders.FindLast(DataType);
  if i >= 0 then
    Result := LDataDecoders.Get(i)
  else
    Result := nil;  // TODO: log warning
end;

procedure RegisterDataDecoder(DataDecoder: TCEDataDecoder);
begin
  LDataDecoders.Add(DataDecoder);
end;

function GetResTypeFromExt(const ext: string): TCEDataTypeID;
var i: Integer;
begin
  Result.Bytes[0] := Ord('.');
  for i := 1 to High(Result.Bytes) do
    if i <= Length(ext) then
      Result.Bytes[i] := Ord(UpperCase(Copy(ext, i, 1))[1])
    else
      Result.Bytes[i] := Ord(' ');
end;

function GetResourceTypeIDFromUrl(const URL: string): TCEDataTypeID;
begin
  Result := GetResTypeFromExt(GetFileExt(URL));
end;

function GetFileNameFromURL(const URL: string): string;
var Ind: Integer;
begin
  Ind := Pos(CE_URL_TYPE_SEPARATOR, URL);
  if Ind <> 0 then
    Result := Copy(URL, Ind + 2, Length(URL))
  else
    Result := URL;
end;

function GetResourceModificationTime(const URL: string): TDateTime;
var FileName: string;
begin
  FileName := GetFileNameFromURL(URL);
  if FileExists(FileName) then
    Result := GetFileModifiedTime(FileName)
  else
    Result := 0;
end;

function GetResourceInputStream(const URL: string): TCEInputStream;
var FileName: string;
begin
  FileName := GetFileNameFromURL(URL);
  if FileExists(FileName) then
    Result := TCEFileInputStream.Create(FileName)
  else
    Result := nil;
end;

{ TCEResourceCarrier }

procedure TCEDataDecoder.Init;
begin
  FLoadingTypes := nil;
end;

constructor TCEDataDecoder.Create;
begin
  Init();
  // TODO: log types
end;

function TCEDataDecoder.CanHandle(ResType: TCEDataTypeID): Boolean;
var i: Integer;
begin
  i := High(FLoadingTypes);
  while (i >= 0) and (FLoadingTypes[i].DWord <> ResType.DWord) do Dec(i);
  Result := i >= 0;
end;

function TCEDataDecoder.Decode(Stream: TCEInputStream; var Entity: TCEBaseEntity;
                               const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean;
begin
  Result := DoDecode(Stream, Entity, Target, MetadataOnly);
end;

function FreeCallback(const e: TCEDataDecoder; Data: Pointer): Boolean;
begin
  if Assigned(e) then e.Free();
end;

initialization
  LDataDecoders := TDataDecoders.Create();
finalization
  LDataDecoders.ForEach(FreeCallback, nil);
  LDataDecoders.Free();
end.


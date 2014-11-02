(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEResourceCarrier.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE resource carrier unit)

The unit contains resource carriers support facility

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEResourceCarrier;

interface

uses
  CEBaseTypes, CEEntity, CEResource, CEIO;

const
  // A substring to separate URL type part in a resource URL
  CE_URL_TYPE_SEPARATOR = '://';

type
  // Variables of this type are resource type identifiers i.e. bitmap, .obj model, etc
  TCEResourceTypeID = TSignature;

  // Array of resource type IDs
  TResTypeList = array of TCEResourceTypeID;

  // Abstract class descendants of which should load resources of a certain class
  TCEResourceCarrier = class
  protected
    // List of types the carrier can load
    FLoadingTypes: TResTypeList;
    // Should perform actual resource load
    function DoLoad(Stream: TCEInputStream; const AURL: string; var Resource: TCEResource): Boolean; virtual; abstract;
    // Should fill LoadingTypes
    procedure Init; virtual;
  public
    // Calls Init() and logs supported formats
    constructor Create;
    // Returns True if the carrier can load resources of the specified type
    function CanLoad(ResType: TCEResourceTypeID): Boolean;
    // Returns resource class which the carrier can handle
    function GetResourceClass: CCEEntity; virtual; abstract;
    { Checks if class of the resource matches type of the data stream and calls DoLoad() to load the resource.
      If Resource is nil the function creates a new resource of appropriate class.
      Some streams can contain multiple resources and even other items (e.g. mesh file).
      Carriers which handles those kind of resources can create hierarchies of items.
      For this Resource.Manager should be assigned. Otherwise only Resource data will be loaded.
      Returns True on success. }
    function Load(Stream: TCEInputStream; const AURL: string; var Resource: TCEResource): Boolean;
  end;

  // Returns class which can load resources of the specified type or nil if such a class was not registered
  function GetResourceLoader(const ResType: TCEResourceTypeID): TCEResourceCarrier;
  // Register a resource loader class. The latter registered carriers will override previously registered ones if those can handle same resource types.
  procedure RegisterCarrier(Carrier: TCEResourceCarrier);
  function GetResourceTypeIDFromUrl(const URL: string): TCEResourceTypeID;
  function GetFileNameFromURL(const URL: string): string;
  function GetResourceModificationTime(const URL: string): TDateTime;
  function GetResourceInputStream(const URL: string): TCEInputStream;

implementation

uses
  SysUtils, CECommon, CETemplate;

type
  _VectorValueType = TCEResourceCarrier;
  _VectorSearchType = TCEResourceTypeID;
  {$MESSAGE 'Instantiating TCEResourceCarriers interface'}
  {$I tpl_coll_vector.inc}
  TCEResourceCarriers = _GenVector;

  const _VectorOptions = [];

  // Search callback. Returns True if the given carrier can load resouces specified by Data.
  function _VectorFound(const v: TCEResourceCarrier; ResourceTypeID: TCEResourceTypeID): Boolean; {$I inline.inc}
  begin
     Result := v.CanLoad(ResourceTypeID);
  end;
  {$MESSAGE 'Instantiating TCEResourceCarriers'}
  {$I tpl_coll_vector.inc}


{ Resource linker }

var
  LCarriers: TCEResourceCarriers;

function GetResourceLoader(const ResType: TCEResourceTypeID): TCEResourceCarrier;
var i: Integer;
begin
  i := LCarriers.Search(ResType);
  if i >= 0 then
    Result := LCarriers.Get(i)
  else
    Result := nil;  // TODO: log warning
end;

procedure RegisterCarrier(Carrier: TCEResourceCarrier);
begin
  LCarriers.Add(Carrier);
end;

function GetResTypeFromExt(const ext: string): TCEResourceTypeID;
var i: Integer;
begin
  Result.Bytes[0] := Ord('.');
  for i := 1 to High(Result.Bytes) do
    if i <= Length(ext) then
      Result.Bytes[i] := Ord(UpperCase(Copy(ext, i, 1))[1])
    else
      Result.Bytes[i] := Ord(' ');
end;

function GetResourceTypeIDFromUrl(const URL: string): TCEResourceTypeID;
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

procedure TCEResourceCarrier.Init;
begin
  FLoadingTypes := nil;
end;

constructor TCEResourceCarrier.Create;
begin
  Init();
  // TODO: log types
end;

function TCEResourceCarrier.CanLoad(ResType: TCEResourceTypeID): Boolean;
var i: Integer;
begin
  i := High(FLoadingTypes);
  while (i >= 0) and (FLoadingTypes[i].DWord <> ResType.DWord) do Dec(i);
  Result := i >= 0;
end;

function TCEResourceCarrier.Load(Stream: TCEInputStream; const AURL: string; var Resource: TCEResource): Boolean;
begin
  Result := False;
  if not Assigned(Resource) then
  begin
    Resource := GetResourceClass.Create() as TCEResource;
    //Resource.Name := GetResourceName(GetFileNameFromURL(AURL));
  end;
  if not (Resource is GetResourceClass) then
  begin
    //Log(Format('%S.%S: incompatible classes "%s" and "%s"', [ClassName, 'Load', Resource.ClassName, GetResourceClass.ClassName]), lkError);
    Exit;
  end;
  Result := DoLoad(Stream, AURL, Resource);
end;

end.


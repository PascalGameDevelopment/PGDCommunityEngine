(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEResource.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE base resource entity unit)

Base resource entity, loader, converter classes and linker facility

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEResource;

interface

uses
  CEBaseTypes, CEEntity, CEIO, CEProperty;

type
  // Resource format type
  TCEFormat = Cardinal;

  // Base resource class for all resources: texts, images, textures, shaders, sounds, etc
  TCEResource = class(TCEBaseEntity)
  private
    FLoaded: Boolean;
    FExternal: Boolean;
    FFormat: TCEFormat;
    FDataHolder: TPointerData;
    DataOffsetInStream: Integer;
    FCarrierURL: string;
    FLastModified: TDateTime;
    function GetData: Pointer;
    procedure SetDataHolder(const Value: TPointerData);
    function SaveToCarrier: Boolean;
    function LoadFromCarrier(NewerOnly: Boolean): Boolean;
    procedure SetCarrierURL(const Value: string);
  public
    // Performs conversion from old format to a new one and return True if the conversion is possible and successful
    function Convert(const OldFormat, NewFormat: TCEFormat): Boolean;

    property Data: Pointer read GetData;
  published
    property DataHolder: TPointerData read FDataHolder write SetDataHolder;
    property CarrierURL: string read FCarrierURL write SetCarrierURL;
  end;

  // Base class for resource convertor
  TCEBaseResourceConverter = class
  public
    function CanConvert(const OldFormat, NewFormat: TCEFormat): Boolean; virtual; abstract;
    function Convert(const Resource: TCEResource; const NewFormat: TCEFormat): Boolean; virtual; abstract;
  end;

  // Variables of this type are resource type identifiers i.e. bitmap, .obj model, etc
  TCEResourceTypeID = TSignature;

  // Array of resource type IDs
  TResTypeList = array of TCEResourceTypeID;

  // Abstract class descendants of which should load resources of a certain class
  TCEResourceLoader = class
  protected
    // List of types the carrier can load
    LoadingTypes: TResTypeList;
    // Sets carrier URL for the specified resource without trying to load it immediately
    procedure SetCarrierURL(AResource: TCEResource; const ACarrierURL: string);
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
    function Load(Stream: TCEInputStream; const AURL: string; var Resource: TCEResource   ): Boolean;
  end;

implementation

type
  // Singleton class which registers and manages carriers classes for various resource types
  TResourceLinker = class
  private
    FCarriers: array of TCEResourceLoader;
  public
    constructor Create;
    destructor Destroy; override;
    // Returns carrier class which can load resources of the specified type or nil if such a carrier was not registered
    function GetLoader(const ResType: TCEResourceTypeID): TCEResourceLoader;
    // Adds a registered carrier. The latter registered carriers will override previously registered ones if those can handle same resource types
    procedure RegisterCarrier(Carrier: TCEResourceLoader);
  end;


{ TCEResource }

function TCEResource.GetData: Pointer;
begin

end;

procedure TCEResource.SetDataHolder(const Value: TPointerData);
begin
  FDataHolder := Value;
end;

function TCEResource.SaveToCarrier: Boolean;
begin

end;


function TCEResource.LoadFromCarrier(NewerOnly: Boolean): Boolean;
begin

end;


procedure TCEResource.SetCarrierURL(const Value: string);
begin

end;

function TCEResource.Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
begin

end;

end.

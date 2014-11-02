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
  public
    // Loads resource specified by CarrierURL using resource carriers facility and returns True if success
    function LoadFromCarrier(NewerOnly: Boolean): Boolean;
    // Performs conversion from old format to a new one and return True if the conversion is possible and successful
    function Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
    // Pointer to resource data
    property Data: Pointer read GetData;
  published
    // Binary data holder instance
    property DataHolder: TPointerData read FDataHolder write SetDataHolder;
    //
    property CarrierURL: string read FCarrierURL write FCarrierURL;
  end;

  // Base class for resource convertor
  TCEBaseResourceConverter = class
  public
    function CanConvert(const OldFormat, NewFormat: TCEFormat): Boolean; virtual; abstract;
    function Convert(const Resource: TCEResource; const NewFormat: TCEFormat): Boolean; virtual; abstract;
  end;

implementation

uses CEResourceCarrier;

{ TCEResource }

function TCEResource.GetData: Pointer;
begin
  Result := FDataHolder.Data;
end;

procedure TCEResource.SetDataHolder(const Value: TPointerData);
begin
  FDataHolder := Value;
end;


function TCEResource.LoadFromCarrier(NewerOnly: Boolean): Boolean;
var
  LCarrier: TCEResourceCarrier;
  Stream: TCEInputStream;
  CarrierModified: TDateTime;
begin
  Result := False;
  if FCarrierURL = '' then Exit;
  LCarrier := CEResourceCarrier.GetResourceLoader(GetResourceTypeIDFromUrl(FCarrierURL));
  if not Assigned(LCarrier) then
  begin
    //Log(ClassName + '.LoadFromCarrier: No appropriate loader found for URL: "' + FCarrierURL + '"', lkWarning);
    Exit;
  end;
  CarrierModified := GetResourceModificationTime(FCarrierURL);
  if NewerOnly and (CarrierModified <= FLastModified) then
  begin
    //Log(' *** Resource: ' + DateTimeToStr(FLastModified) + ', carrier: ' + DateTimeToStr(CarrierModified), lkDebug);
    Exit;
  end;
  FLastModified := CarrierModified;

  try
    Stream := GetResourceInputStream(FCarrierURL);
    if not Assigned(Stream) then
    begin
      // Log
    end;
    Result := LCarrier.Load(Stream, FCarrierURL, Self);
    //if Result then SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
  finally
    Stream.Free();
  end;
end;


procedure TCEResource.SetCarrierURL(const Value: string);
begin

end;

function TCEResource.Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
begin

end;

end.

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
    FDataURL: string;
    FLastModified: TDateTime;
    function GetData: Pointer;
    procedure SetDataHolder(const Value: TPointerData);
  protected
    { Returns resource size in bytes when it is stored.
     For some types (e.g. image with generated mip maps) stored size can be less than regular size. }
    function GetStoredDataSize: Integer; virtual;
    // Allocates an empty data buffer or changes allocated size of an existing one using realloc
    procedure Allocate(ASize: Integer);
    // Sets already allocated and probably ready to use data
    procedure SetAllocated(ASize: Integer; AData: Pointer);
  public
    // Attempts to load resource data specified by DataURL using resource carriers facility and returns True if success
    function LoadFromCarrier(NewerOnly: Boolean): Boolean;
    // Performs conversion from old format to a new one using data converters facility.
    // Return True if the conversion was successful.
    function Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
    // Pointer to resource data
    property Data: Pointer read GetData;
  published
    // Resource data format
    property Format: TCEFormat read FFormat;
    // Binary data holder instance
    property DataHolder: TPointerData read FDataHolder write SetDataHolder;
    // External data URL
    property DataURL: string read FDataURL write FDataURL;
  end;

implementation

uses
  SysUtils, CEResourceCarrier, CEDataConverter;

{ TCEResource }

function TCEResource.GetData: Pointer;
begin
  Result := FDataHolder.Data;
end;

procedure TCEResource.SetDataHolder(const Value: TPointerData);
begin
  FDataHolder := Value;
end;

function TCEResource.GetStoredDataSize: Integer;
begin
  Result := FDataHolder.Size;
end;

procedure TCEResource.Allocate(ASize: Integer);
var OldData: Pointer;
begin
  if (ASize = FDataHolder.Size) and (FDataHolder.Data <> nil) then Exit;
  OldData := FDataHolder.Data;
  ReallocMem(FDataHolder.Data, ASize);
  FDataHolder.Size := ASize;
  FLoaded := True;
  //if Assigned(FManager) and (FData <> OldData) then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, OldData <> nil), nil, [mfCore, mfBroadcast]);
end;

procedure TCEResource.SetAllocated(ASize: Integer; AData: Pointer);
var OldData: Pointer;
begin
  Assert((ASize = 0) or Assigned(AData));
  OldData := FDataHolder.Data;
  FDataHolder.Size := ASize;
  if (FDataHolder.Data <> AData) and (FDataHolder.Data <> nil) then FreeMem(FDataHolder.Data);
  FDataHolder.Data := AData;
  FLoaded := True;
  FLastModified := Now;
  //if Assigned(FManager) and (FDataHolder.Data <> OldData) then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, True), nil, [mfCore, mfBroadcast]);
end;

function TCEResource.LoadFromCarrier(NewerOnly: Boolean): Boolean;
var
  LCarrier: TCEResourceCarrier;
  Stream: TCEInputStream;
  CarrierModified: TDateTime;
begin
  Result := False;
  if FDataURL = '' then Exit;
  LCarrier := CEResourceCarrier.GetResourceLoader(GetResourceTypeIDFromUrl(FDataURL));
  if not Assigned(LCarrier) then
  begin
    //Log(ClassName + '.LoadFromCarrier: No appropriate loader found for URL: "' + FDataURL + '"', lkWarning);
    Exit;
  end;
  CarrierModified := GetResourceModificationTime(FDataURL);
  if NewerOnly and (CarrierModified <= FLastModified) then
  begin
    //Log(' *** Resource: ' + DateTimeToStr(FLastModified) + ', carrier: ' + DateTimeToStr(CarrierModified), lkDebug);
    Exit;
  end;
  FLastModified := CarrierModified;

  try
    Stream := GetResourceInputStream(FDataURL);
    if not Assigned(Stream) then
    begin
      // Log
    end;
    Result := LCarrier.Load(Stream, FDataURL, Self);
    //if Result then SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
  finally
    Stream.Free();
  end;
end;

function TCEResource.Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
var
  Conversion: TCEDataConversion;
  Converter: TCEDataConverter;
  Dest: TCEDataPackage;
begin
  Conversion.SrcFormat := OldFormat;
  Conversion.DestFormat := NewFormat;
  Converter := CEDataConverter.GetDataConverter(Conversion);
  if not Assigned(Converter) then
  begin
    // TODO: log
    Exit;
  end;

  Dest := GetDataPackage(NewFormat, nil, 0);
  if Converter.Convert(GetDataPackage(FFormat, FDataHolder.Data, FDataHolder.Size, Self), Dest) then
  begin
  end else begin
    // TODO: log
  end;
end;

end.

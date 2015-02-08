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
  CEBaseTypes, CEEntity, CEIO, CEProperty, CEDataDecoder;

type
  // Resource format type
  TCEFormat = Cardinal;

  // Resource state
  TCEResourceState = (
    // Resource is invalid state (e.g. format was changed but data not yet changed)
    rsInvalid,
    // Resource is not loaded
    rsNotLoaded,
    // Resource is currently loading
    rsLoading,
    // Resource is loaded into memory
    rsMemory,
    // Resource is loaded into target (e.g. video memory for textures etc)
    rsTarget,
    // // Resource is loaded both into memory and target
    rsFull
  );

  { Base resource class for all resources: images, texts, shaders, sounds etc
    Data changes are not thread safe and should be synchronized. }
  TCEResource = class(TCEBaseEntity)
  private
    FState, _FState: TCEResourceState;
    FFormat, _FFormat: TCEFormat;
    FDataHolder, _FDataHolder: TPointerData;
    FDataURL, _FDataURL: string;
    FLastModified: TDateTime;
    function GetData: Pointer;
    procedure SetDataHolder(const Value: TPointerData);
  protected
    // Called from constructor
    procedure Init(); virtual;
    //procedure FlushChanges(); override;
    { Returns resource size in bytes when it is stored.
     For some types (e.g. image with generated mip maps) stored size can be less than regular size. }
    function GetStoredDataSize: Integer; virtual;
    // Allocates an empty data buffer or changes allocated size of an existing one using realloc
    procedure Allocate(ASize: Integer);
    // Sets already allocated and probably ready to use data
    procedure SetAllocated(ASize: Integer; AData: Pointer);
  public
    constructor Create();
    // Create and loads the resource from the specified URL
    constructor CreateFromUrl(const Url: string);
    destructor Destroy(); override;
    { Attempts to load resource data specified by DataURL using data loader and data decoder facilities and returns True if success.
      If NewerOnly is True resource will be loaded only if it was changed since last load.
      If Target is specified loading will be performed directly into Target bypassing Data field. }
    function LoadExternal(NewerOnly: Boolean; const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean;
    // Performs conversion from old format to a new one using data converters facility.
    // Return True if the conversion was successful.
    function Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
    // Pointer to resource data
    property Data: Pointer read GetData;
  published
    // Resource state
    property State: TCEResourceState read FState write FState;
    // Resource data format
    property Format: TCEFormat read FFormat write FFormat;
    // Binary data holder instance which stores data in memory
    property DataHolder: TPointerData read FDataHolder write SetDataHolder;
    // External data URL
    property DataURL: string read FDataURL write FDataURL;
  end;

  TCETextResource = class(TCEResource)
  private
    FTextData: TTextData;
    procedure SetDataHolder(const Value: TTextData);
    function GetText: AnsiString;
    procedure SetText(const Value: AnsiString);
  protected
    procedure Init(); override;
  public
    destructor Destroy(); override;
    procedure SetBuffer(Buf: PAnsiChar; Len: Integer);
    property Text: AnsiString read GetText write SetText;
  published
    property DataHolder: TTextData read FTextData write SetDataHolder;
  end;

  // For internal use
  procedure _SetResourceFormat(Resource: TCEResource; Format: TCEFormat);

implementation

uses
  SysUtils, CEDataLoader, CEDataConverter;

procedure _SetResourceFormat(Resource: TCEResource; Format: TCEFormat);
begin
  Resource.FFormat := Format;
end;

{ TCEResource }

function TCEResource.GetData: Pointer;
begin
  Result := FDataHolder.Data;
end;

procedure TCEResource.SetDataHolder(const Value: TPointerData);
begin
  FDataHolder := Value;
end;

procedure TCEResource.Init;
begin
  SetDataHolder(TPointerData.Create());
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
  FState := rsNotLoaded;
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
  FState := rsMemory;
  FLastModified := Now;
  //if Assigned(FManager) and (FDataHolder.Data <> OldData) then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, True), nil, [mfCore, mfBroadcast]);
end;

constructor TCEResource.Create;
begin
  inherited;
  Init();
end;

constructor TCEResource.CreateFromUrl(const Url: string);
begin
  Create();
  DataURL := Url;
  LoadExternal(False);
end;

destructor TCEResource.Destroy;
begin
  if Assigned(FDataHolder) then
    FreeAndNil(FDataHolder);
  inherited;
end;

function TCEResource.LoadExternal(NewerOnly: Boolean; const Target: TCELoadTarget = nil; MetadataOnly: Boolean = False): Boolean;
var
  Loader: TCEDataLoader;
  Decoder: TCEDataDecoder;
  Stream: TCEInputStream;
  ResourceModified: TDateTime;
  Entity: TCEBaseEntity;
begin
  Result := False;
  if FDataURL = '' then Exit;
  Loader := CEDataLoader.GetDataLoader(CEIO.GetProtocolFromUrl(FDataURL));
  if not Assigned(Loader) then
    raise ECEIOError.CreateFmt('No appropriate loader found for URL %s', [FDataUrl]);

  ResourceModified := Loader.GetResourceModificationTime(FDataURL);
  if NewerOnly and (ResourceModified <= FLastModified) then
  begin
    //Log(' *** Resource: ' + DateTimeToStr(FLastModified) + ', carrier: ' + DateTimeToStr(CarrierModified), lkDebug);
    Exit;
  end;
  FLastModified := ResourceModified;

  Decoder := CEDataDecoder.GetDataDecoder(GetDataTypeIDFromUrl(FDataURL));
  if not Assigned(Decoder) then
    raise ECEIOError.CreateFmt('No appropriate decoder found for URL %s', [FDataUrl]);

  Stream := nil;
  FState := rsLoading;
  try
    Stream := Loader.GetInputStream(FDataURL);
    if not Assigned(Stream) then
      raise ECEIOError.CreateFmt('Can''t obtain data stream by URL: ', [FDataURL]);

    //if Result then SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
    Entity := Self;
    if Assigned(Target) then begin
      Result := Decoder.Decode(Stream, Entity, Target, MetadataOnly);
      FState := rsTarget
    end else begin
      Result := Decoder.Decode(Stream, Entity, FDataHolder.Data);
      FState := rsMemory;
    end;
  finally
    if Assigned(Stream) then
      Stream.Free();
    if FState = rsLoading then
      FState := rsNotLoaded;
  end;
end;

function TCEResource.Convert(const OldFormat, NewFormat: TCEFormat): Boolean;
var
  Conversion: TCEDataConversion;
  Converter: TCEDataConverter;
  Dest: TCEDataPackage;
begin
  Result := True;
  if OldFormat = NewFormat then Exit;
  Result := False;

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
    Result := True;
  end else begin
    // TODO: log
  end;
end;

{ TCETextResource }

procedure TCETextResource.SetDataHolder(const Value: TTextData);
begin
  FTextData := Value;
end;

function TCETextResource.GetText: AnsiString;
begin
  if Assigned(FTextData) then
    Result := FTextData.Data
  else
    Result := '';
end;

procedure TCETextResource.SetText(const Value: AnsiString);
begin
  FTextData.Data := Value;
end;

procedure TCETextResource.Init;
begin
  inherited;
  SetDataHolder(TTextData.Create());
end;

destructor TCETextResource.Destroy;
begin
  if Assigned(FTextData) then
    FreeAndNil(FTextData);
  inherited;
end;

procedure TCETextResource.SetBuffer(Buf: PAnsiChar; Len: Integer);
begin
  FTextData.Data := '';
  SetString(FTextData.Data, Buf, Len);
end;

end.

(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEImageResampler.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE image resampling unit)

The unit contains image resampling support facility

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEImageResampler;

interface

uses
  CEBaseTypes, CEBaseImage;

type
  // Resample filter
  TResampleFilter = (// Simple and fast filter working only when image size is increased/decreased by N times where N is an integer value
                     rfSimple2X,
                     // Lanczos filter
                     rfLanczos,
                     raForceWord = $FFFF
                     );
  // Resample options
  TResampleOption = (// Allow resampler with another filter to be chosen when requested filter is not provided by any available resamples
                     roAllowFilterFallback,
                     // Included when resampler choosing failed and other resampling filter is suitable option
                     roIgnoreFilter
                     );
  // Resample option set
  TResampleOptions = set of TResampleOption;

  // Variables of this type specifies image resampling conversion
  TCEImageResample = packed record
    // Original image width
    SrcWidth,
    // Original image height
    SrcHeight,
    // Resampled image width
    DestWidth,
    // Resampled image height
    DestHeight: Integer;
    // Affected area on original image. If nil the whole image affected.
    Area: CEBaseTypes.PRect;
    // Image format
    Format: TCEPixelFormat;
    // Options
    Options: TResampleOptions;
    // Resampling filter
    Filter: TResampleFilter;
  end;

  // Abstract class descendants of which should convert resources
  TCEImageResampler = class
  protected
    // List of supported resamplings
    FResamples: array of TCEImageResample;
    // Should check resample parameters other than filter
    function DoCanResample(const Resample: TCEImageResample): Boolean; virtual;
    // Should perform actual resample
    function DoResample(const Resample: TCEImageResample; SrcData, DestData: Pointer): Boolean; virtual; abstract;
    // Should fill FResamples
    procedure Init; virtual;
  public
    // Calls Init() and logs supported resamplings
    constructor Create;
    // Returns True if the resampler can perform the specified resample
    function CanResample(const Resample: TCEImageResample): Boolean;
    { Checks if the resampler can perform the specified resample and calls DoResample.
      Returns True on success. }
    function Resample(const Resample: TCEImageResample; SrcData, DestData: Pointer): Boolean;
  end;

  // Returns class which can perform the specified resample or nil if such a class was not registered
  function GetImageResampler(const Resample: TCEImageResample): TCEImageResampler;
  // Register an image resampler class. The latter registered resamplers will override previously registered ones if those can handle same resamplings.
  procedure RegisterImageResampler(const Resampler: TCEImageResampler);

  // Creates a resample record
  function GetImageResample(SrcWidth, SrcHeight, DestWidth, DestHeight: Integer; Area: CEBaseTypes.PRect;
                            const Format: TCEPixelFormat; Options: TResampleOptions; Filter: TResampleFilter): TCEImageResample;

implementation

uses
  SysUtils, CECommon, CETemplate;

type
  _VectorValueType = TCEImageResampler;
  _VectorSearchType = TCEImageResample;
  {$MESSAGE 'Instantiating TImageResamplers interface'}
  {$I tpl_coll_vector.inc}
  TImageResamplers = _GenVector;

  const _VectorOptions = [];

  // Search callback. Returns True if the given resampler can perform the specified resample
  function _VectorFound(const v: TCEImageResampler; const Resample: TCEImageResample): Boolean; {$I inline.inc}
  begin
     Result := v.CanResample(Resample);
  end;
  {$MESSAGE 'Instantiating TImageResamplers'}
  {$I tpl_coll_vector.inc}

var
  LResamplers: TImageResamplers;

function GetImageResampler(const Resample: TCEImageResample): TCEImageResampler;
var i: Integer;
begin
  i := LResamplers.FindLast(Resample);
  if i >= 0 then
    Result := LResamplers.Get(i)
  else begin
    // TODO: log warning
    Result := nil;
  end;
end;

procedure RegisterImageResampler(const Resampler: TCEImageResampler);
begin
  LResamplers.Add(Resampler);
end;

function GetImageResample(SrcWidth, SrcHeight, DestWidth, DestHeight: Integer; Area: CEBaseTypes.PRect;
                          const Format: TCEPixelFormat; Options: TResampleOptions; Filter: TResampleFilter): TCEImageResample;
begin
  Result.SrcWidth   := SrcWidth;
  Result.SrcHeight  := SrcHeight;
  Result.DestWidth  := DestWidth;
  Result.DestHeight := DestHeight;
  Result.Area       := Area;
  Result.Format     := Format;
  Result.Options    := Options;
  Result.Filter     := Filter;
end;

{ TCEImageResampler }

function TCEImageResampler.DoCanResample(const Resample: TCEImageResample): Boolean;
begin
  Result := True;
end;

procedure TCEImageResampler.Init;
begin
  FResamples := nil;
end;

constructor TCEImageResampler.Create;
begin
  Init();
  // TODO: log types
end;

function TCEImageResampler.CanResample(const Resample: TCEImageResample): Boolean;
var i: Integer;
begin
  i := High(FResamples);
  while (i >= 0) and
       ((FResamples[i].Filter <> Resample.Filter) and not (roIgnoreFilter in Resample.Options)) and
       not DoCanResample(Resample) do
    Dec(i);
  Result := i >= 0;
end;

function TCEImageResampler.Resample(const Resample: TCEImageResample; SrcData, DestData: Pointer): Boolean;
begin
  Result := DoResample(Resample, SrcData, DestData);
end;

function FreeCallback(const e: TCEImageResampler; Data: Pointer): Boolean;
begin
  if Assigned(e) then e.Free();
end;

initialization
  LResamplers := TImageResamplers.Create();
finalization
  LResamplers.ForEach(FreeCallback, nil);
  LResamplers.Free();
end.


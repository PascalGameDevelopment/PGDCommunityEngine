(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEBaseImage.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE base image unit)

Base image types and utilities

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEBaseImage;

interface

uses
  CEBaseTypes;

const
  // Maximum of mip levels an image can have
  MAX_MIP_LEVELS = 32;

type
  // Known pixel formats for image data, textures and render targets (to be extended)
  TCEPixelFormat = (pfUndefined = 0,
                    pfR8G8B8  = 1,  pfA8R8G8B8 = 2,
                    pfR5G6B5  = 4,  pfR5G5B5   = 5,  pfA1R5G5B5 = 6,  pfA4R4G4B4 = 7,
                    pfA8      = 8,  pfA8P8     = 9,  pfP8       = 10, pfL8       = 11,
                    pfA8L8    = 12, pfA4L4     = 13,
                    pfB8G8R8  = 14, pfB8G8R8A8 = 15, pfA1B5G5R5 = 16,
                    pfD16     = 20, pfD24      = 21, pfD32      = 22,  pfD15S1   = 23, pfD24S8 = 24,
                    pfATIDF16 = 40, pfATIDF24  = 41,
                    pfDXT1    = 50, pfDXT3     = 51, pfDXT5     = 52
                    );

  // Image palette for paletted graphics file formats
  TPalette = array[0..255] of TCEColor;
  PPalette = ^TPalette;
  // Image origin
  TImageOrigin = (// Top-down image and its origin is the upper-left corner.
                  ioTopLeft,
                  // Bottom-up image and its origin is the lower-left corner
                  ioBottomLeft);
  // Image parameters data structure
  TImageHeader = record
    Format: TCEPixelFormat;
    LineSize: Integer;
    Width, Height: Integer;
    BitsPerPixel, ImageSize: Integer;
    ImageOrigin: TImageOrigin;
    PaletteSize: Cardinal;
    Palette: PPalette;
    Data: Pointer;
  end;

  // Image mip level record. Width, Height - level dimensions, Size - size of level data in bytes, Offset - offset of level data on bytes from top level data
  TImageLevel = record
    Width, Height: Integer;
    Size, Offset: Integer;
  end;
  PImageLevel = TImageLevel;
  // Image levels info
  TImageLevels = array[0..MAX_MIP_LEVELS - 1] of TImageLevel;
  PImageLevels = ^TImageLevels;

  // Mip (LOD) levels policy
  TMipPolicy = (// No mip levels used
                mpNoMips,
                // Mip levels are persistent and stored with image data
                mpPersistent,
                // Mip levels are generated and not stored
                mpGenerated);

  // Returns number of bits per pixel for the specified pixel format
  function GetBitsPerPixel(PixelFormat: TCEPixelFormat): Integer;

  //
  function GetSuggestedMipLevelsInfo(Width, Height: Integer; const Format: TCEPixelFormat; const Levels: PImageLevels): Integer;

implementation

uses
  CECommon;

function GetBitsPerPixel(PixelFormat: TCEPixelFormat): Integer;
begin
  Result := 0;
  case PixelFormat of
    pfA8R8G8B8, pfD32, pfD24S8, pfD24, pfB8G8R8A8: Result := 32;
    pfR8G8B8, pfB8G8R8, pfATIDF24: Result := 24;
    pfR5G6B5, pfR5G5B5, pfA1R5G5B5, pfA4R4G4B4, pfA8P8, pfA8L8,
    pfD15S1, pfD16, pfA1B5G5R5, pfATIDF16: Result := 16;
    pfA8, pfP8, pfL8, pfA4L4: Result := 8;
    pfDXT1: Result := 4;
    pfDXT3: Result := 8;
    pfDXT5: Result := 8;
    pfUndefined: ;
    else Assert(False, 'Unknown pixel format');
  end;
end;

function GetSuggestedMipLevelsInfo(Width, Height: Integer; const Format: TCEPixelFormat; const Levels: PImageLevels): Integer;
var MaxDim: Integer;
begin
  Levels^[0].Width  := Width;
  Levels^[0].Height := Height;
  Levels^[0].Size   := Levels^[0].Width * Levels^[0].Height * GetBitsPerPixel(Format) * BITS_IN_BYTE;
  Levels^[0].Offset := 0;

  Result := 1;
  MaxDim := MaxI(Width, Height);
  while MaxDim > 1 do
  begin
    Levels^[Result].Width  := MaxI(1, Levels^[Result-1].Width  div 2);
    Levels^[Result].Height := MaxI(1, Levels^[Result-1].Height div 2);
    Levels^[Result].Offset := Levels^[Result-1].Offset + Levels^[Result-1].Size;
    Levels^[Result].Size   := Levels^[Result].Width * Levels^[Result].Height * GetBitsPerPixel(Format) * BITS_IN_BYTE;
    Inc(Result);
    MaxDim := MaxDim div 2;
    Assert(Result < MAX_MIP_LEVELS);
  end;
end;

end.


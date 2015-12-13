(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEAndroidAssets.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2015 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Android assets wrapper)
The unit contains Android native assets API wrapper

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEAndroidAssets;

interface

uses
  CEIO, CEDataLoader,
  jni;

type
  PAAssetManager = Pointer;
  PAAssetDir = Pointer;
  PAAsset = Pointer;

  TCEAndroidAssetInputStream = class(TCEInputStream)
  private
    Asset: PAAsset;
  protected
    function GetSize(): Int64; override;
  public
    // Creates input stream of asset identified by the name
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; Mode: Cardinal); overload;
    // Closes asset
    procedure Close; override;
    function Read(var Buffer; const Count: Cardinal): Cardinal; override;
  end;

  TCEAndroidAssetLoader = class(TCEDataLoader)
  protected
    function DoGetInputStream(const AURL: string): TCEInputStream; override;
    procedure Init; override;
  public
    function GetResourceModificationTime(const AURL: string): TDateTime; override;
  end;

  // Initializes native asset manager object with the given VM and AssetManager instance retrieved from Java side
  procedure InitAssetManager(PEnv: PJNIEnv; assetManager: JObject);

const
  libname = 'libandroid.so';

  // Available modes for opening assets
  // No specific information about how data will be accessed.
  AASSET_MODE_UNKNOWN   = 0;
  // Read chunks, and seek forward and backward.
  AASSET_MODE_RANDOM    = 1;
  // Read sequentially, with an occasional forward seek.
  AASSET_MODE_STREAMING = 2;
  // Caller plans to ask for a read-only buffer with all data.
  AASSET_MODE_BUFFER    = 3;

{ Open the named directory within the asset hierarchy.
  The directory can then be inspected with the AAssetDir functions.
  To open the top-level directory,  pass in "" as the dirName.
  The object returned here should be freed by calling AAssetDir_close(). }
  function AAssetManager_openDir(mgr: PAAssetManager; dirName: Pchar): PAAssetDir; cdecl; external libname;

{ Open an asset.
  The object returned here should be freed by calling AAsset_close(). }
  function AAssetManager_open(mgr: PAAssetManager; filename: Pchar; mode: Integer): PAAsset; cdecl; external libname;

{ Iterate over the files in an asset directory.
  A NULL string is returned when all the file names have been returned.
  The returned file name is suitable for passing to AAssetManager_open().
  The string returned here is owned by the AssetDir implementation and is not guaranteed
  to remain valid if any other calls are made on this AAssetDir instance. }
  function AAssetDir_getNextFileName(assetDir: PAAssetDir): Pchar; cdecl; external libname;

{ Reset the iteration state of AAssetDir_getNextFileName() to the beginning. }
  procedure AAssetDir_rewind(assetDir: PAAssetDir); cdecl; external libname;

{ Close an opened AAssetDir, freeing any related resources. }
  procedure AAssetDir_close(assetDir: PAAssetDir); cdecl; external libname;

{ Attempt to read 'count' bytes of data from the current offset.
  Returns the number of bytes read, zero on EOF, or < 0 on error. }
  function AAsset_read(asset: PAAsset; buf: Pointer; count: Cardinal): Integer; cdecl; external libname;

{ Seek to the specified offset within the asset data. 'whence' uses the same constants as lseek()/fseek().
  Returns the new position on success, or (off_t) -1 on error. }
  function AAsset_seek(asset: PAAsset; offset: Int64; whence: Cardinal): Int64; cdecl; external libname;

{ Close the asset, freeing all associated resources. }
  procedure AAsset_close(asset: PAAsset); cdecl; external libname;

{ Get a pointer to a buffer holding the entire contents of the assset.
  Returns NULL on failure. }
  function AAsset_getBuffer(asset: PAAsset): Pointer; cdecl; external libname;

{ Report the total size of the asset data. }
  function AAsset_getLength(asset: PAAsset): Int64; cdecl; external libname;

{ Report the total amount of asset data that can be read from the current position. }
  function AAsset_getRemainingLength(asset: PAAsset): Int64; cdecl; external libname;

{ Open a new file descriptor that can be used to read the asset data.
  Returns < 0 if direct fd access is not possible (for example, if the asset is compressed). }
  function AAsset_openFileDescriptor(asset: PAAsset; var outStart, outLength: Int64): Integer; cdecl; external libname;

  // Returns whether this asset's internal buffer is allocated in ordinary RAM (i.e. not mmapped).
  function AAsset_isAllocated(asset: PAAsset): Integer; cdecl; external libname;

{ Given a Dalvik AssetManager object, obtain the corresponding native AAssetManager object.
  Note that the caller is responsible for obtaining and holding a VM reference to the jobject
  to prevent its being garbage collected while the native object is in use. }
  function AAssetManager_fromJava(Env: PJNIEnv; assetManager: JObject): PAAssetManager; cdecl; external libname;

implementation

uses
  CELog;

const
  LOGTAG = 'ce.android.assets';

var
  Manager: PAAssetManager;

{ TCEAndroidAssetInputStream }

function TCEAndroidAssetInputStream.GetSize(): Int64;
begin
  Result := AAsset_getLength(Asset);
end;

constructor TCEAndroidAssetInputStream.Create(const AName: string); overload;
begin
  Create(AName, AASSET_MODE_STREAMING);
end;

constructor TCEAndroidAssetInputStream.Create(const AName: string; Mode: Cardinal); overload;
begin
  Asset := AAssetManager_open(Manager, PChar(AName), Mode);
end;

procedure TCEAndroidAssetInputStream.Close;
begin
  if Assigned(Asset) then
    AAsset_close(Asset);
end;

function TCEAndroidAssetInputStream.Read(var Buffer; const Count: Cardinal): Cardinal;
var
  Res: Integer;
begin
  Res := AAsset_read(Asset, Pointer(Buffer), Count);
  if Res >= 0 then
    Result := Res
  else
    Result := 0;
end;

{ TCEAndroidAssetLoader }

function TCEAndroidAssetLoader.DoGetInputStream(const AURL: string): TCEInputStream;
begin
  Result := TCEAndroidAssetInputStream.Create(GetPathFromURL(AURL));
end;

procedure TCEAndroidAssetLoader.Init;
begin
  SetLength(FProtocols, 1);
  FProtocols[0] := 'asset';
end;

function TCEAndroidAssetLoader.GetResourceModificationTime(const AURL: string): TDateTime;
begin
  Result := 0;
end;

procedure InitAssetManager(PEnv: PJNIEnv; AssetManager: JObject);
begin
  CELog.Debug(LOGTAG, 'Obtaining asset manager');
  Manager := AAssetManager_fromJava(PEnv, AssetManager);
end;

initialization
  RegisterDataLoader(TCEFileAssetLoader.Create());
end.

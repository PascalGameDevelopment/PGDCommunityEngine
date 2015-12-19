(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEIO.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(Base input/output unit)

The unit contains common input/output classes

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEIO;

interface

uses CEBaseTypes;

const
  // A substring to separate URL type part in a resource URL
  CE_URL_TYPE_SEPARATOR = '://';
  // File protocol (default)
  PROTOCOL_FILE = 'file';
  // Protocol to query assets which location is platform dependent
  PROTOCOL_ASSET = 'asset';

type
  { @Abstract(Abstract binary stream) }
  TCEStream = class
  protected
    FPosition: Int64;
    FClosed: Boolean;
  public
    // Calls Close() before destruction
    destructor Destroy(); override;
    // Closes this stream and releases any system resources associated with the stream
    procedure Close(); virtual; abstract;
    // Current position within the stream in bytes
    property Position: Int64 read FPosition;
  end;

  { @Abstract(Abstract input binary stream) }
  TCEInputStream = class(TCEStream)
  protected
    // Returns stream size or -1 if not applicable/supported
    function GetSize(): Int64; virtual; abstract;
  public
    // Reads up to Count of bytes from this stream to Buffer, moves current position forward for number of bytes read and returns that number
    function Read(var Buffer; const Count: Cardinal): Cardinal; virtual; abstract;
    // Reads Count bytes from this stream to Buffer, moves current position forward for the number of bytes read and returns True if all the Count bytes were successfully read
    function ReadCheck(var Buffer; const Count: Cardinal): Boolean;
    property Size: Int64 read GetSize;
  end;

  { @Abstract(Abstract output binary stream) }
  TCEOutputStream = class(TCEStream)
  public
    // Writes up to Count bytes from Buffer to this stream, moves current position forward for the number of bytes written and returns that number
    function Write(const Buffer; const Count: Cardinal): Cardinal; virtual; abstract;
    // Writes Count bytes from Buffer to this stream, moves current position forward for the number of bytes written and returns True if all the Count bytes were successfully written
    function WriteCheck(const Buffer; const Count: Cardinal): Boolean;
  end;

  // File usage mode
  TCEFileUsage = (fuRead, fuWrite, fuReadWrite, fuAppend);

  TCEFileShare = (smAllowAll, smAllowRead, smExclusive);

  TCEFile = class
  private
    FFileName: string;
    FFileSize: Int64;
    FPosition: Int64;
    F: file;
    FClosed: Boolean;
  public
    constructor Create(const AFileName: string; const Usage: TCEFileUsage = fuReadWrite; const ShareMode: TCEFileShare = smAllowAll);
    function Seek(const NewPos: Int64): Boolean;
    // Closes file
    procedure Close;
    destructor Destroy; override;

    function Read(var Buffer; const Count: Cardinal): Cardinal;
    function Write(const Buffer; const Count: Cardinal): Cardinal;

    // Associated file name
    property Filename: string read FFileName;
  end;

  { @Abstract(File input stream)
    Provides input stream implementation for binary files }
  TCEFileInputStream = class(TCEInputStream)
  private
    FFile: TCEFile;
  protected
    function GetSize(): Int64; override;
  public
    // Creates a file stream associating it with file with the given file name
    constructor Create(const AFileName: string);
    // Frees FFile
    destructor Destroy(); override;
    // Closes file
    procedure Close; override;
    function Read(var Buffer; const Count: Cardinal): Cardinal; override;
  end;

  { @Abstract(File output stream)
  Provides output stream implementation for binary files }
  TCEFileOutputStream = class(TCEOutputStream)
  private
    FFile: TCEFile;
  public
    // Creates a file stream associating it with file with the given file name
    constructor Create(const AFileName: string; const ShareMode: TCEFileShare = smAllowAll);
    // Frees FFile
    destructor Destroy(); override;
    // Closes file
    procedure Close; override;
    function Write(const Buffer; const Count: Cardinal): Cardinal; override;
  end;

  ECEIOError = class(ECEError)
  public
    Code: Integer;
    constructor Create(ACode: Integer; AMsg: string);
  end;

  // Variables of this type are data type identifiers i.e. bitmap, .obj model, etc
  TCEDataTypeID = TSignature;

  function ReadShortString(InS: TCEInputStream; out Str: ShortString): Boolean;
  function WriteShortString(OutS: TCEOutputStream; const Str: ShortString): Boolean;
  function ReadAnsiString(InS: TCEInputStream; out Str: AnsiString): Boolean;
  function WriteAnsiString(OutS: TCEOutputStream; const Str: AnsiString): Boolean;
  function ReadUnicodeString(InS: TCEInputStream; out Str: UnicodeString): Boolean;
  function WriteUnicodeString(OutS: TCEOutputStream; const Str: UnicodeString): Boolean;

  function GetFileModifiedTime(const FileName: string): TDateTime;

  // Returns data type ID based on file extension
  function GetDataTypeFromExt(const ext: string): TCEDataTypeID;
  // Returns protocol part of URL
  function GetProtocolFromUrl(const URL: string): AnsiString;
  // Returns data type ID based on URL (extension part)
  function GetDataTypeIDFromUrl(const URL: string): TCEDataTypeID;
  // Returns path part of URL
  function GetPathFromURL(const URL: string): string;
  // Returns modification time of a resource by URL or 0 zero if not found or modification time is unsupported
  function GetResourceModificationTime(const URL: string): TDateTime;
  // Returns input stream for a resource specified by URL. Currently only local files supported.
  function GetResourceInputStream(const URL: string): TCEInputStream;

implementation

uses
  SysUtils, CECommon, CEContext;

  function ReadShortString(InS: TCEInputStream; out Str: ShortString): Boolean;
  var l: Byte;
  begin
    Result := InS.ReadCheck(l, SizeOf(l));
    if Result then
    begin
      SetLength(Str, l);
      if l > 0 then Result := InS.ReadCheck(Str[1], l);
    end;
  end;

  function WriteShortString(OutS: TCEOutputStream; const Str: ShortString): Boolean;
  begin
    Result := OutS.WriteCheck(Str[0], Length(Str)+1);
  end;

  function ReadAnsiString(InS: TCEInputStream; out Str: AnsiString): Boolean;
  var l: Cardinal;
  begin
    Result := InS.ReadCheck(l, SizeOf(l));
    if Result then
    begin
      SetLength(Str, l);
      if l > 0 then Result := InS.ReadCheck(Pointer(Str)^, l * SizeOf(AnsiChar));
    end;
  end;

  function WriteAnsiString(OutS: TCEOutputStream; const Str: AnsiString): Boolean;
  var l: Cardinal;
  begin
    l := Length(Str);
    Result := OutS.WriteCheck(l, SizeOf(l));
    if Result and (l > 0) then
      Result := OutS.WriteCheck(Pointer(Str)^, l * SizeOf(AnsiChar));
  end;

  function ReadUnicodeString(InS: TCEInputStream; out Str: UnicodeString): Boolean;
  var
    l: Cardinal;
    UTF8: UTF8String;
  begin
    Str := '';
    Result := InS.ReadCheck(l, SizeOf(l));
    if Result and (l > 0) then
    begin
      SetLength(UTF8, l);
      Result := InS.ReadCheck(Pointer(UTF8)^, l * SizeOf(AnsiChar));
      {$IFDEF UNICODE_STRING}
      Str := UTF8ToUnicodeString(UTF8);
      {$ELSE}
        {$IFDEF FPC}
        Str := UTF8Decode(UTF8);

        {$ELSE}
        Str := UTF8Decode(UTF8);

        {$ENDIF}
      {$ENDIF}
    end;
  end;

  function WriteUnicodeString(OutS: TCEOutputStream; const Str: UnicodeString): Boolean;
  var
    l: Cardinal;
    UTF8: UTF8String;
  begin
      UTF8 := UTF8Encode(Str);
      l := Length(UTF8);
      Result := OutS.WriteCheck(l, SizeOf(l));
      if Result and (l > 0) then
        Result := OutS.WriteCheck(Pointer(UTF8)^, l * SizeOf(AnsiChar));
  end;

function GetFileModifiedTime(const FileName: string): TDateTime;
var sr: TSearchRec;
begin
  Result := 0;
  if SysUtils.FindFirst(FileName, faDirectory, sr) = 0 then
  begin
    {$IFDEF HAS_FILE_TIMESTAMP}
      Result := sr.TimeStamp;
    {$ELSE}
      Result := SysUtils.FileDateToDateTime(sr.Time);
    {$ENDIF}
  end;
  SysUtils.FindClose(sr);
end;

function GetDataTypeFromExt(const ext: string): TCEDataTypeID;
var i: Integer;
begin
  Result.Bytes[0] := Ord('.');
  for i := 1 to High(Result.Bytes) do
    if i <= Length(ext) then
      Result.Bytes[i] := Ord(UpperCase(Copy(ext, i, 1))[1])
    else
      Result.Bytes[i] := Ord(' ');
end;

function GetProtocolFromUrl(const URL: string): AnsiString;
var Ind: Integer;
begin
  Ind := Pos(CE_URL_TYPE_SEPARATOR, URL);
  if Ind >= STRING_INDEX_BASE then
    Result := AnsiString(Copy(URL, STRING_INDEX_BASE, Ind-1))
  else
    Result := '';
end;

function GetDataTypeIDFromUrl(const URL: string): TCEDataTypeID;
begin
  Result := GetDataTypeFromExt(GetFileExt(URL));
end;

function GetPathFromURL(const URL: string): string;
var Ind: Integer;
begin
  Ind := Pos(CE_URL_TYPE_SEPARATOR, URL);
  if Ind >= STRING_INDEX_BASE then
    Result := Copy(URL, Ind + 3, Length(URL))
  else
    Result := URL;
end;

function GetResourceModificationTime(const URL: string): TDateTime;
var FileName: string;
begin
  FileName := GetPathFromURL(URL);
  if FileExists(FileName) then
    Result := GetFileModifiedTime(FileName)
  else
    Result := 0;
end;

function JoinPaths(const Path1, Path2: string): string;
begin
  Result := IncludeTrailingPathDelimiter(Path1) + ExcludeTrailingPathDelimiter(Path2);
end;

function GetResourceInputStream(const URL: string): TCEInputStream;
var
  Protocol: AnsiString;
  FileName: string;
  AssetsPath: string;
  Config: TCEConfig;
begin
  Protocol := GetProtocolFromUrl(URL);
  if (Protocol = '') or (Protocol = PROTOCOL_FILE) or (Protocol = PROTOCOL_ASSET) then
  begin
    FileName := GetPathFromURL(URL);
    if Protocol = PROTOCOL_ASSET then
    begin
      Config := CEContext.GetSingleton(TCEConfig) as TCEConfig;
      AssetsPath := Config['Path.Asset'];
      FileName := GetPathRelativeToFile(ParamStr(0), JoinPaths(AssetsPath, FileName));
    end;
    if FileExists(FileName) then
      Result := TCEFileInputStream.Create(FileName)
    else
      Result := nil;
  end else
    Raise ECEIOError.CreateFmt('Unknown protocol in URL: %s', [Protocol]);
end;

{ TCEStream }

destructor TCEStream.Destroy;
begin
  Close();
  inherited;
end;

{ TCEInputStream }

function TCEInputStream.ReadCheck(var Buffer; const Count: Cardinal): Boolean;
begin
  Result := Read(Buffer, Count) = Count;
end;

{ TCEOutputStream }

function TCEOutputStream.WriteCheck(const Buffer; const Count: Cardinal): Boolean;
begin
  Result := Write(Buffer, Count) = Count;
end;

{ TCEFile }

constructor TCEFile.Create(const AFileName: string; const Usage: TCEFileUsage = fuReadWrite; const ShareMode: TCEFileShare = smAllowAll);
var OldFileMode: Byte;
begin
  OldFileMode := FileMode;
  case ShareMode of
    smAllowAll: FileMode := 0;
    smAllowRead: FileMode := fmShareDenyWrite;
    smExclusive: FileMode := fmShareExclusive;
  end;
  FFileName := ExpandFileName(AFileName);
  AssignFile(F, FFileName);
  case Usage of
    fuRead: begin
      FileMode := FileMode or fmOpenRead;
      Reset(F, 1);
    end;
    fuReadWrite: begin
      FileMode := FileMode or fmOpenReadWrite;
      {$I-}
      Reset(F, 1);
      {$I+}
      if (IOResult <> 0) and not FileExists(FFileName) then Rewrite(F, 1);
    end;
    fuWrite: Rewrite(F, 1);
    fuAppend: if FileExists(FFileName) then
    begin
      FileMode := FileMode or fmOpenReadWrite;
      Reset(F, 1);
      FFileSize := FileSize(F);
      Seek(FFileSize);
    end else Rewrite(F, 1);
  end;

  FFileSize := FileSize(F);

  FileMode := OldFileMode;
end;

destructor TCEFile.Destroy;
begin
  Close();
  inherited;
end;

function TCEFile.Read(var Buffer; const Count: Cardinal): Cardinal;
begin
  BlockRead(F, Buffer, Count, Result);
  if Result > 0 then FPosition := FPosition + Result;
end;

function TCEFile.Write(const Buffer; const Count: Cardinal): Cardinal;
begin
  BlockWrite(F, Buffer, Count, Result);
  if Result > 0 then FPosition := FPosition + Result;
  FFileSize := FPosition;
end;

procedure TCEFile.Close;
begin
  if FClosed then Exit;
{$I-}
  CloseFile(F);
  FClosed := IOResult = 0;
end;

function TCEFile.Seek(const NewPos: Int64): Boolean;
begin
{$I-}
  System.Seek(F, NewPos);
  Result := IOResult = 0;
  if Result then FPosition := NewPos;
end;

{ TCEIOError }

constructor ECEIOError.Create(ACode: Integer; AMsg: string);
begin
  inherited Create(AMsg);
  Code := ACode;
end;

{ TCEFileInputStream }

function TCEFileInputStream.GetSize(): Int64;
begin
  Result := FFile.FFileSize;
end;

constructor TCEFileInputStream.Create(const AFileName: string);
begin
  FFile := TCEFile.Create(AFileName, fuRead);
end;

destructor TCEFileInputStream.Destroy;
begin
  FreeAndNil(FFile);
  inherited;
end;

procedure TCEFileInputStream.Close;
begin
  if Assigned(FFile) then FFile.Close();
end;

function TCEFileInputStream.Read(var Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FFile.Read(Buffer, Count);
end;

{ TCEFileOutputStream }

constructor TCEFileOutputStream.Create(const AFileName: string; const ShareMode: TCEFileShare);
begin
  FFile := TCEFile.Create(AFileName, fuWrite, ShareMode);
end;

destructor TCEFileOutputStream.Destroy;
begin
  FreeAndNil(FFile);
  inherited;
end;

procedure TCEFileOutputStream.Close;
begin
  if Assigned(FFile) then FFile.Close();
end;

function TCEFileOutputStream.Write(const Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FFile.Write(Buffer, Count);
end;

end.

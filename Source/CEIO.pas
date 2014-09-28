(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CECore.pas

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
  public
    // Reads up to Count of bytes from this stream to Buffer, moves current position forward for number of bytes read and returns that number
    function Read(out Buffer; const Count: Cardinal): Cardinal; virtual; abstract;
    // Reads Count bytes from this stream to Buffer, moves current position forward for the number of bytes read and returns True if all the Count bytes were successfully read
    function ReadCheck(out Buffer; const Count: Cardinal): Boolean;
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

    function Read(out Buffer; const Count: Cardinal): Cardinal;
    function Write(const Buffer; const Count: Cardinal): Cardinal;

    // Associated file name
    property Filename: string read FFileName;
  end;

  { @Abstract(File input stream)
    Provides input stream implementation for binary files }
  TCEFileInputStream = class(TCEInputStream)
  private
    FFile: TCEFile;
  public
    // Creates `a file stream associating it with file with the given file name
    constructor Create(const AFileName: string);
    // Closes file
    procedure Close; override;
    function Read(out Buffer; const Count: Cardinal): Cardinal; override;
  end;

  { @Abstract(File output stream)
  Provides output stream implementation for binary files }
  TCEFileOutputStream = class(TCEOutputStream)
  private
    FFile: TCEFile;
  public
    // Creates a file stream associating it with file with the given file name
    constructor Create(const AFileName: string; const ShareMode: TCEFileShare = smAllowAll);
    // Closes file
    procedure Close; override;
    function Write(const Buffer; const Count: Cardinal): Cardinal; override;
  end;

  ECEIOError = class(ECEError)
  public
    Code: Integer;
    constructor Create(ACode: Integer; AMsg: string);
  end;

  function ReadShortString(InS: TCEInputStream; out Str: ShortString): Boolean;
  function WriteShortString(OutS: TCEOutputStream; const Str: ShortString): Boolean;
  function ReadAnsiString(InS: TCEInputStream; out Str: AnsiString): Boolean;
  function WriteAnsiString(OutS: TCEOutputStream; const Str: AnsiString): Boolean;
  function ReadUnicodeString(InS: TCEInputStream; out Str: UnicodeString): Boolean;
  function WriteUnicodeString(OutS: TCEOutputStream; const Str: UnicodeString): Boolean;

implementation

uses SysUtils;

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
    {$IFDEF UNICODE}
    UTF8: UTF8String;
    {$ENDIF }
  begin
    Str := '';
    Result := InS.ReadCheck(l, SizeOf(l));
    if Result and (l > 0) then
    begin
      {$IFDEF UNICODE}
      SetLength(UTF8, l);
      Result := InS.ReadCheck(Pointer(UTF8)^, l * SizeOf(AnsiChar));
      Str := UTF8ToUnicodeString(UTF8);
      {$ELSE }
      SetLength(Str, l);
      Result := InS.ReadCheck(Pointer(Str)^, l * SizeOf(WideChar));
      {$ENDIF }
    end;
  end;

  function WriteUnicodeString(OutS: TCEOutputStream; const Str: UnicodeString): Boolean;
  var
    l: Cardinal;
    {$IFDEF UNICODE}
      UTF8: UTF8String;
    {$ENDIF }
  begin
    {$IFDEF UNICODE}
      UTF8 := UTF8Encode(Str);
      l := Length(UTF8);
      Result := OutS.WriteCheck(l, SizeOf(l));
      if Result and (l > 0) then
        Result := OutS.WriteCheck(Pointer(UTF8)^, l * SizeOf(AnsiChar));
    {$ELSE }
      l := Length(Str);
      Result := OutS.WriteCheck(l, SizeOf(l));
      if Result and (l > 0) then
        Result := OutS.WriteCheck(Pointer(Str)^, l * SizeOf(WideChar));
    {$ENDIF }
  end;

{ TCEStream }

destructor TCEStream.Destroy;
begin
  Close();
  inherited;
end;

{ TCEInputStream }

function TCEInputStream.ReadCheck(out Buffer; const Count: Cardinal): Boolean;
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

function TCEFile.Read(out Buffer; const Count: Cardinal): Cardinal;
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
  CloseFile(F);
  FClosed := True;
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

constructor TCEFileInputStream.Create(const AFileName: string);
begin
  FFile := TCEFile.Create(AFileName, fuRead);
end;

procedure TCEFileInputStream.Close;
begin
  FFile.Close();
end;

function TCEFileInputStream.Read(out Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FFile.Read(Buffer, Count);
end;

{ TCEFileOutputStream }

constructor TCEFileOutputStream.Create(const AFileName: string; const ShareMode: TCEFileShare);
begin
  FFile := TCEFile.Create(AFileName, fuWrite, ShareMode);
end;

procedure TCEFileOutputStream.Close;
begin
  FFile.Close();
end;

function TCEFileOutputStream.Write(const Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FFile.Write(Buffer, Count);
end;

end.

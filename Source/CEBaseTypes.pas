(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEBaseTypes.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(Base types unit)

The unit contains common types

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEBaseTypes;

interface

uses SysUtils;

const
  // Index of first character in strings
  STRING_INDEX_BASE = 1;
  // Number of bits per byte
  BITS_IN_BYTE = 8;

  ONE_OVER_255 = 1/255;

type
  {$IF not Declared(UnicodeString)}
    UnicodeString = WideString;
  {$IFEND}
  {$IFDEF UNICODE_ONLY}
  // Entity name type
  TCEEntityName = UnicodeString;
  PCEEntityName = PChar;
  // Entity class name type
  TCEEntityClassName = TCEEntityName;
  {$ELSE}
  // Entity name type
  TCEEntityName = AnsiString;
  PCEEntityName = PAnsiChar;
  // Entity class name type
  TCEEntityClassName = TCEEntityName;
  {$ENDIF}

  // Pointer to 32-bit color
  PCEColor = ^TCEColor;
  // 32-bit color (A8R8G8B8)
  TCEColor = packed record
    case Boolean of
      False: (C: Longword);
      True: (B, G, R, A: Byte);
  end;

  // Identifier of a virtual key which may be a key on keyboard, mouse etc
  TCEVirtualKey = Byte;
  // Button action
  TButtonAction = (baUp, baDown);
  // Mouse buttons
  TMouseButton = (// Left mouse button
                  mbLeft,
                  // Right mouse button
                  mbRight,
                  // Middle mouse button
                  mbMiddle,
                  // 4-th mouse button
                  mbCustom1);

  // Command - parameterless procedure method
  TCommand = procedure() of object;

  // Signature
  TSignature = record
  case Integer of
    0: (Bytes: array[0..3] of Byte;);
    1: (DWord: Longword;);
  end;
  TShortString4 = string[4];

  // Rectangle data. Last pixel convention: not include.
  TRect = packed record
    Left, Top, Right, Bottom: Integer;
  end;
  PRect = ^TRect;

  // Base error class
  ECEError = Exception;

  // Occurs when a requested operation is not supported
  ECEUnsupportedOperation = class(ECEError)
  end;

  // Occurs when an invalid argument passed to a method or routine
  ECEInvalidArgument = class(ECEError)
  end;

  // Abstract class for any kind of entities with most generic properties
  TCEAbstractEntity = class
  public
    // Should return unique name of this entity
    function GetFullName: TCEEntityName; virtual; abstract;
    // Set full name of a linked object so it can be resolved in future. See @Link(ResolveObjectLink).
    procedure SetObjectLink(const PropertyName: string; const FullName: TCEEntityName); virtual; abstract;
  end;
  // Abstract entity metaclass
  CCEAbstractEntity = class of TCEAbstractEntity;

  // Pointer to source code location
  PCodeLocation = ^TCodeLocation;
  // Describes location in code - file, unit, procedure name and line number
  TCodeLocation = record
    // Address of the location. Nil if the record is not initilized or failed to obtain the location info.
    Address: Pointer;
    // Source file name
    SourceFilename: string;
    // Unit name
    UnitName: string;
    // Procedure name
    ProcedureName: string;
    // Line number in source file
    LineNumber: Integer;
  end;
  // Stack trace
  TBaseStackTrace = array of TCodeLocation;

  function GetColor(const R, G, B, A: Byte): TCEColor; overload; {$I inline.inc}
  function GetColor(const C: Longword): TCEColor; overload; {$I inline.inc}
  // Converts int to string
  function IntToStr(v: Int64): string;
  // Returns ResTrue if cond and ResFalse otherwise
  function IFF(Cond: Boolean; const ResTrue, ResFalse: string): string; overload; {$I inline.inc}
  // Returns TSignature structure by 4 characters
  function GetSignature(Sign: TShortString4): TSignature;
  // Fills the specified rectangle record and returns it in Result
  procedure Rect(ALeft, ATop, ARight, ABottom: Integer; out Result: TRect); {$I inline.inc}
  // Returns the specified by its bounds rectangle record
  function GetRect(ALeft, ATop, ARight, ABottom: Integer): TRect; {$I inline.inc}
  // Returns filled code location structure
  function GetCodeLoc(const ASourceFilename, AUnitName, AProcedureName: string; ALineNumber: Integer; AAddress: Pointer): TCodeLocation;
  // Converts code location to a readable string
  function CodeLocToStr(const CodeLoc: TCodeLocation): string;

type  
  // Version of interfaced object with non thread-safe reference counting which is much faster and suitable for the TRefcountedContainer
  TLiteInterfacedObject = class(TObject, IInterface)
  protected
    FRefCount: Integer;
    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult;
    {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
    function _AddRef: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
    function _Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
  public
    procedure AfterConstruction; override;
    class function NewInstance: TObject; override;
  end;

  { Replaces assert error procedure with the specified one.
    Old assert error procedure is save to be restored with AssertRestore.
    Returns True if hook successful or False otherwise.
    Used internally for Assert-based features.
    Thread safe if MULTITHREADASSERT defined. }
  function AssertHook(NewAssertProc: TAssertErrorProc): Boolean;
  { Restores assert error procedure changed by AssertHook.
    Used internally for Assert-based features.
    Thread safe if MULTITHREADASSERT defined. }
  procedure AssertRestore();

implementation

{$IFDEF MULTITHREADASSERT}
  uses SyncObjs;
{$ENDIF}

function GetColor(const R, G, B, A: Byte): TCEColor; {$I inline.inc}
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
  Result.A := A;
end;

function GetColor(const C: Longword): TCEColor; {$I inline.inc}
begin
  Result.C := C;
end;

function IntToStr(v: Int64): string;
var s: ShortString;
begin
  Str(v, s);
  Result := string(s);
end;

function IFF(Cond: Boolean; const ResTrue, ResFalse: string): string; overload; {$I inline.inc}
begin
  if Cond then Result := ResTrue else Result := ResFalse;
end;

function GetSignature(Sign: TShortString4): TSignature;
begin
  Result.Bytes[0] := Ord(Sign[1]);
  Result.Bytes[1] := Ord(Sign[2]);
  Result.Bytes[2] := Ord(Sign[3]);
  Result.Bytes[3] := Ord(Sign[4]);
end;

procedure Rect(ALeft, ATop, ARight, ABottom: Integer; out Result: TRect);
begin
  with Result do begin
    Left := ALeft; Top := ATop;
    Right:= ARight; Bottom := ABottom;
  end;
end;

function GetRect(ALeft, ATop, ARight, ABottom: Integer): TRect;
begin
  Rect(ALeft, ATop, ARight, ABottom, Result);
end;

function GetCodeLoc(const ASourceFilename, AUnitName, AProcedureName: string; ALineNumber: Integer; AAddress: Pointer): TCodeLocation;
begin
  Result.Address        := AAddress;
  Result.SourceFilename := ASourceFilename;
  Result.UnitName       := AUnitName;
  Result.ProcedureName  := AProcedureName;
  Result.LineNumber     := ALineNumber;
end;

function CodeLocToStr(const CodeLoc: TCodeLocation): string;
begin
  Result := IFF(CodeLoc.UnitName <> '', CodeLoc.UnitName + '.', '') + CodeLoc.ProcedureName
          + '(' + IFF(CodeLoc.SourceFilename <> '', CodeLoc.SourceFilename, 'Unknown source') + ':'
          + IFF(CodeLoc.LineNumber > 0, IntToStr(CodeLoc.LineNumber), '-') + ')';
end;

{ TLiteInterfacedObject }

procedure TLiteInterfacedObject.AfterConstruction;
begin
  FRefCount := FRefCount-1; // Release the constructor's implicit refcount
end;

// Set an implicit refcount so that refcounting
// during construction won't destroy the object.
class function TLiteInterfacedObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TLiteInterfacedObject(Result).FRefCount := 1;
end;

function TLiteInterfacedObject.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  Result := E_NOINTERFACE;
end;

function TLiteInterfacedObject._AddRef: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  FRefCount := FRefCount+1;
  Result := FRefCount;
end;

function TLiteInterfacedObject._Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  FRefCount := FRefCount-1;
  Result := FRefCount;
  if Result = 0 then Destroy;
end;

var
  StoredAssertProc: TAssertErrorProc = nil;
  {$IFDEF MULTITHREADASSERT}
    AssertCriticalSection: TCriticalSection;
  {$ENDIF}

function AssertHook(NewAssertProc: TAssertErrorProc): Boolean;
begin
  Assert(@StoredAssertProc = nil, 'Assert already hooked');
  {$IFDEF MULTITHREADASSERT}
    AssertCriticalSection.Enter();
  {$ENDIF}
  StoredAssertProc := AssertErrorProc;
  AssertErrorProc  := NewAssertProc;
  Result := True;
end;

procedure AssertRestore();
begin
  AssertErrorProc := StoredAssertProc;
  StoredAssertProc := nil;
  {$IFDEF MULTITHREADASSERT}
    AssertCriticalSection.Leave();
  {$ENDIF}
end;

{$IFDEF MULTITHREADASSERT}
  initialization
    AssertCriticalSection := TCriticalSection.Create();
  finalization
    AssertCriticalSection.Free();
{$ENDIF}

end.

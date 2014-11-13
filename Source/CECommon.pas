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
@abstract(Common routines unit)

The unit contains common routines

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CECommon;

interface

uses
  CEBaseTypes;

  // Returns max pf the two arguments
  function Max(V1, V2: Integer): Integer; {$I inline.inc}
  // Returns min pf the two arguments
  function Min(V1, V2: Integer): Integer; {$I inline.inc}
  // Clamp the value to range
  function Clamp(V, Min, Max: Integer): Integer; {$I inline.inc}

  // Returns base pointer shifted by offset
  function PtrOffs(Base: Pointer; Offset: Integer): Pointer; {$I inline.inc}

  // Returns positions of ch within the given string starting from Start or -1 if not found
  function CharPos(const ch: AnsiChar; const s: AnsiString; const Start: Integer ): Integer;
  // Returns extension part of file name
  function GetFileExt(const FileName: string): string;

type
  { @Abstract(Pseudo-random numbers generator)
    Generates a sequence of pseudo-random numbers.
    }
  TRandomGenerator = class
  protected
    // Seeds for sequences
    RandomSeed: array of Longword;
    // Chain values for sequences
    RandomChain: array of Longword;
    // Current sequence
    FCurrentSequence: Cardinal;
    // Number of sequences
    procedure SetMaxSequence(AMaxSequence: Integer);
    procedure SetCurrentSequence(const Value: Cardinal);
  public
    constructor Create;
    // Initializes the current sequence with the specified chain value and the specified seed
    procedure InitSequence(Chain, Seed: Longword);
    // Generate a raw random number. Fastest method.
    function GenerateRaw: Longword; virtual;
    // Generate a floating point random number within the given range
    function Rnd(Range: Single): Single;
    // Generate a floating point random number within the range [-<b>Range..Range</b>]
    function RndSymm(Range: Single): Single;
    // Generate an integer random number within the range [0..<b>Range</b>-1]
    function RndI(Range: Integer): Integer;
    // Current sequence
    property CurrentSequence: Cardinal read FCurrentSequence write SetCurrentSequence;
  end;

  { @Abstract(Reference-counted container of temporary objects and memory buffers )
    Create an instance with @Link(CreateRefcountedContainer). The container can be used to accumulate temporary objects and buffers.
    When no more references points to the container it destroys itself and all accumulated objects and buffers.
    Usage:
    with CreateRefcountedContainer do begin
      obj := TSomeObject.Create();
      Managed.AddObject(obj);
    end;
    The container and all added objects will be destroyed after the current routine execution (but not after "with" statement end). }
  IRefcountedContainer = interface
    // Adds an object instance
    function AddObject(Obj: TObject): TObject;
    // Adds a memory buffer
    function AddPointer(Ptr: Pointer): Pointer;
    // Adds an array of object instances
    procedure AddObjects(Objs: array of TObject);
    // Adds an array of memory buffers
    procedure AddPointers(Ptrs: array of Pointer);
    // Returns self for use within "with" statement
    function GetContainer(): IRefcountedContainer;
    // Returns self for use within "with" statement
    property Managed: IRefcountedContainer read GetContainer;
  end;

  // Create an instance of reference counted container
  function CreateRefcountedContainer: IRefcountedContainer;

implementation

uses SysUtils;

function Max(V1, V2: Integer): Integer; {$I inline.inc}
begin
  Result := V1 * Ord(V1 >= V2) + V2 * Ord(V1 < V2);
end;

function Min(V1, V2: Integer): Integer; {$I inline.inc}
begin
  Result := V1 * Ord(V1 <= V2) + V2 * Ord(V1 > V2);
end;

function Clamp(V, Min, Max: Integer): Integer; {$I inline.inc}
begin
//  if V < B1 then Result := B1 else if V > B2 then Result := B2 else Result := V;
  Result := V + (Min - V) * Ord(V < Min) - (V - Max) * Ord(V > Max);
  Assert((Result >= Min) and (Result <= Max));
end;

function PtrOffs(Base: Pointer; Offset: Integer): Pointer; {$I inline.inc}
begin
  Result := Base;
  Inc(PByte(Result), Offset);
end;

function CharPos(const ch: AnsiChar; const s: AnsiString; const Start: Integer): Integer;
begin       // TODO: optimize
  Result := Pos(ch, Copy(s, Start, Length(s)));
  if Result >= STRING_INDEX_BASE then
    Result := Result + Start
  else
    Result := -1;
end;

function GetFileExt(const FileName: string): string;
var i, ind: Integer;
begin
  ind := -1;
  for i := 1 to Length(FileName) do
  begin
    if FileName[i] = '.' then
      ind := i
    else if FileName[i] = '\' then
      ind := -1;
  end;

  if ind = -1 then
    Result := ''
  else
    Result := Copy(FileName, ind+1, Length(FileName));
end;

const
  // Minimum capacity of reference counted container
  MinRefCContainerLength = 8;

type
  TRefcountedContainer = class(TLiteInterfacedObject, IRefcountedContainer)
  private
    ObjList: array of TObject;
    PtrList: array of Pointer;
    ObjCount, PtrCount: Integer;
  public
    destructor Destroy; override;

    function AddObject(Obj: TObject): TObject;
    function AddPointer(Ptr: Pointer): Pointer;
    procedure AddObjects(Objs: array of TObject);
    procedure AddPointers(Ptrs: array of Pointer);
    function GetContainer(): IRefcountedContainer;
  end;

{ TRandomGenerator }

constructor TRandomGenerator.Create;
begin
  SetMaxSequence(8);
  CurrentSequence := 0;
  InitSequence(1, 1);
end;

procedure TRandomGenerator.InitSequence(Chain, Seed: Longword);
begin
  RandomChain[FCurrentSequence] := Chain;
  RandomSeed [FCurrentSequence] := Seed;
end;

function TRandomGenerator.GenerateRaw: Longword;
begin
{$Q-}
  RandomSeed[FCurrentSequence] := 97781173 * RandomSeed[FCurrentSequence] + RandomChain[FCurrentSequence];
  Result := RandomSeed[FCurrentSequence];
end;

function TRandomGenerator.Rnd(Range: Single): Single;
const RandomNorm = 1/$FFFFFFFF;
begin
  Result := GenerateRaw * RandomNorm * Range;
end;

function TRandomGenerator.RndSymm(Range: Single): Single;
begin
  Result := Rnd(2*Range) - Range;
end;

function TRandomGenerator.RndI(Range: Integer): Integer;
begin
  Result := Round(Rnd(Max(0, Range-1)));
end;

procedure TRandomGenerator.SetMaxSequence(AMaxSequence: Integer);
begin
  SetLength(RandomSeed, AMaxSequence);
  SetLength(RandomChain, AMaxSequence);
end;

procedure TRandomGenerator.SetCurrentSequence(const Value: Cardinal);
begin
  FCurrentSequence := Value;
  if Integer(Value) > High(RandomSeed) then
  begin
    SetMaxSequence(Value+1);
  end;
end;

{ TRefcountedContainer }

destructor TRefcountedContainer.Destroy;
var i: Integer;
begin
  for i := ObjCount-1 downto 0 do if Assigned(ObjList[i]) then
  begin
    try
      FreeAndNil(ObjList[i]);
    except
      // TODO: log
    end;
  end;
  for i := PtrCount-1 downto 0 do if Assigned(PtrList[i]) then
  begin
    FreeMem(PtrList[i]);
  end;
  ObjList := nil;
  PtrList := nil;
  inherited;
end;

function TRefcountedContainer.AddObject(Obj: TObject): TObject;
begin
  Inc(ObjCount);
  if ObjCount > Length(ObjList) then
  begin
    SetLength(ObjList, Max(MinRefCContainerLength, Length(ObjList) * 2));
  end;
  ObjList[ObjCount-1] := Obj;
  Result := Obj;
end;

function TRefcountedContainer.AddPointer(Ptr: Pointer): Pointer;
begin
  Inc(PtrCount);
  if PtrCount > Length(PtrList) then
  begin
    SetLength(PtrList, Max(MinRefCContainerLength, Length(PtrList) * 2));
  end;
  PtrList[PtrCount-1] := Ptr;
  Result := Ptr;
end;

procedure TRefcountedContainer.AddObjects(Objs: array of TObject);
var i: Integer;
begin
  for i := Low(Objs) to High(Objs) do AddObject(Objs[i]);
end;

procedure TRefcountedContainer.AddPointers(Ptrs: array of Pointer);
var i: Integer;
begin
  for i := Low(Ptrs) to High(Ptrs) do AddPointer(Ptrs[i]);
end;

function TRefcountedContainer.GetContainer: IRefcountedContainer;
begin
  Result := Self;
end;

function CreateRefcountedContainer: IRefcountedContainer;
begin
  Result := TRefcountedContainer.Create;
end;

end.

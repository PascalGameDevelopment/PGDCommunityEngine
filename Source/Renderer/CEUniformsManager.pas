(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOpenGL4Renderer.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE uniforms manager)

Uniforms management unit.

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEUniformsManager;

interface

uses
  CEVectors, CEBaseTypes;

const
  // Special buffer index value meaning that the buffer was not allocated yet
  DATA_NOT_ALLOCATED = -1;

type
  TCEUniformsManager = class(TObject)
  public
    procedure SetInteger(const Name: PAPIChar; Value: Integer); virtual; abstract;
    procedure SetSingle(const Name: PAPIChar; Value: Single); virtual; abstract;
    procedure SetSingleVec2(const Name: PAPIChar; const Value: TCEVector2f); virtual; abstract;
    procedure SetSingleVec3(const Name: PAPIChar; const Value: TCEVector3f); virtual; abstract;
    procedure SetSingleVec4(const Name: PAPIChar; const Value: TCEVector4f); virtual; abstract;
  end;

  // Type of data stores in a buffer
  TCEDataType = (// Data rarely or never changes
                 dtStatic,
                 // Data changes nearly every frame (particle system vertices, etc)
                 dtDynamic);

  //  Data state
  TCEDataState = (// Data size changed. May need to invalidate other data in buffer.
                  dsSizeChanged,
                  // Data was changed
                  dsChanged,
                  // Data was not changed so no reason to update it
                  dsValid);

  PCEDataStatus = ^TCEDataStatus;
    { Current data status data structure
      <b>BufferIndex</b>      - index of buffer in API-independent buffers
      <b>Offset</b>           - offset within the buffer in bytes
      <b>Status</b>           - current data state
      should not be modified manually }
  TCEDataStatus = record
    BufferIndex, Offset: Integer;
    DataType: TCEDataType;
    Status: TCEDataState;
  end;

  TCEDataBuffer = record
    // API-specific buffer identifier
    Id: Integer;
    Position, Size: Integer;
    ElementSize: Integer;
    DataType: TCEDataType;
  end;
  PCEDataBuffer = ^TCEDataBuffer;
  TCEDataBufferList = array[0..$FFFF] of TCEDataBuffer;
  PCEDataBufferList = ^TCEDataBufferList;

  TCERenderBufferManager = class(TObject)
  private
    function IndexOf(ElementSize: Integer; const DataType: TCEDataType): Integer;
    function AddBuffer(ElementSize: Integer; Status: PCEDataStatus): Integer;
  protected
    FBuffers: PCEDataBufferList;
    Count: Integer;
    procedure ApiAddBuffer(Index: Integer); virtual; abstract;
    property Buffers: PCEDataBufferList read FBuffers;
  public
    destructor Destroy(); override;
    function GetOrCreate(ElementSize: Integer; Status: PCEDataStatus; out Res: PCEDataBuffer): Integer;
  end;

implementation

function TCERenderBufferManager.IndexOf(ElementSize: Integer; const DataType: TCEDataType): Integer;
begin
  Result := Count-1;
  while (Result >= 0)
    and ((FBuffers^[Result].ElementSize <> ElementSize) or (FBuffers^[Result].DataType <> DataType)) do
    Dec(Result);
end;

function TCERenderBufferManager.AddBuffer(ElementSize: Integer; Status: PCEDataStatus): Integer;
begin
  Result := Count;
  ReallocMem(FBuffers, (Count + 1) * SizeOf(TCEDataBuffer));
  FBuffers^[Count].Id := DATA_NOT_ALLOCATED;
  FBuffers^[Count].Position := 0;
  FBuffers^[Count].ElementSize := ElementSize;
  FBuffers^[Count].DataType := Status^.DataType;
  Inc(Count);
  ApiAddBuffer(Count-1);
end;

destructor TCERenderBufferManager.Destroy();
begin
  FreeMem(FBuffers, Count * SizeOf(TCEDataBuffer));
  inherited;
end;

function TCERenderBufferManager.GetOrCreate(ElementSize: Integer; Status: PCEDataStatus; out Res: PCEDataBuffer): Integer;
begin
  Result := IndexOf(ElementSize, Status^.DataType);
  if Result = -1 then
    Result := AddBuffer(ElementSize, Status);
  Status^.Status := dsSizeChanged;
  Status^.BufferIndex := Result;
  Res := @FBuffers^[Result];
end;

end.

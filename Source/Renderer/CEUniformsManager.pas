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
  CEBaseTypes;

const
  // Special buffer index value meaning that the buffer was not allocated yet
  DATA_NOT_ALLOCATED = -1;
  // Default static data buffer size measured in elements
  DATA_BUFFER_SIZE_STATIC = 65536;
  // Default dynamic data buffer size measured in elements
  DATA_BUFFER_SIZE_DYNAMIC = 65536;
  // Max size of vertex buffer element in bytes
  DATA_VERTEX_BUFFER_ELEMENT_MAX_SIZE = 64;
  // Max size of index buffer element in bytes
  DATA_INDEX_BUFFER_ELEMENT_MAX_SIZE = 4;

type
  // Uniforms management class. Used in mesh classes to set uniform constants.
  TCEUniformsManager = class(TObject)
  public
    procedure SetInteger(const Name: PAPIChar; Value: Integer); virtual; abstract;
    procedure SetSingle(const Name: PAPIChar; Value: Single); virtual; abstract;
    procedure SetSingleVec2(const Name: PAPIChar; const Value: TCEVector2f); virtual; abstract;
    procedure SetSingleVec3(const Name: PAPIChar; const Value: TCEVector3f); virtual; abstract;
    procedure SetSingleVec4(const Name: PAPIChar; const Value: TCEVector4f); virtual; abstract;
  end;

  // Type of data stored in a buffer
  TCEDataUsage = ({ Index data. Persists between frames and may be updated from time to time.
                    Data size change will invalidate whole buffer which may be expensive. }
                  duStaticIndices,
                  { Vertex data. Persists between frames and may be updated from time to time.
                    Data size change will invalidate whole buffer which may be expensive. }
                  duStaticVertices,
                  // Index data. Changes every frame (particle system vertices, etc)
                  duStreamingIndices,
                  // Vertex data. Changes every frame (particle system vertices, etc)
                  duStreamingVertices);

  // Data state
  TCEDataState = (// Data size changed. May need to invalidate other data in buffer.
                  dsSizeChanged,
                  // Data was changed
                  dsChanged,
                  // Data was not changed so no reason to update it
                  dsValid);
  // Data buffer types
  TCEDataType = (dbtVertex1, dbtIndex, dbtVertex2, dbtVertex3);

  PCEDataStatus = ^TCEDataStatus;

  { Current data status data structure
      <b>BufferIndex</b>      - index of buffer in API-independent buffers
      <b>Offset</b>           - offset within the buffer measured in elements
      <b>Status</b>           - current data state
      should not be modified manually }
  TCEDataStatus = record
    BufferIndex: Integer;
    Offset: Cardinal;
    DataUsage: TCEDataUsage;
    Status: TCEDataState;
  end;

  // Internal data structure for buffer manager
  TCEDataBuffer = packed record
    // API-specific buffer identifier
    Id: Integer;
    // Current position and size measured in elements
    Position, Size: Integer;
    // Size of each element in bytes
    ElementSize: Word;
    // Kind of data: static or streaming
    DataUsage: TCEDataUsage;
  end;
  PCEDataBuffer = ^TCEDataBuffer;
  TCEDataBufferList = array[0..$FFFF] of TCEDataBuffer;
  PCEDataBufferList = ^TCEDataBufferList;

  // Render buffer management class. User of PGDCE usually should not use this class directly.
  TCERenderBufferManager = class(TObject)
  private
    function IndexOf(ElementSize: Integer; const DataType: TCEDataUsage): Integer;
    function AddBuffer(ElementSize: Integer; const Status: TCEDataStatus): Integer;
  protected
    FBuffers: PCEDataBufferList;
    Count: Integer;
    // Perfroms necessary GAPI calls to create new data buffer
    procedure ApiAddBuffer(Index: Integer); virtual; abstract;
    // Maps API buffer and returns pointer to write data
    function ApiMapBuffer(const Status: TCEDataStatus; ElementsCount: Integer; Discard: Boolean): Pointer; virtual; abstract;
    // Finalizes data transfer if necessary and unmaps API buffer
    procedure ApiUnmapBuffer(const Status: TCEDataStatus; ElementsCount: Integer; Data: Pointer); virtual; abstract;
    // List of currently allocated buffers
    property Buffers: PCEDataBufferList read FBuffers;
  public
    destructor Destroy(); override;
    { Finds or creates buffer matching specified data type and element size, udpates Status.Offset with current position,
      increases current position and returns matching buffer in Res }
    procedure FindOrCreate(ElementsCount, ElementsSize: Integer; var Status: TCEDataStatus; out Res: PCEDataBuffer);
    // Maps part of buffer and returns pointer to write data to the mapped part
    function MapBuffer(ElementsCount, ElementsSize: Integer; var Status: TCEDataStatus): Pointer;
    // Finalize data transfer if necessary and unmap buffer
    procedure UnmapBuffer(const Status: TCEDataStatus; ElementsCount: Integer; Data: Pointer);
  end;

implementation

uses CELog;

function TCERenderBufferManager.IndexOf(ElementSize: Integer; const DataType: TCEDataUsage): Integer;
begin
  Result := Count-1;
  while (Result >= 0)
    and ((FBuffers^[Result].ElementSize <> ElementSize) or (FBuffers^[Result].DataUsage <> DataType)) do
    Dec(Result);
end;

function TCERenderBufferManager.AddBuffer(ElementSize: Integer; const Status: TCEDataStatus): Integer;
begin
  Result := Count;
  ReallocMem(FBuffers, (Count + 1) * SizeOf(TCEDataBuffer));
  FBuffers^[Count].Id := DATA_NOT_ALLOCATED;
  FBuffers^[Count].Position := 0;
  FBuffers^[Count].ElementSize := ElementSize;
  FBuffers^[Count].DataUsage := Status.DataUsage;
  FBuffers^[Count].Size := DATA_BUFFER_SIZE_DYNAMIC;
  Inc(Count);
  ApiAddBuffer(Count - 1);
end;

destructor TCERenderBufferManager.Destroy();
begin
  FreeMem(FBuffers, Count * SizeOf(TCEDataBuffer));
  inherited;
end;

procedure TCERenderBufferManager.FindOrCreate(ElementsCount, ElementsSize: Integer; var Status: TCEDataStatus; out Res: PCEDataBuffer);
begin
  Assert(ElementsSize * ElementsCount > 0, 'Invalid element size');
  Status.BufferIndex := IndexOf(ElementsSize, Status.DataUsage);
  if Status.BufferIndex = -1 then
    Status.BufferIndex := AddBuffer(ElementsSize, Status);
  Status.Offset := FBuffers^[Status.BufferIndex].Position;
  Inc(FBuffers^[Status.BufferIndex].Position, ElementsCount);
  Status.Status := dsSizeChanged;
  Res := @FBuffers^[Status.BufferIndex];
end;

function TCERenderBufferManager.MapBuffer(ElementsCount, ElementsSize: Integer; var Status: TCEDataStatus): Pointer;
begin
  Assert(ElementsSize * ElementsCount > 0, 'Invalid element size');
  if Status.BufferIndex = DATA_NOT_ALLOCATED then
  begin
    Status.BufferIndex := IndexOf(ElementsSize, Status.DataUsage);
    if Status.BufferIndex < 0 then
      Status.BufferIndex := AddBuffer(ElementsSize, Status);
  end;

  {    Streaming - contents overwrites every frame, ring buffer
    - get or create buffer
    - if current mesh doesn't fit: discard and reset
    - write at current position}
  if Status.DataUsage >= duStreamingIndices then
  begin
    if FBuffers^[Status.BufferIndex].Position + ElementsCount <= FBuffers^[Status.BufferIndex].Size then
    begin
      Status.Offset := FBuffers^[Status.BufferIndex].Position;
      Inc(FBuffers^[Status.BufferIndex].Position, ElementsCount);
      Result := ApiMapBuffer(Status, ElementsCount, false);
    end else if ElementsCount <= FBuffers^[Status.BufferIndex].Size then begin
      Status.Offset := 0;
      FBuffers^[Status.BufferIndex].Position := ElementsCount;
      Result := ApiMapBuffer(Status, ElementsCount, true);
    end else
    begin
      Result := nil;
      CELog.Error('Mesh data doesn''t fit into buffer. ElementSize: ' + IntToStr(ElementsSize));
    end;
  end else
    Result := ApiMapBuffer(Status, ElementsCount, false);
end;

procedure TCERenderBufferManager.UnmapBuffer(const Status: TCEDataStatus; ElementsCount: Integer; Data: Pointer);
begin
  ApiUnmapBuffer(Status, ElementsCount, Data);
end;

end.

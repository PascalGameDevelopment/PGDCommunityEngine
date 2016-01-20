(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEMesh.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE mesh entity unit)

The unit contains mesh entity class

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEMesh;

interface

uses
  CEBaseTypes, CEEntity, CEUniformsManager;

type
  // Primitive types
  TPrimitiveType = (ptPointList, ptLineList, ptLineStrip, ptTriangleList, ptTriangleStrip, ptTriangleFan, ptQuads);

  // Vertex attribute data types
  TAttributeDataType = (adtShortint, adtByte, adtSmallint, adtWord, adtSingle);
  // Data buffer types
  TDataBufferType = (dbtIndex, dbtVertex1, dbtVertex2, dbtVertex3);
  // Vertex attribute data information
  TAttributeData = record
    DataType: TAttributeDataType;
    Size: Integer;
    Name: PAPIChar;
  end;
  TAttributeDataArray = array[0..$FFFF] of TAttributeData;
  PAttributeDataArray = ^TAttributeDataArray;

  TCEMeshData = record
    Status: TCEDataStatus;
    // Size of each element (vertex size or index size)
    Size: Integer;
    VertexAttribsCount: Integer;
    VertexAttribs: PAttributeDataArray;
  end;
  PCEMeshData = ^TCEMeshData;

  {
  Encapsulates vertex data needed to render a visible entity
  }
  TCEMesh = class(TCEBaseEntity)
    procedure SetVertexAttribsCount(Buffer: TDataBufferType; Count: Integer);
  protected
    FBuffer: array[TDataBufferType] of TCEMeshData;
    FVerticesCount: Integer;
    FPrimitiveType: TPrimitiveType;
    FPrimitiveCount: Integer;                            // TODO: remove?
    // Set data element size for the given buffer
    procedure SetDataSize(Buffer: TDataBufferType; Size: Integer);
    // Set vertex attribute data for the given buffer
    procedure SetVertexAttrib(Buffer: TDataBufferType; Index: Integer; DataType: TAttributeDataType; DataSize: Integer; DataName: PAPIChar);
    procedure InvalidateData(Buffer: TDataBufferType; SizeNotChanged: Boolean);
    // Called by InvalidateData() and should be overridden by classes which change data layout in buffer such as max vertices count change
    procedure ApplyParameters(); virtual;
  public
    destructor Destroy; override;
    procedure DoInit(); override;
    // Fill vertex buffer
    procedure FillVertexBuffer(Buffer: TDataBufferType; Dest: Pointer); virtual;
    // Fill index buffer
    procedure FillIndexBuffer(Buffer: TDataBufferType; Dest: Pointer); virtual;
    // Called by renderer when uniforms for the mesh need to be set
    procedure SetUniforms(Manager: TCEUniformsManager); virtual;
    { Number of vertices to allocate buffer space for.
      Should be either set before any rendering and not changed later or should be updated in ApplyParameters().
      Actual number of vertices generated in FillVertexBuffer() may be less without reallocating buffer. }
    property VerticesCount: Integer read FVerticesCount;
    // Primitive type
    property PrimitiveType: TPrimitiveType read FPrimitiveType;
    { Number of primitives (points, lines, triangles etc depending on PrimitiveType) in mesh to render.
      This value can be calculated while filling buffer and may correspond to less than VerticesCount amount of vertices. }
    property PrimitiveCount: Integer read FPrimitiveCount;
  end;

  // Used by renderer
  function GetBuffer(const Mesh: TCEMesh; Buffer: TDataBufferType): PCEMeshData; {$I inline.inc}
  procedure InitTesselationStatus(var Status: TCEDataStatus); {$I inline.inc}

implementation

uses
  CEVectors;

function GetBuffer(const Mesh: TCEMesh; Buffer: TDataBufferType): PCEMeshData; {$I inline.inc}
begin
  Result := @Mesh.FBuffer[Buffer];
end;

procedure InitTesselationStatus(var Status: TCEDataStatus); {$I inline.inc}
begin
  Status.BufferIndex := DATA_NOT_ALLOCATED;
  Status.Offset := 0;
  Status.Status := dsSizeChanged;
  Status.DataType := dtStatic;
end;

{ TCEMesh }

procedure TCEMesh.SetVertexAttribsCount(Buffer: TDataBufferType; Count: Integer);
begin
  FBuffer[Buffer].VertexAttribsCount := Count;
  ReallocMem(FBuffer[Buffer].VertexAttribs, FBuffer[Buffer].VertexAttribsCount * SizeOf(TAttributeData));
end;

procedure TCEMesh.SetDataSize(Buffer: TDataBufferType; Size: Integer);
begin
  FBuffer[Buffer].Size := Size;
end;

procedure TCEMesh.SetVertexAttrib(Buffer: TDataBufferType; Index: Integer; DataType: TAttributeDataType; DataSize: Integer; DataName: PAPIChar);
begin
  Assert(Index < FBuffer[Buffer].VertexAttribsCount, 'Attribute index out of bounds');
  FBuffer[Buffer].VertexAttribs^[Index].DataType := DataType;
  FBuffer[Buffer].VertexAttribs^[Index].Size := DataSize;
  FBuffer[Buffer].VertexAttribs^[Index].Name := DataName;
end;

procedure TCEMesh.InvalidateData(Buffer: TDataBufferType; SizeNotChanged: Boolean);
begin
  if SizeNotChanged then
    FBuffer[Buffer].Status.Status := dsChanged
  else begin
    FBuffer[Buffer].Status.Status := dsSizeChanged;
    ApplyParameters();
  end;
end;

procedure TCEMesh.ApplyParameters();
begin
  // do nothing
end;

destructor TCEMesh.Destroy;
var
  buf: TDataBufferType;
begin
  for buf := Low(TDataBufferType) to High(TDataBufferType) do
    FreeMem(FBuffer[buf].VertexAttribs, FBuffer[buf].VertexAttribsCount * SizeOf(TAttributeData));
  inherited;
end;

procedure TCEMesh.DoInit();
var
  buf: TDataBufferType;
begin
  FVerticesCount := 1;
  FPrimitiveType := ptTriangleList;
  FPrimitiveCount := 1;
  for buf := Low(TDataBufferType) to High(TDataBufferType) do
  begin
    FBuffer[buf].Size := 0;
    SetVertexAttribsCount(buf, 0);
    InitTesselationStatus(FBuffer[buf].Status);
  end;
end;

procedure TCEMesh.FillVertexBuffer(Buffer: TDataBufferType; Dest: Pointer);
begin
  FBuffer[Buffer].Status.Status := dsValid;
end;

procedure TCEMesh.FillIndexBuffer(Buffer: TDataBufferType; Dest: Pointer);
begin
  FBuffer[Buffer].Status.Status := dsValid;
end;

procedure TCEMesh.SetUniforms(Manager: TCEUniformsManager);
begin
// do nothing
end;

end.

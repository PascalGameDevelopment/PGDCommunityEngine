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
  // Vertex attribute data information
  TAttributeData = record
    // Data type
    DataType: TAttributeDataType;
    // Number of components
    Count: Cardinal;
    // Name of attribute in vertex program
    Name: PAPIChar;
  end;
  TAttributeDataArray = array[0..$FFFF] of TAttributeData;
  PAttributeDataArray = ^TAttributeDataArray;

  TDataDestinations = array[TCEDataType] of Pointer;
  PDataDestinations = ^TDataDestinations;

  TCEMeshData = record
    Status: TCEDataStatus;
    // Size of each element (vertex size or index size)
    Size: Cardinal;
    // Number of attributes. 1 for index buffer.
    VertexAttribsCount: Integer;
    VertexAttribs: PAttributeDataArray;
  end;
  PCEMeshData = ^TCEMeshData;

  {
  Encapsulates vertex data needed to render a visible entity
  }
  TCEMesh = class(TCEBaseEntity)
    procedure SetVertexAttribsCount(Buffer: TCEDataType; Count: Integer);
  protected
    FBuffer: array[TCEDataType] of TCEMeshData;
    FVerticesCount, FIndicesCount: Integer;
    FPrimitiveType: TPrimitiveType;
    FPrimitiveCount: Integer;
    // Set data element size for the given buffer
    procedure DoInit(); override;
    procedure SetDataSize(Buffer: TCEDataType; Size: Integer);
    // Set vertex attribute data for the given buffer
    procedure SetVertexAttrib(Buffer: TCEDataType; Index: Integer; DataType: TAttributeDataType; DataCount: Integer; DataName: PAPIChar);
    procedure InvalidateData(Buffer: TCEDataType; SizeNotChanged: Boolean);
    // Called by InvalidateData() and should be overridden by classes which change data layout in buffer such as max vertices count change
    procedure ApplyParameters(); virtual;
  public
    destructor Destroy; override;
    // Writes vertex/index data into destination pointed by Destinations
    procedure WriteMeshData(Destinations: PDataDestinations); virtual; abstract;
    // Called by renderer when uniforms for the mesh need to be set
    procedure SetUniforms(Manager: TCEUniformsManager); virtual;
    { Number of vertices to allocate buffer space for.
      Should be either set before any rendering and not changed later or should be updated in ApplyParameters().
      Actual number of vertices generated in WriteMeshData() may be less without reallocating buffer. }
    property VerticesCount: Integer read FVerticesCount;
    { Number of indices to allocate buffer space for.
      Should be either set before any rendering and not changed later or should be updated in ApplyParameters().
      Actual number of indices generated in WriteMeshData() may be less without reallocating buffer. }
    property IndicesCount: Integer read FIndicesCount;
    // Primitive type
    property PrimitiveType: TPrimitiveType read FPrimitiveType;
    { Number of primitives (points, lines, triangles etc depending on PrimitiveType) in mesh to render.
      This value can be calculated while filling buffer and may correspond to less than VerticesCount amount of vertices. }
    property PrimitiveCount: Integer read FPrimitiveCount;
  end;

  // Used by renderer
  function GetBuffer(const Mesh: TCEMesh; Buffer: TCEDataType): PCEMeshData; {$I inline.inc}
  procedure InitTesselationStatus(var Status: TCEDataStatus; BufType: TCEDataType); {$I inline.inc}

implementation

function GetBuffer(const Mesh: TCEMesh; Buffer: TCEDataType): PCEMeshData; {$I inline.inc}
begin
  Result := @Mesh.FBuffer[Buffer];
end;

procedure InitTesselationStatus(var Status: TCEDataStatus; BufType: TCEDataType); {$I inline.inc}
begin
  Status.BufferIndex := DATA_NOT_ALLOCATED;
  Status.Offset := 0;
  Status.Status := dsSizeChanged;
  if BufType = dbtIndex then
    Status.DataUsage := duStreamingIndices
  else
    Status.DataUsage := duStreamingVertices;
end;

{ TCEMesh }

procedure TCEMesh.SetVertexAttribsCount(Buffer: TCEDataType; Count: Integer);
begin
  FBuffer[Buffer].VertexAttribsCount := Count;
  ReallocMem(FBuffer[Buffer].VertexAttribs, FBuffer[Buffer].VertexAttribsCount * SizeOf(TAttributeData));
end;

procedure TCEMesh.SetDataSize(Buffer: TCEDataType; Size: Integer);
begin
  FBuffer[Buffer].Size := Size;
end;

procedure TCEMesh.SetVertexAttrib(Buffer: TCEDataType; Index: Integer; DataType: TAttributeDataType; DataCount: Integer; DataName: PAPIChar);
begin
  Assert(Index < FBuffer[Buffer].VertexAttribsCount, 'Attribute index out of bounds');
  FBuffer[Buffer].VertexAttribs^[Index].DataType := DataType;
  FBuffer[Buffer].VertexAttribs^[Index].Count := DataCount;
  FBuffer[Buffer].VertexAttribs^[Index].Name := DataName;
end;

procedure TCEMesh.InvalidateData(Buffer: TCEDataType; SizeNotChanged: Boolean);
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
  buf: TCEDataType;
begin
  for buf := Low(TCEDataType) to High(TCEDataType) do
    FreeMem(FBuffer[buf].VertexAttribs, FBuffer[buf].VertexAttribsCount * SizeOf(TAttributeData));
  inherited;
end;

procedure TCEMesh.DoInit();
var
  buf: TCEDataType;
begin
  FVerticesCount := 1;
  FIndicesCount := 0;
  FPrimitiveType := ptTriangleList;
  FPrimitiveCount := 1;
  for buf := Low(TCEDataType) to High(TCEDataType) do
  begin
    FBuffer[buf].Size := 0;
    SetVertexAttribsCount(buf, 0);
    InitTesselationStatus(FBuffer[buf].Status, buf);
  end;
end;

procedure TCEMesh.SetUniforms(Manager: TCEUniformsManager);
begin
// do nothing
end;

end.

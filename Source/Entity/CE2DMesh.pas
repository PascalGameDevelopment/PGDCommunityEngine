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
unit CE2DMesh;

interface

uses
  CEMesh, CEVectors;

type
  TVert3 = packed record
    vec: TCEVector3f;
    //u, v: Single;
  end;
  TVert4 = packed record
    vec: TCEVector4f;
    vec2: TCEVector4f;
    width: TCEVector2f;
    //u, v: Single;
  end;
  TVert3Array = array[0..$FFFF] of TVert3;
  TVert4Array = array[0..$FFFF] of TVert4;
  PVert4Array = ^TVert4Array;

  // Circle mesh class
  TCECircleMesh = class(TCEMesh)
  private
  public
    procedure FillVertexBuffer(Dest: Pointer); override;
  end;

  // Line mesh class
  TCELineMesh = class(TCEMesh)
  public
    procedure DoInit(); override;
    procedure FillVertexBuffer(Dest: Pointer); override;
  end;

implementation

uses
  CECommon;

procedure TCECircleMesh.FillVertexBuffer(Dest: Pointer);
const
  SEGMENTS = 16;
  RADIUS = 0.5;
var
  i: Integer;
  v: ^TVert3Array;
begin
  v := Dest;
  for i := 0 to SEGMENTS - 1 do begin
    Vec3f(0, 0, 0, v^[i * 3].vec);
    Vec3f(RADIUS * Cos((i + 1) / SEGMENTS * 2 * pi), RADIUS * Sin((i + 1) / SEGMENTS * 2 * pi), 0, v^[i * 3 + 1].vec);
    Vec3f(RADIUS * Cos(i / SEGMENTS * 2 * pi), RADIUS * Sin(i / SEGMENTS * 2 * pi), 0, v^[i * 3 + 2].vec);
  end;
  FVerticesCount := SEGMENTS * 3;
  FPrimitiveCount := SEGMENTS;
  FVertexSize := SizeOf(TVert3);
end;

procedure TCELineMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(3);
  VertexAttribs^[0].DataType := atSingle;
  VertexAttribs^[0].Size := 4;
  VertexAttribs^[0].Name := 'position';
  VertexAttribs^[1].DataType := atSingle;
  VertexAttribs^[1].Size := 4;
  VertexAttribs^[1].Name := 'data';
  VertexAttribs^[2].DataType := atSingle;
  VertexAttribs^[2].Size := 2;
  VertexAttribs^[2].Name := 'width';
  FPrimitiveType := ptTriangleStrip;
end;

const
  Points: array[0..3] of TCEVector2f = ((x: -0.5; y: 0.3), (x: 0.3; y: 0.3), (x: +0.6; y: -0.3), (x: 0.7; y: -0.3));

procedure TCELineMesh.FillVertexBuffer(Dest: Pointer);
const
  th1 = 0.003; th2 = 0.004;

var
  v: PVert4Array;
  Width, w: Single;
  Dir1, Dir2, Norm1, Norm2: TCEVector2f;
  P1, P2, P31, P32, P41, P42, P3, P4, P5, P6, AD, BD: TCEVector2f;
  i, Count: Integer;
begin
  FVerticesCount := 0;
  FPrimitiveCount := 0;
  Count := Length(Points);
  if Count < 2 then Exit;

  v := Dest;
  Width := 0.05;
  w := Width + th1 + 0.03;

  // First two points
  Dir1 := VectorNormalize(VectorSub(points[0+1], points[0]));
  Norm1 := Vec2f(-Dir1.y, Dir1.x);
  P1 := Vec2f(points[0].x - (Dir1.x + Norm1.x) * w, points[0].y - (Dir1.y + Norm1.y) * w);
  P2 := Vec2f(points[0].x - (Dir1.x - Norm1.x) * w, points[0].y - (Dir1.y - Norm1.y) * w);
  Vec4f(P1.x, P1.y, points[0+1].x, points[0+1].y, v^[0].vec);
  Vec4f(points[0].x - Dir1.x * w, points[0].y - Dir1.y * w, points[0].x, points[0].y, v^[0].vec2);
  Vec2f(Width, th1, v^[0].width);
  Vec4f(P2.x, P2.y, points[0+1].x, points[0+1].y, v^[1].vec);
  Vec4f(points[0].x - Dir1.x * w, points[0].y - Dir1.y * w, points[0].x, points[0].y, v^[1].vec2);
  Vec2f(Width, th1, v^[1].width);
  FVerticesCount := 2;

  i := 0;
  while i < Count-2 do
  begin

    Dir2 := VectorNormalize(VectorSub(Points[i+2], Points[i+1]));
    Norm2 := Vec2f(-Dir2.y, Dir2.x);
    P31 := Vec2f(Points[i+1].x + (Dir1.x - Norm1.x) * w, Points[i+1].y + (Dir1.y - Norm1.y) * w);
    P41 := Vec2f(Points[i+1].x + (Dir1.x + Norm1.x) * w, Points[i+1].y + (Dir1.y + Norm1.y) * w);
    P32 := Vec2f(Points[i+1].x - (Dir2.x + Norm2.x) * w, Points[i+1].y - (Dir2.y + Norm2.y) * w);
    P42 := Vec2f(Points[i+1].x - (Dir2.x - Norm2.x) * w, Points[i+1].y - (Dir2.y - Norm2.y) * w);
    P5  := Vec2f(Points[i+2].x + (Dir2.x - Norm2.x) * w, Points[i+2].y + (Dir2.y - Norm2.y) * w);
    P6  := Vec2f(Points[i+2].x + (Dir2.x + Norm2.x) * w, Points[i+2].y + (Dir2.y + Norm2.y) * w);
    LineIntersect(P1, P31, P32, P5, P3);
    LineIntersect(P2, P41, P42, P6, P4);

    Vec4f(P3.x, P3.y, Points[i+1].x, Points[i+1].y, v^[FVerticesCount].vec);
    AD := VectorSub(P3, Vec2f(Points[i].x - Dir1.x * w, Points[i].y - Dir1.y * w));
    Vec4f(Points[i].x - Dir1.x * w + Dir1.x * VectorMagnitude(AD), Points[i].y - Dir1.y * w + Dir1.y * VectorMagnitude(AD), Points[i].x, Points[i].y, v^[FVerticesCount].vec2);
    Vec2f(Width, th1, v^[FVerticesCount].width);

    Vec4f(P4.x, P4.y, Points[i+1].x, Points[i+1].y, v^[FVerticesCount+1].vec);
    BD := VectorSub(P4, Vec2f(Points[i].x - Dir1.x * w, Points[i].y - Dir1.y * w));
    Vec4f(Points[i].x - Dir1.x * w + Dir1.x * VectorMagnitude(BD), Points[i].y - Dir1.y * w + Dir1.y * VectorMagnitude(BD), Points[i].x, Points[i].y, v^[FVerticesCount+1].vec2);
    Vec2f(Width, th1, v^[FVerticesCount+1].width);

    Inc(FVerticesCount, 2);
    Inc(FPrimitiveCount, 2);

    Vec4f(P3.x, P3.y, Points[i+2].x, Points[i+2].y, v^[FVerticesCount].vec);                 // Two degenerated triangles
    AD := VectorSub(P3, Vec2f(Points[i+2].x + Dir2.x * w, Points[i+2].y + Dir2.y * w));
    Vec4f(Points[i+2].x + Dir2.x * w - Dir2.x * VectorMagnitude(AD), Points[i+2].y + Dir2.y * w - Dir2.y * VectorMagnitude(AD), Points[i+1].x, Points[i+1].y, v^[FVerticesCount].vec2);
    Vec2f(Width, th1, v^[FVerticesCount].width);

    Vec4f(P4.x, P4.y, Points[i+2].x, Points[i+2].y, v^[FVerticesCount+1].vec);
    BD := VectorSub(P4, Vec2f(Points[i+2].x + Dir2.x * w, Points[i+2].y + Dir2.y * w));
    Vec4f(Points[i+2].x + Dir2.x * w - Dir2.x * VectorMagnitude(BD), Points[i+2].y + Dir2.y * w - Dir2.y * VectorMagnitude(BD), Points[i+1].x, Points[i+1].y, v^[FVerticesCount+1].vec2);
    Vec2f(Width, th1, v^[FVerticesCount+1].width);

    Inc(FVerticesCount, 2);
    Inc(FPrimitiveCount, 2);
    
    Dir1 := Dir2;

    Inc(i);
  end;
  Dir2 := VectorNormalize(VectorSub(Points[i+1], Points[i]));
  Norm2 := Vec2f(-Dir2.y, Dir2.x);
  P5  := Vec2f(Points[i+1].x + (Dir2.x - Norm2.x) * w, Points[i+1].y + (Dir2.y - Norm2.y) * w);
  P6  := Vec2f(Points[i+1].x + (Dir2.x + Norm2.x) * w, Points[i+1].y + (Dir2.y + Norm2.y) * w);
  Vec4f(P5.x, P5.y, Points[i+1].x, Points[i+1].y, v^[FVerticesCount].vec);
  Vec4f(Points[i+1].x + Dir2.x * w, Points[i+1].y + Dir2.y * w, Points[i].x, Points[i].y, v^[FVerticesCount].vec2);
  Vec2f(Width, th1, v^[FVerticesCount].width);
  Vec4f(P6.x, P6.y, Points[i+1].x, Points[i+1].y, v^[FVerticesCount+1].vec);
  Vec4f(Points[i+1].x + Dir2.x * w, Points[i+1].y + Dir2.y * w, Points[i].x, Points[i].y, v^[FVerticesCount+1].vec2);
  Vec2f(Width, th1, v^[FVerticesCount+1].width);

  Inc(FVerticesCount, 2);
  Inc(FPrimitiveCount, 2);
  FVertexSize := SizeOf(TVert4);
end;

end.
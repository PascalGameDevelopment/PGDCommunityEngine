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

procedure TCELineMesh.FillVertexBuffer(Dest: Pointer);
const
  th1 = 0.004; th2 = 0.004;

  procedure fillVB(x1, y1, x2, y2, w1, w2: Single; v: PVert4Array);
  var
    dirx, diry, len: Single;
  begin
    dirx := x2 - x1;
    diry := y2 - y1;
    len := dirx * dirx + diry * diry;
    len := sqrt(len);
    dirx := dirx / len;
    diry := diry / len;

    // (x, y, w, len) th (midX, midY, endX, endY)
    //Vec4f(x1 - (dirx - diry) * (w1+th1), y1 - (diry + dirx) * (w1+th1), w1, len, v^[0].vec);
    //Vec4f(x1 - dirx * (w1+th1), y1 - diry * (w1+th1), th1, v^[0].vec2);
    Vec4f(x1 - (dirx - diry) * (w1+th1), y1 - (diry + dirx) * (w1+th1), x2, y2, v^[0].vec);
    Vec4f(x1 - dirx * (w1+th1), y1 - diry * (w1+th1), x1, y1, v^[0].vec2);
    Vec2f(w1, th1, v^[0].width);

    //Vec4f(x1 - (dirx + diry) * (w1+th1), y1 - (diry - dirx) * (w1+th1), w1, len, v^[1].vec);
    //Vec4f(x1 - dirx * (w1+th1), y1 - diry * (w1+th1), th1, v^[1].vec2);
    Vec4f(x1 - (dirx + diry) * (w1+th1), y1 - (diry - dirx) * (w1+th1), x2, y2, v^[1].vec);
    Vec4f(x1 - dirx * (w1+th1), y1 - diry * (w1+th1), x1, y1, v^[1].vec2);
    Vec2f(w1, th1, v^[1].width);

    //Vec4f(x2 + (dirx - diry) * (w2+th2), y2 + (diry + dirx) * (w2+th2), w2, len, v^[2].vec);
    //Vec4f(x2 + dirx * (w2+th2), y2 + diry * (w2+th2), th2, v^[2].vec2);
    Vec4f(x2 + (dirx - diry) * (w2+th2), y2 + (diry + dirx) * (w2+th2), x2, y2, v^[2].vec);
    Vec4f(x2 + dirx * (w2+th2), y2 + diry * (w2+th2), x1, y1, v^[2].vec2);
    Vec2f(w2, th2, v^[2].width);


    //Vec4f(x1 - (dirx - diry) * (w1+th1), y1 - (diry + dirx) * (w1+th1), w1, len, v^[3].vec);
  //  Vec4f(x1 - dirx * (w1+th1), y1 - diry * (w1+th1), th1, v^[3].vec2);
    Vec4f(x1 - (dirx - diry) * (w1+th1), y1 - (diry + dirx) * (w1+th1), x2, y2, v^[3].vec);
    Vec4f(x1 - dirx * (w1+th1), y1 - diry * (w1+th1), x1, y1, v^[3].vec2);
    Vec2f(w1, th1, v^[3].width);

    //Vec4f(x2 + (dirx - diry) * (w2+th2), y2 + (diry + dirx) * (w2+th2), w2, len, v^[4].vec);
  //  Vec4f(x2 + dirx * (w2+th2), y2 + diry * (w2+th2), th2, v^[4].vec2);
    Vec4f(x2 + (dirx - diry) * (w2+th2), y2 + (diry + dirx) * (w2+th2), x2, y2, v^[4].vec);
    Vec4f(x2 + dirx * (w2+th2), y2 + diry * (w2+th2), x1, y1, v^[4].vec2);
    Vec2f(w2, th2, v^[4].width);

    //Vec4f(x2 + (dirx + diry) * (w2+th2), y2 + (diry - dirx) * (w2+th2), w2, len, v^[5].vec);
  //  Vec4f(x2 + dirx * (w2+th2), y2 + diry * (w2+th2), th2, v^[5].vec2);
    Vec4f(x2 + (dirx + diry) * (w2+th2), y2 + (diry - dirx) * (w2+th2), x2, y2, v^[5].vec);
    Vec4f(x2 + dirx * (w2+th2), y2 + diry * (w2+th2), x1, y1, v^[5].vec2);
    Vec2f(w2, th2, v^[5].width);
  end;

var
  v: PVert4Array;
  x1, y1, x2, y2, w1, w2: Single;
begin
  x1 := -0.5; y1 := -0.1;
  x2 := +0.5; y2 := +0.1;
  w1 := 0.05; w2 := 0.02;

  v := Dest;
  fillVB(-0.5, -0.1, 0.5, 0.1, 0.02, 0.07, v);
  fillVB(0.5, 0.1, 0.3, 0.5, 0.07, 0.01, PtrOffs(v, 6*SizeOf(v^[0])));

  FVerticesCount := 12;
  FPrimitiveCount := 4;
  FVertexSize := SizeOf(TVert4);
end;

end.
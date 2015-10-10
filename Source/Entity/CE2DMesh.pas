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
  CEBaseTypes, CEMesh, CEVectors, CEUniformsManager;

type
  // Circle mesh class
  TCECircleMesh = class(TCEMesh)
  private
  public
    procedure FillVertexBuffer(Dest: Pointer); override;
  end;

  // 2D antialiased multi-segment line mesh class
  TCELineMesh = class(TCEMesh)
  private
    FWidth, FThreshold: Single;
    FCount: Integer;
    FPoints: P2DPointArray;
    procedure SetWidth(Value: Single);
    procedure SetSoftness(Value: Single);
    procedure SetCount(Value: Integer);
    function GetPoint(Index: Integer): TCEVector2f;
    procedure SetPoint(Index: Integer; const Value: TCEVector2f);
  public
    destructor Destroy; override;
    procedure DoInit(); override;
    procedure FillVertexBuffer(Dest: Pointer); override;
    procedure SetUniforms(Manager: TCEUniformsManager); override;
    // Line width
    property Width: Single read FWidth write SetWidth;
    // Antialiasing softness. 0 - no antialiasing.
    property Softness: Single read FThreshold write SetSoftness;
    // Number of points
    property Count: Integer read FCount write SetCount;
    // Array of points in multi-segment line
    property Point[Index: Integer]: TCEVector2f read GetPoint write SetPoint;
  end;

    // 2D antialiased polygon mesh class
  TCEPolygonMesh = class(TCEMesh)
  private
    FThreshold: Single;
    FColor: TCEColor;
    FCount: Integer;
    FPoints: P2DPointArray;
    procedure SetSoftness(Value: Single);
    procedure SetColor(const Value: TCEColor);
    procedure SetCount(Value: Integer);
    function GetPoint(Index: Integer): TCEVector2f;
    procedure SetPoint(Index: Integer; const Value: TCEVector2f);
    procedure CalcVertex(const P1, D1, P2, D2: TCEVector2f; out Res: TCEVector2f);
  public
    destructor Destroy; override;
    procedure DoInit(); override;
    procedure FillVertexBuffer(Dest: Pointer); override;
    procedure SetUniforms(Manager: TCEUniformsManager); override;
    // Antialiasing softness. 0 - no antialiasing.
    property Softness: Single read FThreshold write SetSoftness;
    // Fill color
    property Color: TCEColor read FColor write SetColor;
    // Number of points
    property Count: Integer read FCount write SetCount;
    // Array of points in polygon
    property Point[Index: Integer]: TCEVector2f read GetPoint write SetPoint;
  end;

  // Vertex buffer type with position element
  TVBRecPos = packed record
    vec: TCEVector3f;
    //u, v: Single;
  end;
  TVBPos = array[0..$FFFF] of TVBRecPos;

implementation

uses
  CECommon;

type
  TLineVertex = packed record
    vec: TCEVector4f;
    vec2: TCEVector4f;
  end;
  TLineVertexBuffer = array[0..$FFFF] of TLineVertex;

procedure TCECircleMesh.FillVertexBuffer(Dest: Pointer);
const
  SEGMENTS = 16;
  RADIUS = 0.5;
var
  i: Integer;
  v: ^TVBPos;
begin
  v := Dest;
  for i := 0 to SEGMENTS - 1 do begin
    Vec3f(0, 0, 0, v^[i * 3].vec);
    Vec3f(RADIUS * Cos((i + 1) / SEGMENTS * 2 * pi), RADIUS * Sin((i + 1) / SEGMENTS * 2 * pi), 0, v^[i * 3 + 1].vec);
    Vec3f(RADIUS * Cos(i / SEGMENTS * 2 * pi), RADIUS * Sin(i / SEGMENTS * 2 * pi), 0, v^[i * 3 + 2].vec);
  end;
  FVerticesCount := SEGMENTS * 3;
  FPrimitiveCount := SEGMENTS;
  FVertexSize := SizeOf(TVBRecPos);
end;

procedure TCELineMesh.SetWidth(Value: Single);
begin
  FWidth := Value;
  VertexBuffer.Status := tsChanged;
end;

procedure TCELineMesh.SetSoftness(Value: Single);
begin
  FThreshold := Value;
  VertexBuffer.Status := tsChanged;
end;

procedure TCELineMesh.SetCount(Value: Integer);
begin
  if FCount = Value then Exit;
  FCount := Value;
  ReallocMem(FPoints, FCount * SizeOf(TCEVector2f));
end;

function TCELineMesh.GetPoint(Index: Integer): TCEVector2f;
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  Result := FPoints^[Index];
end;

procedure TCELineMesh.SetPoint(Index: Integer; const Value: TCEVector2f);
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  FPoints^[Index] := Value;
end;

destructor TCELineMesh.Destroy;
begin
  SetCount(0);
  inherited Destroy();
end;

procedure TCELineMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(2);
  VertexAttribs^[0].DataType := adtSingle;
  VertexAttribs^[0].Size := 4;
  VertexAttribs^[0].Name := 'position';
  VertexAttribs^[1].DataType := adtSingle;
  VertexAttribs^[1].Size := 4;
  VertexAttribs^[1].Name := 'data';
  FPrimitiveType := ptTriangleStrip;
  FWidth := 2/1024;
  FThreshold := 0;
  Count := 0;
end;

procedure CalcDir(const P1, P2: TCEVector2f; w: Single; out Dir: TCEVector2f; out Dist: Single);
var
  Zero: Integer;
begin
  Dir := VectorSub(P2, P1);
  Dist := Sqrt(sqr(Dir.X) + sqr(Dir.Y));
  Zero := Ord(Dist = 0);
  Dist := w * (1 - Zero) / (Dist + Zero);
  Dir.X := Dist * Dir.X;
  Dir.Y := Dist * Dir.Y;
end;

procedure TCELineMesh.FillVertexBuffer(Dest: Pointer);
var
  v: ^TLineVertexBuffer;
  w, oow, dist: Single;
  Dir1, Dir2, Norm1, Norm2: TCEVector2f;
  P1, P2, P3, P4: TCEVector2f;
  i: Integer;

procedure PutVertex(Ind: Integer; P, Dir: TCEVector2f; var Dest: TLineVertex);
var
  AD: TCEVector2f;
begin
  AD := VectorSub(P, Vec2f(FPoints^[Ind].x - Dir.x, FPoints^[Ind].y - Dir.y));
  Vec4f(P.x, P.y, FPoints^[Ind + 1].x, FPoints^[Ind + 1].y, Dest.vec);
  Vec4f(FPoints^[Ind].x - Dir.x + Dir.x * VectorMagnitude(AD) * oow,
        FPoints^[Ind].y - Dir.y + Dir.y * VectorMagnitude(AD) * oow, FPoints^[Ind].x, FPoints^[Ind].y, Dest.vec2);
end;

procedure PutVertexDegen(Ind: Integer; P, Dir: TCEVector2f; var Dest: TLineVertex);
var
  AD: TCEVector2f;
begin
  AD := VectorSub(P, Vec2f(FPoints^[Ind].x + Dir.x, FPoints^[Ind].y + Dir.y));
  Vec4f(P.x, P.y, FPoints^[Ind].x, FPoints^[Ind].y, Dest.vec);
  Vec4f(FPoints^[Ind].x + Dir.x - Dir.x * VectorMagnitude(AD) * oow,
        FPoints^[Ind].y + Dir.y - Dir.y * VectorMagnitude(AD) * oow, FPoints^[Ind-1].x, FPoints^[Ind-1].y, Dest.vec2);
end;

procedure PutVertexSide(Ind: Integer; P, Dir: TCEVector2f; var Dest: TLineVertex);
begin
  Vec4f(P.x, P.y, FPoints^[Ind+1].x, FPoints^[Ind+1].y, Dest.vec);
  Vec4f(FPoints^[Ind].x + Dir.x, FPoints^[Ind].y + Dir.y, FPoints^[Ind].x, FPoints^[Ind].y, Dest.vec2);
end;

begin
  FVerticesCount := 0;
  FPrimitiveCount := 0;
  if Count < 2 then Exit;

  v := Dest;
  w := FWidth + FThreshold;// + 0.03;
  oow := 1 / w;

  // First two points
  CalcDir(FPoints^[0], FPoints^[0+1], w, Dir1, dist);
  Norm1 := Vec2f(-Dir1.y, Dir1.x);
  P1 := Vec2f(FPoints^[0].x - (Dir1.x + Norm1.x), FPoints^[0].y - (Dir1.y + Norm1.y));
  P2 := Vec2f(FPoints^[0].x - (Dir1.x - Norm1.x), FPoints^[0].y - (Dir1.y - Norm1.y));

  PutVertexSide(0, P1, VectorScale(Dir1, -1), v^[0]);
  PutVertexSide(0, P2, VectorScale(Dir1, -1), v^[1]);
  FVerticesCount := 2;

  i := 0;
  while i < Count-2 do
  begin
    CalcDir(FPoints^[i+1], FPoints^[i+2], w, Dir2, dist);
    Norm2 := Vec2f(-Dir2.y, Dir2.x);
    if LineIntersect(VectorSub(FPoints^[i+0], Norm1), VectorSub(FPoints^[i+1], Norm1),
                     VectorSub(FPoints^[i+1], Norm2), VectorSub(FPoints^[i+2], Norm2), P3) <> irIntersect then
      P3 := VectorSub(FPoints^[i+1], Norm2);
    if LineIntersect(VectorAdd(FPoints^[i+0], Norm1), VectorAdd(FPoints^[i+1], Norm1),
                     VectorAdd(FPoints^[i+1], Norm2), VectorAdd(FPoints^[i+2], Norm2), P4) <> irIntersect then
      P4 := VectorAdd(FPoints^[i+1], Norm2);

    PutVertex(i, P3, Dir1, v^[FVerticesCount]);
    PutVertex(i, P4, Dir1, v^[FVerticesCount+1]);

    PutVertexDegen(i+2, P3, Dir2, v^[FVerticesCount+2]);
    PutVertexDegen(i+2, P4, Dir2, v^[FVerticesCount+3]);

    Inc(FVerticesCount, 4);
    Inc(FPrimitiveCount, 4);

    Dir1 := Dir2;
    Norm1 := Norm2;

    Inc(i);
  end;
  CalcDir(FPoints^[i], FPoints^[i+1], w, Dir2, dist);
  Norm2 := Vec2f(-Dir2.y, Dir2.x);
  Vec4f(FPoints^[i+1].x + Dir2.x - Norm2.x, FPoints^[i+1].y + Dir2.y - Norm2.y, FPoints^[i+1].x, FPoints^[i+1].y, v^[FVerticesCount].vec);
  Vec4f(FPoints^[i+1].x + Dir2.x, FPoints^[i+1].y + Dir2.y, FPoints^[i].x, FPoints^[i].y, v^[FVerticesCount].vec2);
  Vec4f(FPoints^[i+1].x + Dir2.x + Norm2.x, FPoints^[i+1].y + Dir2.y + Norm2.y, FPoints^[i+1].x, FPoints^[i+1].y, v^[FVerticesCount+1].vec);
  Vec4f(FPoints^[i+1].x + Dir2.x, FPoints^[i+1].y + Dir2.y, FPoints^[i].x, FPoints^[i].y, v^[FVerticesCount+1].vec2);

  Inc(FVerticesCount, 2);
  Inc(FPrimitiveCount, 2);
  FVertexSize := SizeOf(TLineVertex);
  VertexBuffer.Status := tsChanged;
end;

procedure TCELineMesh.SetUniforms(Manager: TCEUniformsManager);
var
  inv: Single;
begin
  inv := 1 / (FWidth + FThreshold);
  Manager.SetSingleVec2('width', Vec2f(inv, MinS(1, FWidth / (2 / 1024)) * FWidth / MaxS(0.0000001, inv * FThreshold)));
end;

{ TCEPolygonMesh }

procedure TCEPolygonMesh.SetSoftness(Value: Single);
begin
  FThreshold := Value;
  VertexBuffer.Status := tsChanged;
end;

procedure TCEPolygonMesh.SetColor(const Value: TCEColor);
begin
  FColor := Value;
  VertexBuffer.Status := tsChanged;
end;

procedure TCEPolygonMesh.SetCount(Value: Integer);
begin
  if FCount = Value then Exit;
  FCount := Value;
  ReallocMem(FPoints, FCount * SizeOf(TCEVector2f));
end;

function TCEPolygonMesh.GetPoint(Index: Integer): TCEVector2f;
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  Result := FPoints^[Index];
end;

procedure TCEPolygonMesh.SetPoint(Index: Integer; const Value: TCEVector2f);
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  FPoints^[Index] := Value;
end;

procedure TCEPolygonMesh.CalcVertex(const P1, D1, P2, D2: TCEVector2f; out Res: TCEVector2f);
var
  Dist: Single;
  V: TCEVector2f;
begin
  if (RayIntersect(P1, D1, P2, D2, Res) <> irIntersect) then
    Res := P2
  else begin
    V := VectorSub(Res, P2);
    Dist := Sqrt(V.x * V.x + V.y * V.y);
    if Dist > FThreshold * 4 then
    begin
      Res := VectorAdd(P2, VectorScale(V, FThreshold*4/Dist));
    end;
  end;
end;

destructor TCEPolygonMesh.Destroy;
begin
  SetCount(0);
  inherited Destroy();
end;

procedure TCEPolygonMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(1);
  VertexAttribs^[0].DataType := adtSingle;
  VertexAttribs^[0].Size := 3;
  VertexAttribs^[0].Name := 'position';
  FPrimitiveType := ptTriangleList;
  FThreshold := 2;
  FColor := GetColor(255, 255, 255, 255);
  Count := 3;
  Point[0] := Vec2f(-0.5, -0.5);
  Point[1] := Vec2f( 0.0,  0.6);
  Point[2] := Vec2f( 0.5, -0.4);
end;

procedure TCEPolygonMesh.FillVertexBuffer(Dest: Pointer);
const
  tris = 3;
  EPSILON = 0.001;
var
  v: ^TVBPos;
  Center, D00, D01, D12, N00, N01, N12, P1, P2, P3, P4: TCEVector2f;
  i, i0, i1, i2: Integer;
  dist00, dist01, dist12, sharp: Single;
begin
  FVerticesCount := 0;
  FPrimitiveCount := 0;
  if Count < 3 then Exit;

  v := Dest;

  Center.x := 0;
  Center.y := 0;
  for i := 0 to Count - 1 do
    VectorAdd(Center, FPoints^[i], Center);
  VectorScale(Center, Center, 1 / Count);

  for i := 0 to Count - 1 do
  begin
    i0 := (i - 1 + Count) mod Count;
    i1 := (i + 1) mod Count;
    i2 := (i + 2) mod Count;

    VectorSub(D00, FPoints[i0], FPoints[i]);
    VectorSub(D01, FPoints[i],  FPoints[i1]);
    VectorSub(D12, FPoints[i1], FPoints[i2]);

    dist00 := FThreshold / VectorMagnitude(D00)/2;
    dist01 := FThreshold / VectorMagnitude(D01)/2;
    dist12 := FThreshold / VectorMagnitude(D12)/2;
    sharp := 1;
    if (abs(D01.x) < EPSILON) or (abs(D01.y) < EPSILON) or (abs(abs(D01.x) - abs(D01.y)) < EPSILON) then
      sharp := 2;

    N00 := Vec2f(D00.y * dist00, -D00.x * dist00);
    N01 := Vec2f(D01.y * dist01, -D01.x * dist01);
    N12 := Vec2f(D12.y * dist12, -D12.x * dist12);

    CalcVertex(VectorSub(FPoints^[i0], N00), D00, VectorSub(FPoints^[i],  N01), D01, P1);
    CalcVertex(VectorSub(FPoints^[i],  N01), D01, VectorSub(FPoints^[i1], N12), D12, P2);
    CalcVertex(VectorAdd(FPoints^[i0], N00), D00, VectorAdd(FPoints^[i],  N01), D01, P3);
    CalcVertex(VectorAdd(FPoints^[i],  N01), D01, VectorAdd(FPoints^[i1], N12), D12, P4);

    Vec3f(Center.x, Center.y, 1, v^[i * tris*3].vec);
    Vec3f(P1.x, P1.y, 1, v^[i * tris*3 + 1].vec);
    Vec3f(P2.x, P2.y, 1, v^[i * tris*3 + 2].vec);

    Vec3f(FPoints[i].x*0+P3.x, FPoints[i].y*0+P3.y, 0, v^[i * tris*3 + 3].vec);
    Vec3f(P1.x, P1.y, 1*sharp, v^[i * tris*3 + 4].vec);
    Vec3f(P2.x, P2.y, 1*sharp, v^[i * tris*3 + 5].vec);

    Vec3f(FPoints[i].x*0+P3.x, FPoints[i].y*0+P3.y, 0, v^[i * tris*3 + 6].vec);
    Vec3f(P2.x, P2.y, 1*sharp, v^[i * tris*3 + 7].vec);
    Vec3f(FPoints[i1].x*0+P4.x, FPoints[i1].y*0+P4.y, 0, v^[i * tris*3 + 8].vec);
  end;
  FVerticesCount := Count * 3 * tris;
  FPrimitiveCount := Count * tris;
  FVertexSize := SizeOf(v^[0]);
  VertexBuffer.Status := tsChanged;
end;

procedure TCEPolygonMesh.SetUniforms(Manager: TCEUniformsManager);
var
  inv: Single;
begin
  Manager.SetSingleVec4('color', Vec4f(Color.R * ONE_OVER_255, Color.G * ONE_OVER_255, Color.B * ONE_OVER_255, Color.A * ONE_OVER_255));
end;

end.

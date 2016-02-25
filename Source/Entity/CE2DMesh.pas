(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CE2DMesh.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE mesh entity unit)

The unit contains various 2D mesh classes

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CE2DMesh;

interface

uses
  CEBaseTypes, CEMesh, CEUniformsManager;

type
  // Sprite mesh class
  TCESpriteMesh = class(TCEMesh)
  private
    FFrame: Integer;
    FFramesPerTextureCol, FFramesPerTextureRow: Integer;
    FX, FY: Single;
    FWidth, FHeight: Single;
  protected
    procedure DoInit(); override;
  public
    procedure SetTextureParameters(FramesPerTextureCol, FramesPerTextureRow: Integer);
    procedure WriteMeshData(Destinations: PDataDestinations); override;
    property Frame: Integer read FFrame write FFrame;
    property X: Single read Fx write Fx;
    property Y: Single read Fy write Fy;
    property Width: Single read FWidth write FWidth;
    property Height: Single read FHeight write FHeight;
  end;

  // Circle mesh class
  TCECircleMesh = class(TCEMesh)
  private
    FX, FY: Single;
    FRadius, FThreshold: Single;
    FSegments: Integer;
    FColor: TCEColor;
    procedure SetX(Value: Single);
    procedure SetY(Value: Single);
    procedure SetRadius(Value: Single);
    procedure SetSegments(Value: Integer);
    procedure SetSoftness(Value: Single);
    procedure SetColor(const Value: TCEColor);
  protected
    procedure DoInit(); override;
    procedure ApplyParameters(); override;
  public
    procedure WriteMeshData(Destinations: PDataDestinations); override;
    procedure SetUniforms(Manager: TCEUniformsManager); override;
    // X coordinate of point center
    property X: Single read FX write SetX;
    // Y coordinate of point center
    property Y: Single read FY write SetY;
    // Point radius
    property Radius: Single read FRadius write SetRadius;
    // Number of segments in polygon approximation of a circle
    property Segments: Integer read FSegments write SetSegments;
    // Antialiasing softness. 0 - no antialiasing.
    property Softness: Single read FThreshold write SetSoftness;
    // Fill color
    property Color: TCEColor read FColor write SetColor;
  end;

  // Abstract base class for multipoint meshes such as lines or polygons
  TCENPointMesh = class(TCEMesh)
  private
    procedure SetCount(Value: Integer);
    function GetPoint(Index: Integer): TCEVector2f;
    procedure SetPoint(Index: Integer; const Value: TCEVector2f);
  protected
    FCount: Integer;
    FPoints: P2DPointArray;
  public
    destructor Destroy(); override;
    // Number of points
    property Count: Integer read FCount write SetCount;
    // Array of points in multi-segment line
    property Point[Index: Integer]: TCEVector2f read GetPoint write SetPoint;
    // Points as pointer to array
    property Points: P2DPointArray read FPoints;
  end;

  // 2D antialiased multi-segment line mesh class
  TCELineMesh = class(TCENPointMesh)
  private
    FWidth, FThreshold: Single;
    procedure SetWidth(Value: Single);
    procedure SetSoftness(Value: Single);
  protected
    procedure DoInit(); override;
    procedure ApplyParameters(); override;
  public
    procedure WriteMeshData(Destinations: PDataDestinations); override;
    procedure SetUniforms(Manager: TCEUniformsManager); override;
    // Line width
    property Width: Single read FWidth write SetWidth;
    // Antialiasing softness. 0 - no antialiasing.
    property Softness: Single read FThreshold write SetSoftness;
  end;

  // 2D antialiased polygon mesh class
  TCEPolygonMesh = class(TCENPointMesh)
  private
    FThreshold: Single;
    FColor: TCEColor;
    procedure SetSoftness(Value: Single);
    procedure SetColor(const Value: TCEColor);
  protected
    procedure DoInit(); override;
    procedure ApplyParameters(); override;
  public
    procedure WriteMeshData(Destinations: PDataDestinations); override;
    procedure SetUniforms(Manager: TCEUniformsManager); override;
    // Antialiasing softness. 0 - no antialiasing.
    property Softness: Single read FThreshold write SetSoftness;
    // Fill color
    property Color: TCEColor read FColor write SetColor;
  end;

  // Vertex buffer type with position element
  TVBRecPos = packed record
    vec: TCEVector3f;
    //u, v: Single;
  end;
  TVBPos = array[0..$FFFF] of TVBRecPos;

implementation

uses
  CECommon,
  CEVectors;

type
  TLineVertex = packed record
    vec: TCEVector4f;
    vec2: TCEVector4f;
  end;
  PLineVertex = ^TLineVertex;
  TLineVertexBuffer = array[0..$FFFF] of TLineVertex;

  TSpriteVertex = packed record
    xyuv: TCEVector4f;
  end;
  PSpriteVertex = ^TSpriteVertex;
  TSpriteVertexBuffer = array[0..$FFFF] of TSpriteVertex;

  TCVRes = (rIntersect, rCoDir, rInvDir, rSharp);

{ TCECircleMesh }

procedure TCECircleMesh.SetX(Value: Single);
begin
  FX := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCECircleMesh.SetY(Value: Single);
begin
  FY := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCECircleMesh.SetRadius(Value: Single);
begin
  FRadius := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCECircleMesh.SetSegments(Value: Integer);
begin
  InvalidateData(dbtVertex1, (FSegments = Value));
  FSegments := Value;
end;

procedure TCECircleMesh.SetSoftness(Value: Single);
begin
  if Value > 0 then
    FThreshold := Value
  else
    FThreshold := EPSILON_SINGLE;
  InvalidateData(dbtVertex1, true);
end;

procedure TCECircleMesh.SetColor(const Value: TCEColor);
begin
  FColor := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCECircleMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(dbtVertex1, 1);
  SetVertexAttrib(dbtVertex1, 0, adtSingle, 3, 'position');
  FPrimitiveType := ptTriangleFan;
  SetDataSize(dbtVertex1, SizeOf(TVBRecPos));
  FRadius := 0.5;
  FThreshold := 2 / 1024;
  FSegments := 8;
  FColor := GetColor(255, 255, 255, 255);
  ApplyParameters();
end;

procedure TCECircleMesh.ApplyParameters();
begin
  FVerticesCount := 1 + FSegments * 2;
end;

procedure TCECircleMesh.WriteMeshData(Destinations: PDataDestinations);
var
  i: Integer;
  v: ^TVBPos;
  Rad: Single;
begin
  v := Destinations^[dbtVertex1];
  Vec3f(FX, FY, 0, v^[0].vec);
  Rad := (FRadius + FThreshold) / Cos(pi / FSegments);
  for i := 0 to FSegments - 1 do begin
    Vec3f(FX + Rad * Cos(i       / FSegments * 2 * pi), FY + Rad * Sin(i       / FSegments * 2 * pi), 0, v^[i * 2 + 1].vec);
    Vec3f(FX + Rad * Cos((i + 1) / FSegments * 2 * pi), FY + Rad * Sin((i + 1) / FSegments * 2 * pi), 0, v^[i * 2 + 2].vec);
  end;
  FPrimitiveCount := FSegments;
  InvalidateData(dbtVertex1, true);
end;

procedure TCECircleMesh.SetUniforms(Manager: TCEUniformsManager);
begin
  Manager.SetSingleVec4('data', Vec4f(FX, FY, 1/(Sqr(FThreshold) + 2 * FThreshold * FRadius), FRadius + FThreshold));
  Manager.SetSingleVec4('color', Vec4f(Color.R * ONE_OVER_255, Color.G * ONE_OVER_255, Color.B * ONE_OVER_255, Color.A * ONE_OVER_255));
end;

{ TCENPointMesh }

procedure TCENPointMesh.SetCount(Value: Integer);
begin
  if FCount = Value then Exit;
  FCount := Value;
  ReallocMem(FPoints, FCount * SizeOf(TCEVector2f));
  InvalidateData(dbtIndex, false);
  InvalidateData(dbtVertex1, false);
end;

function TCENPointMesh.GetPoint(Index: Integer): TCEVector2f;
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  Result := FPoints^[Index];
end;

procedure TCENPointMesh.SetPoint(Index: Integer; const Value: TCEVector2f);
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  FPoints^[Index] := Value;
end;

destructor TCENPointMesh.Destroy();
begin
  SetCount(0);
  inherited Destroy();
end;

{ TCELineMesh }

procedure TCELineMesh.SetWidth(Value: Single);
begin
  FWidth := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCELineMesh.SetSoftness(Value: Single);
begin
  FThreshold := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCELineMesh.ApplyParameters();
begin
  FVerticesCount := 4 + MaxI(0, Count - 2) * 8;
end;

procedure TCELineMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(dbtVertex1, 2);
  SetVertexAttrib(dbtVertex1, 0, adtSingle, 4, 'position');
  SetVertexAttrib(dbtVertex1, 1, adtSingle, 4, 'data');
  FPrimitiveType := ptTriangleStrip;
  FWidth := 2 / 1024;
  FThreshold := 0;
  Count := 0;
  SetDataSize(dbtVertex1, SizeOf(TLineVertex));
  ApplyParameters();
end;

procedure CalcDir(const P1, P2: TCEVector2f; w: Single; out Dir: TCEVector2f);
var
  Dist: Single;
begin
  VectorSub(Dir, P2, P1);
  Dist := Sqr(Dir.X) + Sqr(Dir.Y);
  if Dist > 0 then
    Dist := w * InvSqrt(Dist)
  else
    Dist := 0;
  Dir.X := Dist * Dir.X;
  Dir.Y := Dist * Dir.Y;
end;

function CalcVertex(const P1, D1, P2, D2: TCEVector2f; Width: Single; out Res: TCEVector2f): TCVRes;
begin
  if (RayIntersect(P1, D1, P2, D2, Res) = irIntersect) then
    Result := rIntersect
  else if VectorDot(D1, D2) < 0 then
  begin
    Res := P2;
    Result := rInvDir;
  end else begin
    Res := P2;
    Result := rCoDir;
  end;
end;

procedure TCELineMesh.WriteMeshData(Destinations: PDataDestinations);
var
  w, oow: Single;
  Dir1, Dir2: TCEVector2f;

procedure PutVertexPair(const A, B, P1, P2, Dir: TCEVector2f; var Dest: PLineVertex);
var
  d: Single;
begin
  d := ((P1.x - B.x) * Dir.x + (P1.y - B.y) * Dir.y) * oow * oow;
  Vec4f(P1.x, P1.y, B.x, B.y, Dest^.vec);
  Vec4f(B.x + Dir.x * d, B.y + Dir.y * d, A.x, A.y, Dest^.vec2);
  Inc(Dest);
  d := ((P2.x - B.x) * Dir.x + (P2.y - B.y) * Dir.y) * oow * oow;
  Vec4f(P2.x, P2.y, B.x, B.y, Dest^.vec);
  Vec4f(B.x + Dir.x * d, B.y + Dir.y * d, A.x, A.y, Dest^.vec2);
  Inc(Dest);
end;

procedure CalcPoints(const P0, P1, Dir1, Dir2, OffsVec, LimDir: TCEVector2f; out OP0, OP1: TCEVector2f);
begin
  RayIntersect(P0, Dir1, OffsVec, LimDir, OP0);
  RayIntersect(P1, Dir2, OffsVec, LimDir, OP1);
end;

procedure CalcSegment(const P0, P1, P2: TCEVector2f; ind: Integer; var Dest: PLineVertex);
const
  LIMIT = 5;
var
  Tmp1, Tmp2: TCEVector2f;
  P3, P4, P5, Norm1, Norm2: TCEVector2f;
  res: TCVRes;
  D, Sign: Single;
  MinD: Single;
begin
  CalcDir(P1, P2, w, Dir2);
  Norm1 := Vec2f(-Dir1.y, Dir1.x);
  Norm2 := Vec2f(-Dir2.y, Dir2.x);
  res := CalcVertex(VectorSub(P0, Norm1), Dir1, VectorSub(P1, Norm2), Dir2, w, P3);
  Sign := 2 * Ord(SignedAreaX2(Dir1, Dir2) < 0) - 1;
  VectorSub(Tmp1, P1, P3);
  MinD := MinS(VectorMagnitudeSq(VectorSub(P0, P1)), VectorMagnitudeSq(VectorSub(P2, P1)));
  D := Tmp1.x * Tmp1.x + Tmp1.y * Tmp1.y;
  if (res <> rIntersect) or (MinD < w * w * 4) or (D > (MinD + w + w * w)) then  // Almost 0
  begin
    VectorAdd(Tmp1, P1, Dir1);
    VectorSub(Tmp2, P1, Dir2);
    PutVertexPair(P0, P1, VectorAdd(Tmp1, Norm1), VectorSub(Tmp1, Norm1), Dir1, Dest);
    Vec4f(Tmp1.x - Norm1.x, Tmp1.y - Norm1.y, 0, 0, Dest^.vec);
    Inc(Dest);
    Vec4f(Tmp2.x + Norm2.x, Tmp2.y + Norm2.y, 0, 0, Dest^.vec);
    Inc(Dest);
    PutVertexPair(P1, P2, VectorAdd(Tmp2, Norm2), VectorSub(Tmp2, Norm2), Dir2, Dest);
    Inc(FPrimitiveCount, 6);
  end else begin
    if D < Sqr(w * LIMIT) then
    begin
      VectorAdd(P4, P1, Tmp1);
      PutVertexPair(P0, P1, P4, P3, Dir1, Dest);
      PutVertexPair(P1, P2, P4, P3, Dir2, Dest);
      Inc(FPrimitiveCount, 4);
    end else begin
      D := w * InvSqrt(D);
      if Sign < 0 then
      begin
        VectorAdd(P3, P1, Tmp1);
        VectorSub(Tmp1, P1, P3);
        CalcPoints(VectorSub(P0, Norm1), VectorSub(P1, Norm2), Dir1, Dir2,
          VectorAdd(P1, VectorScale(Tmp1, LIMIT * D)), Vec2f(Tmp1.y * D, -Tmp1.x * D), P4, P5);
        PutVertexPair(P0, P1, P3, P4, Dir1, Dest);
        PutVertexPair(P0, P1, P3, P5, Dir1, Dest);
        PutVertexPair(P1, P2, P3, P4, Dir2, Dest);
        PutVertexPair(P1, P2, P3, P5, Dir2, Dest);
      end else begin
        CalcPoints(VectorAdd(P0, Norm1), VectorAdd(P1, Norm2), Dir1, Dir2,
          VectorAdd(P1, VectorScale(Tmp1, LIMIT * D)), Vec2f(Tmp1.y * D, -Tmp1.x * D), P4, P5);
        PutVertexPair(P0, P1, P4, P3, Dir1, Dest);
        PutVertexPair(P0, P1, P5, P3, Dir1, Dest);
        PutVertexPair(P1, P2, P4, P3, Dir2, Dest);
        PutVertexPair(P1, P2, P5, P3, Dir2, Dest);
      end;
      Inc(FPrimitiveCount, 8);
    end;
  end;
  Dir1 := Dir2;
end;

var
  i: Integer;
  v: PLineVertex;
  Tmp1, Tmp2: TCEVector2f;

begin
  FPrimitiveCount := 0;
  if Count < 2 then Exit;

  v := Destinations^[dbtVertex1];
  w := FWidth + FThreshold;
  oow := 1 / w;

  // First two points
  CalcDir(FPoints^[0], FPoints^[1], w, Dir1);
  Tmp2 := Vec2f(-Dir1.y, Dir1.x);
  VectorSub(Tmp1, FPoints^[0], Dir1);
  PutVertexPair(FPoints^[0], FPoints^[1], VectorAdd(Tmp1, Tmp2), VectorSub(Tmp1, Tmp2), Dir1, v);

  i := 0;
  while i < Count - 2 do
  begin
    CalcSegment(FPoints^[i + 0], FPoints^[i + 1], FPoints^[i + 2], 0, v);
    Inc(i);
  end;
  CalcDir(FPoints^[i], FPoints^[i + 1], w, Dir2);
  VectorAdd(Tmp1, FPoints^[i + 1], Dir2);
  Tmp2 := Vec2f(-Dir2.y, Dir2.x);
  PutVertexPair(FPoints^[i], FPoints^[i + 1], VectorAdd(Tmp1, Tmp2), VectorSub(Tmp1, Tmp2), Dir2, v);

  Inc(FPrimitiveCount, 2);
  InvalidateData(dbtVertex1, true);
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
  InvalidateData(dbtVertex1, (FThreshold <> 0) = (Value <> 0));
  FThreshold := Value;
end;

procedure TCEPolygonMesh.SetColor(const Value: TCEColor);
begin
  FColor := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCEPolygonMesh.ApplyParameters();
begin
  FVerticesCount := Count * 3 * (1 + 2 * Ord(FThreshold > 0));
end;

procedure TCEPolygonMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(dbtVertex1, 1);
  SetVertexAttrib(dbtVertex1, 0, adtSingle, 3, 'position');
  FPrimitiveType := ptTriangleList;
  FThreshold := 2;
  FColor := GetColor(255, 255, 255, 255);
  SetDataSize(dbtVertex1, SizeOf(TVBRecPos));
  ApplyParameters();
end;

procedure TCEPolygonMesh.WriteMeshData(Destinations: PDataDestinations);

function Sharpness(dx, dy: Single): Single;
const
  EPSILON = 0.002;
begin
  Result := 1 - Ord((abs(dx) < EPSILON) or (abs(dy) < EPSILON) or (abs(abs(dx) - abs(dy)) < EPSILON)) * 0.7;
end;

var
  v: ^TVBPos;
  Center, D01, D12, N01, N12, P1, P2, P3, P4: TCEVector2f;
  i, i1, i2: Integer;
begin
  FPrimitiveCount := 0;
  if Count < 3 then Exit;

  v := Destinations^[dbtVertex1];

  Center.x := 0;
  Center.y := 0;
  for i := 0 to Count - 1 do
    VectorAdd(Center, FPoints^[i], Center);
  VectorScale(Center, Center, 1 / Count);

  VectorSub(D12, FPoints^[Count - 1], FPoints^[0]);
  VectorSub(D01, FPoints^[0],  FPoints^[1]);
  VectorScale(N01, Vec2f(D01.y, -D01.x), FThreshold / VectorMagnitude(D01) * 0.5 * Sharpness(D01.x, D01.y));

  CalcVertex(VectorSub(FPoints^[Count - 1], VectorScale(Vec2f(D12.y, -D12.x),
                       FThreshold / VectorMagnitude(D12) * 0.5 * Sharpness(D12.x, D12.y))),
             D12, VectorSub(FPoints^[0],  N01), D01, FThreshold * 4, P1);
  VectorAdd(P3, FPoints^[0],  VectorSub(FPoints^[0],  P1));

  i1 := 1;
  i2 := 2;
  for i := 0 to Count - 1 do
  begin
    VectorSub(D12, FPoints^[i1], FPoints^[i2]);
    VectorNormalize(N12, Vec2f(D12.y, -D12.x), FThreshold * 0.5 * Sharpness(D12.x, D12.y));

    CalcVertex(VectorSub(FPoints^[i], N01), D01, VectorSub(FPoints^[i1], N12), D12, FThreshold * 4, P2);
    VectorAdd(P4, FPoints^[i1], VectorSub(FPoints^[i1], P2));

    Vec3f(Center.x, Center.y, 1, v^[0].vec);
    Vec3f(P2.x, P2.y, 1, v^[1].vec);
    Vec3f(P1.x, P1.y, 1, v^[2].vec);
    v := PtrOffs(v, SizeOf(v^[0]) * 3);

    if FThreshold > 0 then
    begin
      Vec3f(P3.x, P3.y, 0, v^[0].vec);
      Vec3f(P1.x, P1.y, 1, v^[1].vec);
      Vec3f(P2.x, P2.y, 1, v^[2].vec);

      Vec3f(P3.x, P3.y, 0, v^[3].vec);
      Vec3f(P2.x, P2.y, 1, v^[4].vec);
      Vec3f(P4.x, P4.y, 0, v^[5].vec);
      v := PtrOffs(v, SizeOf(v^[0]) * 6);
    end;

    D01 := D12;
    N01 := N12;
    P1 := P2;
    P3 := P4;
    i1 := i1 + 1 - Count * Ord(i1 = Count - 1);
    i2 := i2 + 1 - Count * Ord(i2 = Count - 1);
  end;
  FPrimitiveCount := Count * (1 + 2 * Ord(FThreshold > 0));
  InvalidateData(dbtVertex1, true);
end;

procedure TCEPolygonMesh.SetUniforms(Manager: TCEUniformsManager);
begin
  Manager.SetSingleVec4('color', Vec4f(Color.R * ONE_OVER_255, Color.G * ONE_OVER_255, Color.B * ONE_OVER_255, Color.A * ONE_OVER_255));
end;

{ TCESpriteMesh }

procedure TCESpriteMesh.DoInit();
begin
  inherited;
  SetVertexAttribsCount(dbtVertex1, 1);
  SetVertexAttrib(dbtVertex1, 0, adtSingle, 4, 'xyuv');
  SetDataSize(dbtVertex1, SizeOf(TSpriteVertex));
  FPrimitiveType := ptTriangleList;
  FPrimitiveCount := 2;
  FVerticesCount := 6;
  Width := 0.1;
  Height := 0.1;
  SetTextureParameters(1, 1);
  Frame := 0;
end;

procedure TCESpriteMesh.SetTextureParameters(FramesPerTextureCol, FramesPerTextureRow: Integer);
begin
  Assert((FramesPerTextureRow > 0) and (FramesPerTextureCol > 0), ClassName() + ': Invalid parameters');
  FFramesPerTextureRow := FramesPerTextureRow;
  FFramesPerTextureCol := FramesPerTextureCol;
  InvalidateData(dbtVertex1, true);
end;

procedure TCESpriteMesh.WriteMeshData(Destinations: PDataDestinations);
var
  vb: ^TSpriteVertexBuffer;
  w, h, u, v, uw, vh: Single;
begin
  vb := Destinations^[dbtVertex1];
  w := width * 0.5;
  h := height * 0.5;
  uw := 1 / FFramesPerTextureRow;
  vh := 1 / FFramesPerTextureCol;
  u := (Frame mod FFramesPerTextureRow) * uw;
  v := (Frame div FFramesPerTextureRow) * vh;
  Vec4f(x - w, y + h, u, v, vb^[0].xyuv);
  Vec4f(x - w, y - h, u, v + vh, vb^[1].xyuv);
  Vec4f(x + w, y - h, u + uw, v + vh, vb^[2].xyuv);
  Vec4f(x - w, y + h, u, v, vb^[3].xyuv);
  Vec4f(x + w, y - h, u + uw, v + vh, vb^[4].xyuv);
  Vec4f(x + w, y + h, u + uw, v, vb^[5].xyuv);
  InvalidateData(dbtVertex1, true);
end;

end.

(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEVectors.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Vector math)

Vector, matrix and quaternion math for PGDCE.

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
@author(Zaflis (v.teemu@gmail.com))
}

{$I PGDCE.inc}
unit CEVectors;

interface

uses
  CEBaseTypes;

type
  TCEMatrix3 = array[0..2, 0..2] of single;
  TCEMatrix4 = array[0..3, 0..3] of single;
  TCEMatrix = TCEMatrix4;

    // Line or segment intersection test result
  TIntersectResult = (irIntersect, irCoincident, irParallel, irOutOfSegment);

  function VectorNormalize(const V: TCEVector2f): TCEVector2f; overload;
  procedure VectorNormalize(out Result: TCEVector2f; const V: TCEVector2f); overload;
  procedure VectorNormalize(out Result: TCEVector2f; const V: TCEVector2f; len: Single); overload;
  function VectorNormalize(const V: TCEVector3f): TCEVector3f; overload;
  function VectorAdd(const V1, V2: TCEVector2f): TCEVector2f; overload;
  procedure VectorAdd(out Result: TCEVector3f; const V1, V2: TCEVector3f); overload;
  procedure VectorAdd(out Result: TCEVector2f; const V1, V2: TCEVector2f); overload;
  function VectorSub(const V1, V2: TCEVector2f): TCEVector2f; overload;
  procedure VectorSub(out Result: TCEVector3f; const V1, V2: TCEVector3f); overload;
  procedure VectorSub(out Result: TCEVector2f; const V1, V2: TCEVector2f); overload;
  function VectorScale(const V: TCEVector2f; const Factor: Single): TCEVector2f; overload;
  procedure VectorScale(out Result: TCEVector3f; const V: TCEVector3f; const Factor: Single); overload;
  procedure VectorScale(out Result: TCEVector2f; const V: TCEVector2f; const Factor: Single); overload;
  function VectorAdd(const V1, V2: TCEVector3f): TCEVector3f; overload;
  function VectorSub(const V1, V2: TCEVector3f): TCEVector3f; overload;
  function VectorScale(const V: TCEVector3f; const Factor: Single): TCEVector3f; overload;
  function VectorMagnitude(const V: TCEVector2f): Single; overload;
  function VectorMagnitude(const V: TCEVector3f): Single; overload;
  function VectorMagnitudeSq(const V: TCEVector2f): Single; overload;
  function VectorMagnitudeSq(const V: TCEVector3f): Single; overload;
  function LineIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
  function RayIntersect(const AP1, ADir, BP1, BDir: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
  function SegmentIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
  // Signed area of ABC triangle > 0 if points specified in CCW order and < 0 otherwise
  function SignedAreaX2(const A, B, C: TCEVector2f): Single; overload;
  // Signed area of a triangle with edges AB and AC > 0 if points specified in CCW order and < 0 otherwise
  function SignedAreaX2(const AB, AC: TCEVector2f): Single; overload;

  function VectorDot(const V1, V2: TCEVector2f): Single; overload;
  function VectorDot(const V1, V2: TCEVector3f): Single; overload;
  function VectorCross(const V1, V2: TCEVector3f): TCEVector3f; overload;
  function VectorReflect(const V, N: TCEVector2f): TCEVector2f; overload;
  function VectorReflect(const V, N: TCEVector3f): TCEVector3f; overload;
  function GetNearestPointIndex(const Points: P2DPointArray; Count: Integer; const Point: TCEVector2f): Integer;

implementation

function VectorNormalize(const V: TCEVector2f): TCEVector2f; overload;
var
  Sq: Single;
  Zero: Integer;
begin
  Sq := Sqrt(sqr(V.X) + sqr(V.Y));
  Zero := Ord(Sq = 0);
  Sq := (1 - Zero) / (Sq + Zero);
  Result.X := Sq * V.X;
  Result.Y := Sq * V.Y;
end;

function VectorNormalize(const V: TCEVector3f): TCEVector3f; overload;
var
  Sq: Single;
  Zero: Integer;
begin
  Sq := Sqrt(sqr(V.X) + sqr(V.Y) + sqr(V.Z));
  Zero := Ord(Sq = 0);
  Sq := (1 - Zero) / (Sq + Zero);
  Result.X := Sq * V.X;
  Result.Y := Sq * V.Y;
  Result.Z := Sq * V.Z;
end;

procedure VectorNormalize(out Result: TCEVector2f; const V: TCEVector2f); overload;
var
  Sq: Single;
  Zero: Integer;
begin
  Sq := Sqrt(sqr(V.X) + sqr(V.Y));       // TODO: switch to invsqrt()
  Zero := Ord(Sq = 0);
  Sq := (1 - Zero) / (Sq + Zero);
  Result.X := Sq * V.X;
  Result.Y := Sq * V.Y;
end;

procedure VectorNormalize(out Result: TCEVector2f; const V: TCEVector2f; len: Single); overload;
var
  Sq: Single;
  Zero: Integer;
begin
  Sq := Sqrt(sqr(V.X) + sqr(V.Y));       // TODO: switch to invsqrt()
  Zero := Ord(Sq = 0);
  Sq := len * (1 - Zero) / (Sq + Zero);
  Result.X := Sq * V.X;
  Result.Y := Sq * V.Y;
end;

function VectorAdd(const V1, V2: TCEVector2f): TCEVector2f; overload;
begin
  Result.X := V1.X + V2.X;
  Result.Y := V1.Y + V2.Y;
end;

procedure VectorAdd(out Result: TCEVector2f; const V1, V2: TCEVector2f); overload;
begin
  Result.X := V1.X + V2.X;
  Result.Y := V1.Y + V2.Y;
end;

function VectorSub(const V1, V2: TCEVector2f): TCEVector2f; overload;
begin
  Result.X := V1.X - V2.X;
  Result.Y := V1.Y - V2.Y;
end;

procedure VectorSub(out Result: TCEVector2f; const V1, V2: TCEVector2f); overload;
begin
  Result.X := V1.X - V2.X;
  Result.Y := V1.Y - V2.Y;
end;

function VectorScale(const V: TCEVector2f; const Factor: Single): TCEVector2f; overload;
begin
  Result.X := V.X * Factor;
  Result.Y := V.Y * Factor;
end;

procedure VectorScale(out Result: TCEVector2f; const V: TCEVector2f; const Factor: Single); overload;
begin
  Result.X := V.X * Factor;
  Result.Y := V.Y * Factor;
end;

function VectorAdd(const V1, V2: TCEVector3f): TCEVector3f; overload;
begin
  with Result do begin
    X := V1.X + V2.X;
    Y := V1.Y + V2.Y;
    Z := V1.Z + V2.Z;
  end;
end;

procedure VectorAdd(out Result: TCEVector3f; const V1, V2: TCEVector3f); overload;
begin
  with Result do begin
    X := V1.X + V2.X;
    Y := V1.Y + V2.Y;
    Z := V1.Z + V2.Z;
  end;
end;

function VectorSub(const V1, V2: TCEVector3f): TCEVector3f; overload;
begin
  with Result do begin
    X := V1.X - V2.X;
    Y := V1.Y - V2.Y;
    Z := V1.Z - V2.Z;
  end;
end;

procedure VectorSub(out Result: TCEVector3f; const V1, V2: TCEVector3f); overload;
begin
  with Result do begin
    X := V1.X - V2.X;
    Y := V1.Y - V2.Y;
    Z := V1.Z - V2.Z;
  end;
end;

function VectorScale(const V: TCEVector3f; const Factor: Single): TCEVector3f; overload;
begin
  Result.X := V.X * Factor;
  Result.Y := V.Y * Factor;
  Result.Z := V.Z * Factor;
end;

procedure VectorScale(out Result: TCEVector3f; const V: TCEVector3f; const Factor: Single); overload;
begin
  Result.X := V.X * Factor;
  Result.Y := V.Y * Factor;
  Result.Z := V.Z * Factor;
end;

function VectorMagnitude(const V: TCEVector2f): Single; overload;
begin
  Result := Sqrt(Sqr(V.X) + Sqr(V.Y));
end;

function VectorMagnitude(const V: TCEVector3f): Single; overload;
begin
  Result := Sqrt(Sqr(V.X) + Sqr(V.Y) + Sqr(V.Z));
end;

function VectorMagnitudeSq(const V: TCEVector2f): Single; overload;
begin
  Result := Sqr(V.X) + Sqr(V.Y);
end;

function VectorMagnitudeSq(const V: TCEVector3f): Single; overload;
begin
  Result := Sqr(V.X) + Sqr(V.Y) + Sqr(V.Z);
end;

const
  EPSILON = 0.00001;

function LineIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
begin
  Result := RayIntersect(AP1, Vec2f(AP2.x - AP1.x, AP2.y - AP1.y), BP1, Vec2f(BP2.x - BP1.x, BP2.y - BP1.y), Hit);
end;

function RayIntersect(const AP1, ADir, BP1, BDir: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
var
  Denominator, NumA, NumB: Single;
  Ua: Single;
begin
  Denominator := BDir.y * ADir.x - BDir.x * ADir.y;
  NumA := BDir.x * (AP1.y - BP1.y) - BDir.y * (AP1.x - BP1.x);
  NumB := ADir.x * (AP1.y - BP1.y) - ADir.y * (AP1.x - BP1.x);
  if (Abs(Denominator) < EPSILON) then
  begin
    if (Abs(NumA) < EPSILON) and (Abs(NumB) < EPSILON) then
      Result := irCoincident
    else
      Result := irParallel;
  end else begin
    Denominator := 1 / Denominator;
    ua := NumA * Denominator;
    Hit.X := AP1.x + ua * ADir.x;
    Hit.Y := AP1.y + ua * ADir.y;
    Result := irIntersect;
  end;
end;

function SegmentIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
var
  Denominator, NumA, NumB: Single;
  a, Ub: Single;
begin
  Denominator := (BP2.y - BP1.y) * (AP2.x - AP1.x) - (BP2.x - BP1.x) * (AP2.y - AP1.y);
  NumA := (BP2.x - BP1.x) * (AP1.y - BP1.y) - (BP2.y - BP1.y) * (AP1.x - BP1.x);
  NumB := (AP2.x - AP1.x) * (AP1.y - BP1.y) - (AP2.y - AP1.y) * (AP1.x - BP1.x);

  if (Abs(Denominator) < EPSILON) then
  begin
    if (Abs(NumA) < EPSILON) and (Abs(NumB) < EPSILON) then
      Result := irCoincident
    else
      Result := irParallel;
  end else begin
    Denominator := 1 / Denominator;
    a := NumA * Denominator;
    ub := NumB * Denominator;

    if (a >= 0.0) and (a <= 1.0) and (ub >= 0.0) and (ub <= 1.0) then
    begin
      Hit.X := AP1.x + a * (AP2.x - AP1.x);
      Hit.Y := AP1.y + a * (AP2.y - AP1.y);
      Result := irIntersect;
    end else
      Result := irOutOfSegment;
  end;
end;

function SignedAreaX2(const A, B, C: TCEVector2f): Single; overload;
begin
  Result := (B.x - A.x) * (C.y - A.y) - (B.y - A.y) * (C.x - A.x);
end;

function SignedAreaX2(const AB, AC: TCEVector2f): Single; overload;
begin
  Result := AB.x * AC.y - AB.y * AC.x;
end;

function VectorDot(const V1, V2: TCEVector2f): Single; overload;
begin
  Result := V1.X*V2.X + V1.Y*V2.Y;
end;

function VectorDot(const V1, V2: TCEVector3f): Single; overload;
begin
  Result := V1.X*V2.X + V1.Y*V2.Y + V1.Z*V2.Z;
end;

function VectorCross(const V1, V2: TCEVector3f): TCEVector3f; overload;
begin
  Result.X := V1.Y*V2.Z - V1.Z*V2.Y;
  Result.Y := V1.Z*V2.X - V1.X*V2.Z;
  Result.Z := V1.X*V2.Y - V1.Y*V2.X;
end;

function VectorReflect(const V, N: TCEVector2f): TCEVector2f; overload;
// N - reflecting surface's normal
var d : Single;
begin
  d := -VectorDot(V, N) * 2;
  Result.X := (d * N.X) + V.X;
  Result.Y := (d * N.Y) + V.Y;
end;

function VectorReflect(const V, N: TCEVector3f): TCEVector3f; overload;
// N - reflecting surface's normal
var d : Single;
begin
  d := -VectorDot(V, N) * 2;
  Result.X := (d * N.X) + V.X;
  Result.Y := (d * N.Y) + V.Y;
  Result.Z := (d * N.Z) + V.Z;
end;

function GetNearestPointIndex(const Points: P2DPointArray; Count: Integer; const Point: TCEVector2f): Integer;
var
  i: Integer;
  dist, maxDist: Single;
  P: ^TCEVector2f;
begin
  Result := 0;
  P := @Points^[0];
  maxDist := VectorMagnitudeSq(VectorSub(P^, Point));
  for i := 1 to Count - 1 do
  begin
    Inc(P);
    Dist := VectorMagnitudeSq(VectorSub(P^, Point));
    if Dist < maxDist then
    begin
      Result := i;
      maxDist := Dist;
    end;
  end;
end;

end.

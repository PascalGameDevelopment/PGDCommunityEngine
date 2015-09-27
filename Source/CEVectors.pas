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

uses CEMath;

type
  TCEVector2f = packed record
    x, y: single;
  end;
  TCEVector3f = packed record
    x, y, z: single;
  end;
  TCEVector4f = packed record
    x, y, z, w: single;
  end;

  TCEVector3fArray = array[0..$FFFFFF] of TCEVector3f;

  TCEMatrix3 = array[0..2, 0..2] of single;
  TCEMatrix4 = array[0..3, 0..3] of single;
  TCEMatrix = TCEMatrix4;

  // Line or segment intersection test result
  TIntersectResult = (irIntersect, irCoincident, irParallel, irOutOfSegment);

  function Vec2f(x, y: Single): TCEVector2f; overload;
  procedure Vec2f(x, y: Single; out dest: TCEVector2f); overload;
  function Vec3f(x, y, z: Single): TCEVector3f; overload;
  procedure Vec3f(x, y, z: Single; out dest: TCEVector3f); overload;
  function Vec4f(x, y, z, W: Single): TCEVector4f; overload;
  procedure Vec4f(x, y, z, W: Single; out dest: TCEVector4f); overload;

  function VectorNormalize(const V: TCEVector2f): TCEVector2f; overload;
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
  function LineIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
  function SegmentIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;

implementation

function Vec2f(x, y: Single): TCEVector2f;
begin
  Vec2f(x, y, Result);
end;

procedure Vec2f(x, y: Single; out dest: TCEVector2f);
begin
  dest.x := x;
  dest.y := y;
end;

function Vec3f(x, y, z: Single): TCEVector3f;
begin
  Vec3f(x, y, z, Result);
end;

procedure Vec3f(x, y, z: Single; out dest: TCEVector3f);
begin
  dest.x := x;
  dest.y := y;
  dest.z := z;
end;

function Vec4f(x, y, z, W: Single): TCEVector4f; overload;
begin
  Vec4f(x, y, z, w, Result);
end;

procedure Vec4f(x, y, z, W: Single; out dest: TCEVector4f); overload;
begin
  dest.x := x;
  dest.y := y;
  dest.z := z;
  dest.w := W;
end;

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

const
  EPSILON = 0.000001;

function LineIntersect(const AP1, AP2, BP1, BP2: TCEVector2f; out Hit: TCEVector2f): TIntersectResult;
var
  Denominator, NumA, NumB: Single;
  Ua, Ub: Single;
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
    ua := NumA * Denominator;
    ub := NumB * Denominator;
    Hit.X := AP1.x + ua * (AP2.x - AP1.x);
    Hit.Y := AP1.y + ua * (AP2.y - AP1.y);
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

end.

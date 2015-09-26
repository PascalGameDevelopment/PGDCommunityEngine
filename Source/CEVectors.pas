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

  function Vec2f(x, y: Single): TCEVector2f; overload;
  procedure Vec2f(x, y: Single; out dest: TCEVector2f); overload;
  function Vec3f(x, y, z: Single): TCEVector3f; overload;
  procedure Vec3f(x, y, z: Single; out dest: TCEVector3f); overload;
  function Vec4f(x, y, z, W: Single): TCEVector4f; overload;
  procedure Vec4f(x, y, z, W: Single; out dest: TCEVector4f); overload;

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

end.


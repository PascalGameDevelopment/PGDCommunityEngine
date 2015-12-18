(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CELocation.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE spatial entity unit)

The unit contains spatial (located in space) entity definition

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CELocation;

interface

uses
  CEEntity, CEVectors;

type
  // Spatial entity location in 3D world which may be additionally subdivided
  TLocation = record
  case Integer of
    0: (Loc: TCEVector4f;);
    1: (Pos: TCEVector3f; Area: Integer;);
    2: (XYZ: TCEVector3f; Row, Col: Word;);
  end;

  // Game entity component which represents entity's position in space
  TCELocation = class(TCEBaseEntity)
  private
    FLocation: TLocation;
  public
    property Location: TLocation read FLocation write FLocation;
  published
  end;

implementation

end.


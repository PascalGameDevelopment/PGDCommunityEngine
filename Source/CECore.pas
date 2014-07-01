(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CECore.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Core)

PGDCE Core engine class

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

unit CECore;

interface

uses
  CEBaseApplication,
  CEBaseRenderer,
  CEBaseAudio,
  CEBaseInput,
  CEBasePhysics,
  CEBaseNetwork,

  CEEntityManager;

type
  TCECore = class
  private
    {Private declarations}
  protected
    {Protected declarations}
    fApplication: TCEBaseApplication;
    fRenderer: TCEBaseRenderer;
    fAudio: TCEBaseAudio;
    fInput: TCEBaseInput;
    fPhysics: TCEBasePhysics;
    fNetwork: TCEBaseNetwork;

    fEntityManager: TCEEntityManager;
  public
    {Public declarations}
    constructor Create;
    destructor Destroy; override;

    property EntityManager: TCEEntityManager read fEntityManager;
  published
    {Published declarations}
    property Application: TCEBaseApplication read fApplication write fApplication;
    property Renderer: TCEBaseRenderer read fRenderer write fRenderer;
    property Audio: TCEBaseAudio read fAudio write fAudio;
    property Input: TCEBaseInput read fInput write fInput;
    property Physics: TCEBasePhysics read fPhysics write fPhysics;
    property Network: TCEBaseNetwork read fNetwork write fNetwork;
  end;

implementation

constructor TCECore.Create;
begin
  inherited;

  fApplication := nil;
  fRenderer := nil;
  fAudio := nil;
  fInput := nil;
  fPhysics := nil;

  fEntityManager := TCEEntityManager.Create;
end;

destructor TCECore.Destroy;
begin
  try
    fEntityManager.Free;
  except
  end;

  inherited;
end;

end.

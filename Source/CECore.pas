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
    constructor create;
    destructor destroy; override;

    property entityManager:TCEEntityManager read fEntityManager;
  published
    {Published declarations}
    property application:TCEBaseApplication read fApplication write fApplication;
    property renderer:TCEBaseRenderer read fRenderer write fRenderer;
    property audio:TCEBaseAudio read fAudio write fAudio;
    property input:TCEBaseInput read fInput write fInput;
    property physics:TCEBasePhysics read fPhysics write fPhysics;
    property network:TCEBaseNetwork read fNetwork write fNetwork;
  end;

implementation

constructor TCECore.create;
begin
  inherited;

  fApplication:=nil;
  fRenderer:=nil;
  fAudio:=nil;
  fInput:=nil;
  fPhysics:=nil;

  fEntityManager:=TCEEntityManager.create;
end;

destructor TCECore.destroy;
begin
  try
    fEntityManager.free;
  except
  end;

  inherited;
end;

end.

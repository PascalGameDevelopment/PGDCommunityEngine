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

  CEEntity,

  CEOSUtils;

type
  TCECore = class
  private
    procedure DoUpdate();
    procedure DoRender();
  protected
    FApplication: TCEBaseApplication;
    fRenderer: TCEBaseRenderer;
    fAudio: TCEBaseAudio;
    fInput: TCEBaseInput;
    fPhysics: TCEBasePhysics;
    fNetwork: TCEBaseNetwork;
    fEntityManager: TCEEntityManager;
    procedure Update(DeltaTime: Single); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    // Launch the engine's main cycle
    procedure Run();
    property EntityManager: TCEEntityManager read fEntityManager;
    property Application: TCEBaseApplication read FApplication write FApplication;
    property Renderer: TCEBaseRenderer read fRenderer write fRenderer;
    property Audio: TCEBaseAudio read fAudio write fAudio;
    property Input: TCEBaseInput read fInput write fInput;
    property Physics: TCEBasePhysics read fPhysics write fPhysics;
    property Network: TCEBaseNetwork read fNetwork write fNetwork;
  end;

implementation

{ TCECore }

procedure TCECore.DoUpdate();
begin
end;

procedure TCECore.DoRender();
begin
end;

procedure TCECore.Update(DeltaTime: Single);
begin
end;

constructor TCECore.Create;
begin
  inherited;

  fEntityManager := TCEEntityManager.Create();
end;

destructor TCECore.Destroy;
begin
  try
    fInput.Free;
  except
  end;

  try
    fEntityManager.Free;
  except
  end;

  try
    fPhysics.Free;
  except
  end;

  try
    fNetwork.Free;
  finally
  end;

  try
    fAudio.Free;
  except
  end;

  try
    fRenderer.Free;
  except
  end;

  try
    FApplication.Free;
  except
  end;

  inherited;
end;

procedure TCECore.Run();
begin
  while not FApplication.Terminated do
  begin
    FApplication.Process();
    DoUpdate();
    DoRender();
  end;
end;

end.

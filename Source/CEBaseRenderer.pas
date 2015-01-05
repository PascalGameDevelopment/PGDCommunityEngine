(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEBaseRenderer.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Base Renderer)

Base definition for the renderer class within PGDCE that will sit between the
rest of the engine and the chosen graphics API

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$Include PGDCE.inc}
unit CEBaseRenderer;

interface

uses
  CEBaseApplication;

type
  TCEBaseRenderer = class
  private

  protected
    // One time initialization
    procedure DoInit(); virtual; abstract;
    // Initialization of GAPI - render context or device
    function DoInitGAPI(App: TCEBaseApplication): Boolean; virtual; abstract;
    // Finalization of GAPI - render context or device
    procedure DoFinalizeGAPI(); virtual; abstract;
  public
    constructor Create(App: TCEBaseApplication);
    destructor Destroy(); override;
    // Performs necessary GAPI calls to finish and present current frame
    procedure NextFrame(); virtual; abstract;
  end;

implementation

{ TCEBaseRenderer }

constructor TCEBaseRenderer.Create(App: TCEBaseApplication);
begin
  DoInit();
  DoInitGAPI(App);
end;

destructor TCEBaseRenderer.Destroy;
begin
  DoFinalizeGAPI();
  inherited;
end;

end.


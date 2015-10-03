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
  CEBaseTypes, CEBaseApplication, CEMesh, CEMaterial, CEUniformsManager;

type
  // Render target clear flags
  TCEClearFlag = (cfColor, cfDepth, cfStencil);
  // Render target clear flag set
  TCEClearFlags = set of TCEClearFlag;

  TCEShaderSource = string;

  // Types of identifiers used in a shader
  TCEShaderIdentKind = (ikINVALID, ikATTRIBUTE, ikVARYING, ikUNIFORM);

  // Identifier used in shader
  TCEShaderIdent = record
    Kind: TCEShaderIdentKind;
    Name, TypeStr: TCEShaderSource;
    Location: Integer;
  end;
  TCEShaderIdentList = array[0..$FFFF] of TCEShaderIdent;
  PCEShaderIdentList = ^TCEShaderIdentList;

  TCEBaseRenderer = class
  private
  protected
    FUniformsManager: TCEUniformsManager;
    FActive: Boolean;
    // One time initialization
    procedure DoInit(); virtual; abstract;
    // Initialization of GAPI - render context or device
    function DoInitGAPI(App: TCEBaseApplication): Boolean; virtual; abstract;
    // Finalization of GAPI - render context or device
    procedure DoFinalizeGAPI(); virtual; abstract;
  public
    constructor Create(App: TCEBaseApplication);
    destructor Destroy(); override;
    // Performs render state setup
    procedure ApplyRenderPass(Pass: TCERenderPass); virtual; abstract;
    // Performs necessary draw calls to render the given geometry
    procedure RenderMesh(Mesh: TCEMesh); virtual; abstract;
    // Clear current render target
    procedure Clear(Flags: TCEClearFlags; Color: TCEColor; Z: Single; Stencil: Cardinal); virtual; abstract;
    // Performs necessary GAPI calls to finish and present current frame
    procedure NextFrame(); virtual; abstract;
    // Determines if the renderer should render anything
    property Active: Boolean read FActive write FActive;
  end;

implementation

{ TCEBaseRenderer }

constructor TCEBaseRenderer.Create(App: TCEBaseApplication);
begin
  DoInit();
  Active := DoInitGAPI(App);
end;

destructor TCEBaseRenderer.Destroy;
begin
  DoFinalizeGAPI();
  inherited;
end;

end.


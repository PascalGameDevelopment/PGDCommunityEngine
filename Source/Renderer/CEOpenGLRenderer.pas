(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOpenGLRenderer.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE OpenGL Renderer)

Definition for the PGDCE OpenGL renderer class

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

unit CEOpenGLRenderer;

interface

uses
  CEBaseRenderer, dglOpenGL in '..\dglOpenGL.pas';

type

  { TCEOpenGLRenderer }

  TCEOpenGLRenderer = class(TCEBaseRenderer)
  private
    {Private declarations}
  protected
    {Protected declarations}
  public
    {Public declarations}
    FarZ: single;
    NearZ: single;
    FOV: single;
    AspectRatio: single;
    constructor Create(doInit: boolean = true);
    procedure InitGL;
  published
    {Published declarations}
  end;

implementation

{ TCEOpenGLRenderer }

constructor TCEOpenGLRenderer.Create(doInit: boolean);
begin
  dglOpenGL.InitOpenGL();
  dglOpenGL.ReadExtensions();

  FarZ := 1000;
  NearZ := 0.1;
  FOV := 45;
  AspectRatio := 1.33;

  if doInit then InitGL();
end;

procedure TCEOpenGLRenderer.InitGL;
begin
  // Init projection matrix
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(FOV, AspectRatio, NearZ, FarZ);

  // Init modelview matrix
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  // Init GL settings
  glClearColor(0, 0, 0, 0);
  glColor3f(1, 1, 1);
  glEnable(GL_TEXTURE_2D);
  glCullFace(GL_NONE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.008);
  glEnable(GL_NORMALIZE);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
end;

end.

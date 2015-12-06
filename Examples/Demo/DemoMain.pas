(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is demomain.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(Crossplatform demo main unit)

This is main unit for crossplatform demo application

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit DemoMain;

interface

uses
  sysutils,
  CELog,
  CEBaseApplication,
  {$IFDEF WINDOWS}
  CEWindowsApplication,
    {$IFDEF OPENGLES_EMULATION}
    CEOpenGLES2Renderer,
    {$ELSE}
    CEOpenGL4Renderer,
    {$ENDIF}
  {$ELSE}
    {$IFDEF XWINDOWS}
    CEXWindowApplication,
    CEOpenGL4Renderer,
    {$ENDIF}
    {$IFDEF MOBILE}
    CEOpenGLES2Renderer,
    {$ENDIF}
  {$ENDIF}
  CEBaseRenderer,
  CEBaseInput,
  CEMesh, CECommon, CEOSUtils, CEResource, CEGameEntity, CE2DMesh, CEUniformsManager,
  CEBaseTypes, CEMessage, CEInputMessage, CEVectors, CEImageResource, CEMaterial, CECore;

const
  VS: AnsiString = 'attribute vec3 position;'#10 +
                  ' varying mediump vec3 pos;'#10 +
                  ' void main() {'#10 +
                  '   gl_Position = vec4(position.xy, 0.0, 1.0);'#10 +
                  '   pos = position;'#10 +
                  ' }'#10;

  PS: AnsiString = 'varying mediump vec3 pos;'#10 +
                  ' uniform lowp vec4 color;'#10 +
                  ' uniform sampler2D s_texture0;'#10 +
                  ' void main() {'#10 +
                  '   gl_FragColor.rgb = color.rgb;'#10 +
                  '   gl_FragColor.a = color.a*pos.z;'#10 +
                  ' }'#10;

type
  TDemo = class(TObject)
  private
    App: TCEBaseApplication;
    Renderer: TCEBaseRenderer;
    Core: TCECore;
    PolyMesh: TCEPolygonMesh;
    Mat: TCEMaterial;
    PolyPass: TCERenderPass;
    Sh: TCETextResource;
    ClickPoint: TCEVector2f;
    Ind: Integer;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Process();
  end;

implementation

constructor TDemo.Create();
begin
  Renderer := TCERendererClass.Create(nil);
  Core := TCECore.Create();

  PolyMesh := TCEPolygonMesh.Create(Core.EntityManager);
  PolyMesh.Count := 4;
  PolyMesh.Point[3] := Vec2f(-0.5, -0.5);
  PolyMesh.Point[2] := Vec2f( 0.0,  -0.4);
  PolyMesh.Point[1] := Vec2f( 0.2, 0.4);
  PolyMesh.Point[0] := Vec2f(-0.3, 0.5);
  PolyMesh.Softness := 2 / 1024 * 1.5;
  PolyMesh.Color := GetColor(100, 200, 150, 255);

  PolyPass := CreateRenderPass(Core.EntityManager, true, '', '', '');
  PolyPass.VertexShader := TCETextResource.Create();
  PolyPass.VertexShader.Text := VS;
  PolyPass.FragmentShader := TCETextResource.Create();
  PolyPass.FragmentShader.Text := PS;
end;

destructor TDemo.Destroy();
begin
  FreeAndNil(Renderer);
  FreeAndNil(App);
  CELog.Info('PGDCE library unload');
  inherited Destroy();
end;

procedure TDemo.Process();
begin
  Renderer.Clear([cfColor, cfDepth], GetColor(40, 130, 130, 0), 1.0, 0);
  log('applying material');
  Renderer.ApplyRenderPass(PolyPass);
  log('rendering mesh');
  Renderer.RenderMesh(PolyMesh);
end;

end.
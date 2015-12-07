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
    PolyPass: TCERenderPass;
    ClickPoint: TCEVector2f;
    Ind: Integer;
    Ids: array[0..$FF] of Integer;
  public
    constructor Create(Application: TCEBaseApplication);
    destructor Destroy(); override;

    procedure HandleMessage(const Msg: TCEMessage);
    procedure Process();
  end;

implementation

uses
  CEOSMessageInput;

constructor TDemo.Create(Application: TCEBaseApplication);
begin
  App := Application;
  Renderer := TCERendererClass.Create(nil);
  Core := TCECore.Create();
  Core.Renderer := Renderer;
  Core.Input := TCEOSMessageInput.Create();
  App.MessageHandler := HandleMessage;

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

  FillChar(Ids, SizeOf(Ids), 255);
end;

destructor TDemo.Destroy();
begin
  FreeAndNil(Renderer);
  FreeAndNil(App);
  CELog.Info('PGDCE library unload');
  inherited Destroy();
end;

procedure TDemo.HandleMessage(const Msg: TCEMessage);
begin
  Core.HandleMessage(Msg);
  if Msg.ClassType() = TTouchMsg then
    if (Renderer.Width > 0) and (Renderer.Height > 0) then
    begin
      case TTouchMsg(Msg).Action of
        iaDown: begin
          ClickPoint := Vec2f(Core.Input.MouseState.X / Renderer.Width * 2 - 1, 1 - Core.Input.MouseState.Y / Renderer.Height * 2);
          Ids[TTouchMsg(Msg).PointerId] := GetNearestPointIndex(PolyMesh.Points, PolyMesh.Count, ClickPoint);
          PolyMesh.Point[Ids[TTouchMsg(Msg).PointerId]] := ClickPoint;
        end;
        iaUp: Ids[TTouchMsg(Msg).PointerId] := -1;
        iaMotion: PolyMesh.Point[Ids[TTouchMsg(Msg).PointerId]] :=
          Vec2f(Core.Input.MouseState.X / Renderer.Width * 2 - 1, 1 - Core.Input.MouseState.Y / Renderer.Height * 2);
        else FillChar(Ids, SizeOf(Ids), 255);
      end;
      //CELog.Debug('Touch: ' + IntToStr(Ord(Action)) + ', but: ' + IntToStr(Ord(Button)));
    end;
end;

procedure TDemo.Process();
begin
  Renderer.Clear([cfColor, cfDepth], GetColor(40, 130, 130, 0), 1.0, 0);
  Renderer.ApplyRenderPass(PolyPass);
  Renderer.RenderMesh(PolyMesh);
  if Core.Input.MouseState.Buttons[mbLeft] = iaDown then
  begin
    if (Renderer.Width > 0) and (Renderer.Height > 0) then
    begin
    end;
  end;
end;

end.
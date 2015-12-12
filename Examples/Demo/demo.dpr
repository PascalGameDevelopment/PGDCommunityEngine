(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is wintest.dpr

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(Windows application test)

This is test for Windows application starter classes

@author(George Bakhtadze (avagames@gmail.com))
}
program demo;
{$Include PGDCE.inc}

{$APPTYPE CONSOLE}

uses
  CEBaseApplication,
  {$IFDEF WINDOWS}
  CEWindowsApplication,

  {$IFDEF OPENGLES_EMULATION}
  CEOpenGLES2Renderer,
  {$ELSE}
  CEOpenGL4Renderer,
  {$ENDIF}

  {$ELSE}
  CEXWindowApplication,
  CEOpenGL4Renderer,
  {$ENDIF}
  CEBaseRenderer,
  CEBaseInput, CEOSMessageInput,
  CEMesh, CECommon, CEOSUtils, CEResource, CEGameEntity, CE2DMesh, CEUniformsManager,
  CEBaseTypes, CEMessage, CEInputMessage, CEVectors, CEImageResource, CEMaterial, CECore;

type
    // Example mesh class
  TCERotatingTriangleMesh = class(TCEMesh)
  private
    FAngle: Single;
    procedure SetAngle(const Value: Single);
  public
    property Angle: Single read FAngle write SetAngle;
    procedure FillVertexBuffer(Dest: Pointer); override;
  end;

  TRotatingTriangle = class(TCEGameEntity)
  public
    procedure Update(const DeltaTime: Single); override;
  end;

var
  speed: Single;

procedure TCERotatingTriangleMesh.SetAngle(const Value: Single);
begin
  FAngle := Value;
  VertexBuffer.Status := dsChanged; // Invalidate buffer
end;

procedure TCERotatingTriangleMesh.FillVertexBuffer(Dest: Pointer);
var
  a: Single;
  v: ^TVBPos;
begin
  inherited;
  a := Angle * pi / 180;
  v := Dest;
  Vec3f(cos(a), sin(a), 0, v^[0].vec);
  //v^[0].u := 0; v^[0].v := 0;
  Vec3f(cos(a + 2 * pi / 3), sin(a + 2 * pi / 3), 0, v^[1].vec);
  //v^[1].u := 1; v^[1].v := 0;
  Vec3f(cos(a + 4 * pi / 3), sin(a + 4 * pi / 3), 0, v^[2].vec);
  //v^[2].u := 0.5; v^[2].v := 0.5;
  FVerticesCount := 3;
  FVertexSize := SizeOf(TVBRecPos);
end;

procedure TRotatingTriangle.Update(const DeltaTime: Single);
begin
  //TCERotatingTriangleMesh(Mesh).Angle := TCERotatingTriangleMesh(Mesh).Angle + speed * DeltaTime;
end;

var
  App: TCEBaseApplication;
  Renderer: TCEBaseRenderer;
  Core: TCECore;
  PolyMesh: TCEPolygonMesh;
  LineMesh: TCELineMesh;
  Mat: TCEMaterial;
  PolyPass, LinePass: TCERenderPass;
  Sh: TCETextResource;
  Polygon, Line: TRotatingTriangle;
  ClickPoint: TCEVector2f;
  Ind: Integer;
begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  App := TCEApplicationClass.Create();
  if App.Terminated then begin
    App.Free();
    Exit;
  end;
  Renderer := TCERendererClass.Create(App);
  Core := TCECore.Create();
  Core.Application := App;
  Core.Renderer := Renderer;
  Core.Input := TCEOSMessageInput.Create();

  Polygon := TRotatingTriangle.Create(Core.EntityManager);

  Line := TRotatingTriangle.Create(Core.EntityManager);
  LineMesh := TCELineMesh.Create(Core.EntityManager);
  LineMesh.Softness := 2 / 1024 * 1.5*10;
  LineMesh.Width := 1 / 1024 * 63;
  LineMesh.Count := 6;
  LineMesh.Point[0] := Vec2f(-0.5,  0.3);
  {LineMesh.Point[2] := Vec2f(0.4,  0.35);
  LineMesh.Point[1] := Vec2f(0.5,  0.3);}
  LineMesh.Point[1] := Vec2f( 0.3, -0.5);
  LineMesh.Point[2] := Vec2f(-0.3, -0.3);
  LineMesh.Point[3] := Vec2f( 0.4,  0.0);
  LineMesh.Point[4] := Vec2f( 0.5,  0.3);
  LineMesh.Point[5] := Vec2f( 0.2,  0.6);

  PolyMesh := TCEPolygonMesh.Create(Core.EntityManager);
  PolyMesh.Count := 4;
  PolyMesh.Point[3] := Vec2f(-0.5, -0.5);
  PolyMesh.Point[2] := Vec2f( 0.0,  -0.4);
  PolyMesh.Point[1] := Vec2f( 0.2, 0.4);
  PolyMesh.Point[0] := Vec2f(-0.3, 0.5);
  PolyMesh.Softness := 2 / 1024 * 1.5;
  PolyMesh.Color := GetColor(100, 200, 150, 255);

  PolyPass := CreateRenderPass(Core.EntityManager, true, '', 'asset://vs_poly.glsl', 'asset://fs_poly.glsl');
  LinePass := CreateRenderPass(Core.EntityManager, true, '', 'asset://vs_line.glsl', 'asset://fs_line.glsl');
  Mat := TCEMaterial.Create(Core.EntityManager);
  Mat.TotalTechniques := 1;
  Mat.Technique[0] := TCERenderTechnique.Create(Core.EntityManager);
  Mat.Technique[0].TotalPasses := 1;
  Mat.Technique[0].Pass[0] := PolyPass;
  Polygon.Mesh := PolyMesh;
  //Triangle.Material := Mat;
  Line.Mesh := LineMesh;

  App.MessageHandler := Core.HandleMessage;
  //Core.OnUpdateDelegate := Mesh.Update;

  speed := 4;

  while not App.Terminated do
  begin
    Renderer.Clear([cfColor, cfDepth], GetColor(40, 130, 130, 0), 1.0, 0);

    Renderer.ApplyRenderPass(PolyPass);
    Renderer.RenderMesh(PolyMesh);
    Renderer.ApplyRenderPass(LinePass);
    Renderer.RenderMesh(LineMesh);

    if Core.Input.Pressed[vkNUMPAD6] or (Core.Input.MouseState.Buttons[mbLeft] = iaDown) then speed := speed + 4;
    if Core.Input.Pressed[vkNUMPAD4] or (Core.Input.MouseState.Buttons[mbRight] = iaDown) then speed := speed - 4;
    speed := Clamps(speed, -360, 360);

    if Core.Input.Pressed[vkALT] and Core.Input.Pressed[vkX] then App.Terminated := True;
    if Core.Input.MouseState.Buttons[mbLeft] = iaDown then
    begin
      ClickPoint := Vec2f(Core.Input.MouseState.X / Renderer.Width * 2 - 1, 1 - Core.Input.MouseState.Y / Renderer.Height * 2);
      Ind := GetNearestPointIndex(LineMesh.Points, LineMesh.Count, ClickPoint);
      LineMesh.Point[Ind] := ClickPoint;
    end;
    Core.Process();
  end;

  PolyPass.VertexShader.Free();
  PolyPass.FragmentShader.Free();
  //PolyPass.Texture0.Free();
  //PolyPass.Free();
  //PolyPass.Texture0.Free();
  LinePass.VertexShader.Free();
  LinePass.FragmentShader.Free();
  //LinePass.Texture0.Free();
  //Line.Free();
  Polygon.Free();
  Core.Free();
end.

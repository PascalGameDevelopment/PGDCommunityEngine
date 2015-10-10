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
program wintest;
{$Include PGDCE.inc}

{$APPTYPE CONSOLE}

uses
  CEWindowsApplication, CEBaseRenderer, CEOpenGLES2Renderer, CEBaseInput, CEOSMessageInput,
  CEMesh, CECommon, CEOSUtils, CEResource, CEGameEntity, CE2DMesh,
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
  VertexBuffer.Status := tsChanged; // Invalidate buffer
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
  App: TCEWindowsApplication;
  Renderer: TCEBaseRenderer;
  Core: TCECore;
  Mesh: TCEPolygonMesh;
  Image: TCEImageResource;
  Mat: TCEMaterial;
  Pass: TCERenderPass;
  Sh: TCETextResource;
  Triangle: TRotatingTriangle;
begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  App := TCEWindowsApplication.Create();
  Renderer := TCEOpenGL4Renderer.Create(App);
  Core := TCECore.Create();
  Core.Application := App;
  Core.Renderer := Renderer;
  Core.Input := TCEOSMessageInput.Create();

  Triangle := TRotatingTriangle.Create(Core.EntityManager);
  {Mesh := TCELineMesh.Create(Core.EntityManager);
  Mesh.Softness := 2 / 1024 * 2;
  Mesh.Width := 1 / 1024 * 4;
  Mesh.Count := 6;
  Mesh.Point[0] := Vec2f(-0.5,  0.3);
  Mesh.Point[1] := Vec2f( 0.3, -0.5);
  Mesh.Point[2] := Vec2f(-0.3, -0.3);
  Mesh.Point[3] := Vec2f( 0.4,  0.0);
  Mesh.Point[4] := Vec2f( 0.3,  0.3);
  Mesh.Point[5] := Vec2f( 0.2,  0.6);}

  Mesh := TCEPolygonMesh.Create(Core.EntityManager);
  Mesh.Softness := 12 / 1024*1.5;

  Image := TCEImageResource.CreateFromUrl(GetPathRelativeToFile(ParamStr(0), '../Assets/test1.bmp'));
  Pass := TCERenderPass.Create(Core.EntityManager);
  Pass.Texture0 := Image;
  Pass.VertexShader := TCETextResource.CreateFromUrl(GetPathRelativeToFile(ParamStr(0), '../Assets/vs_poly.glsl'));
  Pass.FragmentShader := TCETextResource.CreateFromUrl(GetPathRelativeToFile(ParamStr(0), '../Assets/fs_poly.glsl'));
  Pass.AlphaBlending := true;
  Mat := TCEMaterial.Create(Core.EntityManager);
  Mat.TotalTechniques := 1;
  Mat.Technique[0] := TCERenderTechnique.Create(Core.EntityManager);
  Mat.Technique[0].TotalPasses := 1;
  Mat.Technique[0].Pass[0] := Pass;
  Triangle.Mesh := Mesh;
  //Triangle.Material := Mat;

  App.MessageHandler := Core.Input.HandleMessage;
  //Core.OnUpdateDelegate := Mesh.Update;

  speed := 4;

  while not App.Terminated do
  begin
    Renderer.Clear([cfColor, cfDepth], GetColor(40, 30, 130, 0), 1.0, 0);

    Renderer.ApplyRenderPass(Mat.Technique[0].Pass[0]);
    Renderer.RenderMesh(Mesh);

    if Core.Input.Pressed[vkNUMPAD6] or (Core.Input.MouseState.Buttons[mbLeft] = baDown) then speed := speed + 4;
    if Core.Input.Pressed[vkNUMPAD4] or (Core.Input.MouseState.Buttons[mbRight] = baDown) then speed := speed - 4;
    speed := Clamps(speed, -360, 360);

    if Core.Input.Pressed[vkALT] and Core.Input.Pressed[vkX] then App.Terminated := True;
    if Core.Input.MouseState.Buttons[mbLeft] = baDown then
      Mesh.Point[1] := Vec2f(Core.Input.MouseState.X / 512 - 1, 1 - Core.Input.MouseState.Y / 512);

    Core.Process();
  end;

  Pass.VertexShader.Free();
  Pass.FragmentShader.Free();
  Pass.Free();
  Image.Free();
  Triangle.Free();
  Core.Free();
  Readln;
end.

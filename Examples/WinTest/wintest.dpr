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
{$Include PGDCE.inc}
program wintest;

{$APPTYPE CONSOLE}

uses
  SysUtils, Windows, dglOpenGL,
  CEWindowsApplication, CEBaseRenderer, CEOpenGL4Renderer, CEBaseInput, CEOSMessageInput,
  CEMesh, CECommon,
  CEBaseTypes, CEMessage, CEInputMessage, CEVectors, CEImageResource, CEMaterial;

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

procedure TCERotatingTriangleMesh.SetAngle(const Value: Single);
begin
  FAngle := Value;
  VertexBuffer.Status := tsChanged; // Invalidate buffer
end;

type
  TVert = packed record
    vec: TCEVector3f;
    u, v: Single;
  end;
  TVertArray = array[0..$FFFF] of TVert;

procedure TCERotatingTriangleMesh.FillVertexBuffer(Dest: Pointer);
var
  a: Single;
  v: ^TVertArray;
begin
  inherited;
  a := Angle * pi/180;
  v := Dest;
  Vec3f(cos(a), -sin(a), 0, v^[0].vec);
  v^[0].u := 0; v^[0].v := 0;
  Vec3f(cos(a+2*pi/3), -sin(a+2*pi/3), 0, v^[1].vec);
  v^[1].u := 1; v^[1].v := 0;
  Vec3f(cos(a+4*pi/3), -sin(a+4*pi/3), 0, v^[2].vec);
  v^[2].u := 0.5; v^[2].v := 0.5;
  FVerticesCount := 3;
  FVertexSize := SizeOf(TVert);
end;

var
  App: TCEWindowsApplication;
  Renderer: TCEOpenGL4Renderer;
  Input: TCEOSMessageInput;
  Mesh: TCERotatingTriangleMesh;
  Image: TCEImageResource;
  Mat: TCERenderPass;
  speed: Single;
begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  App := TCEWindowsApplication.Create();
  Renderer := TCEOpenGL4Renderer.Create(App);
  Input := TCEOSMessageInput.Create();
  Mesh := TCERotatingTriangleMesh.Create();
  Image := TCEImageResource.Create();
  Image.DataURL := ExtractFilePath(ParamStr(0)) + '../Examples/WinTest/test1.bmp';
  Image.LoadExternal(False);
  Mat := TCERenderPass.Create();
  Mat.Texture0 := Image;

  App.MessageHandler := Input.HandleMessage;

  glLoadIdentity;
  glTranslatef(0, 0, -3);

  speed := 0.1;

  while not App.Terminated do begin
    Renderer.Clear([cfColor, cfDepth], GetColor(0, 0, 0, 0), 1.0, 0);

    App.Process();
    Mesh.Angle := Mesh.Angle + speed;

    Renderer.ApplyRenderPass(Mat);
    Renderer.RenderMesh(Mesh);

    Renderer.NextFrame();

    if Input.Pressed[vkNUMPAD6] or (Input.MouseState.Buttons[mbLeft] = baDown) then speed := speed + 0.1;
    if Input.Pressed[vkNUMPAD4] or (Input.MouseState.Buttons[mbRight] = baDown) then speed := speed - 0.1;
    speed := Clamps(speed, -10, 10);

    if Input.Pressed[vkALT] and Input.Pressed[vkX] then App.Terminated := True;
  end;

  Mat.Free();
  Image.Free();
  Mesh.Free();
  Input.Free();
  Renderer.Free();
  App.Free();
  Readln;
end.

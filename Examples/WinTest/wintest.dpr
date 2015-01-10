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
  SysUtils, dglOpenGL, Windows,
  CEWindowsApplication, CEBaseRenderer, CEOpenGL4Renderer, CEBaseInput, CEOSMessageInput,
  CEMesh, CECommon,
  CEBaseTypes, CEMessage, CEInputMessage, CEVectors;

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

procedure TCERotatingTriangleMesh.FillVertexBuffer(Dest: Pointer);
var
  a: Single;
  v: ^TCEVector3fArray;
begin
  inherited;
  a := Angle * pi/180;
  v := Dest;
  Vec3f(cos(a), -sin(a), 0, v^[0]);
  Vec3f(cos(a+2*pi/3), -sin(a+2*pi/3), 0, v^[1]);
  Vec3f(cos(a+4*pi/3), -sin(a+4*pi/3), 0, v^[2]);
  FVerticesCount := 3;
end;

var
  App: TCEWindowsApplication;
  Renderer: TCEOpenGL4Renderer;
  Input: TCEOSMessageInput;
  Mesh: TCERotatingTriangleMesh;
  speed: Single;
begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  App := TCEWindowsApplication.Create();
  Renderer := TCEOpenGL4Renderer.Create(App);
  Input := TCEOSMessageInput.Create();
  Mesh := TCERotatingTriangleMesh.Create();

  App.MessageHandler := Input.HandleMessage;

  glLoadIdentity;
  glTranslatef(0, 0, -3);

  speed := 0.1;

  while not App.Terminated do begin
    Renderer.Clear([cfColor, cfDepth], GetColor(0, 0, 0, 0), 1.0, 0);

    App.Process();
    Mesh.Angle := Mesh.Angle + speed;
    Renderer.RenderMesh(Mesh);

    Renderer.NextFrame();

    if Input.Pressed[vkNUMPAD6] or (Input.MouseState.Buttons[mbLeft] = baDown) then speed := speed + 0.1;
    if Input.Pressed[vkNUMPAD4] or (Input.MouseState.Buttons[mbRight] = baDown) then speed := speed - 0.1;
    speed := Clamps(speed, -10, 10);

    if Input.Pressed[vkALT] and Input.Pressed[vkX] then App.Terminated := True;
  end;

  Mesh.Free();
  Input.Free();
  Renderer.Free();
  App.Free();
  Readln;
end.

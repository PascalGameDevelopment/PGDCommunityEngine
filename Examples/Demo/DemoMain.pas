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
  2015 of these individuals.

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
  CEBaseApplication,
  CEBaseRenderer,
  CEMesh, CE2DMesh, CEGameEntity,
  CEMessage, CEInputMessage, CEBaseTypes, CEMaterial, CECore;

type
  TRotatingTriangle = class(TCEGameEntity)
  public
    procedure Update(const DeltaTime: Single); override;
  end;

  TDemo = class(TObject)
  private
    App: TCEBaseApplication;
    Renderer: TCEBaseRenderer;
    Core: TCECore;
    PolyMesh: TCEPolygonMesh;
    LineMesh: TCELineMesh;
    SpriteMesh1, SpriteMesh2: TCESpriteMesh;
    PolyPass, LinePass, SpritePass, MonsterSpritePass: TCERenderPass;
    Triangle: TRotatingTriangle;
    ClickPoint: TCEVector2f;
    Ind: Integer;
    Ids: array[0..$FF] of Integer;
    Speed: Single;
    SplineResolution: Integer;
    ControlPoints: P2DPointArray;
    ControlPointsCount: Integer;
    procedure ApplyPoints(Mesh: TCENPointMesh; CPoints: P2DPointArray; Count: Integer);
  public
    constructor Create(Application: TCEBaseApplication);
    destructor Destroy(); override;
    procedure HandleKey(Msg: TKeyboardMsg);
    procedure HandleMessage(const Msg: TCEMessage);
    function Process(): Boolean;
  end;

  // Example mesh class
  TCERotatingTriangleMesh = class(TCEMesh)
  private
    FAngle: Single;
    procedure SetAngle(const Value: Single);
  public
    property Angle: Single read FAngle write SetAngle;
    procedure FillVertexBuffer(Buffer: TDataBufferType; Dest: Pointer); override;
  end;

implementation

uses
  {$IFDEF WINDOWS}
  CEWindowsApplication,
  {$IFDEF OPENGLES_EMULATION}
  CEOpenGLES2Renderer,
  {$ELSE}
  CEOpenGL4Renderer,
  {$ENDIF}
  {$ELSE}
  {$IFDEF XWINDOW}
  CEOpenGL4Renderer,
  {$ENDIF}
  {$IFDEF MOBILE}
  CEOpenGLES2Renderer,
  {$ENDIF}
  {$ENDIF}
  CEOSMessageInput,
  sysutils, CELog,
  CECommon, CEBaseInput, CEEntityMessage, CEVectors, CESplines;

procedure TCERotatingTriangleMesh.SetAngle(const Value: Single);
begin
  FAngle := Value;
  InvalidateData(dbtVertex1, true);
end;

procedure TCERotatingTriangleMesh.FillVertexBuffer(Buffer: TDataBufferType; Dest: Pointer);
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
  SetDataSize(dbtVertex1, SizeOf(TVBRecPos));
end;

procedure TRotatingTriangle.Update(const DeltaTime: Single);
begin
  //TCERotatingTriangleMesh(Mesh).Angle := TCERotatingTriangleMesh(Mesh).Angle + speed * DeltaTime;
end;

procedure TDemo.ApplyPoints(Mesh: TCENPointMesh; CPoints: P2DPointArray; Count: Integer);
begin
  Mesh.Count := (Count) * (SplineResolution) + 1;
  CalcCatmullRom2D(Count, SplineResolution, CPoints, Mesh.Points);
end;

constructor TDemo.Create(Application: TCEBaseApplication);
begin
  App := Application;
  Renderer := TCERendererClass.Create(App);
  CELog.Info('Creating core');
  Core := TCECore.Create();
  Core.Application := App;
  Core.Renderer := Renderer;
  CELog.Info('Creating input');
  Core.Input := TCEOSMessageInput.Create();
  App.MessageHandler := HandleMessage;

  //Triangle := TRotatingTriangle.Create(Core.EntityManager);

  PolyMesh := TCEPolygonMesh.Create(Core.EntityManager);
  PolyMesh.Count := 4;
  PolyMesh.Point[3] := Vec2f(-0.5, -0.5);
  PolyMesh.Point[2] := Vec2f( 0.0, -0.4);
  PolyMesh.Point[1] := Vec2f( 0.2, 0.4);
  PolyMesh.Point[0] := Vec2f(-0.3, 0.5);
  PolyMesh.Softness := 2 / 1024 * 1.5;
  PolyMesh.Color := GetColor(100, 200, 150, 255);

  LineMesh := TCELineMesh.Create(Core.EntityManager);
  LineMesh.Softness := 2 / 1024 * 1.3 * 1;
  LineMesh.Width := 1 / 1024 * 1.3;

  SplineResolution := 8;
  ControlPointsCount := 6;
  GetMem(ControlPoints, (ControlPointsCount + 1) * SizeOf(TCEVector2f));
  ControlPoints^[0] := Vec2f(-0.5,  0.5);
  {pnt^[2] := Vec2f(0.4,  0.25);
  pnt^[1] := Vec2f(0.5,  0.3);}
  ControlPoints^[1] := Vec2f( 0.0, 0.5);
  ControlPoints^[2] := Vec2f( 0.5, 0.5);
  ControlPoints^[3] := Vec2f( 0.5, -0.5);
  ControlPoints^[4] := Vec2f( 0.0, -0.5);
  ControlPoints^[5] := Vec2f(-0.5, -0.5);

  ApplyPoints(LineMesh, ControlPoints, ControlPointsCount);

  SpriteMesh1 := TCESpriteMesh.Create(Core.EntityManager);
  SpriteMesh1.X := -0.5;
  SpriteMesh1.SetTextureParameters(7, 7);
  SpriteMesh2 := TCESpriteMesh.Create(Core.EntityManager);
  SpriteMesh2.X := 0.5;
  SpriteMesh2.Width := 0.5;
  SpriteMesh2.Height := 0.5;

  CELog.Info('Loading materials');
  PolyPass := CreateRenderPass(Core.EntityManager, true, '', 'asset://vs_poly.glsl', 'asset://fs_poly.glsl');
  LinePass := CreateRenderPass(Core.EntityManager, true, '', 'asset://vs_line.glsl', 'asset://fs_line.glsl');
  SpritePass :=
  CreateRenderPass(Core.EntityManager, true, 'asset://sprites.bmp', 'asset://vs_sprite.glsl', 'asset://fs_sprite.glsl');
  MonsterSpritePass :=
  CreateRenderPass(Core.EntityManager, true, 'asset://monster.bmp', 'asset://vs_sprite.glsl', 'asset://fs_sprite.glsl');

  {Mat := TCEMaterial.Create(Core.EntityManager);
  Mat.TotalTechniques := 1;
  Mat.Technique[0] := TCERenderTechnique.Create(Core.EntityManager);
  Mat.Technique[0].TotalPasses := 1;
  Mat.Technique[0].Pass[0] := PolyPass;
  Triangle.Material := Mat;
  Line.Mesh := LineMesh;}

  //Core.OnUpdateDelegate := Mesh.Update;

  FillChar(Ids, SizeOf(Ids), 255);
end;

destructor TDemo.Destroy();
begin
  FreeAndNil(Core);
  Freemem(ControlPoints);
  inherited Destroy();
end;

procedure TDemo.HandleKey(Msg: TKeyboardMsg);
begin
  if Msg.Action = iaUp then
  begin
    if Msg.Key = vkDIVIDE then begin
      SplineResolution := MaxI(1, SplineResolution - 1);
      ApplyPoints(LineMesh, ControlPoints, ControlPointsCount);
    end else if Msg.Key = vkMULTIPLY then begin
      SplineResolution := MinI(100, SplineResolution + 1);
      ApplyPoints(LineMesh, ControlPoints, ControlPointsCount);
    end else if Msg.Key = vkSUBTRACT then begin
      LineMesh.Width := MaxS(0.5/1024, LineMesh.Width - ClampS(LineMesh.Width*0.1, 0.1/1024, 5/1024));
      ApplyPoints(LineMesh, ControlPoints, ControlPointsCount);
    end else if Msg.Key = vkADD then begin
      LineMesh.Width := MinS(100/1024, LineMesh.Width + ClampS(LineMesh.Width*0.1, 0.1/1024, 5/1024));
      ApplyPoints(LineMesh, ControlPoints, ControlPointsCount);
    end;
  end;
end;

procedure TDemo.HandleMessage(const Msg: TCEMessage);
begin
  Core.HandleMessage(Msg);
  if Msg.ClassType() = TAppActivateMsg then
    Core.EntityManager.BroadcastMessage(nil, TEntityDataReloadRequestMessage.Create(nil))
  else if Msg.ClassType() = TKeyboardMsg then
    HandleKey(TKeyboardMsg(Msg))
  else if Msg.ClassType() = TTouchMsg then
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

function TDemo.Process(): Boolean;
begin
  if App.Terminated then begin
    Result := false;
    Exit;
  end;
  Result := true;

  Renderer.Clear([cfColor, cfDepth], GetColor(40, 130, 130, 0), 1.0, 0);

  Renderer.ApplyRenderPass(PolyPass);
  Renderer.RenderMesh(PolyMesh);
  Renderer.ApplyRenderPass(LinePass);
  Renderer.RenderMesh(LineMesh);
{  Renderer.ApplyRenderPass(SpritePass);
  Renderer.RenderMesh(SpriteMesh1);
  Renderer.ApplyRenderPass(MonsterSpritePass);
  Renderer.RenderMesh(SpriteMesh2);}

  if Core.Input.Pressed[vkNUMPAD_6] or (Core.Input.MouseState.Buttons[mbLeft] = iaDown) then Speed := Speed + 4;
  if Core.Input.Pressed[vkNUMPAD_4] or (Core.Input.MouseState.Buttons[mbRight] = iaDown) then Speed := Speed - 4;
  Speed := Clamps(Speed, -360, 360);

  if Core.Input.Pressed[vkALT] and Core.Input.Pressed[vkX] then App.Terminated := True;
  if Core.Input.MouseState.Buttons[mbLeft] = iaDown then
  begin
    if (Renderer.Width > 0) and (Renderer.Height > 0) then
    begin
      ClickPoint := Vec2f(Core.Input.MouseState.X / Renderer.Width * 2 - 1, 1 - Core.Input.MouseState.Y / Renderer.Height * 2);
      Ind := GetNearestPointIndex(ControlPoints, ControlPointsCount, ClickPoint);
      ControlPoints^[Ind] := ClickPoint;
      ApplyPoints(LineMesh, ControlPoints, ControlPointsCount);
      SpriteMesh1.Frame := SpriteMesh1.Frame + 1;
    end;
  end;
  Core.Process();
end;

end.

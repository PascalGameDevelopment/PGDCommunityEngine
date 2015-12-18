(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOpenGL4Renderer.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE OpenGL Renderer)

Definition for the PGDCE OpenGL 4.x renderer class. Platform specific.

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
{$IFDEF OPENGLES_EMULATION}
This unit should not be used when GLES emulation is on
{$ENDIF}
unit CEOpenGL4Renderer;

interface

uses
  CEMessage, CEBaseApplication, CEMesh, CEOpenGL;

type
  TCEOpenGL4Renderer = class(TCEBaseOpenGLRenderer)
  protected
    procedure HandleResize(Msg: TWindowResizeMsg); override;
    function DoInitGAPIPlatform(App: TCEBaseApplication): Boolean; override;
    procedure DoFinalizeGAPIPlatform(); override;
  public
    procedure RenderMesh(Mesh: TCEMesh); override;
  end;

  // Declare renderer class to use it without IFDEFs
  TCERendererClass = TCEOpenGL4Renderer;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF XWINDOW}
  xlib, xutil,
  {$ENDIF}
  CECommon, CELog, CEVectors, dglOpenGL, CEUniformsManager;

const
  LOGTAG = 'ce.render';

var
  GLAttributesList: array [0..16] of Integer;

procedure GenerateAttributes_SingleBufferMode();
begin
  GLAttributesList[0] := Glx_RGBA;
  GLAttributesList[1] := Glx_Red_Size;
  GLAttributesList[2] := 4;
  GLAttributesList[3] := Glx_Green_Size;
  GLAttributesList[4] := 4;
  GLAttributesList[5] := Glx_Blue_Size;
  GLAttributesList[6] := 4;
  GLAttributesList[7] := Glx_Depth_Size;
  GLAttributesList[8] := 16;
  GLAttributesList[9] := GL_NONE;
end;

procedure GenerateAttributes_DoubleBufferMode();
begin
  GLAttributesList[0] := Glx_RGBA;
  GLAttributesList[1] := Glx_DoubleBuffer;
  GLAttributesList[2] := Glx_Red_Size;
  GLAttributesList[3] := 4;
  GLAttributesList[4] := Glx_Green_Size;
  GLAttributesList[5] := 4;
  GLAttributesList[6] := Glx_Blue_Size;
  GLAttributesList[7] := 4;
  GLAttributesList[8] := Glx_Depth_Size;
  GLAttributesList[9] := 16;
  GLAttributesList[10] := GL_NONE;
end;

{ TCEOpenGL4Renderer }

procedure TCEOpenGL4Renderer.HandleResize(Msg: TWindowResizeMsg);
begin
  glViewport(0, 0, Round(Msg.NewWidth), Round(Msg.NewHeight));    // Set the viewport for the OpenGL window

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(0.375, 0.375 - Msg.NewHeight, 0);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, Msg.NewWidth, 0, Msg.NewHeight, -1, 1);
  glScalef(1, -1, 1);

  WriteLn('Resize renderer: ', Msg.NewWidth, 'x', Msg.NewHeight);
end;

function TCEOpenGL4Renderer.DoInitGAPIPlatform(App: TCEBaseApplication): Boolean;
{$IFDEF WINDOWS}
var
  Dummy: LongWord;
  Rect: Windows.TRect;
{$ENDIF}
{$IFDEF XWINDOW}
var
  VisualInfo: PXVisualInfo;
  ScreenNum: Cardinal;
  Attrs: PXWindowAttributes;
{$ENDIF}
begin
  Result := False;

  {$IFDEF WINDOWS}
  Dummy  := 0;
  FRenderWindowHandle := App.Cfg.GetInt64(CFG_WINDOW_HANDLE);
  FOGLDC := GetDC(FRenderWindowHandle);
  if (FOGLDC = 0) then begin
    CELog.Error(ClassName + '.DoInitGAPI: Unable to get a device context');
    Exit;
  end;
  FOGLContext := CreateRenderingContext(FOGLDC, [opDoubleBuffered], 24, 16, 0, 0, 0, Dummy);
  if FOGLContext = 0 then begin
    CELog.Error(ClassName + '.DoInitGAPI: Error creating rendering context');
    Exit;
  end;
  ActivateRenderingContext(FOGLDC, FOGLContext);
  GetClientRect(FRenderWindowHandle, Rect);
  Width := Rect.Right - Rect.Left;
  Height := Rect.Bottom - Rect.Top;
  {$ENDIF}
  {$IFDEF XWINDOW}
  FDisplay := App.Cfg.GetPointer(CFG_XWINDOW_DISPLAY);
  if FDisplay = nil then
  begin
    CELog.Error(LOGTAG, 'No open X-Window display');
    Exit;
  end;
  ScreenNum := App.Cfg.GetInt64(CFG_XWINDOW_SCREEN);
  FRenderWindowHandle := App.Cfg.GetInt64(CFG_WINDOW_HANDLE);
  GenerateAttributes_DoubleBufferMode();
  VisualInfo := GlxChooseVisual(FDisplay, ScreenNum, @GLAttributesList);
  if VisualInfo = nil then
  begin
    GenerateAttributes_SingleBufferMode();
    VisualInfo := GlxChooseVisual(FDisplay, ScreenNum, @GLAttributesList);
  end;

  FOGLContext := GlxCreateContext(FDisplay, VisualInfo, Nil, True);
  glxMakeCurrent(FDisplay, FRenderWindowHandle, FOGLContext);
  XFree(VisualInfo);
  XGetWindowAttributes(FDisplay, FRenderWindowHandle, Attrs);
  Width := Attrs^.width;
  Height := Attrs^.height;
  {$ENDIF}

  glDisable(GL_ALPHA_TEST);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

  Result := True;
end;

procedure TCEOpenGL4Renderer.DoFinalizeGAPIPlatform();
begin
  {$IFDEF WINDOWS}
  DeactivateRenderingContext();
  DestroyRenderingContext(FOGLContext);
  FOGLContext := 0;
  ReleaseDC(FRenderWindowHandle, FOGLDC);
  FOGLDC := 0;
  {$ENDIF}

  {$IFDEF XWINDOW}
  glXMakeCurrent(FDisplay, GL_NONE, nil);
  glXDestroyContext(FDisplay, FOGLContext);
  {$ENDIF}
end;

procedure TCEOpenGL4Renderer.RenderMesh(Mesh: TCEMesh);
var
  i, Ind: Integer;
  ts: PCEDataStatus;
  Buffer: PCEDataBuffer;
begin
  Assert(Assigned(Mesh));
  if not Active then Exit;
  ts := CEMesh.GetVB(Mesh);

  if ts^.BufferIndex = DATA_NOT_ALLOCATED then
    ts^.BufferIndex := FBufferManager.GetOrCreate(Mesh.VertexSize, ts, Buffer)
  else
    Buffer := @TCEOpenGLBufferManager(FBufferManager).Buffers^[ts^.BufferIndex];

  glBindBuffer(GL_ARRAY_BUFFER, Buffer^.Id);
  if ts^.Status <> dsValid then begin
    Mesh.FillVertexBuffer(VertexData);
    glBufferData(GL_ARRAY_BUFFER, Mesh.VerticesCount * Mesh.VertexSize, VertexData, GL_STATIC_DRAW);
  end;

  if Assigned(CurShader) then
  begin
    for i := 0 to Mesh.VertexAttribCount - 1 do
    begin
      //glBindAttribLocation(CurShader.ShaderProgram, i, Mesh.VertexAttribs^[i].Name);
      Ind := glGetAttribLocation(CurShader.ShaderProgram, Mesh.VertexAttribs^[i].Name);
      glEnableVertexAttribArray(Ind);
      glVertexAttribPointer(Ind, Mesh.VertexAttribs^[i].Size, GetGLType(Mesh.VertexAttribs^[i].DataType), false,
        Mesh.VertexSize, PtrOffs(nil, i * SizeOf(TCEVector4f)));
    end;

    TCEOpenGLUniformsManager(FUniformsManager).ShaderProgram := CurShader.ShaderProgram;
    Mesh.SetUniforms(FUniformsManager);

    case Mesh.PrimitiveType of
      ptPointList: glDrawArrays(GL_POINTS, 0, Mesh.PrimitiveCount);
      ptLineList: glDrawArrays(GL_LINES, 0, Mesh.PrimitiveCount * 2);
      ptLineStrip: glDrawArrays(GL_LINE_STRIP, 0, Mesh.PrimitiveCount + 1);
      ptTriangleList: glDrawArrays(GL_TRIANGLES, 0, Mesh.PrimitiveCount * 3);
      ptTriangleStrip: glDrawArrays(GL_TRIANGLE_STRIP, 0, Mesh.PrimitiveCount + 2);
      ptTriangleFan: glDrawArrays(GL_TRIANGLE_FAN, 0, Mesh.PrimitiveCount + 2);
      ptQuads:;
    end;
  end;
end;

end.

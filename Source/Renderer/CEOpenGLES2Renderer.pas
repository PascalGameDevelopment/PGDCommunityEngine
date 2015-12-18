(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOpenGLES2Renderer.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE OpenGL ES 2.0 Renderer)

Definition for the PGDCE OpenGL ES 2.0 renderer class. Platform specific.

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$Include PGDCE.inc}
unit CEOpenGLES2Renderer;

interface

uses
  CEMessage, CEBaseApplication, CEMesh, CEOpenGL;

type
  TCEOpenGLES2Renderer = class(TCEBaseOpenGLRenderer)
  private
  protected
    function DoInitGAPIPlatform(App: TCEBaseApplication): Boolean; override;
    procedure DoFinalizeGAPIPlatform(); override;
    procedure HandleResize(Msg: TWindowResizeMsg); override;
  public
    procedure RenderMesh(Mesh: TCEMesh); override;
  end;

  // Declare renderer class to use it without IFDEFs
  TCERendererClass = TCEOpenGLES2Renderer;

implementation

uses
  {$IFDEF OPENGLES_EMULATION}
  GLES20Regal,
  {$ELSE}
  gles20,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  CECommon, {!}CELog, CEVectors, CEUniformsManager;

{ TCEOpenGLES2Renderer }

function TCEOpenGLES2Renderer.DoInitGAPIPlatform(App: TCEBaseApplication): Boolean;
{$IFDEF WINDOWS}
var
  Dummy: LongWord;
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
  {$ENDIF}

  Result := True;
end;

procedure TCEOpenGLES2Renderer.DoFinalizeGAPIPlatform();
begin
  {$IFDEF WINDOWS}
  DeactivateRenderingContext();
  DestroyRenderingContext(FOGLContext);
  FOGLContext := 0;
  ReleaseDC(FRenderWindowHandle, FOGLDC);
  FOGLDC := 0;
  {$ENDIF}
end;

procedure TCEOpenGLES2Renderer.HandleResize(Msg: TWindowResizeMsg);
begin

end;

procedure TCEOpenGLES2Renderer.RenderMesh(Mesh: TCEMesh);
var
  i: Integer;
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

  //Debug('rendering buffer taken');

  glBindBuffer(GL_ARRAY_BUFFER, Buffer^.Id);
  if ts^.Status <> dsValid then begin
    Mesh.FillVertexBuffer(VertexData);
    glBufferData(GL_ARRAY_BUFFER, Mesh.VerticesCount * Mesh.VertexSize, VertexData, GL_STATIC_DRAW);
  end;

  //Debug('rendering buffer filled');

  if Assigned(CurShader) then
  begin
    for i := 0 to Mesh.VertexAttribCount - 1 do
    begin
      glBindAttribLocation(CurShader.ShaderProgram, i, Mesh.VertexAttribs^[i].Name);
      glEnableVertexAttribArray(i);
      glVertexAttribPointer(i, Mesh.VertexAttribs^[i].Size, GetGLType(Mesh.VertexAttribs^[i].DataType), GL_FALSE,
        Mesh.VertexSize, PtrOffs(nil, i * SizeOf(TCEVector4f)));
    end;

    //Debug('mesh attributes set');

    TCEOpenGLUniformsManager(FUniformsManager).ShaderProgram := CurShader.ShaderProgram;
    Mesh.SetUniforms(FUniformsManager);

    //Debug('uniforms set');

    case Mesh.PrimitiveType of
      ptPointList: glDrawArrays(GL_POINTS, 0, Mesh.PrimitiveCount);
      ptLineList: glDrawArrays(GL_LINES, 0, Mesh.PrimitiveCount * 2);
      ptLineStrip: glDrawArrays(GL_LINE_STRIP, 0, Mesh.PrimitiveCount + 1);
      ptTriangleList: glDrawArrays(GL_TRIANGLES, 0, Mesh.PrimitiveCount * 3);
      ptTriangleStrip: glDrawArrays(GL_TRIANGLE_STRIP, 0, Mesh.PrimitiveCount + 2);
      ptTriangleFan: glDrawArrays(GL_TRIANGLE_FAN, 0, Mesh.PrimitiveCount + 2);
      ptQuads:;
    end;

    //CELog.Verbose('render done');
  end;
end;

end.

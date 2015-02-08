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
  CEBaseTypes, CEBaseRenderer, CEBaseApplication, CEMesh, CEMaterial, CEOpenGL,
  {$IFDEF MOBILE}
    gles20,
  {$ELSE}                                     // Use emulation layer for desktops
    GLES20Regal,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  CELog;

type
  TCEOpenGL4Renderer = class(TCEBaseRenderer)
  private
    {$IFDEF WINDOWS}
      FOGLContext: HGLRC;                    // OpenGL rendering context
      FOGLDC: HDC;
      FRenderWindowHandle: HWND;
    {$ENDIF}
    PhaseLocation: TGLint;

    VertexData: Pointer;
    VBO: GLUInt;

    Shaders: TGLSLShaderList;
    function InitShader(Pass: TCERenderPass): Integer;
  protected
    procedure DoInit(); override;
    function DoInitGAPI(App: TCEBaseApplication): Boolean; override;
    function DoInitGAPIWin(App: TCEBaseApplication): Boolean;
    procedure DoFinalizeGAPI(); override;
    procedure DoFinalizeGAPIWin();
  public
    procedure ApplyRenderPass(Pass: TCERenderPass); override;
    procedure RenderMesh(Mesh: TCEMesh); override;
    procedure Clear(Flags: TCEClearFlags; Color: TCEColor; Z: Single; Stencil: Cardinal); override;
    procedure NextFrame(); override;
  end;

implementation

uses
  CECommon, CEVectors, CEImageResource;

function PrintShaderInfoLog(Shader: TGLUint; ShaderType: string): Boolean;
var
  len, Success: TGLint;
  Buffer: pchar;
begin
  Result := True;
  glGetShaderiv(Shader, GL_COMPILE_STATUS, @Success);
  if Success <> GL_TRUE then
  begin
    Result := False;
    glGetShaderiv(Shader, GL_INFO_LOG_LENGTH, @len);
    if len > 0 then
    begin
      getmem(Buffer, len+1);
      glGetShaderInfoLog(Shader, len, nil, Buffer);
      CELog.Error(ShaderType + ': ' + Buffer);
      freemem(Buffer);
    end;
  end;
end;

function CreateShader(ShaderType: TGLenum; Source: PAnsiChar): TGLuint;
const
  Title: array[Boolean] of String = ('Fragment', 'Vertex');
begin
  Result := glCreateShader(ShaderType);
  glShaderSource(Result, 1, @Source, nil);
  glCompileShader(Result);
  if not PrintShaderInfoLog(Result, Title[ShaderType = GL_VERTEX_SHADER] + ' shader') then
    Result := 0;
end;

{ TCEOpenGL4Renderer }

procedure TCEOpenGL4Renderer.DoInit;
type
  TLib = PWideChar;
begin
  {$IFNDEF MOBILE}
    {$ifdef windows}
    LoadGLESv2(TLib(GetPathRelativeToFile(ParamStr(0), '../Library/regal/regal32.dll')));
    {$endif}
  {$ENDIF}
end;

function TCEOpenGL4Renderer.DoInitGAPI(App: TCEBaseApplication): Boolean;
begin
  Result := False;
  Shaders := TGLSLShaderList.Create();
  {$IFDEF WINDOWS}
  if not DoInitGAPIWin(App) then Exit;
  {$ELSE}
  raise Exception.Create('Not implemented for this platform yet');
  {$ENDIF}
  CELog.Log('Context succesfully created');

  // Init GL settings
  glClearColor(0, 0, 0, 0);
  glEnable(GL_TEXTURE_2D);
  glCullFace(GL_NONE);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_DEPTH_TEST);

  GetMem(VertexData, 1000);

  Result := True;
end;

function TCEOpenGL4Renderer.DoInitGAPIWin(App: TCEBaseApplication): Boolean;
var
  Dummy: LongWord;
begin
  Result := False;

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

  Result := True;
end;

function FreeCallback(const e: TCEGLSLShader; Data: Pointer): Boolean;
begin
  if Assigned(e) then e.Free();
  Result := True;
end;

procedure TCEOpenGL4Renderer.DoFinalizeGAPI();
begin
  if Assigned(VertexData) then
    FreeMem(VertexData);
  {$IFDEF WINDOWS}
  DoFinalizeGAPIWin();
  {$ELSE}
  raise Exception.Create('Not implemented for this platform');
  {$ENDIF}

  Shaders.ForEach(FreeCallback, nil);
  Shaders.Free();
  Shaders := nil;
end;

procedure TCEOpenGL4Renderer.DoFinalizeGAPIWin();
begin
  DeactivateRenderingContext();
  DestroyRenderingContext(FOGLContext);

  FOGLContext := 0;
  ReleaseDC(FRenderWindowHandle, FOGLDC);
  FOGLDC := 0;
end;

procedure TCEOpenGL4Renderer.Clear(Flags: TCEClearFlags; Color: TCEColor; Z: Single; Stencil: Cardinal);
begin
  if (Flags = []) or not Active then Exit;

  glDepthMask(GL_TRUE);
  glClearColor(Color.R * ONE_OVER_255, Color.G * ONE_OVER_255, Color.B * ONE_OVER_255, Color.A * ONE_OVER_255);
  glClearDepthf(Z);
  glClearStencil(Stencil);

  glClear(GL_COLOR_BUFFER_BIT * Ord(cfColor in Flags) or GL_DEPTH_BUFFER_BIT * Ord(cfDepth in Flags) or GL_STENCIL_BITS * Ord(cfStencil in Flags));
end;

function TCEOpenGL4Renderer.InitShader(Pass: TCERenderPass): Integer;
var
  Sh: TCEGLSLShader;
begin
  Sh := TCEGLSLShader.Create();
  Sh.ShaderProgram  := glCreateProgram();
  Sh.VertexShader   := CreateShader(GL_VERTEX_SHADER,   PAnsiChar(Pass.VertexShader.Text));
  Sh.FragmentShader := CreateShader(GL_FRAGMENT_SHADER, PAnsiChar(Pass.FragmentShader.Text));
  if (sh.VertexShader = 0) or (sh.FragmentShader = 0) then
  begin
    Sh.Free();
    Result := ID_NOT_INITIALIZED;
    Exit;
  end;
  glAttachShader(Sh.ShaderProgram, Sh.VertexShader);
  glAttachShader(Sh.ShaderProgram, Sh.FragmentShader);
  glLinkProgram(Sh.ShaderProgram);
  Shaders.Add(Sh);
  Result := Shaders.Count-1;
end;

function InitTexture(Image: TCEImageResource): glUint;
begin
  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);
//  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, Image.ActualLevels);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexImage2D(GL_TEXTURE_2D, 0, 3, Image.Width, Image.Height, 0, GL_RGB, GL_UNSIGNED_BYTE, Image.Data);
end;

procedure TCEOpenGL4Renderer.ApplyRenderPass(Pass: TCERenderPass);
var
  TexId, PrId: Integer;
  Sh: TCEGLSLShader;
begin
  PrId := CEMaterial._GetProgramId(Pass);
  if PrId = ID_NOT_INITIALIZED then
  begin
    PrId := InitShader(Pass);
    CEMaterial._SetProgramId(Pass, PrId);
  end;
  if PrId >= 0 then
  begin
    Sh := Shaders.Get(PrId);
    glUseProgram(Sh.ShaderProgram);
    PhaseLocation := glGetUniformLocation(Sh.ShaderProgram, 'phase');
    if PhaseLocation < 0 then begin
      CELog.Error('Error: Cannot get phase shader uniform location');
    end;
    glUniform1i(glGetUniformLocation(Sh.ShaderProgram, 's_texture0'), 0);
  end;

  TexId := CEMaterial._GetTextureId(Pass, 0);
  if TexId = ID_NOT_INITIALIZED then
  begin
    TexId := InitTexture(Pass.Texture0);
    CEMaterial._SetTextureId(Pass, 0, TexId);
  end;
  glBindTexture(GL_TEXTURE_2D, TexId);
  glActiveTexture(GL_TEXTURE0);
  glEnable(GL_TEXTURE_2D);
end;

procedure TCEOpenGL4Renderer.RenderMesh(Mesh: TCEMesh);
var
  ts: PTesselationStatus;
begin
  if not Active then Exit;
  ts := CEMesh.GetVB(Mesh);

  {if ts^.BufferIndex = -1 then begin  // Create buffer
    glGenBuffers(1, @VBO);
    ts^.BufferIndex := VBO;
    ts^.Status := tsMaxSizeChanged;   // Not tesselated yet as vertex buffer is just created
  end;

  glBindBuffer(GL_ARRAY_BUFFER, ts^.BufferIndex);}
  if ts^.Status <> tsTesselated then begin
    Mesh.FillVertexBuffer(VertexData);
    //glBufferData(GL_ARRAY_BUFFER, Mesh.VerticesCount * Mesh.VertexSize, VertexData, GL_STATIC_DRAW);
  end;

{  glVertexAttribPointer(0,4,GL_FLOAT,0,0,@VertexArray);
  glEnableVertexAttribArray(0);
  glDrawArrays(GL_TRIANGLE_STRIP,0,3);}


  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Mesh.VertexSize, VertexData);
//  glEnableVertexAttribArray(1);
//  glVertexAttribPointer(1, 2, GL_FLOAT, False, Mesh.VertexSize, pointer(3));

  {glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glTexCoordPointer(2, GL_FLOAT, Mesh.VertexSize,  ptroffs(VertexData, SizeOf(TCEVector3f)));
  glVertexPointer(3, GL_FLOAT, Mesh.VertexSize, VertexData);}
  glDrawArrays(GL_TRIANGLES, 0, Mesh.VerticesCount);
end;

procedure TCEOpenGL4Renderer.NextFrame;
begin
  if not Active then Exit;
  {$IFDEF WINDOWS}

    glUniform1f(PhaseLocation,(gettickcount() mod 2000)*0.001*pi);

    SwapBuffers(FOGLDC);                  // Display the scene
  {$ENDIF}
end;

end.

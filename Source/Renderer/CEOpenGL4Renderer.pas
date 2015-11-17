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

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$Include PGDCE.inc}
unit CEOpenGL4Renderer;

interface

uses
  CEBaseTypes, CEBaseRenderer, CEBaseApplication, CEMesh, CEMaterial, CEVectors,
  CEOpenGL, dglOpenGL,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  CEUniformsManager;

type
  TCEOpenGL4Renderer = class(TCEBaseRenderer)
  private
    {$IFDEF WINDOWS}
      FOGLContext: HGLRC;                    // OpenGL rendering context
      FOGLDC: HDC;
      FRenderWindowHandle: HWND;
    {$ENDIF}
    PhaseLocation: TGLint;

    VertexData: Pointer;                  // TODO: eliminate

    Shaders: TGLSLShaderList;
    CurShader: TCEGLSLShader;
    function InitShader(Pass: TCERenderPass): Integer;
  protected
    procedure DoInit(); override;
    function DoInitGAPI(App: TCEBaseApplication): Boolean; override;
    procedure DoFinalizeGAPI(); override;
    {$IFDEF WINDOWS}
    function DoInitGAPIWin(App: TCEBaseApplication): Boolean;
    procedure DoFinalizeGAPIWin();
    {$ENDIF}
  public
    procedure ApplyRenderPass(Pass: TCERenderPass); override;
    procedure RenderMesh(Mesh: TCEMesh); override;
    procedure Clear(Flags: TCEClearFlags; Color: TCEColor; Z: Single; Stencil: Cardinal); override;
    procedure NextFrame(); override;
  end;

  TCEOpenGL4UniformsManager = class(TCEUniformsManager)
  private
    ShaderProgram: Integer;
  public
    procedure SetInteger(const Name: PAPIChar; Value: Integer); override;
    procedure SetSingle(const Name: PAPIChar; Value: Single); override;
    procedure SetSingleVec2(const Name: PAPIChar; const Value: TCEVector2f); override;
    procedure SetSingleVec3(const Name: PAPIChar; const Value: TCEVector3f); override;
    procedure SetSingleVec4(const Name: PAPIChar; const Value: TCEVector4f); override;
  end;

  TCEOpenGL4BufferManager = class(TCERenderBufferManager)
  protected
    procedure ApiAddBuffer(Index: Integer); override;
    property Buffers: PCEDataBufferList read FBuffers;
  public
  end;

implementation

uses
  CECommon, CEImageResource, CELog;

function PrintShaderInfoLog(Shader: TGLUint; ShaderType: string): Boolean;
var
  len, Success: TGLint;
  Buffer: PGLchar;
begin
  Result := True;
  glGetShaderiv(Shader, GL_COMPILE_STATUS, @Success);
  if Success <> GL_TRUE then
  begin
    Result := False;
    glGetShaderiv(Shader, GL_INFO_LOG_LENGTH, @len);
    if len > 0 then
    begin
      GetMem(Buffer, len + 1);
      glGetShaderInfoLog(Shader, len, len, Buffer);
      CELog.Error(ShaderType + ': ' + string(Buffer));
      FreeMem(Buffer);
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
begin
  dglOpenGL.InitOpenGL();
  dglOpenGL.ReadExtensions();
end;

function TCEOpenGL4Renderer.DoInitGAPI(App: TCEBaseApplication): Boolean;
begin
  Result := False;
  Shaders := TGLSLShaderList.Create();
  {$IFDEF WINDOWS}
  if not DoInitGAPIWin(App) then Exit;
  {$ELSE}
  //raise Exception.Create  ('Not implemented for this platform yet');
  {$ENDIF}
  CELog.Log('Context succesfully created');

  FUniformsManager := TCEOpenGL4UniformsManager.Create();
  FBufferManager := TCEOpenGL4BufferManager.Create();

  // Init GL settings
  glClearColor(0, 0, 0, 0);
  glEnable(GL_TEXTURE_2D);
  glCullFace(GL_BACK);
  //glEnable(GL_CULL_FACE);
  glDepthFunc(GL_LEQUAL);
//  glEnable(GL_DEPTH_TEST);
  glDisable(GL_ALPHA_TEST);
  glDisable(GL_STENCIL_TEST);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

  GetMem(VertexData, 1000);

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
  //raise Exception.Create('Not implemented for this platform');
  {$ENDIF}

  FUniformsManager.Free();
  FBufferManager.Free();

  Shaders.ForEach(FreeCallback, nil);
  Shaders.Free();
  Shaders := nil;
end;

{$IFDEF WINDOWS}
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

procedure TCEOpenGL4Renderer.DoFinalizeGAPIWin();
begin
    DeactivateRenderingContext();
    DestroyRenderingContext(FOGLContext);

    FOGLContext := 0;
    ReleaseDC(FRenderWindowHandle, FOGLDC);
    FOGLDC := 0;
end;
{$ENDIF}

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
  Result := Shaders.Count - 1;
end;

function InitTexture(Image: TCEImageResource): glUint;
begin
  if not Assigned(Image) then Exit;
  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, Image.ActualLevels);
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
    {PhaseLocation := glGetUniformLocation(Sh.ShaderProgram, 'phase');
    if PhaseLocation < 0 then begin
      CELog.Error('Error: Cannot get phase shader uniform location');
    end;}
    glUniform1i(glGetUniformLocation(Sh.ShaderProgram, 's_texture0'), 0);
    CurShader := Sh;
  end;

  TexId := CEMaterial._GetTextureId(Pass, 0);
  if TexId = ID_NOT_INITIALIZED then
  begin
    TexId := InitTexture(Pass.Texture0);
    CEMaterial._SetTextureId(Pass, 0, TexId);
  end;
  glBindTexture(GL_TEXTURE_2D, TexId);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glActiveTexture(GL_TEXTURE0);
  glEnable(GL_TEXTURE_2D);

  if Pass.AlphaBlending then
  begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  end;
end;

function GetGLType(Value: TAttributeDataType): GLenum;
begin
  Result := GL_FLOAT;
  case Value of
    adtShortint: Result := GL_BYTE;
    adtByte: Result := GL_UNSIGNED_BYTE;
    adtSmallint: Result := GL_SHORT;
    adtWord: Result := GL_UNSIGNED_SHORT;
    adtSingle: Result := GL_FLOAT;
  end;
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
    Buffer := @TCEOpenGL4BufferManager(FBufferManager).Buffers^[ts^.BufferIndex];

  glBindBuffer(GL_ARRAY_BUFFER, Buffer^.Id);
  if ts^.Status <> dsValid then begin
    Mesh.FillVertexBuffer(VertexData);
    glBufferData(GL_ARRAY_BUFFER, Mesh.VerticesCount * Mesh.VertexSize, VertexData, GL_STATIC_DRAW);
  end;

  for i := 0 to Mesh.VertexAttribCount - 1 do
  begin
    //glBindAttribLocation(CurShader.ShaderProgram, i, Mesh.VertexAttribs^[i].Name);
    Ind := glGetAttribLocation(CurShader.ShaderProgram, Mesh.VertexAttribs^[i].Name);
    glEnableVertexAttribArray(Ind);
    glVertexAttribPointer(Ind, Mesh.VertexAttribs^[i].Size, GetGLType(Mesh.VertexAttribs^[i].DataType), false,
      Mesh.VertexSize, PtrOffs(nil, i * SizeOf(TCEVector4f)));
  end;

  TCEOpenGL4UniformsManager(FUniformsManager).ShaderProgram := CurShader.ShaderProgram;
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

procedure TCEOpenGL4Renderer.Clear(Flags: TCEClearFlags; Color: TCEColor; Z: Single; Stencil: Cardinal);
begin
  if (Flags = []) or not Active then Exit;

  glDepthMask(true);
  glClearColor(Color.R * ONE_OVER_255, Color.G * ONE_OVER_255, Color.B * ONE_OVER_255, Color.A * ONE_OVER_255);
  glClearDepth(Z);
  glClearStencil(Stencil);

  glClear(GL_COLOR_BUFFER_BIT * Ord(cfColor in Flags) or GL_DEPTH_BUFFER_BIT * Ord(cfDepth in Flags) or
  GL_STENCIL_BITS * Ord(cfStencil in Flags));
end;

procedure TCEOpenGL4Renderer.NextFrame;
begin
  if not Active then Exit;
  {$IFDEF WINDOWS}
  glUniform1f(PhaseLocation,(gettickcount() mod 2000)*0.001*pi);
  SwapBuffers(FOGLDC);                  // Display the scene
  {$ELSE}
  {$ENDIF}
end;

function GetUniformLocation(ShaderProgram: Integer; const Name: PAPIChar): Integer;
begin
  Result := glGetUniformLocation(ShaderProgram, Name);
  if Result < 0 then
    CELog.Warning('Can''t find uniform location for name: ' + Name);
end;

{ TCEOpenGLES2UniformsManager }

procedure TCEOpenGL4UniformsManager.SetInteger(const Name: PAPIChar; Value: Integer);
begin
  glUniform1i(GetUniformLocation(ShaderProgram, Name), Value);
end;

procedure TCEOpenGL4UniformsManager.SetSingle(const Name: PAPIChar; Value: Single);
begin
  glUniform1f(GetUniformLocation(ShaderProgram, Name), Value);
end;

procedure TCEOpenGL4UniformsManager.SetSingleVec2(const Name: PAPIChar; const Value: TCEVector2f);
begin
  glUniform2f(GetUniformLocation(ShaderProgram, Name), Value.x, Value.y);
end;

procedure TCEOpenGL4UniformsManager.SetSingleVec3(const Name: PAPIChar; const Value: TCEVector3f);
begin
  glUniform3f(GetUniformLocation(ShaderProgram, Name), Value.x, Value.y, Value.z);
end;

procedure TCEOpenGL4UniformsManager.SetSingleVec4(const Name: PAPIChar; const Value: TCEVector4f);
begin
  glUniform4f(GetUniformLocation(ShaderProgram, Name), Value.x, Value.y, Value.z, Value.w);
end;

{ TCEOpenGL4BufferManager }

procedure TCEOpenGL4BufferManager.ApiAddBuffer(Index: Integer);
begin
  Assert((Index >= 0) and (Index < Count), 'Invalid index');
  glGenBuffers(1, @FBuffers^[Index].Id);
end;

end.

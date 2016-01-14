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
  CEMessage, CEBaseApplication, CEOpenGL;

type
  TCEOpenGLES2Renderer = class(TCEBaseOpenGLRenderer)
  private
  protected
    function DoInitGAPIPlatform(App: TCEBaseApplication): Boolean; override;
    procedure DoFinalizeGAPIPlatform(); override;
    procedure HandleResize(Msg: TWindowResizeMsg); override;
  public
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
  {!}CELog;

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

end.

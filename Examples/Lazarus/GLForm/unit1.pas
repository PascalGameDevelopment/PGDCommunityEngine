(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CECore.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE OpenGL example with TForm)

PGDCE OpenGL example with TForm

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
@author(Zaflis (v.teemu@gmail.com))
}

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, OpenGLContext, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, CECore, dglOpenGL;

type

  { TForm1 }

  TForm1 = class(TForm)
    GLControl: TOpenGLControl;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    core: TCECore;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // DEV NOTE: Just putting up commands needed to init window.
  // Move things to proper units as they build up.
  // There will be another example for Delphi, and one using
  // just console app project without TForm.
  ClientWidth := 800;
  ClientHeight := 600;
  GLControl.Align := alClient;
  try
    core := TCECore.Create;

    dglOpenGL.InitOpenGL();
    dglOpenGL.ReadExtensions();

    Timer1.Enabled := true;
  except
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := false;
  try
    core.Free;
  except
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);


  GLControl.SwapBuffers;
end;

end.


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
  2015 of these individuals.

******************************************************************************)

{
@abstract(Engine demo application)

This is a crossplatform (Windows/X Window) engine test application

@author(George Bakhtadze (avagames@gmail.com))
}
program demo;
{$Include PGDCE.inc}

{$APPTYPE CONSOLE}

uses
  CEBaseApplication,
  {$IFDEF WINDOWS}
    CEWindowsApplication,
    {$IFDEF OPENGLES_EMULATION}
    CEOpenGLES2Renderer,
    {$ELSE}
    CEOpenGL4Renderer,
    {$ENDIF}
  {$ELSE}
    CEXWindowApplication,
  {$ENDIF}
  DemoMain;

var
  App: TCEBaseApplication;
  DemoApp: TDemo;
begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}

  App := TCEApplicationClass.Create();
  if App.Terminated then begin
    App.Free();
    Exit;
  end;
  DemoApp := TDemo.Create(App);

  while not App.Terminated do
  begin
    DemoApp.Process();
  end;
  DemoApp.Free();
end.

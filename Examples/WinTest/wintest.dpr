(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is wintest.pas

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
  SysUtils, CEWindowsApplication;

var
  App: TCEWindowsApplication;

begin
  {$IF Declared(ReportMemoryLeaksOnShutdown)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  App := TCEWindowsApplication.Create();
  while not App.Terminated do
    App.Process();
  App.Free();
end.

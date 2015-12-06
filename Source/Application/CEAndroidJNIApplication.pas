(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEAndroidApplication.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Application for Android)

Android implementation of the application class

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEAndroidJNIApplication;

interface

uses
  CELog, CEBaseApplication;

type
  // Application implementing interaction with Android platform using custom JNI approach
  TCEAndroidApplication = class(TCEBaseApplication)
  private
  protected
    procedure SetConfig(const ConfigString: PAnsiChar);
    procedure InitKeyCodes(); override;
    function DoCreateWindow(): Boolean; override;
    procedure DoDestroyWindow(); override;
  public
    procedure Process(); override;
  end;

implementation

uses CEBaseInput;

procedure TCEAndroidApplication.SetConfig(const ConfigString: PAnsiChar);
begin
  CELog.Debug('Configuration change: ' + ConfigString);
end;

procedure TCEAndroidApplication.InitKeyCodes();
begin

end;

function TCEAndroidApplication.DoCreateWindow(): Boolean;
begin
  Result := True;
end;

procedure TCEAndroidApplication.DoDestroyWindow();
begin
end;

procedure TCEAndroidApplication.Process();
begin

end;

end.

(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEBaseApplication.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Base Application)

Base definition for the application class within PGDCE that will sit between the
rest of the engine and the platform/operating system

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEBaseApplication;

interface

uses
  CEProperty;

type
  TCEBaseApplication = class
  private
    FConfig: TCEProperties;
    FActive: Boolean;
    function GetCfg(const Name: TPropertyName): string;
    procedure SetCfg(const Name: TPropertyName; const Value: string);
  protected
    FName: string;
    FTerminated: Boolean;
    // Actual window creation
    procedure DoCreateWindow(); virtual; abstract;
    // Actual window destruction
    procedure DoDestroyWindow(); virtual; abstract;
  public
    constructor Create();
    destructor Destroy(); override;
    // Should be called in main cycle
    procedure Process(); virtual; abstract;
    // Application name
    property Name: string read FName write FName;
    // When True application is terninated
    property Terminated: Boolean read FTerminated write FTerminated;
    // True if the application is on the foreground
    property Active: Boolean read FActive write FActive;
    // Provides access to configuration specified in command line, config file etc
    property Cfg[const Name: TPropertyName]: string read GetCfg write SetCfg;
  end;

implementation

{ TCEBaseApplication }

function TCEBaseApplication.GetCfg(const Name: TPropertyName): string;
var
  Value: PCEPropertyValue;
begin
  if not Assigned(FConfig) then Exit;
  Value := FConfig.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsUnicodeString
  else
    Result := '';
end;

procedure TCEBaseApplication.SetCfg(const Name: TPropertyName; const Value: string);
begin
  if Assigned(FConfig) then
    FConfig.AddString(Name, Value);
end;

constructor TCEBaseApplication.Create;
begin
  DoCreateWindow();
end;

destructor TCEBaseApplication.Destroy;
begin
  inherited;
  DoDestroyWindow();
end;

end.


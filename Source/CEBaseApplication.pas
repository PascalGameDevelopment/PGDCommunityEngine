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
  CEBaseTypes, CEProperty, CEMessage;

const
  // Window handle config parameter name
  CFG_WINDOW_HANDLE = 'Windows.WindowHandle';

type
  // Class to store subsystem's parameters
  TCEConfig = class
  private
    Data: TCEProperties;
    function GetValue(const Name: TPropertyName): string;
    procedure SetValue(const Name: TPropertyName; const Value: string);
  public
    constructor Create;
    destructor Destroy(); override;
    procedure Remove(const Name: TPropertyName);
    function GetInt64(const Name: TPropertyName): Int64;
    function GetFloat(const Name: TPropertyName): Single;
    procedure SetInt64(const Name: TPropertyName; Value: Int64);
    procedure SetFloat(const Name: TPropertyName; Value: Single);
    property ValuesStr[const Name: TPropertyName]: string read GetValue write SetValue; default;
  end;

  TCEBaseApplication = class
  private
    FConfig: TCEConfig;
    FActive: Boolean;
  protected
    FName: UnicodeString;
    FTerminated: Boolean;
    FMessageHandler: TCEMessageHandler;
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
    property Name: UnicodeString read FName write FName;
    // When True application is terninated
    property Terminated: Boolean read FTerminated write FTerminated;
    // True if the application is on the foreground
    property Active: Boolean read FActive write FActive;
    // Provides access to configuration specified in command line, config file etc
    property Cfg: TCEConfig read FConfig;
    // Handler for handling OS messages converted to PGDCE messages
    property MessageHandler: TCEMessageHandler read FMessageHandler write FMessageHandler;
  end;

implementation

uses
  SysUtils;

{ TCEBaseApplication }

constructor TCEBaseApplication.Create;
begin
  FConfig := TCEConfig.Create();
  Name := ExtractFileName(ParamStr(0));
  FConfig['App.Name'] := Name;
  FConfig['App.Path'] := ParamStr(0);
  DoCreateWindow();
end;

destructor TCEBaseApplication.Destroy;
begin
  inherited;
  DoDestroyWindow();
  FConfig.Free();
  FConfig := nil;
end;

{ TCEConfig }

function TCEConfig.GetValue(const Name: TPropertyName): string;
var
  Value: PCEPropertyValue;
begin
  Result := '';
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsUnicodeString
end;

procedure TCEConfig.SetValue(const Name: TPropertyName; const Value: string);
begin
  Data.AddString(Name, Value);
end;

constructor TCEConfig.Create;
begin
  Data := TCEProperties.Create();
end;

destructor TCEConfig.Destroy;
begin
  Data.Free();
  Data := nil;
  inherited;
end;

procedure TCEConfig.Remove(const Name: TPropertyName);
begin
  Writeln('Not implemented');
end;

function TCEConfig.GetInt64(const Name: TPropertyName): Int64;
var
  Value: PCEPropertyValue;
begin
  Result := 0;
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsInt64
end;

function TCEConfig.GetFloat(const Name: TPropertyName): Single;
var
  Value: PCEPropertyValue;
begin
  Result := 0.0;
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsSingle
end;

procedure TCEConfig.SetInt64(const Name: TPropertyName; Value: Int64);
begin
  Data.AddInt(Name, Value);
end;

procedure TCEConfig.SetFloat(const Name: TPropertyName; Value: Single);
begin
  Data.AddSingle(Name, Value);
end;

end.


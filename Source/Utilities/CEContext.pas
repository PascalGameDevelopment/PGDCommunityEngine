(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEContext.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE context)

Context aims to provide manage and provide dependencies such as singleton instances

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEContext;

interface

uses
  CEProperty;

type
{$MESSAGE 'Instantiating TClassObjectMap interface'}
    {$DEFINE _HashMapTypeNullable}
  _HashMapKeyType = TClass;
  _HashMapValueType = TObject;
    {$I tpl_coll_hashmap.inc}
    // Maps class to instance
  TClassObjectMap = _GenHashMap;

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
    function GetInt(const Name: TPropertyName; const Def: Integer = 0): Integer;
    function GetInt64(const Name: TPropertyName; const Def: Int64 = 0): Int64;
    function GetFloat(const Name: TPropertyName; const Def: Single = 0.0): Single;
    function GetPointer(const Name: TPropertyName; const Def: Pointer = nil): Pointer;
    procedure SetInt(const Name: TPropertyName; Value: Integer);
    procedure SetInt64(const Name: TPropertyName; Value: Int64);
    procedure SetFloat(const Name: TPropertyName; Value: Single);
    procedure SetPointer(const Name: TPropertyName; Value: Pointer);
    property ValuesStr[const Name: TPropertyName]: string read GetValue write SetValue; default;
  end;

{ Returns an singleton instance of the given class previously stored or nil if no such instance exists }
  function GetSingleton(AClass: TClass): TObject;
{ Adds a singleton instance to storage for the given class. If AClass is nil class of the instance will be used.
  Returns True if there was no instance for the class in storage. }
  function AddSingleton(Instance: TObject; AClass: TClass = nil): Boolean;
{ Removes a singleton instance from storage for the given class. Returns True if there was such instance. }
  function RemoveSingleton(AClass: TClass): Boolean;
{ Logs error message for situation when singleton instance was already created }
  procedure LogSingletonExists(Cls: TClass);

implementation

uses
  CELog, CECommon;

  {$MESSAGE 'Instantiating TClassObjectMap'}
  {$I tpl_coll_hashmap.inc}

var
  ClassObjectMap: TClassObjectMap;

procedure LogSingletonExists(Cls: TClass);
begin
  CELog.Error('ce.context', Cls.ClassName() + ' singleton was already created');
end;

function GetSingleton(AClass: TClass): TObject;
begin
  Result := ClassObjectMap[AClass];
end;

function AddSingleton(Instance: TObject; AClass: TClass = nil): Boolean;
begin
  Result := not ClassObjectMap.PutValue(AClass, Instance);
end;

function RemoveSingleton(AClass: TClass): Boolean;
begin
  Result := ClassObjectMap.RemoveValue(AClass);
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
  if not CEContext.AddSingleton(Self, TCEConfig) then
    LogSingletonExists(TCEConfig);
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

function TCEConfig.GetInt(const Name: TPropertyName; const Def: Integer = 0): Integer;
var
  Value: PCEPropertyValue;
begin
  Result := Def;
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsInteger
end;

function TCEConfig.GetInt64(const Name: TPropertyName; const Def: Int64 = 0): Int64;
var
  Value: PCEPropertyValue;
begin
  Result := Def;
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsInt64
end;

function TCEConfig.GetFloat(const Name: TPropertyName; const Def: Single = 0.0): Single;
var
  Value: PCEPropertyValue;
begin
  Result := Def;
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Value^.AsSingle
end;

function TCEConfig.GetPointer(const Name: TPropertyName; const Def: Pointer = nil): Pointer;
var
  Value: PCEPropertyValue;
begin
  Result := Def;
  Value := Data.Value[Name];
  if Assigned(Value) then
    Result := Pointer(Value^.AsInt64)
end;

procedure TCEConfig.SetInt(const Name: TPropertyName; Value: Integer);
begin
  Data.AddInt(Name, Value);
end;

procedure TCEConfig.SetInt64(const Name: TPropertyName; Value: Int64);
begin
  Data.AddInt64(Name, Value);
end;

procedure TCEConfig.SetPointer(const Name: TPropertyName; Value: Pointer);
begin
  Data.AddInt64(Name, PtrToInt(Value));
end;

procedure TCEConfig.SetFloat(const Name: TPropertyName; Value: Single);
begin
  Data.AddSingle(Name, Value);
end;

initialization
  ClassObjectMap := TClassObjectMap.Create();
finalization
  ClassObjectMap.Free();
end.

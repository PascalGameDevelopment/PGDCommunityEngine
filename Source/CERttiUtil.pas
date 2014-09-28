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
@abstract(RTTI support unit)

The unit contains routines for easy use of RTTI

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CERttiUtil;

interface

  uses TypInfo;

  type
    TRTTIName = ShortString;
    TRTTINames = array of TRTTIName;

  { Fills the list of published properties of the given class and its parent classes.
    Returns number of such properties and the list of properties in PPropList. }
  function GetClassPropList(AClass: TClass; out PropInfos: PPropList): Integer;
  // Returns array of published properties names of the given class and its parent classes
  function GetClassPropertyNames(AClass: TClass): TRTTINames;
  {  Returns array of published method names of the given class.
     If ScanParents is True published methods of parent classes are also included. }
  function GetClassMethodNames(AClass: TClass; ScanParents: Boolean): TRTTINames;

  { Invokes parameterless procedure method with the given name of the given class and returns True
    or returns False if such method not found }
  function InvokeCommand(Obj: TObject; const Name: TRTTIName): Boolean;

implementation

uses CECommon, CEBaseTypes;

function GetClassPropList(AClass: TClass; out PropInfos: PPropList): Integer;
begin
  // Get count of published properties
  Result := GetPropList(AClass.ClassInfo, tkProperties, nil);
  // Allocate memory for all data
  GetMem(PropInfos, Result * SizeOf(PPropInfo));
  GetPropList(AClass.ClassInfo, tkProperties, PropInfos);
end;

function GetClassPropertyNames(AClass: TClass): TRTTINames;
var
  PropInfos: PPropList;
  Count, i: Integer;
begin
  Count := GetClassPropList(AClass, PropInfos);
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
  begin
    Result[i] := PropInfos^[i]^.Name;
  end;
end;

type
  {$IFDEF FPC}
    TMethodCount = LongWord;
    TMethodNameRec = packed record
      Name: PShortString;
      Address: Pointer;
    end;
  {$ELSE}
    TMethodCount = Word;
    TMethodNameRec = packed record
      Size: Word;
      Address: Pointer;
      Name: ShortString;
    end;
  {$ENDIF}

  PMethodNameRec = ^TMethodNameRec;
  PMethodNameTable = ^TMethodNameTable;
  TMethodNameTable = packed record
    Count: TMethodCount;
    Methods: TMethodNameRec;
  end;

procedure AddMethods(MethodTable: PMethodNameTable; var Names: TRTTINames);
var
  i, Offs, Count: Integer;
  MethodRec: PMethodNameRec;
begin
  if MethodTable <> nil then
  begin
    Offs := Length(Names);
    Count := MethodTable^.Count;
    SetLength(Names, Offs + Count);

    MethodRec := @MethodTable^.Methods;

    for i := 0 to Count - 1 do
    begin
      {$IFDEF FPC}
        Names[Offs + i] := MethodRec^.Name^;
        Inc(MethodRec);
      {$ELSE}
        Names[Offs + i] := MethodRec^.Name;
        MethodRec := PtrOffs(MethodRec, MethodRec^.Size);
      {$ENDIF}
    end;
  end;
end;

function GetClassMethodNames(AClass: TClass; ScanParents: Boolean): TRTTINames;
var
  MethodTable: PMethodNameTable;
begin
  MethodTable := PPointer(Cardinal(Pointer(AClass)) + vmtMethodTable)^;
  AddMethods(MethodTable, Result);

  AClass := AClass.ClassParent;
  while ScanParents and (AClass <> nil) do
  begin
    MethodTable := PPointer(PtrOffs(AClass, vmtMethodTable))^;
    AddMethods(MethodTable, Result);
    AClass := AClass.ClassParent;
  end;
end;

function InvokeCommand(Obj: TObject; const Name: TRTTIName): Boolean;
var
  Method: TMethod;
begin
  Result := False;
  if not Assigned(Obj) then Exit;
  Method.Code := Obj.MethodAddress(Name);
  if Method.Code <> nil then begin
    // TODO: check method signature for arguments (should be none)
    Method.Data := Pointer(Obj);
    TCommand(Method)();
    Result := True;
  end;
end;

end.

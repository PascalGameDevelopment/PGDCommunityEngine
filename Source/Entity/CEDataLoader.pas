(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEDataLoader.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE data loader main unit)

The unit contains data loader support facility

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEDataLoader;

interface

uses
  CEBaseTypes, CEIO;

type
  // Protocol
  TCEProtocol = string;
  // Protocol list
  TProtocolList = array of TCEProtocol;

  // Variables of this type are data type identifiers i.e. bitmap, .obj model, etc
  TCEDataTypeID = TSignature;

  // Array of resource type IDs
  TDataTypeList = array of TCEDataTypeID;

  // Abstract class descendants of which should load data from URL with various protocols
  TCEDataLoader = class
  protected
    // List of protocols the loader can load
    FProtocols: TProtocolList;
    { Should perform actual retrieving of input stream
    URL format (filename is mandatory): protocol://address/path/filename.ext }
    function DoGetInputStream(const AURL: string): TCEInputStream; virtual; abstract;
    // Should fill FProtocols
    procedure Init; virtual;
  public
    // Calls Init() and logs supported protocols
    constructor Create;
    // Returns True if the loader can handle the specified protocol
    function CanHandle(Protocol: TCEProtocol): Boolean;
    { Locates and returns input stream of the given URL or nil if error occured }
    function GetInputStream(const AURL: string): TCEInputStream;
    // Returns last modification time of a resource specified by URL or 0 if not supported
    function GetResourceModificationTime(const AURL: string): TDateTime; virtual; abstract;
  end;

  TCELocalFileLoader = class(TCEDataLoader)
  protected
    function DoGetInputStream(const AURL: string): TCEInputStream; override;
    procedure Init; override;
  public
    function GetResourceModificationTime(const AURL: string): TDateTime; override;
  end;

  // Returns class which can load resources of the specified type or nil if such a class was not registered
  function GetDataLoader(const Protocol: TCEProtocol): TCEDataLoader;
  // Register a resource loader class. The latter registered carriers will override previously registered ones if those can handle same resource types.
  procedure RegisterDataLoader(DataLoader: TCEDataLoader);

implementation

uses
  SysUtils, CECommon, CETemplate;

type
  _VectorValueType = TCEDataLoader;
  _VectorSearchType = TCEProtocol;
  {$MESSAGE 'Instantiating TDataLoaders interface'}
  {$I tpl_coll_vector.inc}
  TDataLoaders = _GenVector;

  const _VectorOptions = [];

  // Search callback. Returns True if the given loader can handle the specified protocol.
  function _VectorFound(const v: TCEDataLoader; const Protocol: TCEProtocol): Boolean; {$I inline.inc}
  begin
     Result := v.CanHandle(Protocol);
  end;

  {$MESSAGE 'Instantiating TDataLoaders'}
  {$I tpl_coll_vector.inc}

{ Resource linker }

var
  LDataLoaders: TDataLoaders;

function GetDataLoader(const Protocol: TCEProtocol): TCEDataLoader;
var i: Integer;
begin
  i := LDataLoaders.FindLast(Protocol);
  if i >= 0 then
    Result := LDataLoaders.Get(i)
  else
    Result := nil;  // TODO: log warning
end;

procedure RegisterDataLoader(DataLoader: TCEDataLoader);
begin
  LDataLoaders.Add(DataLoader);
end;

{ TCEResourceCarrier }

procedure TCEDataLoader.Init;
begin
  FProtocols := nil;
end;

constructor TCEDataLoader.Create;
begin
  Init();
  // TODO: log types
end;

function TCEDataLoader.CanHandle(Protocol: TCEProtocol): Boolean;
var i: Integer;
begin
  i := High(FProtocols);
  while (i >= 0) and (FProtocols[i] <> Protocol) do Dec(i);
  Result := i >= 0;
end;

function TCEDataLoader.GetInputStream(const AURL: string): TCEInputStream;
begin
  Result := DoGetInputStream(AURL);
end;

{ TCELocalFileLoader }

procedure TCELocalFileLoader.Init;
begin
  SetLength(FProtocols, 2);
  FProtocols[0] := '';
  FProtocols[1] := 'file';
end;

function TCELocalFileLoader.DoGetInputStream(const AURL: string): TCEInputStream;
begin
  Result := GetResourceInputStream(AURL);
end;

function TCELocalFileLoader.GetResourceModificationTime(const AURL: string): TDateTime;
var FileName: string;
begin
  FileName := GetPathFromURL(AURL);
  if FileExists(FileName) then
    Result := GetFileModifiedTime(FileName)
  else
    Result := 0;
end;

function FreeCallback(const e: TCEDataLoader; Data: Pointer): Boolean;
begin
  if Assigned(e) then e.Free();
end;

initialization
  LDataLoaders := TDataLoaders.Create();
  RegisterDataLoader(TCELocalFileLoader.Create());
finalization
  LDataLoaders.ForEach(FreeCallback, nil);
  LDataLoaders.Free();
end.


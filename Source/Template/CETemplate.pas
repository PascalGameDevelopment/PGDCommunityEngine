(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CETemplate.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(Template support unit)

The unit contains template related constants

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CETemplate;

interface
  //  Template option constants
  const
    // sort in descending order
    soDescending = 0;
    // sort data can be extremely quicksort-unfriendly
    soBadData = 1;

  type
    // Data structure options set elements
    TDataStructureOption = (// data structure value can be nil
                            dsNullable,
                            // data structure should perform range checking
                            dsRangeCheck
                            // data structure key is a string (to correctly select hash function)
                            //dsStringKey
                            );

    // Type for collection indexes, sizes etc
    __CollectionIndexType = Integer;

    TCollection = interface

    end;

    TTplList = interface

    end;

    TMap = interface

    end;

    // Implements base interface for template classes
    TTemplateInterface = class(TObject, IInterface)
    protected
      function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
      function _AddRef:  Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
      function _Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
    end;

implementation

{ TTemplateInterface }

function TTemplateInterface.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TTemplateInterface._AddRef: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  Result := 1;
end;

function TTemplateInterface._Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  Result := 1;
end;

end.

(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEEntityMessage.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE entity message unit)

The unit contains entity message classes

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEEntityMessage;

interface

uses CEMessage, CEEntity;

type
  // Base class for entity messages
  TEntityMessage = class(TCEMessage)
  public
    // Entity which is a subject for this message
    Entity: TCEBaseEntity;
    constructor Create(AEntity: TCEBaseEntity);
  end;

  { Triggers reload of data of an entity.
    For example, if the entity is a resource, it should reload its data from external storage.
    This message may be broadcasted with nil entity to trigger all entity reload. }
  TEntityDataReloadRequestMessage = class(TEntityMessage)
  end;

  // Posted when an entity data load is finished
  TEntityDataLoadCompleteMessage = class(TEntityMessage)
  end;

implementation

{ TEntityMessage }

constructor TEntityMessage.Create(AEntity: TCEBaseEntity);
begin
  Entity := AEntity;
end;

end.

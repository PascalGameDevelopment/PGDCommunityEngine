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
@abstract(PGDCE Core)

PGDCE Core engine class

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$I PGDCE.inc}
unit CECore;

interface

uses
  CEMessage,
  CEBaseApplication,
  CEBaseRenderer,
  CEBaseAudio,
  CEBaseInput,
  CEBasePhysics,
  CEBaseNetwork,

  CEEntity, CEGameEntity,

  CEOSUtils;

type
  TUpdateDelegate = procedure(const DeltaTime: Single) of object;

  TCECore = class
  private
    LastTime: Int64;
    FOnUpdateDelegate: TUpdateDelegate;
    procedure DoUpdate();
    procedure DoRender();
  protected
    FApplication: TCEBaseApplication;
    FRenderer: TCEBaseRenderer;
    FAudio: TCEBaseAudio;
    FInput: TCEBaseInput;
    FPhysics: TCEBasePhysics;
    FNetwork: TCEBaseNetwork;
    FEntityManager: TCEGameEntityManager;

    procedure Update(const DeltaTime: Single); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    // Handle engine message. For example, OS message.
    procedure HandleMessage(const Msg: TCEMessage);
    { Performs one step of main cycle. This method is called from TCECore.Run() and may be
      used instead when main program cycle can't be delegated to the engine. }
    procedure Process();
    // Launch the engine's main cycle
    procedure Run();
    property EntityManager: TCEGameEntityManager read FEntityManager;
    property Application: TCEBaseApplication read FApplication write FApplication;
    property Renderer: TCEBaseRenderer read FRenderer write FRenderer;
    property Audio: TCEBaseAudio read FAudio write FAudio;
    property Input: TCEBaseInput read FInput write FInput;
    property Physics: TCEBasePhysics read FPhysics write FPhysics;
    property Network: TCEBaseNetwork read FNetwork write fNetwork;
    property OnUpdateDelegate: TUpdateDelegate read FOnUpdateDelegate write FOnUpdateDelegate;
  end;

implementation

{ TCECore }

procedure TCECore.DoUpdate();
var
  LTime: Int64;
begin
  LTime := CEOSUtils.GetCurrentMs();
  if Assigned(OnUpdateDelegate) then
    OnUpdateDelegate((LTime - LastTime) * 0.001)
  else
    Update((LTime - LastTime) * 0.001);

  LastTime := LTime;
end;

procedure TCECore.DoRender();
begin
  FRenderer.NextFrame();
end;

procedure TCECore.Update(const DeltaTime: Single);
var
  Items: TCEEntityList;
var
  i: Integer;
begin
  Items := FEntityManager.GetUpdateList();
  for i := 0 to Items.Count-1 do
    TCEGameEntity(Items[i]).Update(DeltaTime);
end;

constructor TCECore.Create;
begin
  inherited;

  FEntityManager := TCEGameEntityManager.Create();
end;

destructor TCECore.Destroy;
begin
  try
    FInput.Free;
  except
  end;

  try
    FEntityManager.Free;
  except
  end;

  try
    fPhysics.Free;
  except
  end;

  try
    fNetwork.Free;
  finally
  end;

  try
    fAudio.Free;
  except
  end;

  try
    fRenderer.Free;
  except
  end;

  try
    FApplication.Free;
  except
  end;

  inherited;
end;

procedure TCECore.HandleMessage(const Msg: TCEMessage);
begin
  if Assigned(Input) then
    Input.HandleMessage(Msg);
  if Assigned(Renderer) then
    Renderer.HandleMessage(Msg);
end;

procedure TCECore.Process;
begin
  FApplication.Process();
  if FApplication.Terminated then Exit;
  DoUpdate();
  DoRender();
end;

procedure TCECore.Run();
begin
  while not FApplication.Terminated do
    Process();
end;

end.

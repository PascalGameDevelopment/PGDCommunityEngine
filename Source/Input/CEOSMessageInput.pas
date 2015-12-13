(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEOSMessageInput.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE OS message input Handler)

Platform independent input class based on OS messages handling

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEOSMessageInput;

interface

uses
  CEMessage, CEInputMessage, CEBaseInput;

type
  TCEOSMessageInput = class(TCEBaseInput)
  private
    procedure HandleKeyboard(Msg: TKeyboardMsg);
    procedure HandleMouseMove(Msg: TMouseMoveMsg);  protected
    procedure HandleMouseButton(Msg: TMouseButtonMsg);
    procedure HandleTouchEvent(Msg: TTouchMsg);
  public
    procedure HandleMessage(const Msg: TCEMessage); override;
  end;

implementation

uses
  CELog, CEBaseTypes;

procedure TCEOSMessageInput.HandleKeyboard(Msg: TKeyboardMsg);
begin
  FKeyboardState[Msg.Key] := Ord(Msg.Action);
end;

procedure TCEOSMessageInput.HandleMouseMove(Msg: TMouseMoveMsg);
begin
  FMouseState.X := Msg.X;
  FMouseState.Y := Msg.Y;
end;

procedure TCEOSMessageInput.HandleMouseButton(Msg: TMouseButtonMsg);
begin
  FMouseState.X := Msg.X;
  FMouseState.Y := Msg.Y;
  FMouseState.Buttons[Msg.Button] := Msg.Action;
end;

procedure TCEOSMessageInput.HandleTouchEvent(Msg: TTouchMsg);
begin
  case Msg.Action of
    iaUp: RemovePointer(Msg.PointerId);
    iaDown, iaMotion: AddPointer(Msg.PointerId, Msg.X, Msg.Y);
    iaTouchCancel: ClearPointers();
  end;
  FMouseState.X := Msg.X;
  FMouseState.Y := Msg.Y;
  if Pointers[Msg.PointerId].Active then
    FMouseState.Buttons[Msg.Button] := iaDown
  else
    FMouseState.Buttons[Msg.Button] := iaUp;
end;

procedure TCEOSMessageInput.HandleMessage(const Msg: TCEMessage);
begin
  if Msg.ClassType = TKeyboardMsg then
    HandleKeyboard(TKeyboardMsg(Msg))
  else if Msg.ClassType = TMouseMoveMsg then
    HandleMouseMove(TMouseMoveMsg(Msg))
  else if Msg.ClassType = TMouseButtonMsg then
    HandleMouseButton(TMouseButtonMsg(Msg))
  else if Msg.ClassType = TTouchMsg then
    HandleTouchEvent(TTouchMsg(Msg));
end;

end.

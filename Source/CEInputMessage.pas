(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEInputMessage.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE input message unit)

The unit contains input message classes

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEInputMessage;

interface

uses CEMessage, CEBaseTypes;

type
  // Base class for user-input messages
  TInputMessage = class(TCEMessage)
  public
  end;

  // Base class for mouse-related messages
  TMouseMsg = class(TInputMessage)
  public
    // coordinates of the mouse pointer in screen coordinate system
    X, Y: Single;
    // AX, AY - coordinates of the mouse pointer in screen coordinate system
    constructor Create(AX, AY: Single);
  end;

  // The message is sent to <b>core handler</b> when the mouse pointer moves
  TMouseMoveMsg = class(TMouseMsg)
  end;

  // Mouse button event
  TMouseButtonMsg = class(TMouseMsg)
  public
    // Action (only baDown and baUp are expected)
    Action: TButtonAction;
    // Button in action
    Button: TMouseButton;
    constructor Create(AX, AY: Single; const AAction: TButtonAction; const AButton: TMouseButton);
  end;

  // Keyboard event
  TKeyboardMsg = class(TInputMessage)
  public
    // Action (only baDown and baUp are expected)
    Action: TButtonAction;
    // Virtual key code
    Key: TCEVirtualKey;
    // Scan code of the key as come from hardware/API
    Code: Integer;
    constructor Create(AAction: TButtonAction; AKey: TCEVirtualKey; ACode: Integer);
  end;

  // Message for a character input
  TCharInputMsg = class(TInputMessage)
  public
    // Scan code of the key as come from hardware/API. May be not specified (-$FFFF).
    Code: Integer;
    // Code of the character
    Character: Char;
    // <b>AChar</b> - code of the character, <b>AKey</b> - scan code
    constructor Create(AChar: Char; ACode: Integer);
  end;

implementation

{ TMouseMsg }

constructor TMouseMsg.Create(AX, AY: Single);
begin
  X := AX;
  Y := AY;
end;

{ TMouseButtonMsg }

constructor TMouseButtonMsg.Create(AX, AY: Single; const AAction: TButtonAction; const AButton: TMouseButton);
begin
  inherited Create(AX, AY);
  Action := AAction;
  Button := AButton;
end;

{ TKeyboardMsg }

constructor TKeyboardMsg.Create(AAction: TButtonAction; AKey: TCEVirtualKey; ACode: Integer);
begin
  Action := AAction;
  Key    := AKey;
  Code   := ACode;
end;

{ TCharInputMsg }

constructor TCharInputMsg.Create(AChar: Char; ACode: Integer);
begin
  Character := AChar;
  Code      := ACode;
end;

end.

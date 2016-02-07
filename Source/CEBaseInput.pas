(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEBaseInput.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Base Input Handler)

Base definition for the input handler class within PGDCE

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEBaseInput;

interface

uses
  CEMessage, CEBaseTypes;

type
  // Virtual key codes
  TCEVirtualKey = (vkNONE,
                  vkESCAPE,
                  vk1, vk2, vk3, vk4, vk5, vk6, vk7, vk8, vk9, vk0, vkMINUS, vkEQUALS, vkBACK, vkTAB,
                  vkQ, vkW, vkE, vkR, vkT, vkY, vkU, vkI, vkO, vkP, vkBRACKET_L, vkBRACKET_R,
                  vkRETURN, vkNUMPAD_ENTER,
                  vkCONTROL_L,
                  vkA, vkS, vkD, vkF, vkG, vkH, vkJ, vkK, vkL, vkSEMICOLON, vkAPOSTROPHE,
                  vkGRAVE,
                  vkSHIFT_L, vkBACKSLASH,
                  vkZ, vkX, vkC, vkV, vkB, vkN, vkM, vkCOMMA, vkPERIOD, vkSLASH,
                  vkSHIFT_R, vkMULTIPLY, vkMENU_L, vkSPACE, vkCAPITAL,
                  vkF1, vkF2, vkF3, vkF4, vkF5, vkF6, vkF7, vkF8, vkF9, vkF10,
                  vkNUM_LOCK, vkSCROLL_LOCK, vkCAPS_LOCK,
                  vkNUMPAD_7, vkNUMPAD_8, vkNUMPAD_9, vkSUBTRACT, vkNUMPAD_4, vkNUMPAD_5, vkNUMPAD_6,
                  vkADD, vkNUMPAD_1, vkNUMPAD_2, vkNUMPAD_3, vkNUMPAD_0, vkDECIMAL,
                  vkOEM_102,
                  vkF11, vkF12, vkF13, vkF14, vkF15,
                  vkNUMPAD_EQUALS, vkCIRCUMFLEX, vkAT, vkCOLON, vkUNDERLINE, vkKANJI, vkNEXTTRACK,
                  vkCONTROL_R,
                  vkNUMPAD_COMMA, vkDIVIDE,
                  vkSYSRQ, vkMENU_R, vkPAUSE,
                  vkHOME, vkUP, vkPRIOR, vkLEFT, vkRIGHT, vkEND, vkDOWN,
                  vkNEXT, vkINSERT, vkDELETE,
                  vkOS_L, vkOS_R, vkAPPS,
                        //  Alternate names
                  vkBACKSPACE, vkNUMPAD_STAR, vkALT_L, vkALT_R,
                  vkNUMPAD_MINUS, vkNUMPAD_PLUS, vkNUMPAD_PERIOD, vkNUMPAD_SLASH,
                  vkARROW_UP, vkPGUP, vkARROW_LEFT, vkARROW_RIGHT, vkARROW_DOWN, vkPGDN,
                  vkPREV_TRACK,
                  vkMOUSELEFT, vkMOUSERIGHT, vkMOUSEMIDDLE,
                  vkSHIFT, vkCONTROL, vkALT);
  // Modifier keys
  TKeyModifier  = (// Any CTRL
                   kmControl,
                   // Left CTRL
                   kmLControl,
                   // Right CTRL
                   kmRControl,
                   // Any Shift
                   kmShift,
                   // Left Shift
                   kmLShift,
                   // Right Shift
                   kmRShift,
                   // Any Alt
                   kmAlt,
                   // Left Alt
                   kmLAlt,
                   // Right Alt
                   kmRAlt,
                   // Left Win
                   kmLOS,
                   // Right Win
                   kmROS,
                   // Any Win key
                   kmOS);
  // Modifier keys set
  TKeyModifiers = set of TKeyModifier;
  // Keyboard state
  TKeyboardState = array[TCEVirtualKey] of Byte;
  // Mouse buttons state
  TMouseButtons = array[TMouseButton] of TInputAction;
  // Mouse state data structure. X, Y and Z is mouse position at corresponding axis. Buttons - mouse buttons state
  TMouseState = packed record
    X, Y, Z: Single;
    Buttons: TMouseButtons;
  end;

  // Touch
  TTouchPointer = record
    // Pointer is active
    Active: Boolean;
    // Pointer coordinates
    X, Y, Z: Single;
  end;

  TTouchState = array[0..$FF] of TTouchPointer;

  TCEBaseInput = class(TCESubSystem)
  private
    function GetPressed(key: TCEVirtualKey): Boolean;
    function GetVirtualKey(key: TCEVirtualKey): Integer;
  protected
    // Current state of each virtual key.
    FKeyboardState: TKeyboardState;
    // Current mouse state
    FMouseState: TMouseState;
    // Current touch pointers state
    FTouchState: TTouchState;
    // Current touch pointers count
    FPointerCount: Integer;
    procedure AddPointer(Id: Integer; X, Y: Single);
    procedure RemovePointer(Id: Integer);
    procedure ClearPointers();
    function GetTouch(Id: Integer): TTouchPointer;
  public
    // State of a virtual key. Non-zero value means that the key is pressed.
    property VirtualKey[key: TCEVirtualKey]: Integer read GetVirtualKey;
    // Is a key currently pressed
    property Pressed[key: TCEVirtualKey]: Boolean read GetPressed;
    // Mouse state
    property MouseState: TMouseState read FMouseState write FMouseState;
    // Current touch pointers state
    property Pointers[Id: Integer]: TTouchPointer read GetTouch;
    // Current touch pointers count
    property PointerCount: Integer read FPointerCount;
    end;

var
  // Maps virtual key codes to platform specific key codes. Initialized typically by OS-dependent application class.
  VirtualKeyCodes: array[TCEVirtualKey] of Integer;
  // Maps virtual MOUSE BUTTON to platform specific key codes. Initialized typically by OS-dependent application class.
  vkMOUSEBUTTON: array[TMouseButton] of Integer;

// Returns virtual key code by platform specific key code
function GetVirtualKeyByKeyCode(Code: Integer): TCEVirtualKey;

implementation

function GetVirtualKeyByKeyCode(Code: Integer): TCEVirtualKey;
begin
  for Result := Low(VirtualKeyCodes) to High(VirtualKeyCodes) do
    if VirtualKeyCodes[Result] = Code then
      Exit;
  Result := vkNONE;
end;

{ TCEBaseInput }

function TCEBaseInput.GetPressed(key: TCEVirtualKey): Boolean;
begin
  Result := FKeyboardState[key] <> 0;
end;

function TCEBaseInput.GetVirtualKey(key: TCEVirtualKey): Integer;
begin
  Result := FKeyboardState[key];
end;

procedure TCEBaseInput.AddPointer(Id: Integer; X, Y: Single);
begin
  Inc(FPointerCount, Ord(not FTouchState[Id].Active));
  FTouchState[Id].Active := False;
  FTouchState[Id].X := X;
  FTouchState[Id].Y := Y;
  FTouchState[Id].Z := 0;
  FTouchState[Id].Active := True;
end;

procedure TCEBaseInput.RemovePointer(Id: Integer);
begin
  Dec(FPointerCount, Ord(FTouchState[Id].Active));
  FTouchState[Id].Active := False;
end;

procedure TCEBaseInput.ClearPointers();
var
  i: Integer;
begin
  for i := Low(FTouchState) to High(FTouchState) do
    FTouchState[i].Active := False;
  FPointerCount := 0;
end;

function TCEBaseInput.GetTouch(Id: Integer): TTouchPointer;
begin
  Assert((Id >= 0) and (Id <= 255), 'Invalid touch pointer id');
  Result := FTouchState[Id];
end;

end.

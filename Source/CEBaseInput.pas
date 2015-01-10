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

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

{$Include PGDCE.inc}
unit CEBaseInput;

interface

uses
  CEMessage, CEBaseTypes;

type
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
  TMouseButtons = array[TMouseButton] of TButtonAction;
  // Mouse state data structure. X, Y and Z is mouse position at corresponding axis. Buttons - mouse buttons state
  TMouseState = packed record
    X, Y, Z: Single;
    Buttons: TMouseButtons;
  end;

  TCEBaseInput = class(TCESubSystem)
  private
    function GetPressed(key: TCEVirtualKey): Boolean;
    function GetVirtualKey(key: TCEVirtualKey): Integer;
  protected
    // Current state of each virtual key.
    FKeyboardState: TKeyboardState;
    // Current mouse state
    FMouseState: TMouseState;
  public
    constructor Create;
    // State of a virtual key. Non-zero value means that the key is pressed.
    property VirtualKey[key: TCEVirtualKey]: Integer read GetVirtualKey;
    // Is a key currently pressed
    property Pressed[key: TCEVirtualKey]: Boolean read GetPressed;
    // Mouse state
    property MouseState: TMouseState read FMouseState write FMouseState;
  end;

var
  // Virtual key codes
  vkNONE: Integer = 0;
  vkESCAPE,
  vk1, vk2, vk3, vk4, vk5, vk6, vk7, vk8, vk9, vk0,
  vkMINUS, vkEQUALS, vkBACK, vkTAB,
  vkQ, vkW, vkE, vkR, vkT, vkY, vkU, vkI, vkO, vkP,
  vkLBRACKET, vkRBRACKET,
  vkRETURN,
  vkLCONTROL,
  vkA, vkS, vkD, vkF, vkG, vkH, vkJ, vkK, vkL,
  vkSEMICOLON, vkAPOSTROPHE, vkGRAVE,
  vkLSHIFT,
  vkBACKSLASH,
  vkZ, vkX, vkC, vkV, vkB, vkN, vkM,
  vkCOMMA, vkPERIOD, vkSLASH,
  vkRSHIFT,
  vkMULTIPLY,
  vkLMENU,
  vkSPACE,
  vkCAPITAL,
  vkF1, vkF2, vkF3, vkF4, vkF5, vkF6, vkF7, vkF8, vkF9, vkF10,
  vkNUMLOCK, vkSCROLL,
  vkNUMPAD7, vkNUMPAD8, vkNUMPAD9, vkSUBTRACT, vkNUMPAD4, vkNUMPAD5, vkNUMPAD6,
  vkADD, vkNUMPAD1, vkNUMPAD2, vkNUMPAD3, vkNUMPAD0, vkDECIMAL,
  vkOEM_102,
  vkF11, vkF12,
  vkF13, vkF14, vkF15,
  vkKANA, vkABNT_C1,
  vkCONVERT, vkNOCONVERT,
  vkYEN, vkABNT_C2,
  vkNUMPADEQUALS, vkCIRCUMFLEX,
  vkAT, vkCOLON, vkUNDERLINE, vkKANJI,
  vkSTOP,
  vkAX, vkUNLABELED,
  vkNEXTTRACK,
  vkNUMPADENTER,
  vkRCONTROL,
  vkMUTE, vkCALCULATOR, vkPLAYPAUSE, vkMEDIASTOP,
  vkVOLUMEDOWN, vkVOLUMEUP,
  vkWEBHOME,
  vkNUMPADCOMMA, vkDIVIDE,
  vkSYSRQ, vkRMENU, vkPAUSE,
  vkHOME, vkUP, vkPRIOR, vkLEFT, vkRIGHT, vkEND, vkDOWN,
  vkNEXT, vkINSERT, vkDELETE,
  vkLOS, vkROS,
  vkAPPS, vkPOWER, vkSLEEP, vkWAKE,
  vkWEBSEARCH, vkWEBFAVORITES, vkWEBREFRESH, vkWEBSTOP, vkWEBFORWARD, vkWEBBACK,
  vkMYCOMPUTER, vkMAIL, vkMEDIASELECT,
  //  Alternate names
  vkBACKSPACE, vkNUMPADSTAR, vkLALT, vkCAPSLOCK,
  vkNUMPADMINUS, vkNUMPADPLUS, vkNUMPADPERIOD, vkNUMPADSLASH,
  vkRALT,
  vkUPARROW, vkPGUP, vkLEFTARROW, vkRIGHTARROW, vkDOWNARROW, vkPGDN,
  vkPREVTRACK, vkMOUSELEFT, vkMOUSERIGHT, vkMOUSEMIDDLE,
  vkSHIFT, vkCONTROL, vkALT: Integer;
  vkMOUSEBUTTON: array[TMouseButton] of Integer;

implementation

{ TCEBaseInput }

function TCEBaseInput.GetVirtualKey(key: TCEVirtualKey): Integer;
begin
  Result := FKeyboardState[key];
end;

constructor TCEBaseInput.Create;
begin
  {$I WI_CONST.inc}
  {$IFNDEF _INPUT_KEYCODES_SET}
    {$MESSAGE Error 'Virtual key codes are not set'}
  {$ENDIF}
end;

function TCEBaseInput.GetPressed(key: TCEVirtualKey): Boolean;
begin
  Result := FKeyboardState[key] <> 0;
end;

end.


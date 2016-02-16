(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEXWindowApplication.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Application for X-Window)

X-Window implementation of the application class

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEXWindowApplication;

interface

uses
  CEBaseApplication,
  X,
  XLib;

type
  TCEXWindowApplication = class(TCEBaseApplication)
  private
    // Application window handle
    FWindowHandle: Cardinal;
    FDisplay: PXDisplay;
    FDeleteMessage: TAtom;
    FLastWindowWidth, FLastWindowHeight: Int64;
    // Processes event from X-Window and calls MessageHandler
    procedure ProcessXEvents();
  protected
    // Initializes vkXXX constants
    procedure InitKeyCodes(); override;
    function DoCreateWindow(): Boolean; override;
    procedure DoDestroyWindow(); override;
  public
    procedure Process(); override;
  end;

  // Declare application class to use it without IFDEFs
  TCEApplicationClass = TCEXWindowApplication;

implementation

uses
  sysutils, CELog, CEBaseInput, keysym,
  XUtil, CEBaseTypes, CEInputMessage, CEMessage;

const
  LOGTAG = 'ce.xwindow.app';

procedure WaitKey(const msg: string);
begin
  CELog.Debug(msg + '. Press ENTER');
  ReadLn();
end;

// To use TKeyboardState type as actual keyboard state we should fit vkXXX constants into byte range
function EnsureByteRange(Value: Integer): Byte;
begin
  Result := Value and $FF;
  if Value and $FF00 > 0 then
    Result := (Value shr 16) and $FF;
  {$IFDEF CE_DEBUG}
  Assert((Result >= 0) and (Result <= 255), 'Value doesn''t fit in byte range: ' + IntToStr(Value));
  {$ENDIF}
end;

procedure TCEXWindowApplication.ProcessXEvents();

  function KeyCodeToSym(KeyEvent: TXKeyEvent): Integer;
  begin
    Result := XLookupKeysym(@KeyEvent, 0);
  end;

  function GetResizeMsg(width, height: Integer): TCEMessage;
  begin
    Result := nil;
    if (width <> FLastWindowWidth) or (height <> FLastWindowWidth) then
    begin
      Result := TWindowResizeMsg.Create(FLastWindowWidth, FLastWindowHeight, width, height);
      FLastWindowWidth := width;
      FLastWindowHeight := height;
    end;
  end;

  function GetModifierMsg(AAction: TInputAction; AKey: TCEVirtualKey; ACode: Integer): TCEMessage;
  begin
    if (AKey = vkSHIFT_L) or (AKey = vkSHIFT_R) then
      Result := TKeyboardMsg.Create(AAction, vkSHIFT, ACode);
    if (AKey = vkCONTROL_L) or (AKey = vkCONTROL_R) then
      Result := TKeyboardMsg.Create(AAction, vkCONTROL, ACode);
    if (AKey = vkALT_L) or (AKey = vkALT_R) then
      Result := TKeyboardMsg.Create(AAction, vkALT, ACode);
  end;

var
  CEMsg, CEMsgMod: TCEMessage;
  XEvent: TXEvent;
  KeySym: Integer;
begin
  while not Terminated and (XPending(FDisplay) > 0) do
  begin
    XNextEvent(FDisplay, @XEvent);
    CEMsg := nil;
    CEMsgMod := nil;
    case XEvent._Type of
      ClientMessage: if XEvent.xclient.data.l[0] = FDeleteMessage then
        Terminated := True;
      FocusIn: begin
        Active := True;
        CEMsg := TAppActivateMsg.Create();
      end;
      FocusOut: begin
        Active := False;
        CEMsg := TAppDeactivateMsg.Create();
      end;
      ConfigureNotify: begin
        CEMsg := GetResizeMsg(XEvent.xconfigure.width, XEvent.xconfigure.height);
      end;
      KeyPress: begin
        KeySym := KeyCodeToSym(XEvent.xkey);
        CEMsg := TKeyboardMsg.Create(iaDown, CEBaseInput.GetVirtualKeyByKeyCode(KeySym), XEvent.xkey.keycode);
        CEMsgMod := GetModifierMsg(iaDown, CEBaseInput.GetVirtualKeyByKeyCode(KeySym), XEvent.xkey.keycode);
      end;
      KeyRelease: begin
        KeySym := KeyCodeToSym(XEvent.xkey);
        CEMsg := TKeyboardMsg.Create(iaUp, CEBaseInput.GetVirtualKeyByKeyCode(KeySym), XEvent.xkey.keycode);
        CEMsgMod := GetModifierMsg(iaUp, CEBaseInput.GetVirtualKeyByKeyCode(KeySym), XEvent.xkey.keycode);
      end;
      MotionNotify: begin
        CEMsg := TMouseMoveMsg.Create(XEvent.XMotion.X, XEvent.XMotion.Y);
      end;
      ButtonPress: begin
        case XEvent.XButton.Button of
          1: CEMsg := TMouseButtonMsg.Create(round(XEvent.XMotion.X), round(XEvent.XMotion.Y), iaDown, mbLeft);
          2: CEMsg := TMouseButtonMsg.Create(round(XEvent.XMotion.X), round(XEvent.XMotion.Y), iaDown, mbMiddle);
          3: CEMsg := TMouseButtonMsg.Create(round(XEvent.XMotion.X), round(XEvent.XMotion.Y), iaDown, mbRight);
        end;
      end;
      ButtonRelease: begin
        case XEvent.XButton.Button of
          1: CEMsg := TMouseButtonMsg.Create(round(XEvent.XMotion.X), round(XEvent.XMotion.Y), iaUp, mbLeft);
          2: CEMsg := TMouseButtonMsg.Create(round(XEvent.XMotion.X), round(XEvent.XMotion.Y), iaUp, mbMiddle);
          3: CEMsg := TMouseButtonMsg.Create(round(XEvent.XMotion.X), round(XEvent.XMotion.Y), iaUp, mbRight);
        end;
      end;
    end;
    if Assigned(MessageHandler) then begin
      if Assigned(CEMsg) then
        MessageHandler(CEMsg);
      if Assigned(CEMsgMod) then
        MessageHandler(CEMsgMod);
    end;
  end;
end;

// Virtual key codes initialization
procedure TCEXWindowApplication.InitKeyCodes();
begin
  VirtualKeyCodes[vkESCAPE] := XK_Escape;
  VirtualKeyCodes[vk1] := XK_1;
  VirtualKeyCodes[vk2] := XK_2;
  VirtualKeyCodes[vk3] := XK_3;
  VirtualKeyCodes[vk4] := XK_4;
  VirtualKeyCodes[vk5] := XK_5;
  VirtualKeyCodes[vk6] := XK_6;
  VirtualKeyCodes[vk7] := XK_7;
  VirtualKeyCodes[vk8] := XK_8;
  VirtualKeyCodes[vk9] := XK_9;
  VirtualKeyCodes[vk0] := XK_0;
  VirtualKeyCodes[vkMINUS] := XK_minus;    (* - on main keyboard *)
  VirtualKeyCodes[vkEQUALS] := XK_equal;
  VirtualKeyCodes[vkBACKSPACE] := XK_BackSpace;      (* backspace *)
  VirtualKeyCodes[vkTAB] := XK_Tab;
  VirtualKeyCodes[vkQ] := XK_q;
  VirtualKeyCodes[vkW] := XK_w;
  VirtualKeyCodes[vkE] := XK_e;
  VirtualKeyCodes[vkR] := XK_r;
  VirtualKeyCodes[vkT] := XK_t;
  VirtualKeyCodes[vkY] := XK_y;
  VirtualKeyCodes[vkU] := XK_u;
  VirtualKeyCodes[vkI] := XK_i;
  VirtualKeyCodes[vkO] := XK_o;
  VirtualKeyCodes[vkP] := XK_p;
  VirtualKeyCodes[vkBRACKET_L] := XK_bracketleft;
  VirtualKeyCodes[vkBRACKET_R] := XK_bracketright;
  VirtualKeyCodes[vkPAREN_L] := XK_parenleft;
  VirtualKeyCodes[vkPAREN_R] := XK_parenright;
  VirtualKeyCodes[vkRETURN] := XK_Return;     (* Enter on main keyboard *)
  VirtualKeyCodes[vkCONTROL_L] := XK_Control_L;
  VirtualKeyCodes[vkA] := XK_a;
  VirtualKeyCodes[vkS] := XK_s;
  VirtualKeyCodes[vkD] := XK_d;
  VirtualKeyCodes[vkF] := XK_f;
  VirtualKeyCodes[vkG] := XK_g;
  VirtualKeyCodes[vkH] := XK_h;
  VirtualKeyCodes[vkJ] := XK_j;
  VirtualKeyCodes[vkK] := XK_k;
  VirtualKeyCodes[vkL] := XK_l;
  VirtualKeyCodes[vkSEMICOLON] := XK_semicolon;
  VirtualKeyCodes[vkAPOSTROPHE] := XK_apostrophe;
  VirtualKeyCodes[vkGRAVE] := XK_grave; (* accent grave *)
  VirtualKeyCodes[vkSHIFT_L] := XK_Shift_L;
  VirtualKeyCodes[vkBACKSLASH] := XK_backslash;
  VirtualKeyCodes[vkZ] := XK_z;
  VirtualKeyCodes[vkX] := XK_x;
  VirtualKeyCodes[vkC] := XK_c;
  VirtualKeyCodes[vkV] := XK_v;
  VirtualKeyCodes[vkB] := XK_b;
  VirtualKeyCodes[vkN] := XK_n;
  VirtualKeyCodes[vkM] := XK_m;
  VirtualKeyCodes[vkCOMMA] := XK_COMMA;
  VirtualKeyCodes[vkPERIOD] := XK_period;    (* . on main keyboard *)
  VirtualKeyCodes[vkSLASH] := XK_slash;    (* / on main keyboard *)
  VirtualKeyCodes[vkSHIFT_R] := XK_Shift_R;
  VirtualKeyCodes[vkNUMPAD_MULTIPLY] := XK_KP_Multiply;    (* * on numeric keypad *)
  VirtualKeyCodes[vkALT_L] := XK_Alt_L;    (* left Alt *)
  VirtualKeyCodes[vkSPACE] := XK_space;
  VirtualKeyCodes[vkCAPS_LOCK] := XK_Caps_Lock;
  VirtualKeyCodes[vkF1] := XK_F1;
  VirtualKeyCodes[vkF2] := XK_F2;
  VirtualKeyCodes[vkF3] := XK_F3;
  VirtualKeyCodes[vkF4] := XK_F4;
  VirtualKeyCodes[vkF5] := XK_F5;
  VirtualKeyCodes[vkF6] := XK_F6;
  VirtualKeyCodes[vkF7] := XK_F7;
  VirtualKeyCodes[vkF8] := XK_F8;
  VirtualKeyCodes[vkF9] := XK_F9;
  VirtualKeyCodes[vkF10] := XK_F10;
  VirtualKeyCodes[vkNUM_LOCK] := XK_Num_Lock;
  VirtualKeyCodes[vkSCROLL_LOCK] := XK_Scroll_Lock;    (* Scroll Lock *)
  VirtualKeyCodes[vkNUMPAD_7] := XK_KP_Home;
  VirtualKeyCodes[vkNUMPAD_8] := XK_KP_Up;
  VirtualKeyCodes[vkNUMPAD_9] := XK_KP_Page_Up;
  VirtualKeyCodes[vkNUMPAD_MINUS] := XK_KP_Subtract;    (* - on numeric keypad *)
  VirtualKeyCodes[vkNUMPAD_4] := XK_KP_Left;
  VirtualKeyCodes[vkNUMPAD_5] := XK_KP_Begin;
  VirtualKeyCodes[vkNUMPAD_6] := XK_KP_Right;
  VirtualKeyCodes[vkNUMPAD_PLUS] := XK_KP_Add;    (* + on numeric keypad *)
  VirtualKeyCodes[vkNUMPAD_1] := XK_KP_End;
  VirtualKeyCodes[vkNUMPAD_2] := XK_KP_Down;
  VirtualKeyCodes[vkNUMPAD_3] := XK_KP_Page_Down;
  VirtualKeyCodes[vkNUMPAD_0] := XK_KP_Insert;
  VirtualKeyCodes[vkNUMPAD_PERIOD] := XK_KP_Decimal;     (* . on numeric keypad *)

  VirtualKeyCodes[vkOEM_102] := XK_asterisk;    (* < > | on UK/Germany keyboards *)
  VirtualKeyCodes[vkF11] := XK_F11;
  VirtualKeyCodes[vkF12] := XK_F12;
  VirtualKeyCodes[vkF13] := XK_F13;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkF14] := XK_F14;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkF15] := XK_F15;    (*                     (NEC PC98) *)

  VirtualKeyCodes[vkNUMPAD_EQUALS] := XK_KP_Equal;     (* :=on numeric keypad (NEC PC98) *)
  VirtualKeyCodes[vkCIRCUMFLEX] := XK_dead_circumflex;    (* (Japanese keyboard)            *)
  VirtualKeyCodes[vkAT] := XK_at;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkCOLON] := XK_colon;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkUNDERLINE] := XK_underscore;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkKANJI] := XK_Kanji;    (* (Japanese keyboard)            *)

  VirtualKeyCodes[vkNUMPAD_ENTER] := XK_KP_Enter;     (* Enter on numeric keypad *)
  VirtualKeyCodes[vkCONTROL_R] := XK_Control_R;

  VirtualKeyCodes[vkNUMPAD_COMMA] := XK_KP_Separator;    (* , on numeric keypad (NEC PC98) *)
  VirtualKeyCodes[vkNUMPAD_DIVIDE] := XK_KP_Divide;    (* / on numeric keypad *)
  VirtualKeyCodes[vkSYSRQ] := XK_Sys_Req;
  VirtualKeyCodes[vkALT_R] := XK_Alt_R;    (* right Alt *)
  VirtualKeyCodes[vkPAUSE] := XK_Pause;     (* Pause (watch out - not realiable on some kbds) *)
  VirtualKeyCodes[vkHOME] := XK_Home;     (* Home on arrow keypad *)
  VirtualKeyCodes[vkUP] := XK_UP;     (* UpArrow on arrow keypad *)
  VirtualKeyCodes[vkPGUP] := XK_Page_Up;     (* PgUp on arrow keypad *)

  VirtualKeyCodes[vkLEFT] := XK_Left;     (* LeftArrow on arrow keypad *)
  VirtualKeyCodes[vkRIGHT] := XK_Right;     (* RightArrow on arrow keypad *)
  VirtualKeyCodes[vkEND] := XK_End;     (* End on arrow keypad *)
  VirtualKeyCodes[vkDOWN] := XK_Down;     (* DownArrow on arrow keypad *)
  VirtualKeyCodes[vkPGDN] := XK_Page_Down;     (* PgDn on arrow keypad *)
  VirtualKeyCodes[vkINSERT] := XK_INSERT;     (* Insert on arrow keypad *)
  VirtualKeyCodes[vkDELETE] := XK_Delete;     (* Delete on arrow keypad *)
  VirtualKeyCodes[vkOS_L] := XK_Super_L;     (* Left Windows key *)
  VirtualKeyCodes[vkOS_R] := XK_Super_R;     (* Right Windows key *)
  VirtualKeyCodes[vkAPPS] := XK_Menu;     (* AppMenu key *)

(*
  *  Alternate names for keys, to facilitate transition from DOS.
  *)

  VirtualKeyCodes[vkMOUSELEFT] := $1;
  VirtualKeyCodes[vkMOUSERIGHT] := $2;
  VirtualKeyCodes[vkMOUSEMIDDLE] := $4;

  VirtualKeyCodes[vkSHIFT] := 16;
  VirtualKeyCodes[vkCONTROL] := 17;
  VirtualKeyCodes[vkALT] := 18;

  vkMOUSEBUTTON[mbLeft] := VirtualKeyCodes[vkMOUSELEFT];
  vkMOUSEBUTTON[mbRight] := VirtualKeyCodes[vkMOUSERIGHT];
  vkMOUSEBUTTON[mbMiddle] := VirtualKeyCodes[vkMOUSEMIDDLE];
  vkMOUSEBUTTON[mbCustom1] := VirtualKeyCodes[vkNONE];
end;

function TCEXWindowApplication.DoCreateWindow(): Boolean;
var
  ScreenNum: LongInt;
  ScreenX, ScreenY, ScreenDepth: Integer;
  Title: RawByteString;
  WindowName: TXTextProperty;
  SizeHints: TXSizeHints;
  X11WindowAttributes: TXSetWindowAttributes;
begin
  Result := False;
  FDisplay := XOpenDisplay(nil);
  if FDisplay = nil then begin
    Error('Can''t connect to the X server');
    Exit;
  end;
  ScreenNum := XDefaultScreen(FDisplay);
  ScreenX := XDisplayWidth(FDisplay, ScreenNum);
  ScreenY := XDisplayHeight(FDisplay, ScreenNum);
  ScreenDepth := XDefaultDepth(FDisplay, ScreenNum);

  X11WindowAttributes.override_redirect := 0;                  // 1 for full screen

  FWindowHandle := XCreateWindow(FDisplay, XRootWindow(FDisplay, ScreenNum),
                              (ScreenX - 1024) div 2 + 300, (ScreenY - 1024) div 2, 1024, 1024, 0,
                              CopyFromParent, InputOutput, CopyFromParent, CWOverrideRedirect, @X11WindowAttributes);

  CELog.Debug(LOGTAG, 'HWND: ' + IntToHex(FWindowHandle, 8));

  Cfg.SetInt64(CFG_WINDOW_HANDLE, FWindowHandle);
  Cfg.SetPointer(CFG_XWINDOW_DISPLAY, FDisplay);
  Cfg.SetInt64(CFG_XWINDOW_SCREEN, ScreenNum);

  SizeHints.flags := PPosition or PSize;
  SizeHints.width := 1024;
  SizeHints.height := 1024;
  SizeHints.x := (ScreenX - 1024) div 2 + 300;
  SizeHints.y := (ScreenY - 1024) div 2;
  Title := UTF8Encode(Cfg['App.Name']);

  if Xutf8TextListToTextProperty(FDisplay, @Title, 1, XUTF8StringStyle, @WindowName) <> Success then
  begin
    Warning('UTF-8 window captions not supported? Falling back to ANSI.');
    XStringListToTextProperty(@Title, 1, @WindowName);
  end;

  XSetWMProperties(FDisplay, FWindowHandle, @WindowName, nil, nil, 0, @SizeHints, nil, nil);

  XSelectInput(FDisplay, FWindowHandle, ExposureMask or KeyPressMask or KeyReleaseMask or PointerMotionMask
                                    or ButtonPressMask or ButtonReleaseMask or StructureNotifyMask or FocusChangeMask);

  FDeleteMessage := XInternAtom(FDisplay, 'WM_DELETE_WINDOW', True);
  XSetWMProtocols(FDisplay, FWindowHandle, @FDeleteMessage, 1);
  XMapRaised(FDisplay, FWindowHandle);

  Result := True;
end;

procedure TCEXWindowApplication.DoDestroyWindow();
begin
  XCloseDisplay(FDisplay);
end;

procedure TCEXWindowApplication.Process();
begin
  if XPending(FDisplay) > 0 then
  begin
    ProcessXEvents();
  end else if not Active then
    Sleep(INACTIVE_SLEEP_MS);
end;

end.

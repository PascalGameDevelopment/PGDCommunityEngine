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
    Result := EnsureByteRange(XLookupKeysym(@KeyEvent, 0));
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
    if (AKey = vkLSHIFT) or (AKey = vkRSHIFT) then
      Result := TKeyboardMsg.Create(AAction, vkSHIFT, ACode);
    if (AKey = vkLCONTROL) or (AKey = vkRCONTROL) then
      Result := TKeyboardMsg.Create(AAction, vkCONTROL, ACode);
    if (AKey = vkLALT) or (AKey = vkRALT) then
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
        CEMsg := TKeyboardMsg.Create(iaDown, KeySym, XEvent.xkey.keycode);
        CEMsgMod := GetModifierMsg(iaDown, KeySym, XEvent.xkey.keycode);
        CELog.Debug(Format('KeyPress: [%d, %d]', [XEvent.xkey.keycode, KeySym]));
      end;
      KeyRelease: begin
        KeySym := KeyCodeToSym(XEvent.xkey);
        CEMsg := TKeyboardMsg.Create(iaUp, KeySym, XEvent.xkey.keycode);
        CEMsgMod := GetModifierMsg(iaUp, KeySym, XEvent.xkey.keycode);
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
  vkESCAPE := EnsureByteRange(XK_Escape);
  vk1 := XK_1;
  vk2 := XK_2;
  vk3 := XK_3;
  vk4 := XK_4;
  vk5 := XK_5;
  vk6 := XK_6;
  vk7 := XK_7;
  vk8 := XK_8;
  vk9 := XK_9;
  vk0 := XK_0;
  vkMINUS := EnsureByteRange(XK_minus);    (* - on main keyboard *)
  vkEQUALS := EnsureByteRange(XK_equal);
  vkBACK := EnsureByteRange(XK_BackSpace);      (* backspace *)
  vkTAB := EnsureByteRange(XK_Tab);
  vkQ := XK_q;
  vkW := XK_w;
  vkE := XK_e;
  vkR := XK_r;
  vkT := XK_t;
  vkY := XK_y;
  vkU := XK_u;
  vkI := XK_i;
  vkO := XK_o;
  vkP := XK_p;
  vkLBRACKET := EnsureByteRange(XK_bracketleft);
  vkRBRACKET := EnsureByteRange(XK_bracketright);
  vkRETURN := EnsureByteRange(XK_Return);     (* Enter on main keyboard *)
  vkLCONTROL := EnsureByteRange(XK_Control_L);
  vkA := XK_a;
  vkS := XK_s;
  vkD := XK_d;
  vkF := XK_f;
  vkG := XK_g;
  vkH := XK_h;
  vkJ := XK_j;
  vkK := XK_k;
  vkL := XK_l;
  vkSEMICOLON := EnsureByteRange(XK_semicolon);
  vkAPOSTROPHE := EnsureByteRange(XK_apostrophe);
  vkGRAVE := EnsureByteRange(XK_grave); (* accent grave *)
  vkLSHIFT := EnsureByteRange(XK_Shift_L);
  vkBACKSLASH := EnsureByteRange(XK_backslash);
  vkZ := XK_z;
  vkX := XK_x;
  vkC := XK_c;
  vkV := XK_v;
  vkB := XK_b;
  vkN := XK_n;
  vkM := XK_m;
  vkCOMMA := EnsureByteRange(XK_COMMA);
  vkPERIOD := EnsureByteRange(XK_period);    (* . on main keyboard *)
  vkSLASH := EnsureByteRange(XK_slash);    (* / on main keyboard *)
  vkRSHIFT := EnsureByteRange(XK_Shift_R);
  vkMULTIPLY := EnsureByteRange(XK_KP_Multiply);    (* * on numeric keypad *)
  vkLMENU := EnsureByteRange(XK_Alt_L);    (* left Alt *)
  vkSPACE := EnsureByteRange(XK_space);
  vkCAPITAL := EnsureByteRange(XK_Caps_Lock);
  vkF1 := EnsureByteRange(XK_F1);
  vkF2 := EnsureByteRange(XK_F2);
  vkF3 := EnsureByteRange(XK_F3);
  vkF4 := EnsureByteRange(XK_F4);
  vkF5 := EnsureByteRange(XK_F5);
  vkF6 := EnsureByteRange(XK_F6);
  vkF7 := EnsureByteRange(XK_F7);
  vkF8 := EnsureByteRange(XK_F8);
  vkF9 := EnsureByteRange(XK_F9);
  vkF10 := EnsureByteRange(XK_F10);
  vkNUMLOCK := EnsureByteRange(XK_Num_Lock);
  vkSCROLL := EnsureByteRange(XK_Scroll_Lock);    (* Scroll Lock *)
  vkNUMPAD7 := EnsureByteRange(XK_KP_7);
  vkNUMPAD8 := EnsureByteRange(XK_KP_8);
  vkNUMPAD9 := EnsureByteRange(XK_KP_9);
  vkSUBTRACT := EnsureByteRange(XK_KP_Subtract);    (* - on numeric keypad *)
  vkNUMPAD4 := EnsureByteRange(XK_KP_4);
  vkNUMPAD5 := EnsureByteRange(XK_KP_5);
  vkNUMPAD6 := EnsureByteRange(XK_KP_6);
  vkADD := EnsureByteRange(XK_KP_Add);    (* + on numeric keypad *)
  vkNUMPAD1 := EnsureByteRange(XK_KP_1);
  vkNUMPAD2 := EnsureByteRange(XK_KP_2);
  vkNUMPAD3 := EnsureByteRange(XK_KP_3);
  vkNUMPAD0 := EnsureByteRange(XK_KP_0);
  vkDECIMAL := EnsureByteRange(XK_KP_Decimal);     (* . on numeric keypad *)

  vkOEM_102 := EnsureByteRange(XK_asterisk);    (* < > | on UK/Germany keyboards *)
  vkF11 := EnsureByteRange(XK_F11);
  vkF12 := EnsureByteRange(XK_F12);
  vkF13 := EnsureByteRange(XK_F13);    (*                     (NEC PC98) *)
  vkF14 := EnsureByteRange(XK_F14);    (*                     (NEC PC98) *)
  vkF15 := EnsureByteRange(XK_F15);    (*                     (NEC PC98) *)

  vkNUMPADEQUALS := EnsureByteRange(XK_KP_Equal);     (* :=on numeric keypad (NEC PC98) *)
  vkCIRCUMFLEX := EnsureByteRange(XK_dead_circumflex);    (* (Japanese keyboard)            *)
  vkAT := EnsureByteRange(XK_at);    (*                     (NEC PC98) *)
  vkCOLON := EnsureByteRange(XK_colon);    (*                     (NEC PC98) *)
  vkUNDERLINE := EnsureByteRange(XK_underscore);    (*                     (NEC PC98) *)
  vkKANJI := EnsureByteRange(XK_Kanji);    (* (Japanese keyboard)            *)

  vkNUMPADENTER := EnsureByteRange(XK_KP_Enter);     (* Enter on numeric keypad *)
  vkRCONTROL := EnsureByteRange(XK_Control_R);

  vkNUMPADCOMMA := EnsureByteRange(XK_KP_Separator);    (* , on numeric keypad (NEC PC98) *)
  vkDIVIDE := EnsureByteRange(XK_KP_Divide);    (* / on numeric keypad *)
  vkSYSRQ := EnsureByteRange(XK_Sys_Req);
  vkRMENU := EnsureByteRange(XK_Alt_R);    (* right Alt *)
  vkPAUSE := EnsureByteRange(XK_Pause);     (* Pause (watch out - not realiable on some kbds) *)
  vkHOME := EnsureByteRange(XK_Home);     (* Home on arrow keypad *)
  vkUP := EnsureByteRange(XK_UP);     (* UpArrow on arrow keypad *)
  vkPRIOR := EnsureByteRange(XK_Page_Up);     (* PgUp on arrow keypad *)

  vkLEFT := EnsureByteRange(XK_Left);     (* LeftArrow on arrow keypad *)
  vkRIGHT := EnsureByteRange(XK_Right);     (* RightArrow on arrow keypad *)
  vkEND := EnsureByteRange(XK_End);     (* End on arrow keypad *)
  vkDOWN := EnsureByteRange(XK_Down);     (* DownArrow on arrow keypad *)
  vkNEXT := EnsureByteRange(XK_Page_Down);     (* PgDn on arrow keypad *)
  vkINSERT := EnsureByteRange(XK_INSERT);     (* Insert on arrow keypad *)
  vkDELETE := EnsureByteRange(XK_Delete);     (* Delete on arrow keypad *)
  vkLOS := EnsureByteRange(XK_Meta_L);     (* Left Windows key *)
  vkROS := EnsureByteRange(XK_Meta_R);     (* Right Windows key *)
  vkAPPS := EnsureByteRange(XK_Menu);     (* AppMenu key *)

(*
  *  Alternate names for keys, to facilitate transition from DOS.
  *)
  vkBACKSPACE := vkBACK;      (* backspace *)
  vkNUMPADSTAR := vkMULTIPLY;  (* * on numeric keypad *)
  vkLALT := vkLMENU;     (* left Alt *)
  vkCAPSLOCK := vkCAPITAL;   (* CapsLock *)
  vkNUMPADMINUS := vkSUBTRACT;  (* - on numeric keypad *)
  vkNUMPADPLUS := vkADD;       (* + on numeric keypad *)
  vkNUMPADPERIOD := vkDECIMAL;   (* . on numeric keypad *)
  vkNUMPADSLASH := vkDIVIDE;    (* / on numeric keypad *)
  vkRALT := vkRMENU;     (* right Alt *)
  vkUPARROW := vkUP;        (* UpArrow on arrow keypad *)
  vkPGUP := vkPRIOR;     (* PgUp on arrow keypad *)
  vkLEFTARROW := vkLEFT;      (* LeftArrow on arrow keypad *)
  vkRIGHTARROW := vkRIGHT;     (* RightArrow on arrow keypad *)
  vkDOWNARROW := vkDOWN;      (* DownArrow on arrow keypad *)
  vkPGDN := vkNEXT;      (* PgDn on arrow keypad *)

  vkPREVTRACK := vkCIRCUMFLEX;  (* Japanese keyboard *)

  vkMOUSELEFT := $1;
  vkMOUSERIGHT := $2;
  vkMOUSEMIDDLE := $4;

  vkSHIFT := 16;
  vkCONTROL := 17;
  vkALT := 18;

  vkMOUSEBUTTON[mbLeft] := vkMOUSELEFT;
  vkMOUSEBUTTON[mbRight] := vkMOUSERIGHT;
  vkMOUSEBUTTON[mbMiddle] := vkMOUSEMIDDLE;
  vkMOUSEBUTTON[mbCustom1] := vkNONE;
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

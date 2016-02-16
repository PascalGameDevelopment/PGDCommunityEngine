(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEWindowsApplication.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Application for Windows)

Windows implementation of the application class

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
unit CEWindowsApplication;

interface

uses
  Windows, Messages,
  CEMessage, CEBaseApplication;

type
  // Windows message handling callback
  TWndProc = function (WHandle: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

  TCEWindowsApplication = class(TCEBaseApplication)
  private
    // Application window handle
    FWindowHandle: Cardinal;
    // Current window class
    FWindowClass: TWndClassW;
    FWindowClassName: string;
  protected
    // Should be set to False in ProcessWinMessage() to prevent default message handler call
    FCallDefaultMsgHandler: Boolean;
    // Virtual key codes initialization
    procedure InitKeyCodes(); override;
    function DoCreateWindow(): Boolean; override;
    procedure DoDestroyWindow(); override;
    // Windows message processing
    function ProcessWinMessage(Msg: UINT; wParam: WPARAM; lParam: LPARAM): Integer;
  public
    procedure Process(); override;
  end;

  // Declare application class to use it without IFDEFs
  TCEApplicationClass = TCEWindowsApplication;

  function WMToMessage(Msg: UINT; wParam: WPARAM; lParam: LPARAM): TCEMessage; overload;
  function WMToMessage(const Msg: Messages.TMessage): TCEMessage; overload;

implementation

uses
  SysUtils, CEInputMessage, CEBaseTypes, CEBaseInput;

var
  App: TCEWindowsApplication;

function WMToMessage(Msg: UINT; wParam: WPARAM; lParam: LPARAM): TCEMessage; overload;
const CHANGED_MASK = 1 shl 30;

function GetX(v: Windows.LPARAM): Single;
begin
  Result := SmallInt(v and $FFFF);
end;

function GetY(v: Windows.LPARAM): Single;
begin
  Result := SmallInt((v shr 16) and $FFFF);
end;

begin
  Result := nil;
  case Msg of
    WM_ACTIVATEAPP: begin
      if wParam = 0 then Result := TAppDeactivateMsg.Create else Result := TAppActivateMsg.Create;
    end;
    WM_SIZE: begin
      if wParam = SIZE_MINIMIZED then
        Result := TWindowMinimizeMsg.Create
      else
        Result := TWindowResizeMsg.Create(0, 0, lParam and 65535, lParam shr 16);
    end;
    WM_MOVE:    Result := TWindowMoveMsg.Create(lParam and 65535, lParam shr 16);
    WM_CHAR:    Result := TCharInputMsg.Create(Chr(wParam), lParam);
    WM_KEYUP, WM_SYSKEYUP: Result := TKeyboardMsg.Create(iaUp, CEBaseInput.GetVirtualKeyByKeyCode(wParam), (lParam shr 16) and $FF);
    WM_KEYDOWN, WM_SYSKEYDOWN: if lParam and CHANGED_MASK = 0 then
      Result := TKeyboardMsg.Create(iaDown, CEBaseInput.GetVirtualKeyByKeyCode(wParam), (lParam shr 16) and $FF);
    WM_LBUTTONDOWN: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), iaDown, mbLeft);
    WM_MBUTTONDOWN: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), iaDown, mbMiddle);
    WM_RBUTTONDOWN: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), iaDown, mbRight);
    WM_LBUTTONUP: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), iaUp, mbLeft);
    WM_MBUTTONUP: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), iaUp, mbMiddle);
    WM_RBUTTONUP: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), iaUp, mbRight);
    WM_MOUSEMOVE: Result := TMouseMoveMsg.Create(GetX(lParam), GetY(lParam));
  end;
  if Assigned(Result) then
    Result.Flags := Result.Flags + [mfCore];
end;

function WMToMessage(const Msg: Messages.TMessage): TCEMessage; overload;
begin
  Result := WMToMessage(Msg.Msg, Msg.WParam, Msg.LParam);
end;

// Standard window procedure
function StdWindowProc(WHandle: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  if (App = nil) or (App.FWindowHandle = 0) or (App.Terminated) then
  begin
    Result := DefWindowProc(WHandle, Msg, wParam, lParam)
  end else begin
    App.FCallDefaultMsgHandler := True;
    Result := App.ProcessWinMessage(Msg, wParam, lParam);
    if App.FCallDefaultMsgHandler then
      Result := DefWindowProc(WHandle, Msg, wParam, lParam);
  end;
end;

{ TCEWindowsApplication }

// Virtual key codes initialization
procedure TCEWindowsApplication.InitKeyCodes();
begin
  VirtualKeyCodes[vkESCAPE] := 27;
  VirtualKeyCodes[vk1] := Ord('1');
  VirtualKeyCodes[vk2] := Ord('2');
  VirtualKeyCodes[vk3] := Ord('3');
  VirtualKeyCodes[vk4] := Ord('4');
  VirtualKeyCodes[vk5] := Ord('5');
  VirtualKeyCodes[vk6] := Ord('6');
  VirtualKeyCodes[vk7] := Ord('7');
  VirtualKeyCodes[vk8] := Ord('8');
  VirtualKeyCodes[vk9] := Ord('9');
  VirtualKeyCodes[vk0] := Ord('0');
  VirtualKeyCodes[vkMINUS] := 189;    (* - on main keyboard *)
  VirtualKeyCodes[vkEQUALS] := 187;
  VirtualKeyCodes[vkBACKSPACE] := 8;      (* backspace *)
  VirtualKeyCodes[vkTAB] := 9;
  VirtualKeyCodes[vkQ] := Ord('Q');
  VirtualKeyCodes[vkW] := Ord('W');
  VirtualKeyCodes[vkE] := Ord('E');
  VirtualKeyCodes[vkR] := Ord('R');
  VirtualKeyCodes[vkT] := Ord('T');
  VirtualKeyCodes[vkY] := Ord('Y');
  VirtualKeyCodes[vkU] := Ord('U');
  VirtualKeyCodes[vkI] := Ord('I');
  VirtualKeyCodes[vkO] := Ord('O');
  VirtualKeyCodes[vkP] := Ord('P');
  VirtualKeyCodes[vkBRACKET_L] := 219;
  VirtualKeyCodes[vkBRACKET_R] := 221;
  VirtualKeyCodes[vkPAREN_L] := 0;
  VirtualKeyCodes[vkPAREN_R] := 0;
  VirtualKeyCodes[vkRETURN] := 13;     (* Enter on main keyboard *)
  VirtualKeyCodes[vkCONTROL_L] := 162;
  VirtualKeyCodes[vkA] := Ord('A');
  VirtualKeyCodes[vkS] := Ord('S');
  VirtualKeyCodes[vkD] := Ord('D');
  VirtualKeyCodes[vkF] := Ord('F');
  VirtualKeyCodes[vkG] := Ord('G');
  VirtualKeyCodes[vkH] := Ord('H');
  VirtualKeyCodes[vkJ] := Ord('J');
  VirtualKeyCodes[vkK] := Ord('K');
  VirtualKeyCodes[vkL] := Ord('L');
  VirtualKeyCodes[vkSEMICOLON] := 186;
  VirtualKeyCodes[vkAPOSTROPHE] := 222;
  VirtualKeyCodes[vkGRAVE] := 192; (* accent grave *)
  VirtualKeyCodes[vkSHIFT_L] := 160;
  VirtualKeyCodes[vkBACKSLASH] := 220;
  VirtualKeyCodes[vkZ] := Ord('Z');
  VirtualKeyCodes[vkX] := Ord('X');
  VirtualKeyCodes[vkC] := Ord('C');
  VirtualKeyCodes[vkV] := Ord('V');
  VirtualKeyCodes[vkB] := Ord('B');
  VirtualKeyCodes[vkN] := Ord('N');
  VirtualKeyCodes[vkM] := Ord('M');
  VirtualKeyCodes[vkCOMMA] := 188;
  VirtualKeyCodes[vkPERIOD] := 190;    (* . on main keyboard *)
  VirtualKeyCodes[vkSLASH] := 191;    (* / on main keyboard *)
  VirtualKeyCodes[vkSHIFT_R] := 161;
  VirtualKeyCodes[vkNUMPAD_MULTIPLY] := 106;    (* * on numeric keypad *)
  VirtualKeyCodes[vkALT_L] := 164;    (* left Alt *)
  VirtualKeyCodes[vkSPACE] := 32;
  VirtualKeyCodes[vkCAPS_LOCK] := 20;
  VirtualKeyCodes[vkF1] := 112;
  VirtualKeyCodes[vkF2] := 113;
  VirtualKeyCodes[vkF3] := 114;
  VirtualKeyCodes[vkF4] := 115;
  VirtualKeyCodes[vkF5] := 116;
  VirtualKeyCodes[vkF6] := 117;
  VirtualKeyCodes[vkF7] := 118;
  VirtualKeyCodes[vkF8] := 119;
  VirtualKeyCodes[vkF9] := 120;
  VirtualKeyCodes[vkF10] := 121;
  VirtualKeyCodes[vkNUM_LOCK] := 144;
  VirtualKeyCodes[vkSCROLL_LOCK] := 145;    (* Scroll Lock *)
  VirtualKeyCodes[vkNUMPAD_7] := 36;
  VirtualKeyCodes[vkNUMPAD_8] := 38;
  VirtualKeyCodes[vkNUMPAD_9] := 33;
  VirtualKeyCodes[vkNUMPAD_MINUS] := 109;    (* - on numeric keypad *)
  VirtualKeyCodes[vkNUMPAD_4] := 37;
  VirtualKeyCodes[vkNUMPAD_5] := 12;
  VirtualKeyCodes[vkNUMPAD_6] := 39;
  VirtualKeyCodes[vkNUMPAD_PLUS] := 107;    (* + on numeric keypad *)
  VirtualKeyCodes[vkNUMPAD_1] := 35;
  VirtualKeyCodes[vkNUMPAD_2] := 40;
  VirtualKeyCodes[vkNUMPAD_3] := 34;
  VirtualKeyCodes[vkNUMPAD_0] := 45;
  VirtualKeyCodes[vkNUMPAD_PERIOD] := 46;     (* . on numeric keypad *)
  // $54 to $55 unassigned
  VirtualKeyCodes[vkOEM_102] := $56;    (* < > | on UK/Germany keyboards *)
  VirtualKeyCodes[vkF11] := 122;
  VirtualKeyCodes[vkF12] := 123;
  // $59 to $63 unassigned
  VirtualKeyCodes[vkF13] := $64;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkF14] := $65;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkF15] := $66;    (*                     (NEC PC98) *)
  // $67 to $6F unassigned
  // $74 to $78 unassigned
  // $7A unassigned
  // $7C unassigned
  // $7F to 8C unassigned
  VirtualKeyCodes[vkNUMPAD_EQUALS] := 13;     (* :=on numeric keypad (NEC PC98) *)
  // $8E to $8F unassigned
  VirtualKeyCodes[vkCIRCUMFLEX] := $90;    (* (Japanese keyboard)            *)
  VirtualKeyCodes[vkAT] := $91;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkCOLON] := $92;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkUNDERLINE] := $93;    (*                     (NEC PC98) *)
  VirtualKeyCodes[vkKANJI] := $94;    (* (Japanese keyboard)            *)
  // $98 unassigned
  VirtualKeyCodes[vkNEXTTRACK] := $99;    (* Next Track *)
  // $9A to $9D unassigned
  VirtualKeyCodes[vkNUMPAD_ENTER] := 13;     (* Enter on numeric keypad *)
  VirtualKeyCodes[vkCONTROL_R] := 163;
  // $9E to $9F unassigned
  // $A5 to $AD unassigned
  // $AF unassigned
  // $B1 unassigned
  VirtualKeyCodes[vkNUMPAD_COMMA] := $B3;    (* , on numeric keypad (NEC PC98) *)
  // $B4 unassigned
  VirtualKeyCodes[vkNUMPAD_DIVIDE] := 111;    (* / on numeric keypad *)
  // $B6 unassigned
  VirtualKeyCodes[vkSYSRQ] := $B7;
  VirtualKeyCodes[vkALT_R] := 165;    (* right Alt *)
  // $B9 to $C4 unassigned
  VirtualKeyCodes[vkPAUSE] := 19;     (* Pause (watch out - not realiable on some kbds) *)
  // $C6 unassigned
  VirtualKeyCodes[vkHOME] := 36;     (* Home on arrow keypad *)
  VirtualKeyCodes[vkUP] := 38;     (* UpArrow on arrow keypad *)
  VirtualKeyCodes[vkPGUP] := 33;     (* PgUp on arrow keypad *)
  // $CA unassigned
  VirtualKeyCodes[vkLEFT] := 37;     (* LeftArrow on arrow keypad *)
  // $CC unassigned
  VirtualKeyCodes[vkRIGHT] := 39;     (* RightArrow on arrow keypad *)
  // $CE unassigned
  VirtualKeyCodes[vkEND] := 35;     (* End on arrow keypad *)
  VirtualKeyCodes[vkDOWN] := 40;     (* DownArrow on arrow keypad *)
  VirtualKeyCodes[vkPGDN] := 34;     (* PgDn on arrow keypad *)
  VirtualKeyCodes[vkINSERT] := 45;     (* Insert on arrow keypad *)
  VirtualKeyCodes[vkDELETE] := 46;     (* Delete on arrow keypad *)
  VirtualKeyCodes[vkOS_L] := 91;     (* Left Windows key *)
  VirtualKeyCodes[vkOS_R] := 92;     (* Right Windows key *)
  VirtualKeyCodes[vkAPPS] := 93;     (* AppMenu key *)
  // $E0 to $E2 unassigned
  // $E4 unassigned


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

function TCEWindowsApplication.DoCreateWindow(): Boolean;
var
  WindowStyle: Cardinal;
  ScreenX, ScreenY: Integer;
  WindowRect: CEBaseTypes.TRect;
begin
  Result := False;
  WindowStyle := WS_OVERLAPPED or WS_CAPTION or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX or WS_SYSMENU;
//  WindowStyle := WS_OVERLAPPEDWINDOW{ or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX};
  FWindowClass.style := 0;//CS_VREDRAW or CS_HREDRAW or CS_OWNDC;
  FWindowClass.lpfnWndProc := @StdWindowProc;
  FWindowClass.cbClsExtra := 0;
  FWindowClass.cbWndExtra := 0;
  FWindowClass.hIcon := LoadIcon(hInstance, 'MAINICON');
  FWindowClass.hCursor := LoadCursor(FWindowClass.hInstance*0, IDC_ARROW);
  FWindowClass.hInstance := HInstance;
  FWindowClass.hbrBackground := 0;//GetStockObject(WHITE_BRUSH);
  FWindowClass.lpszMenuName := nil;
  FWindowClassName := ClassName + '.WindowClass';
  FWindowClass.lpszClassName := PWideChar(FWindowClassName);

  Cfg['Window.Windows.ClassName'] := FWindowClassName;

  if RegisterClassW(FWindowClass) = 0 then
  begin
    Writeln('TCEWindowsApplication.DoCreateWindow: Window class registration failed');
    Exit;
  end;
  ScreenX := GetSystemMetrics(SM_CXSCREEN);
  ScreenY := GetSystemMetrics(SM_CYSCREEN);
  if ScreenX = 0 then ScreenX := 640;
  if ScreenY = 0 then ScreenY := 480;

  WindowRect := CalcWindowRect(ScreenX, ScreenY);

  FWindowHandle := Windows.CreateWindowW(FWindowClass.lpszClassName, PWideChar(FName), WindowStyle,
                                        WindowRect.Left, WindowRect.Top,
                                        WindowRect.Right - WindowRect.Left + 4, WindowRect.Bottom - WindowRect.Top + 28,
                                        0, 0, HInstance, nil);
  if FWindowHandle = 0 then
  begin
    Writeln('TCEWindowsApplication.DoCreateWindow: Window creation failed');
    Exit;
  end;
  Cfg.SetInt64(CFG_WINDOW_HANDLE, FWindowHandle);

  ShowWindow(FWindowHandle, SW_NORMAL);
  App := Self;
  Result := True;
end;

procedure TCEWindowsApplication.DoDestroyWindow;
begin
  if FWindowHandle <> 0 then DestroyWindow(FWindowHandle);
  FWindowHandle := 0;
  Cfg.Remove(CFG_WINDOW_HANDLE);
  if not UnRegisterClass(@FWindowClassName, hInstance) then
  //Log('Error unregistering window class: ' + GetOSErrorStr(GetLastError), lkError);
end;

procedure TCEWindowsApplication.Process;
var Msg: tagMSG;
begin
  if (PeekMessage(Msg, FWindowHandle, 0, 0, PM_REMOVE)) then
  begin
    repeat
      if Msg.message = WM_QUIT then Terminated := True;
      if (Msg.message = WM_KEYDOWN) or (Msg.message = WM_KEYUP) or (Msg.message = WM_SYSKEYDOWN) or (Msg.message = WM_SYSKEYUP) then
        TranslateMessage(Msg);
      DispatchMessage(Msg);
    until not PeekMessage(Msg, FWindowHandle, 0, 0, PM_REMOVE);
  end
  else if not Active then
  begin
    Sleep(INACTIVE_SLEEP_MS);
    Active := GetActiveWindow = FWindowHandle;
  end;
end;

function TCEWindowsApplication.ProcessWinMessage(Msg: UINT; wParam: WPARAM; lParam: LPARAM): Integer;
var
  CEMsg: TCEMessage;
begin
  Result := 1;
  case Msg of
    WM_CLOSE: begin
      Result := 0;
      Terminated := True;
    end;
    WM_ACTIVATEAPP: begin
      if (wParam and 65535 = WA_ACTIVE) or (wParam and 65535 = WA_CLICKACTIVE) then
        Active := True;
      if wParam and 65535 = WA_INACTIVE then
        Active := False;
    end;
  end;
  if Assigned(MessageHandler) then begin
    CEMsg := WMToMessage(Msg, wParam, lParam);
    if Assigned(CEMsg) then
      MessageHandler(CEMsg);
  end;
end;

end.


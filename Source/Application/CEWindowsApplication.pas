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
  CEBaseTypes, CEMessage, CEBaseApplication;

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

  TCEApplicationClass = TCEWindowsApplication;

  function WMToMessage(Msg: UINT; wParam: WPARAM; lParam: LPARAM): TCEMessage; overload;
  function WMToMessage(const Msg: Messages.TMessage): TCEMessage; overload;

implementation

uses
  SysUtils, CEInputMessage, CEBaseInput;

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
    WM_KEYUP:   Result := TKeyboardMsg.Create(baUp, wParam, (lParam shr 16) and $FF);
    WM_KEYDOWN, WM_SYSKEYDOWN: if lParam and CHANGED_MASK = 0 then
      Result := TKeyboardMsg.Create(baDown, wParam, (lParam shr 16) and $FF);
    WM_LBUTTONDOWN: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), baDown, mbLeft);
    WM_MBUTTONDOWN: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), baDown, mbMiddle);
    WM_RBUTTONDOWN: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), baDown, mbRight);
    WM_LBUTTONUP: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), baUp, mbLeft);
    WM_MBUTTONUP: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), baUp, mbMiddle);
    WM_RBUTTONUP: Result := TMouseButtonMsg.Create(GetX(lParam), GetY(lParam), baUp, mbRight);
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
  vkESCAPE          := 27;
  vk1               :=Ord('1');
  vk2               :=Ord('2');
  vk3               :=Ord('3');
  vk4               :=Ord('4');
  vk5               :=Ord('5');
  vk6               :=Ord('6');
  vk7               :=Ord('7');
  vk8               :=Ord('8');
  vk9               :=Ord('9');
  vk0               :=Ord('0');
  vkMINUS           :=189;    (* - on main keyboard *)
  vkEQUALS          :=187;
  vkBACK            :=8;      (* backspace *)
  vkTAB             :=9;
  vkQ               :=Ord('Q');
  vkW               :=Ord('W');
  vkE               :=Ord('E');
  vkR               :=Ord('R');
  vkT               :=Ord('T');
  vkY               :=Ord('Y');
  vkU               :=Ord('U');
  vkI               :=Ord('I');
  vkO               :=Ord('O');
  vkP               :=Ord('P');
  vkLBRACKET        :=219;
  vkRBRACKET        :=221;
  vkRETURN          :=13;     (* Enter on main keyboard *)
  vkLCONTROL        :=162;
  vkA               :=Ord('A');
  vkS               :=Ord('S');
  vkD               :=Ord('D');
  vkF               :=Ord('F');
  vkG               :=Ord('G');
  vkH               :=Ord('H');
  vkJ               :=Ord('J');
  vkK               :=Ord('K');
  vkL               :=Ord('L');
  vkSEMICOLON       :=186;
  vkAPOSTROPHE      :=222;
  vkGRAVE           :=192; (* accent grave *)
  vkLSHIFT          :=160;
  vkBACKSLASH       :=220;
  vkZ               :=Ord('Z');
  vkX               :=Ord('X');
  vkC               :=Ord('C');
  vkV               :=Ord('V');
  vkB               :=Ord('B');
  vkN               :=Ord('N');
  vkM               :=Ord('M');
  vkCOMMA           :=188;
  vkPERIOD          :=190;    (* . on main keyboard *)
  vkSLASH           :=191;    (* / on main keyboard *)
  vkRSHIFT          :=161;
  vkMULTIPLY        :=106;    (* * on numeric keypad *)
  vkLMENU           :=164;    (* left Alt *)
  vkSPACE           :=32;
  vkCAPITAL         :=20;
  vkF1              :=112;
  vkF2              :=113;
  vkF3              :=114;
  vkF4              :=115;
  vkF5              :=116;
  vkF6              :=117;
  vkF7              :=118;
  vkF8              :=119;
  vkF9              :=120;
  vkF10             :=121;
  vkNUMLOCK         :=144;
  vkSCROLL          :=145;    (* Scroll Lock *)
  vkNUMPAD7         :=36;
  vkNUMPAD8         :=38;
  vkNUMPAD9         :=33;
  vkSUBTRACT        :=109;    (* - on numeric keypad *)
  vkNUMPAD4         :=37;
  vkNUMPAD5         :=12;
  vkNUMPAD6         :=39;
  vkADD             :=107;    (* + on numeric keypad *)
  vkNUMPAD1         :=35;
  vkNUMPAD2         :=40;
  vkNUMPAD3         :=34;
  vkNUMPAD0         :=45;
  vkDECIMAL         :=46;     (* . on numeric keypad *)
  // $54 to $55 unassigned
  vkOEM_102         :=$56;    (* < > | on UK/Germany keyboards *)
  vkF11             :=122;
  vkF12             :=123;
  // $59 to $63 unassigned
  vkF13             :=$64;    (*                     (NEC PC98) *)
  vkF14             :=$65;    (*                     (NEC PC98) *)
  vkF15             :=$66;    (*                     (NEC PC98) *)
  // $67 to $6F unassigned
  // $74 to $78 unassigned
  // $7A unassigned
  // $7C unassigned
  // $7F to 8C unassigned
  vkNUMPADEQUALS    :=13;     (* :=on numeric keypad (NEC PC98) *)
  // $8E to $8F unassigned
  vkCIRCUMFLEX      :=$90;    (* (Japanese keyboard)            *)
  vkAT              :=$91;    (*                     (NEC PC98) *)
  vkCOLON           :=$92;    (*                     (NEC PC98) *)
  vkUNDERLINE       :=$93;    (*                     (NEC PC98) *)
  vkKANJI           :=$94;    (* (Japanese keyboard)            *)
  // $98 unassigned
  vkNEXTTRACK       :=$99;    (* Next Track *)
  // $9A to $9D unassigned
  vkNUMPADENTER     :=13;     (* Enter on numeric keypad *)
  vkRCONTROL        :=163;
  // $9E to $9F unassigned
  // $A5 to $AD unassigned
  // $AF unassigned
  // $B1 unassigned
  vkNUMPADCOMMA     :=$B3;    (* , on numeric keypad (NEC PC98) *)
  // $B4 unassigned
  vkDIVIDE          :=111;    (* / on numeric keypad *)
  // $B6 unassigned
  vkSYSRQ           :=$B7;
  vkRMENU           :=165;    (* right Alt *)
  // $B9 to $C4 unassigned
  vkPAUSE           :=19;     (* Pause (watch out - not realiable on some kbds) *)
  // $C6 unassigned
  vkHOME            :=36;     (* Home on arrow keypad *)
  vkUP              :=38;     (* UpArrow on arrow keypad *)
  vkPRIOR           :=33;     (* PgUp on arrow keypad *)
  // $CA unassigned
  vkLEFT            :=37;     (* LeftArrow on arrow keypad *)
  // $CC unassigned
  vkRIGHT           :=39;     (* RightArrow on arrow keypad *)
  // $CE unassigned
  vkEND             :=35;     (* End on arrow keypad *)
  vkDOWN            :=40;     (* DownArrow on arrow keypad *)
  vkNEXT            :=34;     (* PgDn on arrow keypad *)
  vkINSERT          :=45;     (* Insert on arrow keypad *)
  vkDELETE          :=46;     (* Delete on arrow keypad *)
  vkLOS             :=91;     (* Left Windows key *)
  vkROS             :=92;     (* Right Windows key *)
  vkAPPS            :=93;     (* AppMenu key *)
  // $E0 to $E2 unassigned
  // $E4 unassigned


(*
  *  Alternate names for keys, to facilitate transition from DOS.
  *)
  vkBACKSPACE      :=vkBACK;      (* backspace *)
  vkNUMPADSTAR     :=vkMULTIPLY;  (* * on numeric keypad *)
  vkLALT           :=vkLMENU;     (* left Alt *)
  vkCAPSLOCK       :=vkCAPITAL;   (* CapsLock *)
  vkNUMPADMINUS    :=vkSUBTRACT;  (* - on numeric keypad *)
  vkNUMPADPLUS     :=vkADD;       (* + on numeric keypad *)
  vkNUMPADPERIOD   :=vkDECIMAL;   (* . on numeric keypad *)
  vkNUMPADSLASH    :=vkDIVIDE;    (* / on numeric keypad *)
  vkRALT           :=vkRMENU;     (* right Alt *)
  vkUPARROW        :=vkUP;        (* UpArrow on arrow keypad *)
  vkPGUP           :=vkPRIOR;     (* PgUp on arrow keypad *)
  vkLEFTARROW      :=vkLEFT;      (* LeftArrow on arrow keypad *)
  vkRIGHTARROW     :=vkRIGHT;     (* RightArrow on arrow keypad *)
  vkDOWNARROW      :=vkDOWN;      (* DownArrow on arrow keypad *)
  vkPGDN           :=vkNEXT;      (* PgDn on arrow keypad *)

(*
  *  Alternate names for keys originally not used on US keyboards.
  *)

  vkPREVTRACK      :=vkCIRCUMFLEX;  (* Japanese keyboard *)

  vkMOUSELEFT       :=$1;
  vkMOUSERIGHT      :=$2;
  vkMOUSEMIDDLE     :=$4;

  vkSHIFT :=16;
  vkCONTROL :=17;
  vkALT :=18;

  vkMOUSEBUTTON[mbLeft]    := vkMOUSELEFT;
  vkMOUSEBUTTON[mbRight]   := vkMOUSERIGHT;
  vkMOUSEBUTTON[mbMiddle]  := vkMOUSEMIDDLE;
  vkMOUSEBUTTON[mbCustom1] := vkNONE;
end;

function TCEWindowsApplication.DoCreateWindow(): Boolean;
var
  WindowStyle: Cardinal;
  ScreenX, ScreenY: Integer;
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

  FWindowHandle := Windows.CreateWindowW(FWindowClass.lpszClassName, PWideChar(FName), WindowStyle,
                                        (ScreenX - 1024) div 2+300, (ScreenY - 1024) div 2, 1024+4, 1024+28,
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


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
  Windows,
  CEBaseApplication;

const
  // Sleep time when there is no messages in queue and application is deactived
  INACTIVE_SLEEP_MS = 60;

type
  // Windows message handling callback
  TWndProc = function (WHandle: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

  TCEWindowsApplication = class(TCEBaseApplication)
  private
    // Application window handle
    FWindowHandle: Cardinal;
    // Current window class
    WindowClass: TWndClassW;
    FWindowClassName: string;
  protected
    // Should be set to False in ProcessWinMessage() to prevent default message handler call
    FCallDefaultMsgHandler: Boolean;
    procedure DoCreateWindow(); override;
    procedure DoDestroyWindow(); override;
    // Windows message processing
    function ProcessWinMessage(Msg: Longword; wParam: Integer; lParam: Integer): Integer;
  public
    procedure Process(); override;
  end;

implementation

uses
  SysUtils, Messages;

var
  App: TCEWindowsApplication;

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

procedure TCEWindowsApplication.DoCreateWindow;
var
  WindowStyle: Cardinal;
  ScreenX, ScreenY: Integer;
begin
  WindowStyle := WS_OVERLAPPED or WS_CAPTION or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX or WS_SYSMENU;
//  WindowStyle := WS_OVERLAPPEDWINDOW{ or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX};
  WindowClass.style := 0;//CS_VREDRAW or CS_HREDRAW or CS_OWNDC;
  WindowClass.lpfnWndProc := @StdWindowProc;
  WindowClass.cbClsExtra := 0;
  WindowClass.cbWndExtra := 0;
  WindowClass.hIcon := LoadIcon(hInstance, 'MAINICON');
  WindowClass.hCursor := LoadCursor(WindowClass.hInstance*0, IDC_ARROW);
  WindowClass.hInstance := HInstance;
  WindowClass.hbrBackground := 0;//GetStockObject(WHITE_BRUSH);
  WindowClass.lpszMenuName := nil;
  FWindowClassName := ClassName + '.WindowClass';
  WindowClass.lpszClassName := PWideChar(FWindowClassName);

  Cfg['Windows.ClassName'] := FWindowClassName;

  if RegisterClassW(WindowClass) = 0 then
  begin
    Writeln('TCEWindowsApplication.DoCreateWindow: Window class registration failed');
    Exit;
  end;
  ScreenX := GetSystemMetrics(SM_CXSCREEN);
  ScreenY := GetSystemMetrics(SM_CYSCREEN);
  if ScreenX = 0 then ScreenX := 640;
  if ScreenY = 0 then ScreenY := 480;

  FWindowHandle := Windows.CreateWindowW(WindowClass.lpszClassName, PWideChar(FName), WindowStyle,
                                        (ScreenX - 1024) div 2+300, (ScreenY - 768) div 2, 1024+4, 768+28,
                                        0, 0, HInstance, nil);
  if FWindowHandle = 0 then
  begin
    Writeln('TCEWindowsApplication.DoCreateWindow: Window creation failed');
    Exit;
  end;
  Cfg.SetInt64('Windows.WindowHandle', FWindowHandle);

  ShowWindow(FWindowHandle, SW_NORMAL);
  App := Self;
end;

procedure TCEWindowsApplication.DoDestroyWindow;
begin
  if FWindowHandle <> 0 then DestroyWindow(FWindowHandle);
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
  end else if not Active then
  begin
    Sleep(INACTIVE_SLEEP_MS);
    Active := GetActiveWindow = FWindowHandle;
  end;
end;

function TCEWindowsApplication.ProcessWinMessage(Msg: Longword; wParam, lParam: Integer): Integer;
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
end;

end.


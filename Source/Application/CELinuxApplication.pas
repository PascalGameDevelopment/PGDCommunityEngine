(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CELinuxApplication.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Application for Linux)

Linux implementation of the application class

@author(Benjamin Gregg-Smith (bgreggsmith@gmail.com))
}

{$I PGDCE.inc}
unit CELinuxApplication;

interface

uses
  CEBaseApplication,
  CEMessage,
  CEInputMessage,
  CEBaseTypes,

  Gl,
  Glx,
  Glext,
  X,
  XLib,
  XUtil,
  XF86VMode;

type
  TCEX11WindowContainer = Record //Contains most of the X11 specific stuff
    X11Display: pDisplay;
    X11ScreenID: Integer;
    X11Window: TWindow;
    GLXContext: GlXContext;
    X11WindowAttributes: TXSetWindowAttributes;
    X11WindowCurrentAttributes: TXWindowAttributes;
    Fullscreen: Boolean;
    DoubleBuffered: Boolean;
    VideoModes: TXF86VidModeModeInfo;
    Width, Height, X, Y: Int64;
  end;
  TCELinuxApplication = class(TCEBaseApplication)
  private
    {Private declarations}
    Window: TCEX11WindowContainer;
    GLAttributesList: array [0..16] of Integer;
    Xev: tXEvent;
    //XNev: tXEvent;
    Xce: tXConfigureEvent;
    OriginalWindowWidth, OriginalWindowHeight: Int64;

    OverrideXF86ModeSelection: Boolean;
    Mode_FullScreen: Boolean;

    procedure GenerateAttributes_SingleBufferMode();
    procedure GenerateAttributes_DoubleBufferMode();
    procedure InitializeOpenGL();
    procedure InitializeWindow();
    function GetEvents_Core(): TCEMessage;
  protected
    {Protected declarations}

    //These are lifted from CEWindowsApplication.pas
    procedure DoCreateWindow(); override;
    procedure DoDestroyWindow(); override;
  public
    {Public declarations}
    procedure Process(); override;
  published
    {Published declarations}
  end;

implementation

procedure TCELinuxApplication.DoDestroyWindow();
begin
  //Stub
end;

procedure TCELinuxApplication.GenerateAttributes_SingleBufferMode();
begin
  GLAttributesList[0] := Glx_RGBA;
  GLAttributesList[1] := Glx_Red_Size;
  GLAttributesList[2] := 4;
  GLAttributesList[3] := Glx_Green_Size;
  GLAttributesList[4] := 4;
  GLAttributesList[5] := Glx_Blue_Size;
  GLAttributesList[6] := 4;
  GLAttributesList[7] := Glx_Depth_Size;
  GLAttributesList[8] := 16;
  GLAttributesList[9] := None;
end;

procedure TCELinuxApplication.GenerateAttributes_DoubleBufferMode();
begin
  GLAttributesList[0] := Glx_RGBA;
  GLAttributesList[1] := Glx_DoubleBuffer;
  GLAttributesList[2] := Glx_Red_Size;
  GLAttributesList[3] := 4;
  GLAttributesList[4] := Glx_Green_Size;
  GLAttributesList[5] := 4;
  GLAttributesList[6] := Glx_Blue_Size;
  GLAttributesList[7] := 4;
  GLAttributesList[8] := Glx_Depth_Size;
  GLAttributesList[9] := 16;
  GLAttributesList[10] := None;
end;

procedure TCELinuxApplication.InitializeOpenGL();
begin
  //Load up some extensions... We shall assume we do not need any by default.
  //glext_LoadExtension('GL_EXT_framebuffer_object');
  //glext_LoadExtension('GL_ARB_framebuffer_object');
  //glext_LoadExtension('GL_EXT_shader_objects');
  //glext_LoadExtension('ARB_geometry_shader4');

  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glClearColor( 0.0, 0.0, 0.0, 0.0 );
  glViewport( 0, 0, Window.Width, Window.Height );
  glClear( GL_COLOR_BUFFER_BIT );

  glMatrixMode( GL_PROJECTION );
  glLoadIdentity();

  glOrtho(0, Window.Width, Window.Height, 0, -16, 16);

  glMatrixMode( GL_MODELVIEW );
  glLoadIdentity();
end;

procedure TCELinuxApplication.InitializeWindow();
var
  VisualInfo: pXVisualInfo;
  ColourMap: TColorMap;
  DisplayWidth, DisplayHeight: Int64;
  Version_GlxMaj, Version_GlxMin: Integer;
  Version_VMMaj, Version_VMMin: Integer;
  ModeList: ppXF86VidModeModeInfo;
  VideoModeNumber, BestVideoMode: Int64;
  Atom_WmDelete: TAtom;
  DummyWindow: TWindow;
  DummyBorder: LongWord;
  c: Int64;

begin
  BestVideoMode := 0;

  Window.X11Display := XOpenDisplay('');
  Window.X11ScreenID := DefaultScreen(Window.X11Display);
  Window.Width := 1024;
  Window.Height := 600;
  XF86VidModeQueryVersion(Window.X11Display, @Version_VMMaj, @Version_VMMin);
  XF86VidModeGetAllModeLines(Window.X11Display, Window.X11ScreenID, @VideoModeNumber, @ModeList);

  Window.VideoModes := ModeList^[0];

  if OverrideXF86ModeSelection = False then
  begin
    c := 0;
    repeat
      if (ModeList[c]^.hDisplay = Window.Width) and (ModeList[c]^.vDisplay = Window.Height) then
        BestVideoMode := c;
      c += 1;
    until c >= VideoModeNumber;
  end
  else
    BestVideoMode := 0;

  GenerateAttributes_DoubleBufferMode();
  VisualInfo := GlxChooseVisual(Window.X11Display, Window.X11ScreenID, @GLAttributesList);
  if VisualInfo = Nil then
  begin
    //This means there is no double buffering available...
    //So try again for single buffered mode...
    GenerateAttributes_SingleBufferMode();
    VisualInfo := GlxChooseVisual(Window.X11Display, Window.X11ScreenID, @GLAttributesList);
    Window.DoubleBuffered := False;
  end
  else
    Window.DoubleBuffered := True;

  //GlxQueryVersion(Window.X11Display, @Version_GlxMaj, @Version_GlxMin); //This screws up for no reason...

  Window.GLXContext := GlxCreateContext(Window.X11Display, VisualInfo, Nil, True);
  ColourMap :=
  XCreateColorMap(Window.X11Display, RootWindow(Window.X11Display, VisualInfo^.Screen), VisualInfo^.Visual, AllocNone);
  Window.X11WindowAttributes.ColorMap := ColourMap;
  Window.X11WindowAttributes.Border_Pixel := 0;

  if Mode_FullScreen = True then
  begin
    Window.FullScreen := True;

    XF86VidModeSwitchToMode(Window.X11Display, Window.X11ScreenID, ModeList[BestVideoMode]);
    XF86VidModeSetViewPort(Window.X11Display, Window.X11ScreenID, 0, 0);

    DisplayWidth := ModeList[BestVideoMode]^.hDisplay;
    DisplayHeight := ModeList[BestVideoMode]^.vDisplay;

    XFree(ModeList);

    Window.X11WindowAttributes.Override_Redirect := 1; //Assuming 1 = true
    //Note: we could have customizeable masks for input... Though these have most bases covered.
    Window.X11WindowAttributes.Event_Mask :=
    ExposureMask Or KeyPressMask Or KeyReleaseMask or PointerMotionMask Or ButtonPressMask Or ButtonReleaseMask or
    StructureNotifyMask or ButtonMotionMask;
    Window.X11Window := XCreateWindow
    (Window.X11Display, RootWindow(Window.X11Display, VisualInfo^.Screen), 0, 0, DisplayWidth, DisplayHeight, 0,
    VisualInfo^.Depth, InputOutput, VisualInfo^.Visual, CWBorderPixel Or CWColorMap Or CWEventMask Or CWOverrideRedirect
    , @Window.X11WindowAttributes);
    XWarpPointer(Window.X11Display, None, Window.X11Window, 0, 0, 0, 0, 0, 0);
    XGrabKeyboard(Window.X11Display, Window.X11Window, True, GrabModeASync, GrabModeASync, CurrentTime);
  end
  else
  begin
    Window.X11WindowAttributes.Event_Mask :=
    ExposureMask Or KeyPressMask Or KeyReleaseMask or PointerMotionMask Or ButtonPressMask Or ButtonReleaseMask or
    StructureNotifyMask or ButtonMotionMask;
    Window.X11Window := XCreateWindow
    (Window.X11Display, RootWindow(Window.X11Display, VisualInfo^.Screen), 0, 0, Window.width, Window.Height, 0, VisualInfo^.Depth,
    InputOutput, VisualInfo^.Visual, CWBorderPixel Or CWColorMap Or CWEventMask Or CWOverrideRedirect,
    @Window.X11WindowAttributes);

    Atom_WmDelete := XInternAtom(Window.X11Display, 'WM_DELETE_WINDOW', True);
    XSetWMProtocols(Window.X11Display, Window.X11Window, @Atom_WmDelete, 1);
    XSetStandardProperties(Window.X11Display, Window.X11Window, PAnsiChar(Name), PAnsiChar(Name), None, Nil, 0, Nil);
    XMapRaised(Window.X11Display, Window.X11Window);
  end;

  glxMakeCurrent(Window.X11Display, Window.X11Window, Window.GlXContext);
end;

procedure TCELinuxApplication.DoCreateWindow();
begin
  {
  * A note on OverrideXF86ModeSelection:
  *   On some combinations of later X-server (from later 2013 I believe) with some mesa drivers) using XF86 for window sizes breaks.
  *   From testing in Prometheus this varies to nothing being returned, garbage being returned or the initial call to fetch available modes
  *     crashing the application. Any further info on this would be appreciated, for the time being it is turned off fo reliability.
  }
  OverrideXF86ModeSelection := True;
  Mode_FullScreen := False;

  InitializeWindow();
  InitializeOpenGL();
end;


function TCELinuxApplication.GetEvents_Core(): TCEMessage;
begin
  if XPending(Window.X11Display) <= 0 then
    Exit;
  XNextEvent(Window.X11Display, @Xev);
  case Xev._Type of
    Expose: begin
      XGetWindowAttributes(Window.X11Display, Window.X11Window, @Window.X11WindowCurrentAttributes);

      if (Window.X11WindowCurrentAttributes.Width <> Window.Width) or (Window.X11WindowCurrentAttributes.Height <> Window.Height) then
          //Check for a resize
      begin
        GetEvents_Core := TWindowResizeMsg.Create(Window.Width, Window.Height, Window.X11WindowCurrentAttributes.Width, Window.X11WindowCurrentAttributes.Height);

        Window.Width := Window.X11WindowCurrentAttributes.Width;
        Window.Height := Window.X11WindowCurrentAttributes.Height;

        glXMakeCurrent(Window.X11Display, Window.X11Window, Window.GLXContext);

        glViewport(0, 0, Window.Width, Window.Height);
        glOrtho(0, Window.Width, Window.Height, 0, -16, 16);

        //ClearCanvas(); //X11 can corrupt the current frame
      end else
        GetEvents_Core := TAppActivateMsg.Create();
    end;
    ConfigureNotify: begin
      Xce := Xev.XConfigure;
    end;
    KeyPress: begin
      glXMakeCurrent(Window.X11Display, Window.X11Window, Window.GLXContext);

      { This needs to be plugged into the event system...
        //Lets convert the X key code to a similar convention use by KeyPressed() in crt unit
        LastKeyID := XLookupKeysym(@Xev.xkey, 0);
        if LastKeyID > 65280 then
            LastKeyID := LastKeyID - 65280;
        if (LastKeyID <= 255) and (LastKeyID >= 0) then //we care about these keys more than the rest
            KeyDown[PrometheusEventData.LastKeyID] := True; //Set the status of the key pressed as down
        }
  //TODO GetEvents_Core := TKeyboardMsg.Create(baDown, wParam, (lParam shr 16) and $FF); //TKeyboardMsg not found in CEMessage
    end;
    KeyRelease: begin
      glXMakeCurrent(Window.X11Display, Window.X11Window, Window.GLXContext);

      { This needs to be plugged into the event system...
        //Lets convert the X key code to a similar convention use by KeyPressed() in crt unit
        LastKeyID := XLookupKeysym(@Xev.xkey, 0);
        if LastKeyID > 65280 then
            LastKeyID := LastKeyID - 65280;
        if (LastKeyID <= 255) and (LastKeyID >= 0) then //we care about these keys more than the rest
            KeyDown[PrometheusEventData.LastKeyID] := False; //Set the status of the key pressed as down
        }
  //TODO GetEvents_Core := TKeyboardMsg.Create(baUp, wParam, (lParam shr 16) and $FF);
    end;
    MotionNotify: //Mouse motion
    begin
      GetEvents_Core := TMouseMoveMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y));
    end;
    ButtonPress: begin
      case Xev.XButton.Button of
      1: GetEvents_Core := TMouseButtonMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y), baDown, mbLeft);
      2: GetEvents_Core := TMouseButtonMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y), baDown, mbMiddle);
      3: GetEvents_Core := TMouseButtonMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y), baDown, mbRight);
      end;
    end;
    ButtonRelease: begin
      case Xev.XButton.Button of
      1: GetEvents_Core := TMouseButtonMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y), baUp, mbLeft);
      2: GetEvents_Core := TMouseButtonMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y), baUp, mbMiddle);
      3: GetEvents_Core := TMouseButtonMsg.Create(round(Xev.XMotion.X), round(Xev.XMotion.Y), baUp, mbRight);
      end;
    end;
  end;
end;

  procedure TCELinuxApplication.Process();
  var
    FastEventBufferMode: Boolean;
  begin
    FastEventBufferMode := False;
    if XPending(Window.X11Display) > 0 then
    begin
      if FastEventBufferMode = True then
          //Work around the insane amount of events X sends for moving the mouse (virtually every pixel)
      begin
        repeat
          GetEvents_Core();
        until XPending(Window.X11Display) <= 0;
      end
      else
        GetEvents_Core();
    end
    else
    begin
      //No events, things are idle
    end;
  end;

end.

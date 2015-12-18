(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is pgdce.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Android library)

Android library implementation for integration through JNI

@author(George Bakhtadze (avagames@gmail.com))
}

{$Include PGDCE.inc}
library pgdce;

uses
  CELog, CEAndroidAssets,
  CEBaseTypes, CEMessage, CEInputMessage,
  jni, CEAndroidJNIApplication,
  DemoMain;

type
  TCEAndroidJNIApplication = class(TCEAndroidApplication)
  end;

var
  App: TCEAndroidJNIApplication;
  Demo: TDemo;

function JStringtoString(PEnv: PJNIEnv; Obj: JObject; JavaStr: JString) : PAnsiChar;
begin
  Result := (PEnv^^).GetStringUTFChars(PEnv, JavaStr, nil);
end;

procedure SendMsg(const Msg: TCEMessage);
begin
  if Assigned(App.MessageHandler) then
    App.MessageHandler(Msg);
end;

procedure Init(PEnv: PJNIEnv; Obj: JObject; AssetManager: jobject); stdcall; export;
var
  buf: AnsiString;
  AssetStream: TCEAndroidAssetInputStream;
begin
  CEAndroidAssets.InitAssetManager(PEnv, AssetManager);
  CELog.Debug('Opening test asset');
  AssetStream := TCEAndroidAssetInputStream.Create('test.xml');
  SetLength(buf, AssetStream.Size);
  CELog.Debug('Reading test asset. Size: ' + IntToStr(AssetStream.Size));
  try
    AssetStream.Read(buf, AssetStream.Size);
    CELog.Debug('Test asset read done');
    CELog.Debug('Test asset: ' + buf);
  finally
    CELog.Debug('Finally block');
    SetLength(buf, 0);
    AssetStream.Free();
  end;
end;

procedure OnSurfaceCreated(PEnv: PJNIEnv; Obj: JObject); stdcall; export;
begin
  CELog.Debug('Surface created');
  Demo := TDemo.Create(App);
end;

procedure OnSurfaceChanged(PEnv: PJNIEnv; Obj: JObject; Width, Height: jint); stdcall; export;
begin
  CELog.Debug('PGDCE resize: ' + IntToStr(Width) + 'x' + IntToStr(Height));
  SendMsg(TWindowResizeMsg.Create(0, 0, Width, Height))
end;

procedure DrawFrame(PEnv: PJNIEnv; Obj: JObject); stdcall; export;
begin
  //CELog.Debug('PGDCE frame ***');
  Demo.Process();
end;

procedure SetConfig(PEnv: PJNIEnv; Obj: JObject; Config: JString); stdcall; export;
var
  str: PAnsiChar;
begin
  str := JStringtoString(PEnv, Obj, Config);
  App.SetConfig(str);
  (PEnv^^).ReleaseStringUTFChars(PEnv, Config, str); // release memory to avoid memory leak
end;

procedure OnPause(PEnv: PJNIEnv; Obj: JObject); stdcall; export;
begin
  CELog.Debug('PGDCE pause');
  App.Active := False;
  SendMsg(TAppDeactivateMsg.Create);
end;

procedure OnResume(PEnv: PJNIEnv; Obj: JObject); stdcall; export;
begin
  CELog.Debug('PGDCE resume');
  SendMsg(TAppActivateMsg.Create);
  App.Active := True;
end;

const
  KEY_ACTION_DOWN     = 0;
  KEY_ACTION_UP       = 1;
  KEY_ACTION_MULTIPLE = 2;

  TOUCH_ACTION_DOWN         = 0;
  TOUCH_ACTION_UP           = 1;
  TOUCH_ACTION_MOVE         = 2;
  TOUCH_ACTION_CANCEL       = 3;
  TOUCH_ACTION_OUTSIDE      = 4;
  TOUCH_ACTION_POINTER_DOWN = 5;
  TOUCH_ACTION_POINTER_UP   = 6;
  TOUCH_ACTION_HOVER_MOVE   = 7;
  TOUCH_ACTION_SCROLL       = 8;
  TOUCH_ACTION_HOVER_ENTER  = 9;
  TOUCH_ACTION_HOVER_EXIT   = 10;

function OnKeyEvent(PEnv: PJNIEnv; Obj: JObject; Action, KeyCode, ScanCode: jint): jboolean; stdcall; export;
var
  Act: TInputAction;
begin
  if Action = KEY_ACTION_DOWN then
    Act := iaDown
  else if Action = KEY_ACTION_UP then
    Act := iaUp
  else Exit;
  SendMsg(TKeyboardMsg.Create(Act, KeyCode, ScanCode));
  Result := 1;
end;

function OnTouchEvent(PEnv: PJNIEnv; Obj: JObject; Action, PointerId: jint; X, Y: jfloat): jboolean; stdcall; export;
var
  Act: TInputAction;
begin
  //CELog.Debug('Touch: ' + IntToStr(Ord(Action)));
  case Action of
    TOUCH_ACTION_POINTER_DOWN: Act := iaDown;
    TOUCH_ACTION_POINTER_UP:   Act := iaUp;
    TOUCH_ACTION_MOVE:         Act := iaMotion;
    TOUCH_ACTION_DOWN:         Act := iaTouchStart;
    TOUCH_ACTION_CANCEL:       Act := iaTouchCancel;
    else Exit;
  end;
  SendMsg(TTouchMsg.Create(X, Y, Act, mbLeft, PointerId));
  Result := 1;
end;

function JNI_OnLoad(VM: PJavaVM; Obj: JObject): Integer; cdecl; export;
begin
  CELog.Debug('PGDCE library load');
  CurJavaVM := VM;
  Result := JNI_VERSION_1_6;
  App := TCEAndroidJNIApplication.Create();
end;

{procedure FreeAndNil(var Obj: TObject);
begin
  if Assigned(Obj) then
    Obj.Free();
  Obj := nil;
end;}

procedure JNI_OnUnload(VM: PJavaVM; Obj: JObject); cdecl; export;
begin
  CELog.Debug('PGDCE library OnUnload');
  {if Assigned(Core) then
    Core.Free();
  Core := nil;}
  Demo.Free();
end;

const
  JNI_PREFIX = 'Java_com_pascalgamedevelopment_ce_lib_';

exports
  //launch name 'Java_com_pascalgamedevelopment_ce_pgdce_launch';
  Init name JNI_PREFIX + 'init',
  OnSurfaceCreated name JNI_PREFIX + 'onSurfaceCreated',
  OnSurfaceChanged name JNI_PREFIX + 'onSurfaceChanged',
  DrawFrame name JNI_PREFIX + 'drawFrame',
  SetConfig name JNI_PREFIX + 'setConfig',
  OnPause name JNI_PREFIX + 'onPause',
  OnResume name JNI_PREFIX + 'onResume',
  OnKeyEvent name JNI_PREFIX + 'onKeyEvent',
  OnTouchEvent name JNI_PREFIX + 'onTouchEvent',
  JNI_OnLoad,
  JNI_OnUnload;

end.
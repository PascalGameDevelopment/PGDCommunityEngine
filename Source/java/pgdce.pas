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
  CELog, CEAndroidLog, CEMessage,
  jni, CEAndroidJNIApplication,
  demomain;

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

procedure OnSurfaceCreated(PEnv: PJNIEnv; Obj: JObject); stdcall; export;
begin
  CELog.Debug('Surface created');
  App.DoCreateWindow();
  Demo := TDemo.Create();
end;

procedure OnSurfaceChanged(PEnv: PJNIEnv; Obj: JObject; Width, Height: jint); stdcall; export;
begin
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
  OnSurfaceCreated name JNI_PREFIX + 'onSurfaceCreated',
  OnSurfaceChanged name JNI_PREFIX + 'onSurfaceChanged',
  DrawFrame name JNI_PREFIX + 'drawFrame',
  SetConfig name JNI_PREFIX + 'setConfig',
  OnPause name JNI_PREFIX + 'onPause',
  OnResume name JNI_PREFIX + 'onResume',
  JNI_OnLoad,
  JNI_OnUnload;

end.
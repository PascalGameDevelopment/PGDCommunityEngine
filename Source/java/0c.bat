rem Android library (libpgdce.so) compilation script

set SRC_DIR=../../Source
set fpcfile=pgdce.pas

set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dDEBUG -Sa
rem set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dRELESE -O3 -Sa

set fpcoptions="-Fu$SRC_DIR -Fu$SRC_DIR/Entity -Fu$SRC_DIR/Template -Fi$SRC_DIR -Fi$SRC_DIR/Template"

set fpcoptions=-Fu%SRC_DIR% -Fu%SRC_DIR%/Entity -Fu%SRC_DIR%/Template -Fu%SRC_DIR%/Application -Fu%SRC_DIR%/Renderer -Fu%SRC_DIR%/Input
set fpcoptions=%fpcoptions% -Fu%SRC_DIR%/Utilities -Fu%SRC_DIR%/../Examples/Demo -Fu%SRC_DIR%/IO
set fpcoptions=%fpcoptions% -Fi%SRC_DIR% -Fi%SRC_DIR%/Template -Fi%SRC_DIR%/Input
set fpcoptions=%fpcoptions% -Tandroid -Parm -B -FcCP1251
set fpcoptions=%fpcoptions% -FE. -FU%SRC_DIR%/../output
rem for position-independent executable (Android 5+)
rem set fpcoptions=%fpcoptions% -K-pie 
rem set fpcoptions=%fpcoptions% -Sa


rem del /Q ..\..\Output\

del /Q ce\src\main\jniLibs\armeabi\*

%fpccmd% %fpcoptions% %fpcfile%

copy libpgdce.so ce\src\main\jniLibs\armeabi\

:End
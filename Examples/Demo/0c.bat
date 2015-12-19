set SRC_DIR=../../Source
set fpcfile=demo.dpr

set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dDEBUG -Sa
rem set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dRELESAE -O3 -Sa

set fpcoptions=-Fu%SRC_DIR% -Fu%SRC_DIR%/Entity -Fu%SRC_DIR%/Template -Fu%SRC_DIR%/Application -Fu%SRC_DIR%/Renderer -Fu%SRC_DIR%/Input -Fu%SRC_DIR%/Utilities
set fpcoptions=%fpcoptions% -Fi%SRC_DIR% -Fi%SRC_DIR%/Template -Fi%SRC_DIR%/Input
set fpcoptions=%fpcoptions% -FE%SRC_DIR%/../bin -FU%SRC_DIR%/../output -B
rem set fpcoptions=%fpcoptions% -Sa

del /Q ..\..\Output\

%fpccmd% %fpcoptions% %fpcfile%

:End
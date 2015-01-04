set SRC_DIR=../../Source
set fpcfile=WinTest.dpr

set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dDEBUG -Sa
rem set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dRELESE -O3 -Sa

set fpcoptions=-Fu%SRC_DIR% -Fu%SRC_DIR%/Entity -Fu%SRC_DIR%/Template -Fu%SRC_DIR%/Application -Fi%SRC_DIR% -Fi%SRC_DIR%/Template
set fpcoptions=%fpcoptions% -FE%SRC_DIR%/../bin -FU%SRC_DIR%/../output -B
rem set fpcoptions=%fpcoptions% -Sa

del /Q ..\..\Output\

%fpccmd% %fpcoptions% %fpcfile%

:End
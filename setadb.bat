@ECHO OFF
REM ============================================================
REM  setadb - set ANDROID_SERIAL for the current CMD session
REM  https://github.com/huanfeng/setadb
REM
REM  IMPORTANT: never use SETLOCAL in this script. ENDLOCAL would
REM  discard the ANDROID_SERIAL change we are trying to make, so
REM  delayed expansion is emulated with CALL SET instead.
REM ============================================================

SET "_SETADB_VER=1.1.0"
SET "_SETADB_ARG=%~1"
REM Captured here because inside a CALLed subroutine %0 is the label, not the file.
SET "_SETADB_SELF=%~n0"

IF "%_SETADB_ARG%"=="/?" GOTO :help
IF /I "%_SETADB_ARG%"=="-h" GOTO :help
IF /I "%_SETADB_ARG%"=="--help" GOTO :help
IF /I "%_SETADB_ARG%"=="help" GOTO :help
IF /I "%_SETADB_ARG%"=="-v" GOTO :version
IF /I "%_SETADB_ARG%"=="--version" GOTO :version
IF /I "%_SETADB_ARG%"=="-s" GOTO :show
IF /I "%_SETADB_ARG%"=="--show" GOTO :show
IF /I "%_SETADB_ARG%"=="-c" GOTO :clear
IF /I "%_SETADB_ARG%"=="clear" GOTO :clear
IF /I "%_SETADB_ARG%"=="--clear" GOTO :clear

WHERE adb >NUL 2>NUL
IF ERRORLEVEL 1 (
    ECHO [setadb] Error: 'adb' was not found in PATH.
    GOTO :cleanup
)

CALL :collect_devices

IF /I "%_SETADB_ARG%"=="-l" GOTO :list_only
IF /I "%_SETADB_ARG%"=="--list" GOTO :list_only
IF /I "%_SETADB_ARG%"=="list" GOTO :list_only

IF NOT DEFINED _SETADB_ARG GOTO :interactive

REM A pure number selects a menu entry, anything else is a raw serial.
ECHO %_SETADB_ARG%| FINDSTR /R /C:"^[0-9][0-9]*$" >NUL
IF NOT ERRORLEVEL 1 GOTO :by_index
GOTO :by_serial


REM ------------------------------------------------------------
REM  Modes
REM ------------------------------------------------------------

:interactive
CALL :print_menu
SET /P "_SETADB_IN=Please select: "
IF NOT DEFINED _SETADB_IN (
    ECHO [setadb] Cancelled, nothing changed.
    GOTO :cleanup
)
SET "_SETADB_ARG=%_SETADB_IN%"
ECHO %_SETADB_ARG%| FINDSTR /R /C:"^[0-9][0-9]*$" >NUL
IF ERRORLEVEL 1 GOTO :bad_input
GOTO :by_index

:bad_input
ECHO [setadb] Invalid input: %_SETADB_ARG%
GOTO :cleanup

:list_only
CALL :print_menu
GOTO :cleanup

:by_index
IF %_SETADB_ARG% GEQ %_SETADB_IDX% GOTO :out_of_range
IF "%_SETADB_ARG%"=="0" GOTO :clear
CALL SET "_SETADB_SEL=%%_SETADB_D_%_SETADB_ARG%%%"
REM Guards against forms the lookup cannot resolve, e.g. a leading zero.
IF NOT DEFINED _SETADB_SEL GOTO :bad_index
GOTO :apply

:out_of_range
ECHO [setadb] Index out of range: %_SETADB_ARG% ^(valid: 0-%_SETADB_LAST%^)
GOTO :cleanup

:bad_index
ECHO [setadb] Invalid index: %_SETADB_ARG%
GOTO :cleanup

:by_serial
SET "_SETADB_SEL=%_SETADB_ARG%"
CALL :find_serial "%_SETADB_SEL%"
IF DEFINED _SETADB_FOUND GOTO :apply
ECHO [setadb] Warning: '%_SETADB_SEL%' is not in the device list, setting it anyway.
GOTO :apply

:clear
SET "ANDROID_SERIAL="
ECHO [setadb] ANDROID_SERIAL cleared.
CALL :warn_oneshot
GOTO :cleanup

:apply
SET "ANDROID_SERIAL=%_SETADB_SEL%"
ECHO [setadb] ANDROID_SERIAL = %_SETADB_SEL%
CALL :warn_oneshot
GOTO :cleanup

:show
IF NOT DEFINED ANDROID_SERIAL GOTO :show_unset
ECHO [setadb] ANDROID_SERIAL = %ANDROID_SERIAL%
GOTO :cleanup

:show_unset
ECHO [setadb] ANDROID_SERIAL is not set.
GOTO :cleanup

:version
ECHO setadb %_SETADB_VER%
GOTO :cleanup

:help
ECHO setadb %_SETADB_VER% - select the ADB device for the current session
ECHO.
ECHO Usage:
ECHO   setadb                 Show the device menu and select interactively
ECHO   setadb ^<index^>         Select the device by menu index directly
ECHO   setadb 0               Same as 'setadb clear'
ECHO   setadb clear^|-c        Clear ANDROID_SERIAL
ECHO   setadb ^<serial^>        Set ANDROID_SERIAL to the given serial
ECHO   setadb list^|-l         List devices without changing anything
ECHO   setadb -s              Show the current ANDROID_SERIAL
ECHO   setadb -h              Show this help
ECHO.
ECHO Notes:
ECHO   Only the current CMD session is affected. PowerShell users should
ECHO   use setadb.ps1 instead - see the README for details.
GOTO :cleanup


REM ------------------------------------------------------------
REM  Helpers
REM ------------------------------------------------------------

REM Fill _SETADB_D_n / _SETADB_T_n and set _SETADB_IDX to the entry count.
REM %_SETADB_IDX% is only expanded inside :add_device, which is re-parsed on
REM every CALL - that is what makes the counter work without SETLOCAL.
:collect_devices
SET "_SETADB_IDX=0"
CALL :add_device "Clear" ""
FOR /F "tokens=1,2" %%A IN ('adb devices 2^>NUL') DO (
    IF /I NOT "%%A"=="List" IF NOT "%%A"=="*" IF NOT "%%B"=="" CALL :add_device "%%A" "%%B"
)
SET /A _SETADB_LAST=%_SETADB_IDX%-1
GOTO :eof

:add_device
SET "_SETADB_D_%_SETADB_IDX%=%~1"
SET "_SETADB_T_%_SETADB_IDX%=%~2"
SET /A _SETADB_IDX+=1
GOTO :eof

:print_menu
ECHO ADB devices
ECHO -------------------
SET "_SETADB_I=0"
:print_loop
IF %_SETADB_I% GEQ %_SETADB_IDX% GOTO :print_done
CALL :print_item %_SETADB_I%
SET /A _SETADB_I+=1
GOTO :print_loop
:print_done
ECHO -------------------
GOTO :eof

:print_item
CALL SET "_SETADB_N=%%_SETADB_D_%~1%%"
CALL SET "_SETADB_S=%%_SETADB_T_%~1%%"
SET "_SETADB_MARK= "
IF DEFINED ANDROID_SERIAL IF "%ANDROID_SERIAL%"=="%_SETADB_N%" SET "_SETADB_MARK=*"
IF "%_SETADB_S%"=="" GOTO :print_item_plain
ECHO %_SETADB_MARK% %~1. [%_SETADB_N%] %_SETADB_S%
GOTO :eof

:print_item_plain
ECHO %_SETADB_MARK% %~1. [%_SETADB_N%]
GOTO :eof

REM Set _SETADB_FOUND when %1 matches a collected serial.
:find_serial
SET "_SETADB_FOUND="
SET "_SETADB_I=1"
:find_loop
IF %_SETADB_I% GEQ %_SETADB_IDX% GOTO :eof
CALL SET "_SETADB_N=%%_SETADB_D_%_SETADB_I%%%"
IF /I "%_SETADB_N%"=="%~1" SET "_SETADB_FOUND=1"
SET /A _SETADB_I+=1
GOTO :find_loop

REM %CMDCMDLINE% holds the command line that started this cmd.exe. A one-shot
REM cmd always carries /c - which is exactly what happens when PowerShell runs
REM setadb.bat, or when a shim spawns a fresh cmd. That process dies right
REM after us and takes ANDROID_SERIAL with it, so warn instead of failing
REM silently. Substring replacement is used rather than ECHO | FINDSTR because
REM the command line may contain characters that break a pipeline.
:warn_oneshot
IF DEFINED SETADB_QUIET GOTO :eof
REM The raw value contains quotes, which would break the IF below, so strip
REM them first. A pipeline is not an option here: it spawns a child cmd.exe
REM that has its own CMDCMDLINE, which always contains /c.
SET "_SETADB_CL=%CMDCMDLINE%"
SET _SETADB_CL=%_SETADB_CL:"=%
REM No /c: a persistent session, so the setting sticks. Nothing to warn about.
IF "%_SETADB_CL%"=="%_SETADB_CL: /c =%" GOTO :eof
REM One-shot, but launched to run some other batch file that merely CALLs us -
REM the variable is still usable for the rest of that script, so stay quiet.
REM The file name is matched with its extension: the bare stem would also hit
REM any directory that happens to contain "setadb". .cmd is checked too so a
REM Scoop shim named setadb.cmd is recognised.
CALL :cl_contains "%_SETADB_SELF%.bat"
IF DEFINED _SETADB_HIT GOTO :do_warn
CALL :cl_contains "%_SETADB_SELF%.cmd"
IF DEFINED _SETADB_HIT GOTO :do_warn
GOTO :eof

:cl_contains
SET "_SETADB_HIT="
CALL SET "_SETADB_TMP=%%_SETADB_CL:%~1=%%"
IF NOT "%_SETADB_TMP%"=="%_SETADB_CL%" SET "_SETADB_HIT=1"
GOTO :eof

:do_warn
ECHO.
ECHO [setadb] WARNING: this cmd.exe exits immediately, so the setting is lost.
ECHO          In PowerShell run setadb.ps1 instead, or install a $PROFILE
ECHO          function once via install-profile.ps1. See the README.
ECHO          Set SETADB_QUIET=1 to silence this warning.
GOTO :eof

:cleanup
FOR /F "delims==" %%V IN ('SET _SETADB_ 2^>NUL') DO SET "%%V="
GOTO :eof

@ECHO OFF

ECHO ADB devices
ECHO -------------------

SET IDX=0
CALL :show_menu_item Clear

FOR /F "tokens=1 skip=1 delims=	"  %%A IN ('adb devices') DO CALL :show_menu_item %%A

ECHO -------------------

SET /p ID=Please select:
IF "%id%"=="0" (
	SET ANDROID_SERIAL=
) ELSE IF %id% LSS %IDX% (
	FOR /f "usebackq delims== tokens=2" %%j in (`set DEVICE_%id%`) do (
 	CALL :set_device %%j
	)
) ELSE (
	ECHO No Select!
)


GOTO :eof

:show_menu_item
ECHO %IDX%. [%1]
SET DEVICE_%IDX%=%1
SET /A IDX=%IDX%+1
GOTO :eof

:set_device
 	SET ANDROID_SERIAL=%1
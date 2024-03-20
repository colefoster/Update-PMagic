:: P-Magic Updater Script PMagic v:2023-11-22
:: By Cole Foster
:: March 20, 2023
@echo off
:begin
::enables for loops
setlocal enabledelayedexpansion
echo.
echo    ...::: P-Magic Updater Script :::...		
echo              (v:2023-11-22)
echo.

echo Available removable drives:
echo.
echo #  Letter    Label
echo -----------------------------

set /a count=0
for /f "tokens=2,3 delims=," %%a in ('wmic logicaldisk where drivetype^=2 get deviceid^, volumename /format:csv ^| findstr /v "Node"') do (
    if "%%b" NEQ "" (
        set /a count+=1
        set "drive!count!=%%a"
        echo !count!.  %%a         %%b
    )
)
:driveSelection
echo.
set /p userInput="Enter the drive number or letter (e.g., '1' or 'D'): "
if "!userInput!"=="" (
    echo Empty selection, please try again.
    goto driveSelection
)
:: Check if input is numeric and map it to a drive letter
set /a num=0
set /a num=!userInput! 2>nul
if "!num!" NEQ "0" (
    if defined drive!num! (
        rem The corrected syntax to retrieve the drive letter mapped to the number
        set drive=!drive%num%!
    ) else (
        echo Invalid Drive Selection - No Drive !num!, please try again.
        goto driveSelection
    )
) else (
    :: User entered a letter drive
    set drive=!userInput!:
)

:: Verify the drive exists
if not exist !drive!\ (
    echo Drive !drive! does not exist, please try again.
    goto driveSelection
)
echo.
echo Selected drive: '!drive!'
echo.

set /p label="Enter a new label for the drive (Empty for MAGIC X): " 
if "%label%"=="" set label=MAGIC-X

:formatConfirmation
echo.
set /p confirm="Confirm formatting drive %drive% and set its label to '%label%'? (Enter to Continue) "
::Add optional skip for troubleshooting
if /i "%confirm%"=="skip" (
	echo Skipping formatting...
	goto copyFiles
)

:: Check if the drive size is greater than 32GB using PowerShell
for /f "tokens=*" %%s in ('powershell -Command "(Get-PSDrive -Name '%drive%').Used -gt 34359738368"') do set greaterThan32GB=%%s

if "%greaterThan32GB%"=="True" (
    echo The selected drive is larger than 32GB. FAT32 format is not recommended for drives larger than 32GB.
    set /p confirmExFAT="Do you want to format this drive to exFAT? (Y/N): "
    if /i "%confirmExFAT%"=="y" (
        if "%label%"=="" (
            format %drive% /fs:exFAT /q /y
        ) else (
            format %drive% /fs:exFAT /q /y /v:%label%
        )
    ) else (
        goto driveSelection
    )
) else (
    if "%label%"=="" (
        format %drive% /fs:FAT32 /q /y
    ) else (
        format %drive% /fs:FAT32 /q /y /v:%label%
    )
)



echo Format complete...
echo.

:copyFiles 
set /p confirmCopy="Confirm copying Update PMagic files to %drive% ('%label%')? (Enter to Continue) "
echo.
echo Copying New PMagic files to %drive%...

::set sourceDir to relative folder containing pmagic
set sourceDir=%~dp0updated-pmagic\

::Check if the folder exists
IF EXIST "%sourceDir%" (
    robocopy %sourceDir% %drive% /MT:4 /E /R:2 /W:1
    echo File Copy Completed.
	echo.
	echo Drive can now be removed.
	pause
) 
if not exist "%sourceDir%" (
    echo ERROR: The source directory does not exist. Please check the .bat's local directory to ensure PMagic files exist.
	goto exit
)

echo.


set /p restart="Do you want to format another drive? (Y/N): "


if /i "%restart%"=="y" (
    echo Restarting...
	cls
    goto begin
) else (
    goto exit
)

:exit
echo Exiting...
endlocal
pause

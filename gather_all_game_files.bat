@echo off
setlocal enabledelayedexpansion

REM === CONFIG ===
set SOURCE_ROOT=%cd%
set TARGET_ROOT=%cd%\..\_gml_export_temp

echo.
echo Exporting all .gml files...
echo Source: %SOURCE_ROOT%
echo Target: %TARGET_ROOT%
echo.

REM === Clean target directory ===
if exist "%TARGET_ROOT%" (
    echo Removing old export folder...
    rmdir /s /q "%TARGET_ROOT%"
)

mkdir "%TARGET_ROOT%"

REM === Copy while preserving folder structure ===
for /r %%f in (*.gml) do (
    set "FULLPATH=%%f"
    set "RELPATH=!FULLPATH:%SOURCE_ROOT%\=!"
    set "DESTPATH=%TARGET_ROOT%\!RELPATH!"
    
    REM Create destination folder
    for %%d in ("!DESTPATH!") do (
        if not exist "%%~dpd" mkdir "%%~dpd"
    )

    copy "%%f" "!DESTPATH!" >nul
)

echo.
echo Export complete.
echo.
pause
@echo off
set "NumMon=%1"
set "GPUFN=%2"
set "AppPath=%3"

echo Setting up Virtual Display Driver...

if not exist "%AppPath%" (
    echo Installation path "%AppPath%" does not exist. Creating it...
    mkdir "%AppPath%" 2>nul
    if not exist "%AppPath%" (
        echo Error: Failed to create installation path "%AppPath%".
        exit /b 1
    )
    echo Created installation path successfully.
)

cd /d "%AppPath%"

echo Creating subdirectories if needed...
if not exist "%AppPath%\scripts\onoff_at_loginout" (
    mkdir "%AppPath%\scripts\onoff_at_loginout" 2>nul
)

echo Running configuration script...
:: Handle paths with spaces properly for PowerShell arguments
:: Jocke's fix approach - ensuring all parameters are properly quoted
powershell -ExecutionPolicy Bypass -File "fixxml.ps1" "%NumMon%" "%GPUFN%" "\"%AppPath%\""
if errorlevel 1 (
    echo Error: Configuration script failed.
    exit /b 1
)

echo Removing any existing device nodes...
nefconw.exe --remove-device-node --hardware-id Root\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318

echo Creating device node...
nefconw.exe --create-device-node --hardware-id Root\MttVDD --class-name Display --class-guid 4D36E968-E325-11CE-BFC1-08002BE10318
if errorlevel 1 (
    echo Error: Failed to create device node.
    exit /b 1
)

echo Installing driver...
if not exist "%AppPath%\MttVDD.inf" (
    echo Error: Driver INF file not found.
    exit /b 1
)

:: Jocke's fix for paths with spaces - using double quotes to encapsulate the path
nefconw.exe --install-driver --inf-path "\"%AppPath%\MttVDD.inf\""
if errorlevel 1 (
    echo Error: Driver installation failed.
    exit /b 1
)

echo Installation completed successfully.
exit /b 0

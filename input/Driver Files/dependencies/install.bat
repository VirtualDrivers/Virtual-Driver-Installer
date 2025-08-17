::@echo off
set "AppPath=%3"
cd /d "%AppPath%"
powershell -ExecutionPolicy Bypass -File "fixxml.ps1" %1 %2 %3

:: Check for and remove any existing Virtual Display Driver devices
echo Checking for existing Virtual Display Driver devices...
"C:\VirtualDisplayDriver\EDID\nefconw.exe" --remove-device-node --hardware-id Root\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318 >nul 2>&1

:: Also check for any other VDD-related devices that might exist
"C:\VirtualDisplayDriver\EDID\nefconw.exe" --remove-device-node --hardware-id ROOT\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318 >nul 2>&1

:: Wait a moment for device removal to complete
timeout /t 2 /nobreak >nul

:: installing new VD-driver
echo Installing Virtual Display Driver...
"C:\VirtualDisplayDriver\EDID\nefconw.exe" --create-device-node --hardware-id Root\MttVDD --class-name Display --class-guid 4D36E968-E325-11CE-BFC1-08002BE10318
if %errorlevel% neq 0 (
    echo Failed to create device node. Error level: %errorlevel%
    exit /b %errorlevel%
)

:: encapsulate that posible space in custum folder
"C:\VirtualDisplayDriver\EDID\nefconw.exe" --install-driver --inf-path "\"C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf\"" 
if %errorlevel% neq 0 (
    echo Failed to install driver. Error level: %errorlevel%
    exit /b %errorlevel%
)

echo Virtual Display Driver installation completed successfully.
exit

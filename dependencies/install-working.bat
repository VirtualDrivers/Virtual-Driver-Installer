@echo off
echo =============================================
echo Virtual Display Driver Installation
echo Using proven working method
echo =============================================

set "DEVCON=C:\VirtualDisplayDriver\Driver Files\dependencies\devcon.exe"
set "DRIVERINF=C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

echo Cleaning up existing devices...
"%DEVCON%" remove "Root\MttVDD" >nul 2>&1
"%DEVCON%" remove "MttVDD" >nul 2>&1
timeout /t 2 /nobreak >nul

echo Installing driver to store...
pnputil /add-driver "%DRIVERINF%" /install

echo.
echo Installing Virtual Display Driver device...
"%DEVCON%" install "%DRIVERINF%" "Root\MttVDD"
echo Exit code: %errorlevel%

if %errorlevel% equ 0 (
    echo SUCCESS: Virtual Display Driver installed successfully!
) else (
    echo ERROR: Installation failed with exit code %errorlevel%
    exit /b %errorlevel%
)

echo.
echo Verification:
"%DEVCON%" find "Root\MttVDD"
"%DEVCON%" find "*Virtual*"

echo.
echo PowerShell verification:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') } | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize"

echo.
echo Virtual Display Driver installation completed successfully!
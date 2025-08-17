@echo off
echo =============================================
echo Test 3: devcon install with MttVDD hardware ID
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
echo Testing: devcon install with MttVDD (no Root prefix)
"%DEVCON%" install "%DRIVERINF%" "MttVDD"
echo Exit code: %errorlevel%

echo.
echo Verification:
"%DEVCON%" find "MttVDD"
"%DEVCON%" find "*Virtual*"

echo.
echo PowerShell verification:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') } | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize"

pause
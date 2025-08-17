@echo off
echo =============================================
echo Test 6: pnputil only (no device creation)
echo =============================================

set "DRIVERINF=C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

echo Cleaning up existing devices...
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') } | Remove-PnpDevice -Confirm:$false" >nul 2>&1
timeout /t 2 /nobreak >nul

echo.
echo Testing: pnputil add-driver with /install
pnputil /add-driver "%DRIVERINF%" /install
echo Exit code: %errorlevel%

echo.
echo Testing: pnputil add-driver with /install /force
pnputil /add-driver "%DRIVERINF%" /install /force
echo Exit code: %errorlevel%

echo.
echo Checking driver store:
pnputil /enum-drivers | findstr /i "MttVDD"

echo.
echo Waiting for Windows to auto-detect device...
timeout /t 5 /nobreak >nul

echo.
echo Triggering hardware scan:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | ForEach-Object { try { $_.GetDeviceNode().RescanHardware() } catch { } }"

timeout /t 3 /nobreak >nul

echo.
echo Verification:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') } | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize"

pause
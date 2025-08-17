@echo off
echo =============================================
echo Test 5: nefconw with Display adapters class
echo =============================================

set "NEFCONW=C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"
set "DRIVERINF=C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

echo Cleaning up existing devices...
"%NEFCONW%" --remove-device-node --hardware-id Root\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318 >nul 2>&1
"%NEFCONW%" --remove-device-node --hardware-id MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318 >nul 2>&1
timeout /t 2 /nobreak >nul

echo Installing driver to store...
pnputil /add-driver "%DRIVERINF%" /install

echo.
echo Testing: nefconw create device node with Display adapters class name
"%NEFCONW%" --create-device-node --hardware-id Root\MttVDD --class-name "Display adapters" --class-guid 4D36E968-E325-11CE-BFC1-08002BE10318
echo Exit code: %errorlevel%

timeout /t 3 /nobreak >nul

echo.
echo Testing: nefconw install driver
"%NEFCONW%" --install-driver --inf-path "%DRIVERINF%"
echo Exit code: %errorlevel%

echo.
echo Verification:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice -Class Display | Where-Object { $_.InstanceId -like '*ROOT*' -or $_.InstanceId -like '*MttVDD*' } | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize"

pause
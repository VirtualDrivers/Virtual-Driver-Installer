@echo off
echo =============================================
echo Test 9: Minimal devcon test (just like manual)
echo =============================================

set "DEVCON=C:\VirtualDisplayDriver\Driver Files\dependencies\devcon.exe"
set "DRIVERINF=C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

echo This test tries to mimic exactly what manual installation does:
echo Add Legacy Hardware -^> Display adapters -^> Have Disk

echo.
echo Step 1: Clean slate
"%DEVCON%" remove "Root\MttVDD" >nul 2>&1
"%DEVCON%" remove "MttVDD" >nul 2>&1
"%DEVCON%" remove "@ROOT\DISPLAY\*" >nul 2>&1
timeout /t 3 /nobreak >nul

echo.
echo Step 2: Install driver package (like "Have Disk" does)
pnputil /add-driver "%DRIVERINF%" /install
echo Driver store result: %errorlevel%

echo.
echo Step 3: Simple devcon install (closest to manual process)
"%DEVCON%" install "%DRIVERINF%" "Root\MttVDD"
echo Devcon install result: %errorlevel%

echo.
echo Step 4: Hardware rescan (like F5 in Device Manager)
"%DEVCON%" rescan
echo Rescan result: %errorlevel%

timeout /t 5 /nobreak >nul

echo.
echo Step 5: Check results
echo Looking for ROOT\DISPLAY devices (expected from manual):
"%DEVCON%" find "ROOT\DISPLAY\*"

echo.
echo Looking for Virtual Display devices:
"%DEVCON%" find "*Virtual*"

echo.
echo Looking for MTT1337 monitor devices:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { $_.HardwareID -like '*MTT1337*' } | Format-Table FriendlyName, Status, InstanceId, HardwareID -AutoSize"

echo.
echo All Display class devices:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice -Class Display | Format-Table FriendlyName, Status, InstanceId -AutoSize"

pause
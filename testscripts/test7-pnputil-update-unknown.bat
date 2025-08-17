@echo off
echo =============================================
echo Test 7: Create unknown device then use pnputil update
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
echo Step 1: Create device node (may show as unknown)
"%DEVCON%" install "%DRIVERINF%" "Root\MttVDD"
echo Device creation exit code: %errorlevel%

timeout /t 3 /nobreak >nul

echo.
echo Step 2: Find unknown devices and try to update their drivers
powershell -ExecutionPolicy Bypass -Command "$unknownDevices = Get-PnpDevice | Where-Object { $_.FriendlyName -like '*Unknown*' -and $_.InstanceId -like 'ROOT\*' }; if ($unknownDevices) { Write-Host 'Found unknown devices:'; $unknownDevices | Format-Table InstanceId, Status; foreach ($device in $unknownDevices) { Write-Host \"Trying to update driver for: $($device.InstanceId)\"; try { pnputil /update-driver \"%DRIVERINF%\" $($device.InstanceId) } catch { Write-Host \"Failed: $($_.Exception.Message)\" } } } else { Write-Host 'No unknown devices found' }"

echo.
echo Step 3: Try direct pnputil update with hardware ID
pnputil /update-driver "%DRIVERINF%" Root\MttVDD
echo pnputil update exit code: %errorlevel%

echo.
echo Final verification:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') } | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize"

pause
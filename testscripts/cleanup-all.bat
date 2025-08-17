@echo off
echo =============================================
echo Cleanup Script - Remove All VDD Devices
echo =============================================

set "DEVCON=C:\VirtualDisplayDriver\Driver Files\dependencies\devcon.exe"
set "NEFCONW=C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"

echo Stopping any VDD processes...
taskkill /F /IM VDDSysTray.exe >nul 2>&1
taskkill /F /IM vdd_e-li_d-lo.cmd >nul 2>&1
taskkill /F /IM "Virtual Driver Control.exe" >nul 2>&1

echo.
echo Removing devices with devcon...
if exist "%DEVCON%" (
    "%DEVCON%" remove "Root\MttVDD"
    "%DEVCON%" remove "MttVDD"
    "%DEVCON%" remove "@ROOT\DISPLAY\*"
    "%DEVCON%" remove "*Virtual*"
) else (
    echo devcon.exe not found
)

echo.
echo Removing devices with nefconw...
if exist "%NEFCONW%" (
    "%NEFCONW%" --remove-device-node --hardware-id Root\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
    "%NEFCONW%" --remove-device-node --hardware-id MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
) else (
    echo nefconw.exe not found
)

echo.
echo Removing devices with PowerShell...
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual Display*') -or ($_.HardwareID -like '*MTT1337*') } | Remove-PnpDevice -Confirm:$false"

echo.
echo Final verification - remaining devices:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') -or ($_.HardwareID -like '*MTT1337*') } | Format-Table FriendlyName, Status, InstanceId -AutoSize"

echo.
echo Cleanup completed. All VDD-related devices should be removed.
pause
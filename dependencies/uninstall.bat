@echo off
set "flag=false"

for %%I in (%*) do (
    if "%%I" == "-installer" set "flag=true"
)

if "%flag%"=="true" (
    echo ================================================
    echo Virtual Display Driver Uninstallation
    echo Using devcon.exe for device removal
    echo ================================================
    
    :: Set paths for devcon
    set "DEVCON=C:\VirtualDisplayDriver\Driver Files\dependencies\devcon.exe"
    
    :: Check if devcon exists
    if not exist "%DEVCON%" (
        echo WARNING: devcon.exe not found at %DEVCON%
        echo Attempting alternative removal method...
        goto :alternative_removal
    )
    
    echo Using devcon: %DEVCON%
    
    :: Kill any running VDD processes first
    echo Stopping Virtual Display Driver processes...
    taskkill /F /IM VDDSysTray.exe >nul 2>&1
    taskkill /F /IM vdd_e-li_d-lo.cmd >nul 2>&1
    taskkill /F /IM "Virtual Driver Control.exe" >nul 2>&1
    
    :: Remove Virtual Display Driver devices using devcon
    echo Removing Virtual Display Driver devices...
    "%DEVCON%" remove "Root\MttVDD"
    "%DEVCON%" remove "MttVDD"
    
    :: Also try to remove any instances that might exist
    "%DEVCON%" remove "@ROOT\MTTVDD\*"
    
    echo Virtual Display Driver devices removed.
    goto :cleanup
    
    :alternative_removal
    echo Using alternative removal method...
    
    :: Kill processes
    taskkill /F /IM VDDSysTray.exe >nul 2>&1
    taskkill /F /IM vdd_e-li_d-lo.cmd >nul 2>&1
    taskkill /F /IM "Virtual Driver Control.exe" >nul 2>&1
    
    :: Try using PowerShell to remove devices
    powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual Display*') } | Remove-PnpDevice -Confirm:$false"
    
    :cleanup
    :: Clean up temporary installer files
    echo Cleaning up temporary files...
    rmdir /s /q "%USERPROFILE%\AppData\Local\VDDInstaller" >nul 2>&1
    
    :: Final verification
    echo.
    echo Verifying removal...
    if exist "%DEVCON%" (
        "%DEVCON%" find "Root\MttVDD"
        "%DEVCON%" find "MttVDD"
    ) else (
        powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual Display*') } | Format-Table FriendlyName, Status, InstanceId -AutoSize"
    )
    
    echo.
    echo ================================================
    echo Virtual Display Driver uninstall completed.
    echo ================================================
    
) else (
    start "" "unins000.exe"
)

exit

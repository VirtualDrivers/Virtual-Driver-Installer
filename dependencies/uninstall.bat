@echo off
set "flag=false"

for %%I in (%*) do (
    if "%%I" == "-installer" set "flag=true"
)

if "%flag%"=="true" (
    set "regPath=HKLM\SOFTWARE\MikeTheTech\VirtualDisplayDriver"
    set "valueName=VDDPATH"
    set "defaultPath=C:\VirtualDisplayDriver"

    for /f "tokens=2* delims=    " %%A in ('reg query "%regPath%" /v "%valueName%" 2^>nul') do (
        set "vddPath=%%B"
    )
    
    if defined vddPath (
        echo Using installation path from registry: "%vddPath%"
    ) else (
        echo Registry key not found, using default path: "%defaultPath%"
        set "vddPath=%defaultPath%"
    )
    
    set "nefconwPath=%vddPath%\nefconw.exe"
    
    if exist "%nefconwPath%" (
        echo Removing device node...
        :: Handle paths with spaces - similar to Jocke's fix in install.bat
        "%nefconwPath%" --remove-device-node --hardware-id ROOT\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
    ) else (
        echo Warning: nefconw.exe not found at "%nefconwPath%"
    )
    
    echo Stopping related processes...
    tasklist /FI "IMAGENAME eq VDDSysTray.exe" | find "VDDSysTray.exe" >nul
    if not errorlevel 1 (
        taskkill /F /IM VDDSysTray.exe
    )
    
    tasklist /FI "IMAGENAME eq vdd_e-li_d-lo.cmd" | find "vdd_e-li_d-lo.cmd" >nul
    if not errorlevel 1 (
        taskkill /F /IM vdd_e-li_d-lo.cmd
    )
    
    if exist "%vddPath%" (
        echo Removing installation directory...
        rmdir /s /q "%vddPath%"
    )
    
    echo Removing registry entries...
    reg delete "HKLM\SOFTWARE\MikeTheTech\VirtualDisplayDriver" /f >nul 2>&1
    
    echo Cleaning up local app data...
    if exist "%USERPROFILE%\AppData\Local\VDDInstaller" (
        rmdir /s /q "%USERPROFILE%\AppData\Local\VDDInstaller"
    )
    
    echo Uninstallation complete.
) else (
    start "" "unins000.exe"
)

exit

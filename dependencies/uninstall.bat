@echo off
set "flag=false"

for %%I in (%*) do (
    if "%%I" == "-installer" set "flag=true"
)

if "%flag%"=="true" (
    set "regPath=HKLM\SOFTWARE\MikeTheTech\VirtualDisplayDriver"
    set "valueName=VDDPATH"

    for /f "tokens=2* delims=    " %%A in ('reg query "%regPath%" /v "%valueName%" 2^>nul') do (
        set "vddPath=%%B"
    )
    if defined vddPath (
        set "nefconwPath=%vddPath%\nefconw.exe"
        "%nefconwPath%" --remove-device-node --hardware-id ROOT\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
        taskkill /F /IM VDDSysTray.exe
        taskkill /F /IM vdd_e-li_d-lo.cmd
        rmdir /s /q "%vddPath%"
    ) else (
        C:\VirtualDisplayDriver\nefconw.exe --remove-device-node --hardware-id ROOT\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
        taskkill /F /IM VDDSysTray.exe
        taskkill /F /IM vdd_e-li_d-lo.cmd
        rmdir /s /q "C:\VirtualDisplayDriver"
    )
    reg delete "HKLM\SOFTWARE\MikeTheTech\VirtualDisplayDriver" /f >nul 2>&1
    rm dir /s /q "%USERPROFILE%\AppData\Local\VDDInstaller"
) else (
    start "" "unins000.exe"
)

exit

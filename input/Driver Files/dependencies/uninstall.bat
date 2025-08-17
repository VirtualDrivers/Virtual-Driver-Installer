@echo off
set "flag=false"

for %%I in (%*) do (
    if "%%I" == "-installer" set "flag=true"
)

if "%flag%"=="true" (
    "C:\VirtualDisplayDriver\EDID\nefconw.exe" --remove-device-node --hardware-id ROOT\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
    taskkill /F /IM VDDSysTray.exe
    taskkill /F /IM vdd_e-li_d-lo.cmd
    rmdir /s /q "%USERPROFILE%\AppData\Local\VDDInstaller"
) else (
    start "" "unins000.exe"
)

exit

::@echo off
set "AppPath=%3"
cd /d "%AppPath%"
powershell -ExecutionPolicy Bypass -File "fixxml.ps1" %1 %2 %3
:: installing VD-driver
nefconw.exe --remove-device-node --hardware-id Root\MttVDD --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
nefconw.exe --create-device-node --hardware-id Root\MttVDD --class-name Display --class-guid 4D36E968-E325-11CE-BFC1-08002BE10318
nefconw.exe --install-driver --inf-path "%AppPath%\MttVDD.inf"
exit

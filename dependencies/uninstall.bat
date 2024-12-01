::@echo off
IF "%1"=="uninstall" (
    rem Run uninstall commands
    C:\VirtualDisplayDriver\nefconw.exe --remove-device-node --hardware-id ROOT\iddsampledriver --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
)

IF "%1"=="" (
    echo Missing argument! Valid arguments are "install" or "uninstall".
)
exit

@echo off
:: Ensure we're in the correct directory
cd "%USERPROFILE%\AppData\Local\VDDInstaller"

:: Delete any existing gpulist.txt
del gpulist.txt 2>nul

:: Create a new gpulist.txt
powershell -Command "Get-WmiObject Win32_VideoController | Where-Object { $_.AdapterRAM -gt 0 } | ForEach-Object { $_.Name } > '%USERPROFILE%\AppData\Local\VDDInstaller\gpulist.txt'"

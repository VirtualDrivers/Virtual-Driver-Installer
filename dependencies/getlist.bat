@echo off
:: Ensure we're in the correct directory
cd "%USERPROFILE%\AppData\Local\VDDInstaller"

:: Delete any existing gpulist.txt
del gpulist.txt 2>nul

:: Run lfn.exe and create gpulist.txt
lfn.exe > gpulist.txt

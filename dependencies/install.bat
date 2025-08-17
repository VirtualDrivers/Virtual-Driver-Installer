::@echo off
echo ================================================
echo Virtual Display Driver Installation
echo Using the exact working test script
echo ================================================

:: The Setup.iss calls this script from the dependencies working directory
:: So we're already in C:\VirtualDisplayDriver\Driver Files\dependencies

:: First run the XML configuration
echo Step 1: Configuring XML settings...
:: Parameters: %1=NumMon %2=GPUFN %3=InstallDir, but Setup.iss passes no parameters
:: We'll use default values or read from a config file if needed
powershell -ExecutionPolicy Bypass -File "fixxml.ps1" 1 "Default GPU" "C:\VirtualDisplayDriver"

echo.
echo Step 2: Running the proven working installation script...

:: Check if the working script exists
if not exist "install-working.bat" (
    echo ERROR: install-working.bat not found in current directory
    echo Current directory: %CD%
    echo Installation cannot continue.
    exit /b 1
)

:: Run the exact script that we know works
call "install-working.bat"

:: Check the result
if %errorlevel% equ 0 (
    echo.
    echo ================================================
    echo Virtual Display Driver installation completed successfully!
    echo The proven working method was used.
    echo Please check Device Manager under Display Adapters.
    echo ================================================
) else (
    echo.
    echo ================================================
    echo Installation failed with error code: %errorlevel%
    echo Even the proven working script failed.
    echo This suggests an environment or file location issue.
    echo ================================================
    exit /b %errorlevel%
)

exit

Virtual Display Driver Test Scripts
====================================

These scripts test different methods of installing the Virtual Display Driver
to determine which approach actually works vs. showing "Unknown Device".

PREREQUISITES:
- Run all scripts as Administrator
- Ensure VirtualDisplayDriver is installed at C:\VirtualDisplayDriver\
- All scripts expect devcon.exe, nefconw.exe, and MttVDD.inf to be in place

TEST SCRIPTS:

test1-devcon-install.bat
    Tests standard "devcon install" with Root\MttVDD hardware ID
    
test2-devcon-classinstall.bat
    Tests "devcon classinstall Display" to force Display adapter class
    
test3-devcon-alternative-hwid.bat
    Tests devcon install with "MttVDD" hardware ID (no Root prefix)
    
test4-nefconw-basic.bat
    Tests nefconw device creation + driver installation
    
test5-nefconw-display-class.bat
    Tests nefconw with explicit "Display adapters" class name
    
test6-pnputil-only.bat
    Tests just adding driver to store and waiting for auto-detection
    
test7-pnputil-update-unknown.bat
    Creates device then uses pnputil to update unknown devices
    
test8-powershell-native.bat
    Tests Windows 10/11 native PowerShell device management cmdlets
    
test9-minimal-devcon.bat
    Minimal test that closely mimics the manual Device Manager process

cleanup-all.bat
    Removes all VDD-related devices between tests

TESTING PROCEDURE:
1. Run cleanup-all.bat
2. Run each test script one by one
3. Check Device Manager after each test
4. Note which methods work vs. show "Unknown Device"
5. Run cleanup-all.bat between tests

EXPECTED SUCCESSFUL RESULTS:
- Device appears under "Display adapters" in Device Manager
- Device instance path: ROOT\DISPLAY\0001
- Virtual monitor with hardware ID: MONITOR\MTT1337
- Device status: Working properly (no yellow warning icons)

Compare the results of these automated tests with your successful manual
"Add Legacy Hardware" -> "Display adapters" -> "Have Disk" process to
identify what's different.
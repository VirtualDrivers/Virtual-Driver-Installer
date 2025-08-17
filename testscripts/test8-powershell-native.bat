@echo off
echo =============================================
echo Test 8: PowerShell native device management
echo =============================================

set "DRIVERINF=C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

echo Installing driver to store...
pnputil /add-driver "%DRIVERINF%" /install

echo.
echo Testing: PowerShell New-PnpDevice (if available)
powershell -ExecutionPolicy Bypass -Command "if (Get-Command 'New-PnpDevice' -ErrorAction SilentlyContinue) { Write-Host 'New-PnpDevice is available, attempting device creation...'; try { New-PnpDevice -Class 'Display' -HardwareId 'Root\MttVDD'; Write-Host 'Device creation successful' } catch { Write-Host \"Device creation failed: $($_.Exception.Message)\" } } else { Write-Host 'New-PnpDevice cmdlet not available on this system' }"

timeout /t 3 /nobreak >nul

echo.
echo Testing: PowerShell Add-PnpDevice (if available)
powershell -ExecutionPolicy Bypass -Command "if (Get-Command 'Add-PnpDevice' -ErrorAction SilentlyContinue) { Write-Host 'Add-PnpDevice is available, attempting device creation...'; try { Add-PnpDevice -HardwareId 'Root\MttVDD' -Class 'Display'; Write-Host 'Device creation successful' } catch { Write-Host \"Device creation failed: $($_.Exception.Message)\" } } else { Write-Host 'Add-PnpDevice cmdlet not available on this system' }"

timeout /t 3 /nobreak >nul

echo.
echo Verification:
powershell -ExecutionPolicy Bypass -Command "Get-PnpDevice | Where-Object { ($_.InstanceId -like '*MttVDD*') -or ($_.FriendlyName -like '*Virtual*') } | Format-Table FriendlyName, Status, Class, InstanceId -AutoSize"

pause
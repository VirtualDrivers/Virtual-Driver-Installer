# Device Manager Style Virtual Display Driver Installation
# Mimics the manual Device Manager installation process

Write-Host "=== Device Manager Style VDD Installation ===" -ForegroundColor Green
Write-Host "This method mimics the manual Device Manager installation process" -ForegroundColor Yellow

$driverPath = "C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

# Function to test if we're admin
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: Must run as Administrator" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $driverPath)) {
    Write-Host "ERROR: Driver INF not found at $driverPath" -ForegroundColor Red
    exit 1
}

Write-Host "Driver INF: $driverPath" -ForegroundColor Cyan

# Step 1: Install driver package to driver store (like Device Manager does first)
Write-Host "`nStep 1: Pre-installing driver package to Windows Driver Store..." -ForegroundColor Cyan
Write-Host "This is what Device Manager does before creating the device..." -ForegroundColor Yellow

try {
    # Install to driver store without creating device (Device Manager approach)
    $installResult = pnputil /add-driver $driverPath /install
    Write-Host "Driver store installation result: $installResult" -ForegroundColor Gray
    
    # Verify it's in the store
    $storeCheck = pnputil /enum-drivers | Select-String -Pattern "MttVDD"
    if ($storeCheck) {
        Write-Host "✓ Driver confirmed in Windows Driver Store" -ForegroundColor Green
    } else {
        Write-Host "⚠ Driver may not be properly in Driver Store" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Driver store installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 3

# Step 2: Create a "legacy" device that Windows will automatically try to match
Write-Host "`nStep 2: Creating legacy device for automatic driver matching..." -ForegroundColor Cyan
Write-Host "This mimics 'Add legacy hardware' from Device Manager" -ForegroundColor Yellow

try {
    # Method 1: Use PowerShell to create a device that Windows will try to match automatically
    # This is closer to what Device Manager does when you "Add legacy hardware"
    
    $newDeviceParams = @{
        Class = "Display"
        HardwareId = "Root\MttVDD"
    }
    
    # Try using New-PnpDevice if available (Windows 10/11)
    if (Get-Command "New-PnpDevice" -ErrorAction SilentlyContinue) {
        Write-Host "Using New-PnpDevice cmdlet (Windows 10/11 method)..." -ForegroundColor Yellow
        try {
            New-PnpDevice @newDeviceParams
            Write-Host "✓ Device created using New-PnpDevice" -ForegroundColor Green
        } catch {
            Write-Host "New-PnpDevice failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "New-PnpDevice not available, using alternative method..." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "PowerShell device creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 3: Wait for Windows PnP manager to enumerate and try to match the driver
Write-Host "`nStep 3: Waiting for Windows PnP enumeration..." -ForegroundColor Cyan
Write-Host "Allowing Windows time to automatically match the driver..." -ForegroundColor Yellow

Start-Sleep -Seconds 5

# Step 4: Force Windows to rescan for hardware changes (like F5 in Device Manager)
Write-Host "`nStep 4: Triggering hardware rescan..." -ForegroundColor Cyan
Write-Host "This is like pressing F5 in Device Manager..." -ForegroundColor Yellow

try {
    # This PowerShell command triggers a hardware rescan
    $rescanResult = Get-PnpDevice | ForEach-Object { 
        try { 
            $_.GetDeviceNode().RescanHardware() 
        } catch { 
            # Ignore errors for devices that can't be rescanned
        }
    }
    Write-Host "Hardware rescan completed" -ForegroundColor Green
} catch {
    Write-Host "Hardware rescan failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Step 5: Look for our device and any unknown devices
Write-Host "`nStep 5: Checking device status..." -ForegroundColor Cyan

# Check for our device
$ourDevices = Get-PnpDevice | Where-Object { 
    ($_.InstanceId -like "*MttVDD*") -or
    ($_.HardwareID -and (($_.HardwareID -contains "Root\MttVDD") -or ($_.HardwareID -contains "MttVDD"))) -or
    ($_.FriendlyName -like "*Virtual Display*")
}

if ($ourDevices) {
    Write-Host "✓ Found Virtual Display Driver devices:" -ForegroundColor Green
    foreach ($device in $ourDevices) {
        $statusColor = if ($device.Status -eq "OK") { "Green" } else { "Yellow" }
        Write-Host "  Device: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "    Status: $($device.Status)" -ForegroundColor $statusColor
        Write-Host "    Class: $($device.Class)" -ForegroundColor White
    }
} else {
    Write-Host "⚠ No Virtual Display Driver devices found yet" -ForegroundColor Yellow
}

# Check for unknown devices that might need manual driver assignment
$unknownDevices = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -like "*Unknown*" -and
    $_.InstanceId -like "ROOT\*"
}

if ($unknownDevices) {
    Write-Host "`nFound unknown ROOT devices (may be our driver):" -ForegroundColor Yellow
    foreach ($device in $unknownDevices) {
        Write-Host "  Device: $($device.InstanceId)" -ForegroundColor White
        Write-Host "    Status: $($device.Status)" -ForegroundColor White
        
        # Try to manually assign our driver to this unknown device
        Write-Host "    Attempting to assign VDD driver..." -ForegroundColor Gray
        try {
            $updateResult = pnputil /update-driver $driverPath $device.InstanceId 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✓ Driver assigned successfully!" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Driver assignment failed: $updateResult" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    ✗ Exception: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
}

# Step 6: If still no luck, try the devcon approach
if (-not $ourDevices -and (Test-Path "C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe")) {
    Write-Host "`nStep 6: Fallback to nefconw device creation..." -ForegroundColor Cyan
    Write-Host "Creating device with nefconw and letting Windows match the driver..." -ForegroundColor Yellow
    
    $nefconPath = "C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"
    
    # Remove any failed devices first
    & $nefconPath --remove-device-node --hardware-id "Root\MttVDD" --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318" 2>$null
    Start-Sleep -Seconds 2
    
    # Create device and let Windows auto-match the driver
    & $nefconPath --create-device-node --hardware-id "Root\MttVDD" --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"
    
    # Wait for enumeration
    Start-Sleep -Seconds 5
    
    # Trigger another rescan
    Write-Host "Triggering final hardware rescan..." -ForegroundColor Yellow
    try {
        Get-PnpDevice | ForEach-Object { 
            try { 
                $_.GetDeviceNode().RescanHardware() 
            } catch { }
        }
    } catch { }
    
    Start-Sleep -Seconds 3
}

# Final verification
Write-Host "`nFinal Verification:" -ForegroundColor Cyan

$finalDevices = Get-PnpDevice | Where-Object { 
    ($_.InstanceId -like "*MttVDD*") -or
    ($_.HardwareID -and (($_.HardwareID -contains "Root\MttVDD") -or ($_.HardwareID -contains "MttVDD"))) -or
    ($_.FriendlyName -like "*Virtual Display*")
}

if ($finalDevices) {
    Write-Host "✓ SUCCESS! Virtual Display Driver devices found:" -ForegroundColor Green
    foreach ($device in $finalDevices) {
        $statusColor = if ($device.Status -eq "OK") { "Green" } elseif ($device.Status -eq "Error") { "Red" } else { "Yellow" }
        Write-Host "  Device: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "    Status: $($device.Status)" -ForegroundColor $statusColor
        Write-Host "    Class: $($device.Class)" -ForegroundColor White
        Write-Host "    Instance: $($device.InstanceId)" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Virtual Display Driver not found" -ForegroundColor Red
    
    # Show remaining unknown devices
    $stillUnknown = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Unknown*" }
    if ($stillUnknown) {
        Write-Host "`nRemaining unknown devices:" -ForegroundColor Yellow
        foreach ($device in $stillUnknown) {
            Write-Host "  $($device.InstanceId) - $($device.Status)" -ForegroundColor Gray
        }
        Write-Host "`nTry manually updating driver for these unknown devices in Device Manager" -ForegroundColor Cyan
        Write-Host "using the INF file: $driverPath" -ForegroundColor Cyan
    }
}

Write-Host "`n=== Device Manager Style Installation Complete ===" -ForegroundColor Green
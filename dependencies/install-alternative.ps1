# Alternative Virtual Display Driver Installation
# Tries different approaches and hardware IDs

Write-Host "=== Alternative VDD Installation Method ===" -ForegroundColor Green

$driverPath = "C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"
$nefconPath = "C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"

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

# Clean up any existing devices first
Write-Host "`nStep 1: Comprehensive device cleanup..." -ForegroundColor Cyan
$devicesToRemove = @("Root\MttVDD", "ROOT\MttVDD", "MttVDD")
foreach ($hwid in $devicesToRemove) {
    Write-Host "Removing devices with Hardware ID: $hwid" -ForegroundColor Yellow
    & $nefconPath --remove-device-node --hardware-id $hwid --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318" 2>$null
}

# Also remove any unknown devices that might be ours
$unknownDevices = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Unknown*" -and $_.InstanceId -like "*ROOT*" }
foreach ($device in $unknownDevices) {
    Write-Host "Removing unknown device: $($device.InstanceId)" -ForegroundColor Yellow
    try {
        $device | Remove-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Could not remove $($device.InstanceId)" -ForegroundColor Gray
    }
}

Start-Sleep -Seconds 3

# Install driver to store with different methods
Write-Host "`nStep 2: Installing driver package..." -ForegroundColor Cyan

# Method 1: Standard installation
Write-Host "Method 1: Standard pnputil installation" -ForegroundColor Yellow
pnputil /add-driver $driverPath /install
Start-Sleep -Seconds 2

# Method 2: Force installation
Write-Host "Method 2: Force installation" -ForegroundColor Yellow
pnputil /add-driver $driverPath /install /force
Start-Sleep -Seconds 2

# Try different hardware ID variations
Write-Host "`nStep 3: Trying different device creation methods..." -ForegroundColor Cyan

$hardwareIds = @("Root\MttVDD", "MttVDD")
$success = $false

foreach ($hwid in $hardwareIds) {
    if ($success) { break }
    
    Write-Host "Trying Hardware ID: $hwid" -ForegroundColor Yellow
    
    # Method A: nefconw with class name
    Write-Host "  Method A: With Display adapters class" -ForegroundColor Gray
    & $nefconPath --create-device-node --hardware-id $hwid --class-name "Display adapters" --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"
    Start-Sleep -Seconds 3
    
    # Check if device was created successfully
    $devices = Get-PnpDevice | Where-Object { $_.InstanceId -like "*$($hwid.Replace('\', '*'))*" }
    if ($devices) {
        Write-Host "  ✓ Device created with Hardware ID: $hwid" -ForegroundColor Green
        
        # Try to install driver for this device
        foreach ($device in $devices) {
            Write-Host "  Installing driver for: $($device.InstanceId)" -ForegroundColor Yellow
            try {
                pnputil /update-driver $driverPath $device.InstanceId
                $success = $true
                Write-Host "  ✓ Driver installed successfully!" -ForegroundColor Green
                break
            } catch {
                Write-Host "  Driver installation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  ✗ Device creation failed" -ForegroundColor Red
        
        # Method B: Try without class name
        Write-Host "  Method B: Without class name" -ForegroundColor Gray
        & $nefconPath --create-device-node --hardware-id $hwid --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"
        Start-Sleep -Seconds 3
        
        $devices = Get-PnpDevice | Where-Object { $_.InstanceId -like "*$($hwid.Replace('\', '*'))*" }
        if ($devices) {
            Write-Host "  ✓ Device created (method B)" -ForegroundColor Green
            foreach ($device in $devices) {
                try {
                    pnputil /update-driver $driverPath $device.InstanceId
                    $success = $true
                    Write-Host "  ✓ Driver installed successfully!" -ForegroundColor Green
                    break
                } catch {
                    Write-Host "  Driver installation failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

# If still not successful, try a different approach
if (-not $success) {
    Write-Host "`nStep 4: Alternative approach - Create then manually install..." -ForegroundColor Cyan
    
    # Create device with minimal parameters
    Write-Host "Creating device with minimal parameters..." -ForegroundColor Yellow
    & $nefconPath --create-device-node --hardware-id "Root\MttVDD"
    Start-Sleep -Seconds 5
    
    # Find ANY unknown devices and try to install our driver
    $unknownDevices = Get-PnpDevice | Where-Object { 
        $_.FriendlyName -like "*Unknown*" -or 
        $_.Status -eq "Error" 
    }
    
    Write-Host "Found $($unknownDevices.Count) unknown/error devices" -ForegroundColor Yellow
    
    foreach ($device in $unknownDevices) {
        Write-Host "Trying to install driver for: $($device.InstanceId)" -ForegroundColor Yellow
        try {
            $result = pnputil /update-driver $driverPath $device.InstanceId 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Successfully installed driver for $($device.InstanceId)" -ForegroundColor Green
                $success = $true
            } else {
                Write-Host "Failed to install for $($device.InstanceId): $result" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Exception installing for $($device.InstanceId): $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
}

# Final verification
Write-Host "`nStep 5: Final verification..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

$vddDevices = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -like "*Virtual Display*" -or
    $_.InstanceId -like "*MttVDD*" -or
    ($_.HardwareID -and ($_.HardwareID -like "*MttVDD*"))
}

if ($vddDevices) {
    Write-Host "✓ Virtual Display Driver devices found:" -ForegroundColor Green
    foreach ($device in $vddDevices) {
        Write-Host "  Device: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "    Status: $($device.Status)" -ForegroundColor White
        Write-Host "    Class: $($device.Class)" -ForegroundColor White
        Write-Host "    Instance: $($device.InstanceId)" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ No Virtual Display Driver devices found" -ForegroundColor Red
    
    # Show remaining unknown devices
    $remainingUnknown = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Unknown*" }
    if ($remainingUnknown) {
        Write-Host "`nRemaining unknown devices:" -ForegroundColor Yellow
        foreach ($device in $remainingUnknown) {
            Write-Host "  $($device.InstanceId) - $($device.Status)" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== Alternative Installation Complete ===" -ForegroundColor Green
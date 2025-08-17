# Virtual Display Driver Installation Script
# Uses Windows Device Management APIs for proper driver installation

param(
    [string]$DriverPath = "C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf",
    [string]$HardwareId = "Root\MttVDD"
)

Write-Host "=== Virtual Display Driver Installation ===" -ForegroundColor Green
Write-Host "Driver Path: $DriverPath" -ForegroundColor Yellow
Write-Host "Hardware ID: $HardwareId" -ForegroundColor Yellow

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

# Step 1: Remove existing devices
Write-Host "`nStep 1: Removing existing Virtual Display Driver devices..." -ForegroundColor Cyan
try {
    $existingDevices = Get-PnpDevice -FriendlyName "*Virtual Display*" -ErrorAction SilentlyContinue
    if ($existingDevices) {
        foreach ($device in $existingDevices) {
            Write-Host "Removing device: $($device.FriendlyName)" -ForegroundColor Yellow
            $device | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
            $device | Remove-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    
    # Also try removing by hardware ID
    $rootDevices = Get-PnpDevice | Where-Object { $_.HardwareID -like "*MttVDD*" }
    if ($rootDevices) {
        foreach ($device in $rootDevices) {
            Write-Host "Removing device by Hardware ID: $($device.InstanceId)" -ForegroundColor Yellow
            $device | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
            $device | Remove-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
} catch {
    Write-Host "Warning: Error during device removal: $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Step 2: Install driver package
Write-Host "`nStep 2: Installing driver package to driver store..." -ForegroundColor Cyan
try {
    $result = pnputil /add-driver $DriverPath /install
    Write-Host "pnputil result: $result" -ForegroundColor Yellow
} catch {
    Write-Host "Warning: pnputil failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# Step 3: Create device using PowerShell Add-PnpDevice (if available)
Write-Host "`nStep 3: Creating virtual device node..." -ForegroundColor Cyan
try {
    # Try using New-PnpDevice if available (Windows 10/11)
    if (Get-Command "Add-PnpDevice" -ErrorAction SilentlyContinue) {
        Write-Host "Using Add-PnpDevice cmdlet..." -ForegroundColor Yellow
        Add-PnpDevice -HardwareId $HardwareId -Class "Display" -Service "WUDFRD"
    } else {
        # Fall back to devcon-style creation
        Write-Host "Using devcon-style device creation..." -ForegroundColor Yellow
        $devconPath = "C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"
        & $devconPath --create-device-node --hardware-id $HardwareId --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"
    }
} catch {
    Write-Host "Device creation method failed: $($_.Exception.Message)" -ForegroundColor Yellow
    
    # Final fallback - try nefconw directly
    Write-Host "Trying nefconw as fallback..." -ForegroundColor Yellow
    try {
        $nefconPath = "C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"
        & $nefconPath --create-device-node --hardware-id $HardwareId --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"
    } catch {
        Write-Host "All device creation methods failed" -ForegroundColor Red
        exit 1
    }
}

Start-Sleep -Seconds 5

# Step 4: Force driver update/installation
Write-Host "`nStep 4: Installing driver for device..." -ForegroundColor Cyan
try {
    # Method 1: Use pnputil to update driver
    Write-Host "Attempting driver update with pnputil..." -ForegroundColor Yellow
    $updateResult = pnputil /update-driver $DriverPath $HardwareId
    Write-Host "Update result: $updateResult" -ForegroundColor Yellow
} catch {
    Write-Host "pnputil update failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Method 2: Try PowerShell Update-PnpDeviceDriver if available
try {
    if (Get-Command "Update-PnpDeviceDriver" -ErrorAction SilentlyContinue) {
        Write-Host "Attempting PowerShell driver update..." -ForegroundColor Yellow
        $devices = Get-PnpDevice | Where-Object { $_.HardwareID -like "*MttVDD*" }
        foreach ($device in $devices) {
            Update-PnpDeviceDriver -InstanceId $device.InstanceId -DriverInfPath $DriverPath
        }
    }
} catch {
    Write-Host "PowerShell driver update failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Step 5: Verification
Write-Host "`nStep 5: Verifying installation..." -ForegroundColor Cyan

# Check for devices with Virtual Display in the name
$vddDevices = Get-PnpDevice -FriendlyName "*Virtual Display*" -ErrorAction SilentlyContinue
if ($vddDevices) {
    Write-Host "Found Virtual Display devices:" -ForegroundColor Green
    foreach ($device in $vddDevices) {
        Write-Host "  - $($device.FriendlyName) | Status: $($device.Status) | Class: $($device.Class)" -ForegroundColor White
    }
} else {
    Write-Host "No devices found with 'Virtual Display' in name" -ForegroundColor Yellow
}

# Check for devices with MttVDD hardware ID
$mttDevices = Get-PnpDevice | Where-Object { $_.HardwareID -like "*MttVDD*" }
if ($mttDevices) {
    Write-Host "Found MttVDD devices:" -ForegroundColor Green
    foreach ($device in $mttDevices) {
        Write-Host "  - $($device.FriendlyName) | Status: $($device.Status) | Class: $($device.Class)" -ForegroundColor White
        Write-Host "    Hardware ID: $($device.HardwareID)" -ForegroundColor Gray
    }
} else {
    Write-Host "No devices found with MttVDD hardware ID" -ForegroundColor Red
}

# Check for any Unknown devices
$unknownDevices = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Unknown*" -or $_.Status -eq "Unknown" }
if ($unknownDevices) {
    Write-Host "Unknown devices found (may be our driver):" -ForegroundColor Yellow
    foreach ($device in $unknownDevices) {
        Write-Host "  - $($device.FriendlyName) | Status: $($device.Status) | Instance: $($device.InstanceId)" -ForegroundColor White
    }
}

Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
Write-Host "Please check Device Manager under Display Adapters for the Virtual Display Driver" -ForegroundColor Cyan
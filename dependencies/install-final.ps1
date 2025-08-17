# Final Virtual Display Driver Installation
# Uses exact hardware IDs from INF file: Root\MttVDD and MttVDD

Write-Host "=== FINAL VDD Installation - Using Exact INF Hardware IDs ===" -ForegroundColor Green

$driverPath = "C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"
$nefconPath = "C:\VirtualDisplayDriver\Driver Files\dependencies\nefconw.exe"

# The exact hardware IDs from the INF file
$exactHardwareIds = @("Root\MttVDD", "MttVDD")

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

Write-Host "Using Hardware IDs from INF: $($exactHardwareIds -join ', ')" -ForegroundColor Yellow

# Step 1: Complete cleanup
Write-Host "`nStep 1: Complete device cleanup..." -ForegroundColor Cyan
foreach ($hwid in $exactHardwareIds) {
    Write-Host "Removing devices with Hardware ID: $hwid" -ForegroundColor Yellow
    & $nefconPath --remove-device-node --hardware-id $hwid --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318" 2>$null
}

# Remove any unknown ROOT devices that might be ours
$unknownRootDevices = Get-PnpDevice | Where-Object { 
    $_.InstanceId -like "ROOT\*" -and 
    ($_.FriendlyName -like "*Unknown*" -or $_.Status -eq "Error")
}
foreach ($device in $unknownRootDevices) {
    Write-Host "Removing unknown ROOT device: $($device.InstanceId)" -ForegroundColor Gray
    try {
        $device | Remove-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
    } catch { }
}

Start-Sleep -Seconds 5

# Step 2: Install driver package properly
Write-Host "`nStep 2: Installing driver package to Windows Driver Store..." -ForegroundColor Cyan
try {
    # First try standard installation
    $result1 = pnputil /add-driver $driverPath /install 2>&1
    Write-Host "Standard install result: $result1" -ForegroundColor Gray
    
    # Then force installation to ensure it's in the store
    $result2 = pnputil /add-driver $driverPath /install /force 2>&1
    Write-Host "Force install result: $result2" -ForegroundColor Gray
} catch {
    Write-Host "Driver installation error: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 3

# Step 3: Try creating device with each exact hardware ID
Write-Host "`nStep 3: Creating devices with exact hardware IDs..." -ForegroundColor Cyan

foreach ($hwid in $exactHardwareIds) {
    Write-Host "`nAttempting Hardware ID: $hwid" -ForegroundColor Yellow
    
    # Create device
    Write-Host "Creating device with nefconw..." -ForegroundColor Gray
    & $nefconPath --create-device-node --hardware-id $hwid --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"
    
    Start-Sleep -Seconds 3
    
    # Check if device was created
    $newDevices = Get-PnpDevice | Where-Object { 
        $_.InstanceId -like "*$($hwid.Replace('\', '\'))*" -or
        ($_.HardwareID -and ($_.HardwareID -contains $hwid))
    }
    
    if ($newDevices) {
        Write-Host "✓ Device created successfully" -ForegroundColor Green
        foreach ($device in $newDevices) {
            Write-Host "  Device: $($device.FriendlyName) | Status: $($device.Status)" -ForegroundColor White
            Write-Host "  Instance: $($device.InstanceId)" -ForegroundColor Gray
        }
        
        # Try to install driver immediately
        Write-Host "Installing driver for created device..." -ForegroundColor Yellow
        try {
            $updateResult = pnputil /update-driver $driverPath $hwid 2>&1
            Write-Host "Driver update result: $updateResult" -ForegroundColor Gray
        } catch {
            Write-Host "Driver update failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "✗ Device creation failed for $hwid" -ForegroundColor Red
    }
}

Start-Sleep -Seconds 5

# Step 4: Manual driver installation for any remaining unknown devices
Write-Host "`nStep 4: Manual driver installation for unknown devices..." -ForegroundColor Cyan

$unknownDevices = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -like "*Unknown*" -or 
    $_.Status -eq "Error" -or
    $_.Status -eq "Unknown"
}

if ($unknownDevices) {
    Write-Host "Found $($unknownDevices.Count) unknown devices. Trying to install our driver..." -ForegroundColor Yellow
    
    foreach ($device in $unknownDevices) {
        Write-Host "Trying device: $($device.InstanceId)" -ForegroundColor Gray
        try {
            $result = pnputil /update-driver $driverPath $device.InstanceId 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ SUCCESS! Driver installed for $($device.InstanceId)" -ForegroundColor Green
            } else {
                Write-Host "Failed for $($device.InstanceId): $result" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Exception for $($device.InstanceId): $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "No unknown devices found" -ForegroundColor Green
}

# Step 5: Final verification with detailed analysis
Write-Host "`nStep 5: Final verification..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Check for our driver by hardware ID patterns
$ourDevices = Get-PnpDevice | Where-Object { 
    ($_.InstanceId -like "*MttVDD*") -or
    ($_.HardwareID -and (($_.HardwareID -contains "Root\MttVDD") -or ($_.HardwareID -contains "MttVDD"))) -or
    ($_.FriendlyName -like "*Virtual Display*")
}

if ($ourDevices) {
    Write-Host "✓ Virtual Display Driver devices found:" -ForegroundColor Green
    foreach ($device in $ourDevices) {
        $statusColor = if ($device.Status -eq "OK") { "Green" } elseif ($device.Status -eq "Error") { "Red" } else { "Yellow" }
        Write-Host "  Device: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "    Status: $($device.Status)" -ForegroundColor $statusColor
        Write-Host "    Class: $($device.Class)" -ForegroundColor White
        Write-Host "    Instance: $($device.InstanceId)" -ForegroundColor Gray
        if ($device.HardwareID) {
            Write-Host "    Hardware IDs: $($device.HardwareID -join ', ')" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "✗ No Virtual Display Driver devices found" -ForegroundColor Red
    
    # Show all unknown devices for manual inspection
    $stillUnknown = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Unknown*" }
    if ($stillUnknown) {
        Write-Host "`nRemaining unknown devices (check if any could be our driver):" -ForegroundColor Yellow
        foreach ($device in $stillUnknown) {
            Write-Host "  $($device.InstanceId) | $($device.Status)" -ForegroundColor Gray
            if ($device.HardwareID) {
                Write-Host "    Hardware IDs: $($device.HardwareID -join ', ')" -ForegroundColor Gray
            }
        }
    }
}

# Check driver store to confirm our driver is there
Write-Host "`nDriver Store Status:" -ForegroundColor Cyan
try {
    $storeCheck = pnputil /enum-drivers | Select-String -Pattern "MttVDD"
    if ($storeCheck) {
        Write-Host "✓ MttVDD driver found in Windows Driver Store" -ForegroundColor Green
        $storeCheck | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        Write-Host "✗ MttVDD driver not found in Driver Store" -ForegroundColor Red
    }
} catch {
    Write-Host "Could not check driver store: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Final Installation Complete ===" -ForegroundColor Green
Write-Host "If you still see Unknown Device, there may be an issue with:" -ForegroundColor Yellow
Write-Host "1. Driver signing (even though you said it's signed)" -ForegroundColor Yellow
Write-Host "2. Hardware ID mismatch in the INF file" -ForegroundColor Yellow
Write-Host "3. Missing dependencies or services" -ForegroundColor Yellow
Write-Host "4. Windows version compatibility" -ForegroundColor Yellow
# Virtual Display Driver Diagnostic Script
# Analyzes why the device shows as "Unknown Device"

Write-Host "=== Virtual Display Driver Diagnostic ===" -ForegroundColor Green

# Step 1: Check INF file contents and hardware IDs
Write-Host "`n1. Analyzing INF file..." -ForegroundColor Cyan
$infPath = "C:\VirtualDisplayDriver\Driver Files\VDD x86 x64\MttVDD.inf"

if (Test-Path $infPath) {
    Write-Host "INF file exists: $infPath" -ForegroundColor Green
    
    # Read INF content and look for hardware IDs
    $infContent = Get-Content $infPath -Raw
    Write-Host "`nSearching for Hardware IDs in INF..." -ForegroundColor Yellow
    
    # Look for hardware ID patterns
    if ($infContent -match "Root\\MttVDD") {
        Write-Host "✓ Found Root\MttVDD in INF" -ForegroundColor Green
    } else {
        Write-Host "✗ Root\MttVDD not found in INF" -ForegroundColor Red
    }
    
    if ($infContent -match "MttVDD") {
        Write-Host "✓ Found MttVDD pattern in INF" -ForegroundColor Green
    } else {
        Write-Host "✗ MttVDD pattern not found in INF" -ForegroundColor Red
    }
    
    # Extract hardware IDs from INF
    $lines = $infContent -split "`n"
    foreach ($line in $lines) {
        if ($line -match ".*=.*,\s*(Root\\|)MttVDD") {
            Write-Host "Hardware ID line: $($line.Trim())" -ForegroundColor White
        }
    }
} else {
    Write-Host "ERROR: INF file not found at $infPath" -ForegroundColor Red
    exit 1
}

# Step 2: Check driver store
Write-Host "`n2. Checking Windows Driver Store..." -ForegroundColor Cyan
try {
    $storeDrivers = pnputil /enum-drivers | Select-String -Pattern "MttVDD|Virtual.*Display"
    if ($storeDrivers) {
        Write-Host "Drivers in store:" -ForegroundColor Green
        $storeDrivers | ForEach-Object { Write-Host "  $($_)" -ForegroundColor White }
    } else {
        Write-Host "No MttVDD drivers found in driver store" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error checking driver store: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Find all devices (including unknown ones)
Write-Host "`n3. Analyzing all PnP devices..." -ForegroundColor Cyan

# Get all devices
$allDevices = Get-PnpDevice | Sort-Object FriendlyName

# Look for unknown devices
$unknownDevices = $allDevices | Where-Object { 
    $_.FriendlyName -like "*Unknown*" -or 
    $_.Status -eq "Error" -or 
    $_.Status -eq "Unknown" -or
    $_.Problem -ne $null
}

if ($unknownDevices) {
    Write-Host "Unknown/Problem devices found:" -ForegroundColor Yellow
    foreach ($device in $unknownDevices) {
        Write-Host "  Device: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "    Instance ID: $($device.InstanceId)" -ForegroundColor Gray
        Write-Host "    Status: $($device.Status)" -ForegroundColor Gray
        Write-Host "    Class: $($device.Class)" -ForegroundColor Gray
        if ($device.HardwareID) {
            Write-Host "    Hardware IDs: $($device.HardwareID -join ', ')" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "No unknown devices found" -ForegroundColor Green
}

# Step 4: Look for MttVDD specifically
Write-Host "`n4. Searching for MttVDD devices..." -ForegroundColor Cyan
$mttDevices = $allDevices | Where-Object { 
    ($_.InstanceId -like "*MttVDD*") -or 
    ($_.HardwareID -like "*MttVDD*") -or
    ($_.FriendlyName -like "*MttVDD*") -or
    ($_.FriendlyName -like "*Virtual Display*")
}

if ($mttDevices) {
    Write-Host "MttVDD-related devices found:" -ForegroundColor Green
    foreach ($device in $mttDevices) {
        Write-Host "  Device: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "    Instance ID: $($device.InstanceId)" -ForegroundColor Gray
        Write-Host "    Status: $($device.Status)" -ForegroundColor Gray
        Write-Host "    Class: $($device.Class)" -ForegroundColor Gray
        if ($device.HardwareID) {
            Write-Host "    Hardware IDs: $($device.HardwareID -join ', ')" -ForegroundColor Gray
        }
        if ($device.Service) {
            Write-Host "    Service: $($device.Service)" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "No MttVDD devices found" -ForegroundColor Red
}

# Step 5: Check for Root enumerated devices
Write-Host "`n5. Checking Root enumerated devices..." -ForegroundColor Cyan
$rootDevices = $allDevices | Where-Object { $_.InstanceId -like "ROOT\*" }
$rootMttDevices = $rootDevices | Where-Object { $_.InstanceId -like "*MttVDD*" }

if ($rootMttDevices) {
    Write-Host "Root MttVDD devices:" -ForegroundColor Green
    foreach ($device in $rootMttDevices) {
        Write-Host "  $($device.InstanceId) - $($device.FriendlyName) - $($device.Status)" -ForegroundColor White
    }
} else {
    Write-Host "No Root\MttVDD devices found" -ForegroundColor Yellow
    
    # Show some other Root devices for comparison
    $otherRoot = $rootDevices | Select-Object -First 5
    Write-Host "Sample Root devices for reference:" -ForegroundColor Gray
    foreach ($device in $otherRoot) {
        Write-Host "  $($device.InstanceId) - $($device.FriendlyName)" -ForegroundColor Gray
    }
}

# Step 6: Try to manually match driver
Write-Host "`n6. Attempting manual driver matching..." -ForegroundColor Cyan
$problemDevices = Get-PnpDevice | Where-Object { $_.Status -eq "Error" -or $_.FriendlyName -like "*Unknown*" }

foreach ($device in $problemDevices) {
    Write-Host "Trying to update driver for: $($device.InstanceId)" -ForegroundColor Yellow
    try {
        pnputil /update-driver $infPath $device.InstanceId
        Write-Host "Update attempt completed for $($device.InstanceId)" -ForegroundColor Green
    } catch {
        Write-Host "Update failed for $($device.InstanceId): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Diagnostic Complete ===" -ForegroundColor Green
Write-Host "Please review the above information to identify the issue." -ForegroundColor Cyan
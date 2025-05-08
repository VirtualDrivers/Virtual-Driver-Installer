# Retrieve arguments
param (
    [int]$NumMon,
    [string]$GPUFN,
    [string]$InstallDir
)

# Remove any extra quotes that might have been added by Jocke's fix in install.bat
$InstallDir = $InstallDir.Trim('"')
Write-Host "Installing to path: $InstallDir"

# Define file paths
$file1="$InstallDir\vdd_settings.xml"
$file2="$InstallDir\scripts\onoff_at_loginout\psscripts.ini"
$file3="$InstallDir\scripts\onoff_at_loginout\vdd_e-li_d-lo.cmd"
$file4="$InstallDir\uninstall.bat"

# Define the default installation path that needs to be replaced
$defaultPath = "C:\VirtualDisplayDriver"
$newPath = "$InstallDir"

# Note: Path handling for spaces is already correct here.
# PowerShell handles paths with spaces properly when variables are properly quoted,
# which we've done throughout this script. Jocke's fix in install.bat complements this.

# Function to safely update file content
function Update-FileContent {
    param (
        [string]$FilePath,
        [string]$OldValue,
        [string]$NewValue,
        [string]$FileDescription
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Warning "File not found: $FilePath ($FileDescription)"
            return $false
        }
        
        # Create backup with .bak extension
        $backupPath = "$FilePath.bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Replace content
        $updatedContent = $content.Replace($OldValue, $NewValue)
        
        # Write back
        Set-Content -Path $FilePath -Value $updatedContent -Force -ErrorAction Stop
        
        Write-Host "Updated $FileDescription successfully."
        return $true
    }
    catch {
        Write-Error "Error updating $FileDescription: $_"
        # Attempt to restore from backup if it exists
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $FilePath -Force
            Write-Host "Restored $FileDescription from backup."
        }
        return $false
    }
}

# Update XML settings
if (Test-Path $file1) {
    Write-Host "Updating VDD settings..."
    
    try {
        [xml]$xmlContent = Get-Content -Path $file1 -ErrorAction Stop
        
        # Update XML values using proper XML methods
        $monitorNode = $xmlContent.SelectSingleNode("//monitors/count")
        if ($monitorNode -ne $null) {
            $monitorNode.InnerText = "$NumMon"
        }
        
        $gpuNode = $xmlContent.SelectSingleNode("//gpu/friendlyname")
        if ($gpuNode -ne $null) {
            $gpuNode.InnerText = "$GPUFN"
        }
        
        # Save XML with proper formatting
        $xmlContent.Save($file1)
        Write-Host "Updated VDD settings XML successfully."
    }
    catch {
        Write-Error "Error updating VDD settings XML: $_"
        exit 1
    }
}
else {
    Write-Error "VDD settings file not found: $file1"
    exit 1
}

# Update script paths
$pathsUpdated = $true
$pathsUpdated = $pathsUpdated -and (Update-FileContent -FilePath $file2 -OldValue "CmdLine=$defaultPath\scripts\toggle-VDD.ps1" -NewValue "CmdLine=$newPath\scripts\toggle-VDD.ps1" -FileDescription "psscripts.ini")
$pathsUpdated = $pathsUpdated -and (Update-FileContent -FilePath $file3 -OldValue $defaultPath -NewValue $newPath -FileDescription "login/logoff script")
$pathsUpdated = $pathsUpdated -and (Update-FileContent -FilePath $file4 -OldValue $defaultPath -NewValue $newPath -FileDescription "uninstall script")

if (-not $pathsUpdated) {
    Write-Warning "Some path updates may have failed. Installation might not work correctly."
}

Write-Host "Configuration completed successfully."
exit 0

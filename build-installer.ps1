# Create inno-setup directories if they don't exist already
if (-not (Test-Path "inno-setup")) {
  New-Item -Path "inno-setup" -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path "inno-setup\input")) {
  New-Item -Path "inno-setup\input" -ItemType Directory -Force | Out-Null
}

# Copy signed artifacts
if (Test-Path "SignedArtifacts") {
  Copy-Item "SignedArtifacts\*" -Destination "inno-setup\input\" -Recurse -Force
}

$platform = "x64"

# Display directory contents for debugging
Write-Host "Contents of SignedArtifacts directory:"
if (Test-Path "SignedArtifacts") {
  Get-ChildItem "SignedArtifacts"
} else {
  Write-Host "SignedArtifacts directory not found"
}

Write-Host "Contents of inno-setup\input directory after copy:"
Get-ChildItem "inno-setup\input"

# Check if Companion directory exists before attempting operations
if (Test-Path "inno-setup\input\Companion") {
  Write-Host "Contents of Companion directory:"
  Get-ChildItem "inno-setup\input\Companion" -Recurse
} else {
  Write-Host "Companion directory not found"
}

# Set release tag
$releaseTag = (Get-Date).ToString('yy.MM.dd')
if (Test-Path "inno-setup\Setup.iss") {
  (Get-Content "inno-setup\Setup.iss") | 
    ForEach-Object { $_ -replace '1.0.0', $releaseTag } | 
    Set-Content "inno-setup\Setup.iss"
}

# ARM64-specific handling
if ($platform -eq 'ARM64') {
  if (Test-Path "inno-setup\Setup.iss") {
    (Get-Content "inno-setup\Setup.iss") | 
      ForEach-Object { $_ -replace 'x64compatible', 'arm64' } | 
      Set-Content "inno-setup\Setup.iss"
        
    (Get-Content "inno-setup\Setup.iss") | 
      ForEach-Object { $_ -replace '-x64', '-arm64' } | 
      Set-Content "inno-setup\Setup.iss"
  }
  
  # VDDSysTray has been replaced with VDDControl
  if (Test-Path "inno-setup\input\Companion\VDDControl.exe") {
    Remove-Item "inno-setup\input\Companion\VDDControl.exe" -Force
    Write-Host "Removed x64 VDDControl.exe"
  }
  
  # Check if ARM64 VDDControl exists before copying
  if (Test-Path "inno-setup\input\Companion\arm64\VDDControl.exe") {
    Copy-Item "inno-setup\input\Companion\arm64\VDDControl.exe" -Destination "inno-setup\input\Companion\" -Force
    Write-Host "Copied ARM64 VDDControl.exe"
  } else {
    Write-Host "Warning: ARM64 VDDControl.exe not found in expected location"
    Get-ChildItem "inno-setup\input\Companion" -Recurse
  }
}
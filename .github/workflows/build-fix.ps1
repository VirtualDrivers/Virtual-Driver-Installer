# Don't use mkdir -p which is failing on GitHub Actions
# Instead use native PowerShell commands with error handling

# Clean and recreate the directories to ensure fresh state
try {
  # Create directories if they don't exist (no error if they do)
  if (-not (Test-Path "inno-setup")) {
    New-Item -Path "inno-setup" -ItemType Directory -Force | Out-Null
    Write-Host "Created inno-setup directory"
  } else {
    Write-Host "inno-setup directory already exists"
  }
  
  if (-not (Test-Path "inno-setup\input")) {
    New-Item -Path "inno-setup\input" -ItemType Directory -Force | Out-Null
    Write-Host "Created inno-setup\input directory"
  } else {
    Write-Host "inno-setup\input directory already exists"
  }

  # Copy signed artifacts with error handling
  if (Test-Path "SignedArtifacts") {
    Copy-Item "SignedArtifacts\*" -Destination "inno-setup\input\" -Recurse -Force
    Write-Host "Copied artifacts successfully"
  } else {
    Write-Host "WARNING: SignedArtifacts directory not found"
  }

  $platform = "x64"

  # Display directory contents for debugging
  Write-Host "Contents of inno-setup\input directory after copy:"
  Get-ChildItem "inno-setup\input" -ErrorAction SilentlyContinue

  # Check if Companion directory exists
  if (Test-Path "inno-setup\input\Companion") {
    Write-Host "Contents of Companion directory:"
    Get-ChildItem "inno-setup\input\Companion" -Recurse -ErrorAction SilentlyContinue
  } else {
    Write-Host "Companion directory not found"
  }

  # Set release tag
  $releaseTag = (Get-Date).ToString('yy.MM.dd')
  if (Test-Path "inno-setup\Setup.iss") {
    (Get-Content "inno-setup\Setup.iss") | 
      ForEach-Object { $_ -replace '1.0.0', $releaseTag } | 
      Set-Content "inno-setup\Setup.iss"
    Write-Host "Updated version to $releaseTag"
  } else {
    Write-Host "WARNING: inno-setup\Setup.iss not found"
  }

  # ARM64-specific handling
  if ($platform -eq 'ARM64') {
    Write-Host "Handling ARM64-specific changes"
    if (Test-Path "inno-setup\Setup.iss") {
      (Get-Content "inno-setup\Setup.iss") | 
        ForEach-Object { $_ -replace 'x64compatible', 'arm64' } | 
        Set-Content "inno-setup\Setup.iss"
          
      (Get-Content "inno-setup\Setup.iss") | 
        ForEach-Object { $_ -replace '-x64', '-arm64' } | 
        Set-Content "inno-setup\Setup.iss"
      
      Write-Host "Updated architecture settings in Setup.iss"
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
      Write-Host "WARNING: ARM64 VDDControl.exe not found in expected location"
      Get-ChildItem "inno-setup\input\Companion" -Recurse -ErrorAction SilentlyContinue
    }
  }
  
  Write-Host "Script completed successfully"
} catch {
  Write-Host "ERROR: $_"
  throw $_
}
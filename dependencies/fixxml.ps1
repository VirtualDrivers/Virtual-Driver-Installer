# Retrieve arguments
param (
    [int]$NumMon,
    [string]$GPUFN,
    [string]$InstallDir
)
$file1="$InstallDir\vdd_settings.xml"
$file2="$InstallDir\utils\onoff_at_loginout\psscripts.ini"
$file3="$InstallDir\utils\onoff_at_loginout\vdd_e-li_d-lo.cmd"
$file4="$InstallDir\uninstall.bat"

# Define the replacement
$oldPath = "CmdLine=C:\VirtualDisplayDriver\scripts\toggle-VDD.ps1"
$newPath = "CmdLine=$InstallDir\scripts\toggle-VDD.ps1"

(Get-Content $file1).replace("<friendlyname>default</friendlyname>","<friendlyname>$GPUFN</friendlyname>")| Set-Content $file1
(Get-Content $file1).replace("<count>1</count>","<count>$NumMon</count>")  | Set-Content $file1
(Get-Content $file2).replace($oldPath, $newPath)  | Set-Content $file2
(Get-Content $file3).replace("C:\VirtualDisplayDriver", "$InstallDir")  | Set-Content $file3
(Get-Content $file4).replace("C:\VirtualDisplayDriver", "$InstallDir")  | Set-Content $file4
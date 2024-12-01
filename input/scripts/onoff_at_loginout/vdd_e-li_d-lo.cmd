REM Check if running as administrator
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM If not running as administrator, restart script with elevated privileges
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell.exe -Command "Start-Process -Verb RunAs -FilePath '%~0'"
    exit /b
)
set "defdir=C:\VirtualDisplayDriver"
if not exist $defdir (
	echo "Ther seems to have been an issue during install, cant logate the needed files"
	exit /b
) else (
	copy psscripts.ini C:\Windows\System32\GroupPolicy\User\Scripts
	reg import enable_at_logon_disable_at_logoff.reg
)
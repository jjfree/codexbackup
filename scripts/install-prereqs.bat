@echo off
setlocal EnableExtensions
chcp 65001 >nul

echo ============================================================
echo Codex Windows prerequisite installer
echo ============================================================
echo.

call :require_admin
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_winget
if errorlevel 1 exit /b %ERRORLEVEL%
call :enable_windows_feature Microsoft-Windows-Subsystem-Linux
if errorlevel 1 exit /b %ERRORLEVEL%
call :enable_windows_feature VirtualMachinePlatform
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_wsl2
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_ubuntu
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_winget_package Git.Git git "git --version"
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_winget_package OpenJS.NodeJS.LTS node "node --version"
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_npm
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_winget_package Microsoft.PowerShell pwsh "pwsh --version"
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_winget_package GitHub.cli gh "gh --version"
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_python312
if errorlevel 1 exit /b %ERRORLEVEL%
call :ensure_winget_package Docker.DockerDesktop docker "docker --version"
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo [OK] All prerequisites are installed or already present.
echo [INFO] If WSL, Docker, or Windows features were newly installed, reboot before running heavy Docker/WSL workloads.
exit /b 0

:require_admin
net session >nul 2>&1
if errorlevel 1 (
  echo [ERROR] This script must be run as Administrator.
  echo         Right-click Command Prompt or PowerShell and choose "Run as administrator".
  exit /b 1
)
echo [OK] Administrator privileges confirmed.
exit /b 0

:ensure_winget
where winget >nul 2>&1
if errorlevel 1 (
  echo [ERROR] winget was not found. Install "App Installer" from Microsoft Store, then rerun this script.
  exit /b 1
)
echo [OK] winget is available.
exit /b 0

:enable_windows_feature
set "FEATURE=%~1"
echo.
echo [STEP] Checking Windows feature: %FEATURE%
dism.exe /online /Get-FeatureInfo /FeatureName:%FEATURE% | findstr /I "State : Enabled" >nul 2>&1
if not errorlevel 1 (
  echo [OK] %FEATURE% is already enabled.
  exit /b 0
)

echo [INFO] Enabling %FEATURE% ...
dism.exe /online /Enable-Feature /FeatureName:%FEATURE% /All /NoRestart
set "RC=%ERRORLEVEL%"
if "%RC%"=="3010" (
  echo [ERROR] %FEATURE% was enabled but Windows requires a reboot.
  echo         Reboot the computer, then run this script again.
  exit /b 3010
)
if not "%RC%"=="0" (
  echo [ERROR] Failed to enable %FEATURE%. Exit code: %RC%
  exit /b %RC%
)
echo [OK] %FEATURE% enabled.
exit /b 0

:ensure_wsl2
echo.
echo [STEP] Checking WSL 2
wsl --status >nul 2>&1
if errorlevel 1 (
  echo [INFO] Installing WSL core without a distribution ...
  wsl --install --no-distribution
  if errorlevel 1 (
    echo [ERROR] Failed to install WSL core.
    exit /b 1
  )
)

wsl --set-default-version 2
if errorlevel 1 (
  echo [ERROR] Failed to set WSL default version to 2.
  exit /b 1
)

wsl --update
if errorlevel 1 (
  echo [ERROR] Failed to update WSL.
  exit /b 1
)

echo [OK] WSL 2 is available and selected as default.
exit /b 0

:ensure_ubuntu
echo.
echo [STEP] Checking Ubuntu WSL distribution
wsl -l -q | findstr /I /C:"Ubuntu" >nul 2>&1
if not errorlevel 1 (
  echo [OK] Ubuntu is already installed in WSL.
  exit /b 0
)

echo [INFO] Installing Ubuntu WSL distribution. First launch may ask you to create a Linux user.
wsl --install -d Ubuntu --no-launch
if errorlevel 1 (
  echo [ERROR] Failed to install Ubuntu WSL distribution.
  exit /b 1
)
echo [OK] Ubuntu WSL distribution installed.
exit /b 0

:ensure_winget_package
set "PKG_ID=%~1"
set "VERIFY_CMD=%~2"
set "VERIFY_LINE=%~3"
echo.
echo [STEP] Checking %PKG_ID%
where %VERIFY_CMD% >nul 2>&1
if not errorlevel 1 (
  call %VERIFY_LINE%
  if not errorlevel 1 (
    echo [OK] %PKG_ID% is already installed.
    exit /b 0
  )
)

echo [INFO] Installing %PKG_ID% ...
winget install --exact --id %PKG_ID% --accept-package-agreements --accept-source-agreements --silent
if errorlevel 1 (
  echo [ERROR] Failed to install %PKG_ID%.
  exit /b 1
)

where %VERIFY_CMD% >nul 2>&1
if errorlevel 1 (
  echo [ERROR] %PKG_ID% installed but %VERIFY_CMD% is still not on PATH. Restart terminal or reboot, then rerun.
  exit /b 1
)

call %VERIFY_LINE%
if errorlevel 1 (
  echo [ERROR] %PKG_ID% verification failed after install.
  exit /b 1
)
echo [OK] %PKG_ID% installed and verified.
exit /b 0

:ensure_npm
echo.
echo [STEP] Checking npm
where npm >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Node.js is present but npm was not found on PATH. Restart terminal or reinstall Node.js LTS.
  exit /b 1
)
npm --version
if errorlevel 1 (
  echo [ERROR] npm verification failed.
  exit /b 1
)
echo [OK] npm is available.
exit /b 0

:ensure_python312
echo.
echo [STEP] Checking Python 3.12
py -3.12 --version >nul 2>&1
if not errorlevel 1 (
  py -3.12 --version
  echo [OK] Python 3.12 is already installed.
  exit /b 0
)

echo [INFO] Installing Python 3.12 for projects that require Python >=3.11,<3.13 ...
winget install --exact --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent
if errorlevel 1 (
  echo [ERROR] Failed to install Python 3.12.
  exit /b 1
)

py -3.12 --version
if errorlevel 1 (
  echo [ERROR] Python 3.12 installed but py -3.12 verification failed. Restart terminal or reboot, then rerun.
  exit /b 1
)
echo [OK] Python 3.12 installed and verified.
exit /b 0

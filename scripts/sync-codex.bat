@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
set "REPO_URL=https://github.com/jjfree/codexbackup.git"
set "DEFAULT_REPO_ROOT=%USERPROFILE%\Documents\Codex\codexbackup"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"
set "CODEX_HOME=%USERPROFILE%\.codex"
set "SNAPSHOT_HOME=%REPO_ROOT%\codex-home"
set "DEFAULT_PRIVATE_BACKUP=C:\envbk\codex-home-private"
set "LOG_DIR=%REPO_ROOT%\restore-logs"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%I"

for %%A in (%*) do (
  if /I "%%~A"=="/refresh-plugins" set "CODEX_REFRESH_PLUGINS=1"
  if /I "%%~A"=="/no-install" set "CODEX_SKIP_INSTALL=1"
  if /I "%%~A"=="/skip-bootstrap" set "CODEX_SKIP_BOOTSTRAP=1"
  if /I "%%~A"=="/skip-git-pull" set "CODEX_SKIP_GIT_PULL=1"
)

if not defined CODEX_SKIP_BOOTSTRAP (
  call :bootstrap_latest_repo %*
  exit /b !ERRORLEVEL!
)

echo ============================================================
echo Codex backup restore and sync
echo ============================================================
echo Repository: %REPO_ROOT%
echo Target Codex home: %CODEX_HOME%
echo.

if not defined CODEX_SKIP_INSTALL (
  call "%REPO_ROOT%\scripts\install-prereqs.bat"
  if errorlevel 1 (
    echo [ERROR] Prerequisite installation failed. Sync stopped.
    exit /b 1
  )
) else (
  echo [INFO] /no-install selected. Skipping prerequisite installer.
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%CODEX_HOME%" mkdir "%CODEX_HOME%"

call :backup_file "%CODEX_HOME%\config.toml"
if errorlevel 1 exit /b %ERRORLEVEL%
call :backup_file "%CODEX_HOME%\AGENTS.md"
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo [STEP] Restoring versioned Codex settings
copy /Y "%SNAPSHOT_HOME%\config.toml" "%CODEX_HOME%\config.toml" >nul
if errorlevel 1 (
  echo [ERROR] Failed to copy config.toml.
  exit /b 1
)
copy /Y "%SNAPSHOT_HOME%\AGENTS.md" "%CODEX_HOME%\AGENTS.md" >nul
if errorlevel 1 (
  echo [ERROR] Failed to copy AGENTS.md.
  exit /b 1
)
echo [OK] config.toml and AGENTS.md restored.

if exist "%SNAPSHOT_HOME%\skills" (
  call :sync_dir "%SNAPSHOT_HOME%\skills" "%CODEX_HOME%\skills" "user skills"
  if errorlevel 1 exit /b !ERRORLEVEL!
)

if exist "%SNAPSHOT_HOME%\rules" (
  call :sync_dir "%SNAPSHOT_HOME%\rules" "%CODEX_HOME%\rules" "rules"
  if errorlevel 1 exit /b !ERRORLEVEL!
)

if exist "%SNAPSHOT_HOME%\memories" (
  call :sync_dir "%SNAPSHOT_HOME%\memories" "%CODEX_HOME%\memories" "memories"
  if errorlevel 1 exit /b !ERRORLEVEL!
)

if not defined SOURCE_CODEX_HOME (
  if exist "%DEFAULT_PRIVATE_BACKUP%" (
    set "SOURCE_CODEX_HOME=%DEFAULT_PRIVATE_BACKUP%"
    echo.
    echo [INFO] Found default private backup: %DEFAULT_PRIVATE_BACKUP%
  )
)

if defined SOURCE_CODEX_HOME (
  call :sync_private_codex_home "%SOURCE_CODEX_HOME%"
  if errorlevel 1 exit /b !ERRORLEVEL!
) else (
  echo.
  echo [INFO] SOURCE_CODEX_HOME is not set.
  echo        To restore private local history/auth from backup, place it at:
  echo        %DEFAULT_PRIVATE_BACKUP%
  echo        Or rerun with:
  echo        set SOURCE_CODEX_HOME=E:\codex-home-private
  echo        scripts\sync-codex.bat /no-install
)

call :refresh_plugins_from_config
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo [OK] Codex restore and sync completed.
echo [NEXT] Open Codex. It should read config.toml and install/enable the configured plugins.
echo        If this is the first run on the target computer, sign in again to GitHub, Google Drive, Figma, and Linear.
exit /b 0

:bootstrap_latest_repo
echo ============================================================
echo Codex backup bootstrap
echo ============================================================
echo.

set "FULL_REPO=0"
if exist "%REPO_ROOT%\.git" if exist "%REPO_ROOT%\codex-home\config.toml" if exist "%REPO_ROOT%\scripts\install-prereqs.bat" set "FULL_REPO=1"

call :ensure_bootstrap_git
if errorlevel 1 exit /b !ERRORLEVEL!

if "%FULL_REPO%"=="1" (
  echo [STEP] Updating existing codexbackup repository: %REPO_ROOT%
  if defined CODEX_SKIP_GIT_PULL (
    echo [INFO] /skip-git-pull selected. Repository update skipped.
  ) else (
    call :pull_repo "%REPO_ROOT%"
    if errorlevel 1 exit /b !ERRORLEVEL!
  )
  echo [STEP] Restarting latest sync script from repository.
  call "%REPO_ROOT%\scripts\sync-codex.bat" /skip-bootstrap /skip-git-pull %*
  exit /b !ERRORLEVEL!
)

echo [INFO] This script is not running from a full git checkout.
echo [INFO] Repository will be cloned or updated at:
echo        %DEFAULT_REPO_ROOT%
echo.

if exist "%DEFAULT_REPO_ROOT%\.git" (
  if defined CODEX_SKIP_GIT_PULL (
    echo [INFO] /skip-git-pull selected. Existing repository update skipped.
  ) else (
    call :pull_repo "%DEFAULT_REPO_ROOT%"
    if errorlevel 1 exit /b !ERRORLEVEL!
  )
) else (
  if exist "%DEFAULT_REPO_ROOT%" (
    echo [ERROR] %DEFAULT_REPO_ROOT% exists but is not a git repository.
    echo         Move it aside or remove it, then rerun this script.
    exit /b 1
  )
  for %%I in ("%DEFAULT_REPO_ROOT%\..") do set "DEFAULT_REPO_PARENT=%%~fI"
  if not exist "!DEFAULT_REPO_PARENT!" mkdir "!DEFAULT_REPO_PARENT!"
  if errorlevel 1 (
    echo [ERROR] Failed to create !DEFAULT_REPO_PARENT!.
    exit /b 1
  )
  echo [STEP] Cloning %REPO_URL%
  git clone "%REPO_URL%" "%DEFAULT_REPO_ROOT%"
  if errorlevel 1 (
    echo [ERROR] Failed to clone %REPO_URL%.
    exit /b 1
  )
)

if not exist "%DEFAULT_REPO_ROOT%\scripts\sync-codex.bat" (
  echo [ERROR] Cloned repository does not contain scripts\sync-codex.bat.
  exit /b 1
)

echo [STEP] Starting repository sync script.
call "%DEFAULT_REPO_ROOT%\scripts\sync-codex.bat" /skip-bootstrap /skip-git-pull %*
exit /b !ERRORLEVEL!

:ensure_bootstrap_git
if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "PATH=%ProgramFiles(x86)%\Git\cmd;%PATH%"
if exist "%LocalAppData%\Microsoft\WindowsApps\winget.exe" set "PATH=%LocalAppData%\Microsoft\WindowsApps;%PATH%"

where git >nul 2>&1
if not errorlevel 1 (
  git --version
  echo [OK] Git is available.
  exit /b 0
)

echo [STEP] Git was not found. Installing Git first so the repository can be cloned or pulled.
where winget >nul 2>&1
if errorlevel 1 (
  echo [ERROR] winget was not found. Install "App Installer" from Microsoft Store, then rerun this script.
  exit /b 1
)

winget install --exact --id Git.Git --accept-package-agreements --accept-source-agreements --silent
if errorlevel 1 (
  echo [ERROR] Failed to install Git.Git via winget.
  exit /b 1
)

if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "PATH=%ProgramFiles(x86)%\Git\cmd;%PATH%"

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Git was installed but is still not on PATH. Restart terminal or reboot, then rerun this script.
  exit /b 1
)

git --version
echo [OK] Git installed and verified.
exit /b 0

:pull_repo
set "TARGET_REPO=%~1"
echo [STEP] Pulling latest main branch in %TARGET_REPO%
git -C "%TARGET_REPO%" remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [ERROR] %TARGET_REPO% has no usable origin remote.
  exit /b 1
)

git -C "%TARGET_REPO%" fetch origin main
if errorlevel 1 (
  echo [ERROR] Failed to fetch origin/main.
  exit /b 1
)

git -C "%TARGET_REPO%" checkout main
if errorlevel 1 (
  echo [ERROR] Failed to checkout main branch.
  exit /b 1
)

git -C "%TARGET_REPO%" pull --ff-only origin main
if errorlevel 1 (
  echo [ERROR] Failed to fast-forward pull origin/main.
  echo         Resolve local repo changes or reclone the repository, then rerun.
  exit /b 1
)
echo [OK] Repository is up to date.
exit /b 0

:backup_file
set "FILE=%~1"
if exist "%FILE%" (
  copy /Y "%FILE%" "%FILE%.before-codexbackup-%STAMP%.bak" >nul
  if errorlevel 1 (
    echo [ERROR] Failed to back up %FILE%.
    exit /b 1
  )
  echo [OK] Backed up %FILE%.
)
exit /b 0

:sync_dir
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"
echo.
echo [STEP] Comparing %LABEL%
robocopy "%SRC%" "%DST%" /E /L /NJH /NJS /NP /XD .sandbox .sandbox-secrets .tmp plugins\cache /XF auth.json cap_sid *.sqlite *.sqlite-shm *.sqlite-wal *.log .env .env.* > "%LOG_DIR%\compare-%LABEL%-%STAMP%.log"
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [ERROR] Robocopy compare failed for %LABEL%. Exit code: %RC%
  exit /b %RC%
)

echo [STEP] Syncing %LABEL%
robocopy "%SRC%" "%DST%" /E /NJH /NJS /NP /XD .sandbox .sandbox-secrets .tmp plugins\cache /XF auth.json cap_sid *.sqlite *.sqlite-shm *.sqlite-wal *.log .env .env.* > "%LOG_DIR%\sync-%LABEL%-%STAMP%.log"
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [ERROR] Robocopy sync failed for %LABEL%. Exit code: %RC%
  exit /b %RC%
)
echo [OK] %LABEL% synced. Compare and sync logs are in restore-logs.
exit /b 0

:sync_private_codex_home
set "SRC_HOME=%~1"
echo.
echo [STEP] Syncing private Codex data from %SRC_HOME%
if not exist "%SRC_HOME%" (
  echo [ERROR] SOURCE_CODEX_HOME does not exist: %SRC_HOME%
  exit /b 1
)

echo [WARN] Close Codex on both computers before syncing sessions or SQLite state.
call :sync_optional_dir "%SRC_HOME%\sessions" "%CODEX_HOME%\sessions" "sessions"
if errorlevel 1 exit /b !ERRORLEVEL!
call :sync_optional_dir "%SRC_HOME%\archived_sessions" "%CODEX_HOME%\archived_sessions" "archived-sessions"
if errorlevel 1 exit /b !ERRORLEVEL!
call :sync_optional_dir "%SRC_HOME%\memories" "%CODEX_HOME%\memories" "private-memories"
if errorlevel 1 exit /b !ERRORLEVEL!
call :sync_optional_dir "%SRC_HOME%\rules" "%CODEX_HOME%\rules" "private-rules"
if errorlevel 1 exit /b !ERRORLEVEL!
call :sync_optional_dir "%SRC_HOME%\skills" "%CODEX_HOME%\skills" "private-skills"
if errorlevel 1 exit /b !ERRORLEVEL!
call :sync_sensitive_optional_dir "%SRC_HOME%\.sandbox-secrets" "%CODEX_HOME%\.sandbox-secrets" "sandbox-secrets"
if errorlevel 1 exit /b !ERRORLEVEL!
call :sync_sensitive_optional_dir "%SRC_HOME%\cache" "%CODEX_HOME%\cache" "private-cache"
if errorlevel 1 exit /b !ERRORLEVEL!

for %%F in (auth.json cap_sid installation_id session_index.jsonl models_cache.json .codex-global-state.json .codex-global-state.json.bak logs_2.sqlite logs_2.sqlite-shm logs_2.sqlite-wal state_5.sqlite state_5.sqlite-shm state_5.sqlite-wal) do (
  if exist "%SRC_HOME%\%%F" (
    call :backup_file "%CODEX_HOME%\%%F"
    if errorlevel 1 exit /b !ERRORLEVEL!
    copy /Y "%SRC_HOME%\%%F" "%CODEX_HOME%\%%F" >nul
    if errorlevel 1 (
      echo [ERROR] Failed to sync %%F.
      exit /b 1
    )
    echo [OK] Synced %%F.
  )
)
exit /b 0

:sync_sensitive_optional_dir
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"
if exist "%SRC%" (
  call :sync_sensitive_dir "%SRC%" "%DST%" "%LABEL%"
  if errorlevel 1 exit /b !ERRORLEVEL!
) else (
  echo [INFO] Skipping missing optional sensitive directory: %SRC%
)
exit /b 0

:sync_sensitive_dir
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"
echo.
echo [STEP] Comparing %LABEL%
robocopy "%SRC%" "%DST%" /E /L /NJH /NJS /NP /XD plugins\cache .tmp tmp /XF *.log > "%LOG_DIR%\compare-%LABEL%-%STAMP%.log"
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [ERROR] Robocopy compare failed for %LABEL%. Exit code: %RC%
  exit /b %RC%
)

echo [STEP] Restoring %LABEL%
robocopy "%SRC%" "%DST%" /E /NJH /NJS /NP /XD plugins\cache .tmp tmp /XF *.log > "%LOG_DIR%\sync-%LABEL%-%STAMP%.log"
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [ERROR] Robocopy restore failed for %LABEL%. Exit code: %RC%
  exit /b %RC%
)
echo [OK] %LABEL% restored. Compare and sync logs are in restore-logs.
exit /b 0

:sync_optional_dir
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"
if exist "%SRC%" (
  call :sync_dir "%SRC%" "%DST%" "%LABEL%"
  if errorlevel 1 exit /b !ERRORLEVEL!
) else (
  echo [INFO] Skipping missing optional directory: %SRC%
)
exit /b 0

:refresh_plugins_from_config
echo.
echo [STEP] Checking plugin enablement from config.toml
findstr /R /C:"^\[plugins\." "%CODEX_HOME%\config.toml"
if errorlevel 1 (
  echo [ERROR] No [plugins.*] sections found in %CODEX_HOME%\config.toml.
  exit /b 1
)

if defined CODEX_REFRESH_PLUGINS (
  echo.
  echo [STEP] Preparing Codex plugin reinstall from config.toml
  if exist "%CODEX_HOME%\plugins\cache" (
    set "PLUGIN_BACKUP=%CODEX_HOME%\plugins\cache.before-refresh-%STAMP%"
    move "%CODEX_HOME%\plugins\cache" "!PLUGIN_BACKUP!" >nul
    if errorlevel 1 (
      echo [ERROR] Failed to move existing plugin cache.
      exit /b 1
    )
    echo [OK] Existing plugin cache moved to !PLUGIN_BACKUP!
  )
  mkdir "%CODEX_HOME%\plugins\cache" >nul 2>&1
) else (
  echo [INFO] Plugin cache was not moved. Add /refresh-plugins to force Codex to reinstall plugin cache.
)

call :launch_codex_for_plugins
exit /b 0

:launch_codex_for_plugins
echo.
echo [STEP] Launching Codex so it can install/enable plugins from config.toml
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cmd = Get-Command codex -ErrorAction SilentlyContinue; if ($cmd) { Start-Process -FilePath $cmd.Source; exit 0 } else { exit 2 }"
set "RC=%ERRORLEVEL%"
if "%RC%"=="2" (
  echo [WARN] Codex command was not found on PATH. Open Codex manually to complete plugin installation.
  exit /b 0
)
if not "%RC%"=="0" (
  echo [WARN] Codex launch failed. Open Codex manually to complete plugin installation.
  exit /b 0
)
echo [OK] Codex launch requested. Plugin installation happens inside Codex using config.toml.
exit /b 0

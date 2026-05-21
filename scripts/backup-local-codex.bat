@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "CODEX_HOME=%USERPROFILE%\.codex"
set "BACKUP_ROOT=C:\envbk"
set "BACKUP_HOME=%BACKUP_ROOT%\codex-home-private"
set "LOG_DIR=%BACKUP_ROOT%\logs"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%I"

echo ============================================================
echo Codex private local data backup
echo ============================================================
echo Source: %CODEX_HOME%
echo Target: %BACKUP_HOME%
echo.
echo [WARN] This backup may contain login tokens, connector auth state,
echo        conversation history, local prompts, and project metadata.
echo        Keep C:\envbk encrypted or offline.
echo.

if not exist "%CODEX_HOME%" (
  echo [ERROR] Codex home was not found: %CODEX_HOME%
  exit /b 1
)

if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"
if errorlevel 1 (
  echo [ERROR] Failed to create %BACKUP_ROOT%.
  exit /b 1
)

if not exist "%BACKUP_HOME%" mkdir "%BACKUP_HOME%"
if errorlevel 1 (
  echo [ERROR] Failed to create %BACKUP_HOME%.
  exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if errorlevel 1 (
  echo [ERROR] Failed to create %LOG_DIR%.
  exit /b 1
)

echo [STEP] Backing up Codex auth and token-bearing files
call :copy_optional_file auth.json
if errorlevel 1 exit /b !ERRORLEVEL!
call :copy_optional_file cap_sid
if errorlevel 1 exit /b !ERRORLEVEL!
call :copy_optional_file installation_id
if errorlevel 1 exit /b !ERRORLEVEL!
call :copy_optional_file .codex-global-state.json
if errorlevel 1 exit /b !ERRORLEVEL!
call :copy_optional_file .codex-global-state.json.bak
if errorlevel 1 exit /b !ERRORLEVEL!
call :copy_optional_file session_index.jsonl
if errorlevel 1 exit /b !ERRORLEVEL!
call :copy_optional_file models_cache.json
if errorlevel 1 exit /b !ERRORLEVEL!

echo.
echo [STEP] Backing up SQLite conversation/state databases
for %%F in (logs_2.sqlite logs_2.sqlite-shm logs_2.sqlite-wal state_5.sqlite state_5.sqlite-shm state_5.sqlite-wal) do (
  call :copy_optional_file %%F
  if errorlevel 1 exit /b !ERRORLEVEL!
)

echo.
echo [STEP] Backing up session and Codex state directories
call :backup_optional_dir sessions sessions
if errorlevel 1 exit /b !ERRORLEVEL!
call :backup_optional_dir archived_sessions archived_sessions
if errorlevel 1 exit /b !ERRORLEVEL!
call :backup_optional_dir memories memories
if errorlevel 1 exit /b !ERRORLEVEL!
call :backup_optional_dir rules rules
if errorlevel 1 exit /b !ERRORLEVEL!
call :backup_optional_dir skills skills
if errorlevel 1 exit /b !ERRORLEVEL!
call :backup_optional_dir .sandbox-secrets .sandbox-secrets
if errorlevel 1 exit /b !ERRORLEVEL!
call :backup_optional_dir cache cache
if errorlevel 1 exit /b !ERRORLEVEL!

echo.
echo [STEP] Writing backup manifest
(
  echo Codex private backup
  echo Created: %STAMP%
  echo Source: %CODEX_HOME%
  echo Target: %BACKUP_HOME%
  echo.
  echo Restore with:
  echo   set SOURCE_CODEX_HOME=%BACKUP_HOME%
  echo   scripts\sync-codex.bat /no-install /refresh-plugins
) > "%BACKUP_ROOT%\README-CODEX-PRIVATE-BACKUP.txt"
if errorlevel 1 (
  echo [ERROR] Failed to write backup manifest.
  exit /b 1
)

echo.
echo [OK] Codex private backup completed.
echo [NEXT] Copy or mount C:\envbk on the target computer before running sync-codex.bat.
exit /b 0

:copy_optional_file
set "NAME=%~1"
if exist "%CODEX_HOME%\%NAME%" (
  copy /Y "%CODEX_HOME%\%NAME%" "%BACKUP_HOME%\%NAME%" >nul
  if errorlevel 1 (
    echo [ERROR] Failed to copy %NAME%.
    exit /b 1
  )
  echo [OK] Copied %NAME%.
) else (
  echo [INFO] Missing optional file: %NAME%
)
exit /b 0

:backup_optional_dir
set "SRC_NAME=%~1"
set "DST_NAME=%~2"
if not exist "%CODEX_HOME%\%SRC_NAME%" (
  echo [INFO] Missing optional directory: %SRC_NAME%
  exit /b 0
)

echo [STEP] Backing up %SRC_NAME%
robocopy "%CODEX_HOME%\%SRC_NAME%" "%BACKUP_HOME%\%DST_NAME%" /E /R:2 /W:2 /NJH /NJS /NP /XD plugins\cache .tmp tmp /XF *.log > "%LOG_DIR%\backup-%DST_NAME%-%STAMP%.log"
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [ERROR] Robocopy backup failed for %SRC_NAME%. Exit code: %RC%
  echo         See %LOG_DIR%\backup-%DST_NAME%-%STAMP%.log
  exit /b %RC%
)
echo [OK] Backed up %SRC_NAME%.
exit /b 0

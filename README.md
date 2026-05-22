# Codex Backup And Restore

This repository restores a Windows Codex workstation from a source computer backup. It is designed for a second computer where Codex and Docker Desktop may already be installed.

Traditional Chinese version: [README.zh-TW.md](README.zh-TW.md)

The repo intentionally stores only safe, versionable configuration and scripts. It does not commit Codex login tokens, connector credentials, private `.env` files, or raw local conversation databases.

## What This Restores

- Windows prerequisites for Codex development work.
- WSL 2 and Ubuntu for Docker Desktop / Linux container workflows.
- Git, Node.js 22, npm, PowerShell 7, GitHub CLI, Python 3.12, and Docker Desktop.
- Codex `config.toml` with enabled plugins.
- Codex global `AGENTS.md`.
- User-installed Playwright CLI skill.
- Private local Codex backup export to `C:\envbk`.
- Optional local Codex history/state sync from a private backup path.

## Enabled Codex Plugins

The restored `config.toml` enables:

- Documents
- Spreadsheets
- Presentations
- GitHub
- Superpowers
- Figma
- Linear
- Google Drive
- Browser

Marketplace/runtime source paths are deliberately omitted because they are machine-local. Codex should recreate them on the target computer.

## Quick Start On The New Computer

Prerequisites before restore:

- Windows 10/11 with virtualization enabled in BIOS/UEFI.
- Codex app installed and launched at least once.
- Docker Desktop installed, or allow the installer to install/verify it.
- Internet access for `winget`, WSL, Docker, and Codex plugin/runtime downloads.
- Administrator terminal for WSL and Windows feature installation.
- Node.js must resolve to `v22.x`; the installer attempts `22.14.0` and stops if another major version is on PATH.
- If you need real login/session restoration, copy the old computer's `C:\envbk` folder to the new computer as `C:\envbk`.

Recommended restore order:

1. On the old computer, close Codex and run `scripts\backup-local-codex.bat`.
2. Copy `C:\envbk` to the new computer as `C:\envbk`.
3. On the new computer, download only `scripts\sync-codex.bat` from this repository.
4. Open an Administrator terminal in the folder containing the downloaded file.
5. Run `sync-codex.bat /refresh-plugins`.
6. Reboot if the WSL/VirtualMachinePlatform step asks for it, then rerun the same command.
7. Open Codex and sign in again if restored auth is rejected or connector sessions need re-consent.

If you want to download from a terminal, use:

```bat
curl.exe -L -o sync-codex.bat https://raw.githubusercontent.com/jjfree/codexbackup/main/scripts/sync-codex.bat
sync-codex.bat /refresh-plugins
```

The sync script first bootstraps Git, clones or pulls this repository into `%USERPROFILE%\Documents\Codex\codexbackup`, then runs the latest repository copy of `scripts\sync-codex.bat`. After that it runs `scripts\install-prereqs.bat`. Each package is installed and verified before the next package starts. If any step fails, the script prints an error and stops.

After restoring the versioned Codex config and any private local state, the sync script adapts source-machine project paths from `C:\Users\<source-user>` to the current Windows `%USERPROFILE%`, adds the checked-out `codexbackup` repository as a trusted project, and creates missing trusted project directories so restored conversations do not open with a missing-working-directory error. If a project lives somewhere other than the same relative path under your profile, update that project entry manually after restore.

Because private restore overwrites Codex auth/session/SQLite files, close Codex before running the restore when you are restoring `C:\envbk`. If you use Codex to coordinate the work on the new computer, have it prepare the command, then run the final restore from an Administrator terminal after closing Codex.

Use `/refresh-plugins` when you want Codex to rebuild plugin cache from `config.toml`. The script moves the existing plugin cache aside instead of deleting it, then launches Codex so the app can install/enable the configured plugins.

Codex plugin installation is completed by the Codex app itself. The script's job is to restore `config.toml`, optionally move old plugin cache aside, and launch Codex so it can reinstall and enable the plugins declared in `[plugins.*]`.

Use `/no-install` when prerequisites are already handled:

```bat
scripts\sync-codex.bat /no-install /refresh-plugins
```

## Back Up The Old Computer's Private Codex Data

On the old computer, close Codex first, then run:

```bat
scripts\backup-local-codex.bat
```

If Windows blocks creating `C:\envbk`, rerun the terminal as Administrator.

The backup script treats `auth.json`, `.codex-global-state.json`, `session_index.jsonl`, `logs_2.sqlite`, and `state_5.sqlite` as required. If any required file is missing, the script stops instead of producing a misleading partial backup.

This exports private Codex data to:

```text
C:\envbk\codex-home-private
```

After a successful backup, the script opens `C:\envbk\codex-home-private` in Windows Explorer so you can inspect or copy the backup folder.

The backup includes real local state such as:

- `auth.json`
- `cap_sid`
- `installation_id`
- `.codex-global-state.json`
- `session_index.jsonl`
- `models_cache.json`
- `logs_2.sqlite*`
- `state_5.sqlite*`
- `sessions`
- `archived_sessions`
- `memories`
- `rules`
- `skills`
- `.sandbox-secrets`
- `cache`

Treat `C:\envbk` as sensitive. It may contain login tokens, connector auth state, prompt history, local conversation DBs, and project metadata. Store it on BitLocker, an encrypted archive, or trusted offline media.

## Optional Private Codex History Sync

If `C:\envbk\codex-home-private` exists on the new computer, `scripts\sync-codex.bat` automatically restores it. You can also provide another backup path:

```bat
set SOURCE_CODEX_HOME=E:\codex-home-private
scripts\sync-codex.bat /no-install /refresh-plugins
```

This can sync:

- `auth.json`
- `cap_sid`
- `installation_id`
- `sessions`
- `archived_sessions`
- `memories`
- `rules`
- `skills`
- `.sandbox-secrets`
- `cache`
- `session_index.jsonl`
- `models_cache.json`
- `.codex-global-state.json`
- `logs_2.sqlite*`
- `state_5.sqlite*`

This private restore intentionally includes Codex auth/session files when they exist in the private backup. It still avoids project `.env` files and plugin cache.

## Sensitive Data Boundary

Do not commit:

- `%USERPROFILE%\.codex\auth.json`
- `%USERPROFILE%\.codex\cap_sid`
- `%USERPROFILE%\.codex\.sandbox-secrets`
- project `.env` files
- API keys, cookies, tokens, or connector credentials
- unencrypted private conversation/state backups

If you do not restore `C:\envbk`, sign in again on the target computer for Codex, GitHub, Google Drive, Figma, Linear, and other connectors. Even with `C:\envbk`, some connector sessions may still require re-consent on the new machine.

## WSL 2 Notes

WSL 2 is included because Docker Desktop on Windows commonly uses the WSL 2 backend for Linux containers. The installer enables:

- `Microsoft-Windows-Subsystem-Linux`
- `VirtualMachinePlatform`
- WSL default version 2
- Ubuntu WSL distribution

If Windows reports that a reboot is required after enabling a feature, the script stops and asks you to reboot before continuing. That is expected.

## Project Notes

`New project 3` / `unitrade-api` requires Python `>=3.11,<3.13`. The installer therefore installs Python 3.12 even if another Python version exists.

Project source code should still be restored through Git remotes or separate project backups. This repository restores the Codex workstation environment, not every project working tree.

# Codex Backup And Restore

This repository restores a Windows Codex workstation close to James's current setup. It is designed for a second computer where Codex and Docker Desktop may already be installed.

The repo intentionally stores only safe, versionable configuration and scripts. It does not commit Codex login tokens, connector credentials, private `.env` files, or raw local conversation databases.

## What This Restores

- Windows prerequisites for Codex development work.
- WSL 2 and Ubuntu for Docker Desktop / Linux container workflows.
- Git, Node.js LTS, npm, PowerShell 7, GitHub CLI, Python 3.12, and Docker Desktop.
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
- If you need real login/session restoration, copy the old computer's `C:\envbk` folder to the new computer as `C:\envbk`.

Recommended restore order:

1. On the old computer, close Codex and run `scripts\backup-local-codex.bat`.
2. Copy `C:\envbk` to the new computer as `C:\envbk`.
3. On the new computer, clone this repository.
4. Open an Administrator terminal in the repository.
5. Run `scripts\sync-codex.bat /refresh-plugins`.
6. Reboot if the WSL/VirtualMachinePlatform step asks for it, then rerun the same command.
7. Open Codex and sign in again if restored auth is rejected or connector sessions need re-consent.

Open an Administrator terminal from this repo and run:

```bat
scripts\sync-codex.bat /refresh-plugins
```

The sync script first runs `scripts\install-prereqs.bat`. Each package is installed and verified before the next package starts. If any step fails, the script prints an error and stops.

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

This exports private Codex data to:

```text
C:\envbk\codex-home-private
```

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

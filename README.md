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

## Optional Private Codex History Sync

If you have an encrypted or external backup of the old `%USERPROFILE%\.codex`, close Codex on both machines, then run:

```bat
set SOURCE_CODEX_HOME=E:\codex-private-backup\.codex
scripts\sync-codex.bat /no-install /refresh-plugins
```

This can sync:

- `sessions`
- `archived_sessions`
- `memories`
- `rules`
- `skills`
- `session_index.jsonl`
- `models_cache.json`
- `.codex-global-state.json`
- `logs_2.sqlite*`
- `state_5.sqlite*`

It excludes common secrets such as `auth.json`, `cap_sid`, `.sandbox-secrets`, `.env`, and plugin cache.

## Sensitive Data Boundary

Do not commit:

- `%USERPROFILE%\.codex\auth.json`
- `%USERPROFILE%\.codex\cap_sid`
- `%USERPROFILE%\.codex\.sandbox-secrets`
- project `.env` files
- API keys, cookies, tokens, or connector credentials
- unencrypted private conversation/state backups

Sign in again on the target computer for Codex, GitHub, Google Drive, Figma, Linear, and other connectors.

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

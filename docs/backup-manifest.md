# Backup Manifest

This repo separates safe, versioned restore data from private, local-only Codex data.

## Versioned In This Repository

- `codex-home/config.toml`
  - Model and reasoning preferences.
  - Enabled plugin list.
  - Windows sandbox preference.
  - Source-machine trusted project paths for reference.
- `codex-home/AGENTS.md`
  - Global Codex operating instructions.
- `codex-home/skills/playwright`
  - User-installed Playwright CLI skill.
- `scripts/install-prereqs.bat`
  - Sequential Windows prerequisite installer.
- `scripts/sync-codex.bat`
  - Restore/sync entrypoint for the target computer.
- `scripts/adapt-codex-config.ps1`
  - Rewrites restored source-machine Codex project paths for the current Windows profile and trusts the local `codexbackup` checkout.
- `scripts/backup-local-codex.bat`
  - Local-only exporter for sensitive Codex auth/session/SQLite data.
- `docs/environment-inventory.md`
  - Observed source-machine environment.

## Private Backup Location

Run `scripts\backup-local-codex.bat` on the old computer to export sensitive local Codex data to:

- `C:\envbk\codex-home-private`

Move or mount `C:\envbk` on the new computer before running `scripts\sync-codex.bat`.

## Not Versioned

These are deliberately excluded from GitHub:

- `auth.json`
- `cap_sid`
- `installation_id`
- `.sandbox-secrets`
- project `.env` files
- plugin cache
- unencrypted private backups

## Optional Private Sync

`scripts/sync-codex.bat` can sync private local Codex state from `SOURCE_CODEX_HOME` when you provide a trusted local or external backup path.

Potential private sync items:

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

Close Codex before syncing SQLite files.

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
- `docs/environment-inventory.md`
  - Observed source-machine environment.

## Not Versioned

These are deliberately excluded from GitHub:

- `auth.json`
- `cap_sid`
- `.sandbox-secrets`
- project `.env` files
- plugin cache
- unencrypted private backups

## Optional Private Sync

`scripts/sync-codex.bat` can sync private local Codex state from `SOURCE_CODEX_HOME` when you provide a trusted local or external backup path.

Potential private sync items:

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

Close Codex before syncing SQLite files.

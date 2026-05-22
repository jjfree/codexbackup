# Codex Environment Inventory

Snapshot date: 2026-05-21

## Codex Preferences

- Model: `gpt-5.5`
- Reasoning effort: `high`
- Windows sandbox: `elevated`

## Enabled Plugins

- `documents@openai-primary-runtime`
- `spreadsheets@openai-primary-runtime`
- `presentations@openai-primary-runtime`
- `github@openai-curated`
- `superpowers@openai-curated`
- `figma@openai-curated`
- `linear@openai-curated`
- `google-drive@openai-curated`
- `browser@openai-bundled`

## Local Toolchain Observed On Source Machine

- Node.js: `v22.14.0`
- npm: `10.9.2`
- Git: `2.49.0.windows.1`
- Docker: `29.4.3`
- Python default: `3.13.3`
- PowerShell: `7.5.5`
- GitHub CLI: `2.92.0`

## Extra Toolchain Requirement

`New project 3` / `unitrade-api` requires Python `>=3.11,<3.13`, so install Python `3.12.x` on the target computer even if Python 3.13 is present.

## Trusted Projects From Source Config

Source-machine trusted project paths are machine-specific and are intentionally not listed here for sharing. During restore, `scripts/sync-codex.bat` detects source profile paths such as `C:\Users\<source-user>\...`, rewrites them to the target computer's `%USERPROFILE%`, and trusts the local `codexbackup` checkout. Update any project entries manually if their relative locations differ on the target computer.

# Development Notes

## Restored Codex Project Paths Are Machine-Specific

- Symptom: Codex opens or trusts the wrong workspace after restore, or source-machine project paths such as `C:\Users\James\...` remain in `%USERPROFILE%\.codex\config.toml`.
- Root cause: Codex project trust entries are absolute Windows paths, while this backup is restored on computers with different user profiles or checkout locations.
- Fix: `scripts\sync-codex.bat` runs `scripts\adapt-codex-config.ps1` after restoring `config.toml`; the helper rewrites the source user profile prefix to the current `%USERPROFILE%` and adds the local `codexbackup` checkout as trusted.
- Verification: Run the adapter against a copied config and confirm project headers use the current profile plus the local `codexbackup` path.

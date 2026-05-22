# Development Notes

## Restored Codex Project Paths Are Machine-Specific

- Symptom: Codex opens or trusts the wrong workspace after restore, or source-machine project paths such as `C:\Users\<source-user>\...` remain in `%USERPROFILE%\.codex\config.toml`.
- Root cause: Codex project trust entries are absolute Windows paths, while this backup is restored on computers with different user profiles or checkout locations.
- Fix: `scripts\sync-codex.bat` runs `scripts\adapt-codex-config.ps1` after restoring config and private state; the helper rewrites the source user profile prefix to the current `%USERPROFILE%`, adds the local `codexbackup` checkout as trusted, repairs restored session/global-state paths, and creates missing trusted project directories.
- Verification: Run the adapter against a copied config/state fixture and confirm project headers, session paths, and global-state paths use the current profile plus the local `codexbackup` path.

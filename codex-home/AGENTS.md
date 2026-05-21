## Learning from Development Issues

When a repeated or environment-specific issue appears during development, testing, linting, CI, dependency installation, local setup, or debugging, capture the lesson when it is likely to recur.

In the final response, include a brief note with:

- Symptom
- Root cause
- Fix
- Verification
- Whether this should be remembered

If the issue is stable and likely to recur in this repo, propose adding it to `AGENTS.md` or `docs/dev-notes.md`.

Prefer concise memory candidates for stable lessons, especially:

- required environment variables
- package manager constraints
- known flaky tests
- required service startup order
- CI-specific gotchas
- platform-specific setup issues
- dependency/version incompatibilities
- local tooling limitations

Only propose memory for issues that are stable, actionable, and likely to save future debugging time.

Do not store secrets, tokens, credentials, private customer data, or one-off temporary errors as memories.

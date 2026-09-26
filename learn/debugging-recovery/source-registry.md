# Source registry — debugging-recovery

Priority order (canonical facts come only from tiers 1–3):

1. **Official vendor or specification documentation**
2. **Official related product documentation** (not marketing copy)
3. **Cross-tool practice guidance** — always labeled as guidance, never as vendor fact
4. Third-party tutorials — teaching questions only, **never** canonical facts.

## Registered sources

Generated from each page's `official_sources` front matter.

| Source | Pages |
|---|---|
| <https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html> | `ask-for-help` |
| <n/a -- cross-tool practice> | `ask-for-help` |
| <https://git-scm.com/docs/git-bisect> | `bisect-and-blame` |
| <https://docs.python.org/3/tutorial/errors.html> | `read-error-messages` |

## Context7 libraries

Pages record their own `context7_library` and stored `context7_queries` in front matter
so refresh checks are reproducible. Libraries used in this module: `/websites/git-scm`.

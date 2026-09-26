# Source registry — testing-basics

Priority order (canonical facts come only from tiers 1–3):

1. **Official vendor or specification documentation**
2. **Official related product documentation** (not marketing copy)
3. **Cross-tool practice guidance** — always labeled as guidance, never as vendor fact
4. Third-party tutorials — teaching questions only, **never** canonical facts.

## Registered sources

Generated from each page's `official_sources` front matter.

| Source | Pages |
|---|---|
| <https://docs.pytest.org/en/stable/how-to/usage.html> | `fix-one-failure` |
| <https://docs.pytest.org/en/stable/reference/exit-codes.html> | `run-tests-locally` |
| <https://pester.dev/docs/quick-start> | `run-tests-locally` |
| <https://pester.dev/docs/commands/Invoke-Pester> | `run-tests-locally` |
| <https://docs.pytest.org/en/stable/> | `why-tests-exist` |

## Context7 libraries

Pages record their own `context7_library` and stored `context7_queries` in front matter
so refresh checks are reproducible. Libraries used in this module: `/websites/pytest_en_stable`.

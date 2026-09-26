# Source registry — agentic-automation

Priority order (canonical facts come only from tiers 1–3):

1. **Official vendor or specification documentation**
2. **Official related product documentation** (not marketing copy)
3. **Cross-tool practice guidance** — always labeled as guidance, never as vendor fact
4. Third-party tutorials — teaching questions only, **never** canonical facts.

## Registered sources

Generated from each page's `official_sources` front matter.

| Source | Pages |
|---|---|
| <https://code.claude.com/docs/en/hooks> | `agent-lifecycle-hooks`, `agentic-loop-vs-code-loop`, `give-every-loop-an-exit`, `headless-noninteractive-mode`, `hook-feedback-loop-risk`, `hooks-as-gates`, `human-approval-gates`, `idempotency-safe-to-rerun`, `loop-hook-schedule-triggers` |
| <https://git-scm.com/docs/githooks> | `agentic-loop-vs-code-loop`, `cost-and-observability`, `git-hooks-101`, `loop-hook-schedule-triggers`, `server-side-git-hooks`, `shared-hooks-and-hookspath` |
| <https://docs.github.com> | `cost-and-observability` |
| <https://code.claude.com/docs> | `cost-and-observability` |
| <https://docs.github.com/en/actions/reference/events-that-trigger-workflows> | `cron-five-fields` |
| <https://man7.org/linux/man-pages/man5/crontab.5.html> | `cron-five-fields` |
| <https://code.claude.com/docs/> | `give-every-loop-an-exit` |
| <https://docs.github.com/> | `human-approval-gates` |
| <https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2> | `idempotency-safe-to-rerun` |
| <https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows> | `idempotency-safe-to-rerun`, `manual-one-off-triggers`, `schedule-reality-checks` |
| <https://docs.github.com/en/actions> | `loop-hook-schedule-triggers`, `the-kill-switch` |
| <https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow> | `manual-one-off-triggers` |
| <https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs> | `overlap-and-concurrency` |
| <https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/canceling-a-workflow> | `overlap-and-concurrency` |
| <https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions> | `runaway-loop-and-timeouts` |
| <https://code.claude.com/docs/en/headless> | `runaway-loop-and-timeouts` |
| <https://crontab.guru> | `schedule-reality-checks` |
| <https://docs.github.com/actions/using-workflows/events-that-trigger-workflows> | `scheduled-workflows-github-actions` |
| <https://pre-commit.com> | `shared-hooks-and-hookspath` |

## Context7 libraries

Pages record their own `context7_library` and stored `context7_queries` in front matter
so refresh checks are reproducible. Libraries used in this module: `/websites/git-scm`, `/websites/github_en_actions`, `/websites/platform_claude_en`.

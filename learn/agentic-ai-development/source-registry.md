# Source registry — agentic-ai-development

Priority order (canonical facts come only from tiers 1–3):

1. **Official vendor or specification documentation**
2. **Official related product documentation** (not marketing copy)
3. **Cross-tool practice guidance** — always labeled as guidance, never as vendor fact
4. Third-party tutorials — teaching questions only, **never** canonical facts.

## Registered sources

Generated from each page's `official_sources` front matter.

| Source | Pages |
|---|---|
| <https://platform.claude.com/docs/en/test-and-evaluate/develop-tests> | `agent-evals` |
| <https://agents.md> | `agent-to-agent-handoff` |
| <https://docs.github.com/en/copilot> | `background-agents-and-ci` |
| <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches> | `background-agents-and-ci` |
| <https://git-scm.com/docs/git-commit> | `checkpoints-and-rollback-for-agent-work` |
| <https://git-scm.com/docs/git-stash> | `checkpoints-and-rollback-for-agent-work` |
| <https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls> | `codebase-retrieval-hybrid-search`, `prompt-injection-and-lethal-trifecta`, `reading-agent-traces`, `tool-and-schema-design` |
| <https://platform.claude.com/docs/en/build-with-claude/compaction> | `context-engineering-and-window-management`, `persistent-agent-memory` |
| <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices> | `context-engineering-and-window-management`, `hitl-interruption-and-steering`, `model-routing-and-cost-tiers`, `multi-agent-orchestration-tradeoffs`, `spec-driven-plan-first-development`, `verification-first-loops` |
| <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5> | `context-engineering-and-window-management`, `multi-agent-orchestration-tradeoffs` |
| <https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks> | `prompt-injection-and-lethal-trifecta`, `sandboxing-and-least-privilege` |
| <https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool> | `prompt-injection-and-lethal-trifecta`, `sandboxing-and-least-privilege` |
| <https://genai.owasp.org/> | `prompt-injection-and-lethal-trifecta` |
| <https://agents.md/> | `repo-instruction-files` |
| <https://code.claude.com/docs> | `repo-instruction-files` |
| <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview> | `reviewing-agent-generated-code` |
| <https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html> | `secrets-and-data-hygiene-for-agent-context` |

## Context7 libraries

Pages record their own `context7_library` and stored `context7_queries` in front matter
so refresh checks are reproducible. Libraries used in this module: `/websites/git-scm`, `/websites/platform_claude_en`.

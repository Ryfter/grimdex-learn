# Source registry — prompt-engineering

Priority order (canonical facts come only from tiers 1–3):

1. **Official Anthropic platform docs** — <https://platform.claude.com/docs> (context
   windows, prompt engineering, messages API, glossary)
2. **Official related product docs** — same platform docs for best-practice pages that
   state provider behavior (not marketing copy)
3. **Cross-tool craft guidance** — practice patterns for agents and verification, always
   labeled as guidance rather than vendor fact
4. Third-party tutorials — teaching questions only, **never** canonical facts.

## Registered sources

| Source | Kind | Used for |
|---|---|---|
| <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview> | Official platform docs | Prerequisites for prompt work (success criteria, testing) |
| <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices> | Official platform docs | Clear/direct instructions, reasons, scope constraints |
| <https://platform.claude.com/docs/en/build-with-claude/context-windows> | Official platform docs | Context window accumulation per turn |
| <https://platform.claude.com/docs/en/about-claude/glossary> | Official platform docs | Context window as working memory |
| <https://platform.claude.com/docs/en/build-with-claude/working-with-messages> | Official platform docs | Stateless API; history re-sent each request |

## Context7 libraries

Pages record their own `context7_library` and stored `context7_queries` in front matter
so refresh checks are reproducible. Official page links in every page are direct links,
never search URLs. Primary library for this module: `/websites/platform_claude_en`.

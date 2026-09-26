# Agentic AI development practices

This is a **Learn module**: essentials-depth explainers any Grimdex user can install to
learn while building. It is not course material — anything course-scented lives in
`course/`, never here.

## What this module is

- One page per capability in `capabilities/*.md`, each following the frozen D32 page
  contract (YAML front matter + eleven fixed sections).
- Sources, refresh rules, and provenance are documented in `source-registry.md`,
  `refresh-policy.md`, and `provenance.md`.
- Depth discipline: pages stop at what/why plus a bit of how, then link to official
  documentation.

## Content admission

Every page passes the content-admission test before it lands: useful without any
specific course or professor; public-ready from its first reviewed version; claims about
vendor behavior are version-stamped and source-linked; provenance is honest; the module
is removable via `learn/manifest.json`.

## Pages (19)

- `capabilities/agent-evals.md` — Agent evals: measuring non-deterministic quality over time
- `capabilities/agent-to-agent-handoff.md` — Agent-to-agent handoff protocols (recognition level)
- `capabilities/background-agents-and-ci.md` — Background and autonomous agents in CI (issue-to-PR patterns)
- `capabilities/checkpoints-and-rollback-for-agent-work.md` — Checkpoints, diffs, and rollback for agent work
- `capabilities/codebase-retrieval-hybrid-search.md` — Codebase retrieval -- hybrid search vs. naive RAG
- `capabilities/context-engineering-and-window-management.md` — Context engineering and window management
- `capabilities/hitl-interruption-and-steering.md` — Human-in-the-loop interruption and steering
- `capabilities/model-routing-and-cost-tiers.md` — Model routing and cost-tier optimization
- `capabilities/multi-agent-orchestration-tradeoffs.md` — Multi-agent orchestration -- the honest tradeoffs
- `capabilities/persistent-agent-memory.md` — Persistent agent memory vs. working context
- `capabilities/prompt-injection-and-lethal-trifecta.md` — Indirect prompt injection and the "lethal trifecta"
- `capabilities/reading-agent-traces.md` — Reading and debugging an agent's trace
- `capabilities/repo-instruction-files.md` — Repo instruction files: AGENTS.md, CLAUDE.md, and rules files
- `capabilities/reviewing-agent-generated-code.md` — Reviewing agent-generated code and staying accountable
- `capabilities/sandboxing-and-least-privilege.md` — Sandboxing and least privilege for agents
- `capabilities/secrets-and-data-hygiene-for-agent-context.md` — Secrets and data hygiene for agent context
- `capabilities/spec-driven-plan-first-development.md` — Spec-driven and plan-first development
- `capabilities/tool-and-schema-design.md` — Tool and schema design: tool descriptions are prompts
- `capabilities/verification-first-loops.md` — Verification-first loops: sensors and closed-loop harnesses

Each page lists its own prerequisites and related capabilities.

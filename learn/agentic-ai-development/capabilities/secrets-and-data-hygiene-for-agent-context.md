---
title: Secrets and data hygiene for agent context
module_id: agentic-ai-development
capabilities:
  - secrets-and-data-hygiene-for-agent-context
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I keep API keys and credentials out of an AI coding agent's context window?
  - Is there an agent-specific ignore file separate from .gitignore for what an agent may read?
  - What files can an agent read that could accidentally leak secrets into its context?
official_sources:
  - https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: practice-guidance-with-official-anchors
---

## What it is

Secrets and data hygiene for agent context is the practice of keeping sensitive values — API keys, credentials, tokens, private customer data — out of what an AI coding agent reads and carries in its context window.

This has two layers:

1. **The general layer:** secrets should never live in your repository at all. This is ordinary, pre-AI secret hygiene — keep credentials in environment variables or a secrets manager, never committed to git. That discipline is covered fully in the dev-tooling-literacy module's **dotenv-and-secrets** lesson; this page does not repeat it.
2. **The agent-context-specific layer (the focus of this page):** even with secrets out of git, an agent's *context window* is its own exposure surface. An agent's context can include file contents — whatever the agent reads while working. So a secret sitting in a local file the repo doesn't track (an uncommitted `.env`, a config file in your home directory, a notes file) can still be pulled into the agent's context if the agent reads that file or a directory containing it. Once a secret is in the agent's context, it can be echoed back into generated code, logs, or tool calls — places it was never meant to go.

Because of this, some agent tools support an **agent-specific ignore mechanism**: a way to tell the agent what it is (and is not) allowed to read or include in context, separate from what git tracks. In other words, `.gitignore` answers "what goes in the repository"; an agent ignore mechanism answers "what the agent may look at." The two are complementary, not interchangeable — a file can be untracked by git and still be readable by an agent, which is exactly the gap this mechanism closes.

## When it is useful

- Any time an AI coding agent (or any agent that reads project files) works in a directory where credentials, tokens, or private data exist — even if those secrets are correctly kept out of git.
- When you keep secrets in untracked local files (the normal, correct pattern) and want to make sure the agent won't read them into its context anyway.
- When onboarding an agent to a project that contains sensitive configuration, customer data, or internal documents it has no business loading.
- When sharing recordings, logs, or traces of agent sessions — context hygiene done up front makes those artifacts safe to review and share.

## Prerequisites

- Familiarity with the general secrets discipline (dotenv-and-secrets lesson in the dev-tooling-literacy module): secrets live outside the codebase, in environment variables or a secrets manager.
- A working understanding that an agent's context window contains whatever the agent reads — files, tool results, command output — not just your prompts.

## Current syntax

There is no single universal syntax for agent-specific ignore mechanisms; this is cross-tool practice, and the exact file name and format depend on the tool you are using. The concept to learn is the *distinction*, not one file name:

- **Git tracking:** governed by `.gitignore` (general software practice — see the dotenv-and-secrets lesson).
- **Agent context:** governed by whatever ignore/exclude mechanism your agent tool provides, if it has one. Check your tool's official documentation for the exact mechanism and syntax — this page deliberately does not name specific flags or files, because they vary by vendor and change over time.

If your tool has no such mechanism, the fallback is the same discipline applied manually: keep secrets physically out of directories the agent will operate in, and scope the agent's working directory as narrowly as the task allows.

## What happens (local and remote)

**Without agent-context hygiene:** the agent reads a broad set of files to "understand the project." If an untracked `.env` or credential file is in scope, its contents enter the agent's context. From there the secret can surface in generated code, in tool invocations, in agent session logs, or in anything you later paste or share — even though git never saw it.

**With agent-context hygiene:** the agent-context ignore mechanism (or careful directory scoping) keeps credential files out of what the agent loads. The agent works from the code and configuration it's allowed to see; secrets stay outside its context entirely, in the environment where the application actually consumes them.

Note that this compounds with the general layer: if secrets are properly out of the codebase *and* out of the agent's readable scope, there is no path for them to leak through the agent at all.

## Practical example

A typical project layout:

```
my-app/
  .env            ← contains API keys (untracked by git — correct so far)
  .gitignore      ← lists .env, so git skips it — correct so far
  src/ ...
```

You start an AI coding agent in `my-app/` and ask it to fix a bug. The agent, doing its job, reads files to build context. If nothing stops it, it may read `.env` too — git's ignore rules do not apply to the agent, only to git. The API keys are now in the agent's context, and may reappear in generated code, an error message the agent writes, or a session log you later share with a colleague.

The agent-context fix: use your agent tool's ignore mechanism (per its documentation) to explicitly exclude `.env` and similar files from what the agent reads — *in addition to* the `.gitignore` entry that already keeps them out of git. The `.gitignore` line and the agent ignore entry do two different jobs; having only the first leaves the agent gap open.

If the tool offers no such mechanism, move the `.env` file (or the sensitive values) outside the directory the agent operates in, and keep only non-secret configuration inside it.

## Explanation guidance

### Essential

- An agent's context window can include file contents — anything the agent reads while working, not just what you type.
- Keeping secrets out of git is necessary but not sufficient: an untracked secret file can still be read by an agent.
- Some agent tools provide an agent-specific ignore mechanism — a rule for what the *agent* may read/include in context, separate from what git tracks. Learn where yours lives by checking the tool's official docs.
- The two mechanisms are complementary: `.gitignore` protects the repository; agent-context ignore protects the agent's context. Use both.
- The general "secrets out of the codebase" discipline is taught in the dotenv-and-secrets lesson (dev-tooling-literacy module); this page adds only the agent-specific layer on top.

### Experienced-user note

Think of it as two distinct trust boundaries with two distinct control surfaces: version control boundary (`.gitignore`, commit hygiene) and agent-context boundary (agent ignore rules, directory scoping). A file can pass the first boundary safely and still fail the second. When auditing a project for agent-readiness, walk both lists separately — the gaps are usually different. Also consider that agent session artifacts (traces, logs) inherit whatever the agent read, so context hygiene is also what makes those artifacts shareable.

### Optional deeper context

This pattern is likely to converge over time — as agent tools mature, agent-specific ignore mechanisms may become as standard as `.gitignore`. Until then, treat it as a per-tool configuration task: each tool's documentation is the source of truth for whether and how it supports restricting agent context. The underlying principle — separate trust boundaries need separate enforcement points — is durable even as the specific mechanisms evolve.

## Cautions and common failures

- **Assuming `.gitignore` protects the agent.** It does not. Git ignore rules govern version control, not what an agent reads. This is the single most common failure.
- **Assuming the agent is "smart enough" not to read secret files.** An agent exploring a project broadly may read credential files incidentally; don't rely on it filtering itself.
- **Secrets in untracked-but-readable places beyond `.env`:** local config files, shell histories, notes files, credential helpers' output files. Audit the whole working directory, not just the obvious file.
- **Pasting secrets into agent conversations.** Even with file hygiene perfect, manually pasting a key into a prompt puts it in context. Inject secrets via environment at runtime instead.
- **Sharing agent session logs or traces that captured secrets before hygiene was applied.** Scrub or regenerate them.
- **Treating agent ignore rules as a security boundary against a malicious actor.** They reduce accidental exposure; they are not a complete defense against an adversary deliberately inducing the agent to exfiltrate data. For that threat model, see sandboxing and least privilege (related capability below).

## Related capabilities

- **dev-tooling-literacy: dotenv-and-secrets** — the general secrets-out-of-the-codebase discipline this page builds on; read that first for the fundamentals.
- **sandboxing-and-least-privilege** — bounding what an agent can *do* complements bounding what it can *read*; both matter for the adversarial threat model.
- **verifying-agent-work** — if a secret did reach the agent's context, verification habits (checking the actual diff, not the agent's narration) are how you catch it appearing in output.

## Official sources

- <https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html> -- the general secrets-hygiene discipline (never commit credentials, rotate, scope access) that the agent-context-specific angle on this page extends.

This capability is documented as real, current cross-tool practice rather than a single vendor's specification. No single canonical official source covers the agent-context-specific ignore mechanism across vendors; consult your specific agent tool's official documentation for its exact mechanism and syntax.

## Provenance

The core claim here — that an agent's context window can include file contents, and that some tools support an agent-specific ignore mechanism separate from git tracking — is real, current cross-tool practice. There is no single settled vendor specification for agent-context ignore mechanisms; the exact file names and syntax vary by tool and should be confirmed against each tool's official docs. The general secrets discipline is cross-referenced to the dev-tooling-literacy module's dotenv-and-secrets lesson rather than restated here. No citations were invented to fill this gap.
---
title: "CLI tools: capabilities your agent already has"
module_id: agent-ecosystem
capabilities:
  - cli-tools-as-agent-capabilities
context7_library: /websites/platform_claude_en
context7_queries:
  - How does a coding agent use command-line tools installed on the machine?
  - How are shell tool permissions and allowlists configured for agents?
  - How do CLI tools compare to MCP servers as agent capabilities?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
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

The moment a coding agent can run a shell, every command-line program already installed on the machine becomes something the agent can use. Tools like `gh`, `aws`, `curl`, and `jq` stop being "utilities a human types into a terminal" and become agent capabilities: the agent can compose them, chain them, and apply them to whatever task it's working on, without anyone writing a custom integration for each one.

This is the source of both the power and the "wait, how did it do that?" moments people have with coding agents. An agent that fixes a bug, then runs the test suite, then opens a pull request with `gh` isn't doing anything mysterious — it's just invoking programs that were on the machine all along.

## When it is useful

- **Quick, one-off interactions with existing tooling.** If a well-established CLI already does the job, the agent can use it directly — no wrapper, plugin, or server needed.
- **Glue work.** Agents excel at chaining programs (`curl | jq | ...`) that a human would have to type out step by step.
- **Probing what's available.** Agents can discover what's installed (`which`, version checks) and adapt to the machine they're on.

It is less useful when a capability lives behind a remote service with no good CLI, or when you need typed, per-server access control — that's where MCP servers fit (see Related capabilities).

## Prerequisites

- A coding agent with shell/tool execution enabled (e.g. Claude Code).
- The relevant CLI programs installed and authenticated on the machine, with credentials configured the way you would for your own use.
- An understanding of how permission prompts and allowlists gate what the agent may run — see the cross-reference below.

## Current syntax

There is no special syntax for this capability. The agent invokes installed programs through its existing shell tool, using ordinary command-line syntax. Nothing needs to be registered, declared, or installed beyond the CLI programs themselves being present on the machine.

## What happens (local and remote)

Locally, the agent's shell tool executes the command as a subprocess on your machine, with your environment: your PATH, your config files, your credentials. That is why the agent "just knows" how to call `gh` — it reads the same help output and errors you would, and runs under the same accounts you have set up.

Remotely-significant effects follow from that: a command like `gh pr create` or `aws s3 cp` acts on remote services, but through the local CLI and the credentials stored on the machine. The agent never talks to the remote service directly; the CLI does.

## Practical example

Ask the agent to fix a failing test and open a PR. Without any custom integration, it can:

1. Run the test runner to reproduce the failure.
2. Edit the code and re-run tests until they pass.
3. Use `git` to branch and commit.
4. Use `gh` (authenticated on the machine) to push and open a pull request.

Each step is just an installed program the agent shell-execs. The novelty isn't a new protocol — it's that the agent can drive the toolchain you already have.

## Explanation guidance

### Essential

- **The core idea:** shell access turns the machine's existing CLI toolset into the agent's toolset. No per-tool integration work is required.
- **Why it can feel surprising:** the agent silently uses tools a person would have typed, so reviewers should expect to see `gh`, `curl`, `jq`, etc. in the agent's activity.
- **Safety lives in permissions, not in the tools themselves.** How to gate this is covered in the prompt-engineering module's `tools-and-agent-actions` lesson (permission prompts and allowlists) — apply those mechanisms here rather than treating CLI access as inherently safe or unsafe.
- **Credentials are shared.** The agent uses the same local credentials you use, so what it can do with a CLI is roughly what you can do with that CLI.

### Experienced-user note

- **CLI vs. MCP is a real tradeoff, not a rule.** A CLI gives the agent unstructured text it must interpret; an MCP server gives self-described, typed tools with per-server allow/deny control and avoids spreading local credentials across many configs. But for a mature, well-documented CLI like `gh`, wrapping it in a new MCP server is usually more work than it's worth. Choose per capability, not by ideology.
- **Non-determinism in output:** CLI output formats change between versions; agents handle this well in practice but verify anything consequential.
- **Remote reach:** CLI tools backed by cloud services effectively give the agent remote capability without any remote protocol — and without the OAuth delegation model (see the OAuth/API keys capability in this module for when *that* matters instead).

### Optional deeper context

- **Why this works at all:** the same model that reads your code also reads CLI help text and error messages, so "what tools exist" is discoverable at runtime rather than fixed at build time. This is a general property of agentic systems, and it's one reason structured tool interfaces like MCP exist — to make the surface explicit and controllable rather than emergent.
- **Connection to Skills and plugins:** when a multi-step CLI workflow becomes routine, it can be captured as a Claude Code Skill (a directory with a `SKILL.md`, model-invoked when relevant) or distributed as part of a plugin. Plugins are fundamentally a packaging mechanism — installing one can bundle several capabilities together.

## Cautions and common failures

- **Command-not-found failures** usually mean the program isn't installed or isn't on the PATH the agent's shell sees — the fix is environment, not prompting.
- **Auth failures** mean the CLI's own credentials are missing or expired; re-authenticate as you would for yourself.
- **Destructive commands:** a shell-capable agent can run anything a shell can, including destructive operations. This is exactly why permission prompts and allowlists exist — configure them deliberately (see `tools-and-agent-actions`).
- **Credential sprawl:** giving an agent broad CLI access means giving it every credential those CLIs hold. If a task needs scoped, revocable access to one third-party service, an OAuth-based connection (or an MCP server using one) may be safer than full CLI access.
- **Output misinterpretation:** because CLI output is unstructured text, the agent can misread it; for high-stakes steps, have it show the relevant output before acting on it.

## Related capabilities

- `tools-and-agent-actions` (prompt-engineering module) — permission prompts and allowlists: the safety lever for shell access; cross-referenced rather than repeated here.
- `mcp-servers` (this module) — structured, typed tool access via the Model Context Protocol; the practical alternative/complement to shelling out to CLIs.
- `oauth-vs-api-keys` (this module) — when connecting to third-party services, when scoped delegated access beats a raw credential.
- `skills` and `plugins` (this module) — packaging and distributing recurring agent workflows.

## Official sources

- Anthropic platform docs — Agent Skills overview (context for how agents gain and use capabilities): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- OAuth 2.0 framework (for the delegated-access contrast): https://oauth.net/2/
- Model Context Protocol (concept pages on tools and clients/servers): https://modelcontextprotocol.io

## Provenance

- Core claim (shell access makes every installed CLI an agent capability) is a research synthesis point on which both research models independently converged; it is practice guidance rather than a single doc-cited fact, anchored by Anthropic's agent/tooling documentation.
- The CLI-vs-MCP tradeoff framing is original research synthesis, presented as practical guidance, not an official benchmark.
- Context7 checks in this session confirmed the MCP connector in the Messages API and the Skill (`SKILL.md`) mechanism as current; those anchor the ecosystem context this page sits in, though this page itself makes no API-level claims.
- No live verification was needed for this page's specific claims beyond the general ecosystem checks noted above; beta-specific or rapidly-shifting details are deliberately not asserted here.
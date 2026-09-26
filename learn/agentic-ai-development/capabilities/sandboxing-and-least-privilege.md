---
title: Sandboxing and least privilege for agents
module_id: agentic-ai-development
capabilities:
  - sandboxing-and-least-privilege
context7_library: /websites/platform_claude_en
context7_queries:
  - How do Claude Code permission systems control which tools an agent may run?
  - What sandboxing options exist for running an agent with limited blast radius?
  - How do allowlists and denylists restrict commands an agent can execute?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool
  - https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks
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

Sandboxing and least privilege are two ways to limit how much damage an AI agent can do if it makes a mistake — or if someone tries to misuse it.

**Least privilege** means giving the agent only the access it needs, nothing more. In practice this shows up as:

- **Permission prompts**: the agent asks before it runs a tool or command, and a human approves or denies each request.
- **Allowlists and denylists**: rules that say which specific commands or tools the agent may use (the allowlist) and which it must never use (the denylist). For example, you might allow the agent to run tests but deny it permission to delete files or make network calls.

**Sandboxing** means running the agent inside a confined environment — a container or a sandbox with network access disabled — so that even a bad action has a **bounded blast radius**. If the agent deletes files, writes bad code, or runs a destructive command, the damage is contained to the sandbox rather than your real machine, real repository, or production systems.

Anthropic's own documentation describes permission systems and a sandboxing mode for Claude Code as real, current features. The exact flag names and configuration syntax live in the official docs — the concepts here are what matter for decision-making.

## When it is useful

Least privilege and sandboxing matter most when:

- An agent can **execute commands** or modify files, not just suggest changes.
- The agent's working environment touches anything you can't easily undo — production code, customer data, credentials, or infrastructure.
- The agent processes **untrusted external content** (emails, web pages, file uploads), which is the indirect prompt injection threat described in Anthropic's guardrails documentation. A sandbox limits what an injected instruction can actually reach.
- A team is **scaling agent use** across many developers, where per-person judgment at every permission prompt isn't sustainable and you need systematic rules instead.

They matter least for low-stakes, read-only work, though even then a permission prompt is a cheap safety net.

## Prerequisites

- An agentic coding tool that supports permission controls and sandboxing (Claude Code's permission system and sandboxing mode are documented, current features).
- A working understanding of what tools and commands the agent will actually need for the task at hand — you can't write an allowlist without knowing what work is in scope.
- For container-based sandboxes, basic familiarity with containers (or access to someone who has it).

## Current syntax

Exact commands and configuration vary by tool and version. This page deliberately describes concepts rather than specific flags. For Claude Code's permission prompts, allowlist/denylist configuration, and sandboxing mode syntax, consult the official Anthropic documentation directly — it is the authoritative source for current syntax.

## What happens (local and remote)

**Locally:** when an agent requests a tool execution, the permission layer checks it against your rules. If it's allowlisted, it may run automatically; if it's denylisted, it's refused; otherwise a permission prompt surfaces and you approve or reject. With a sandbox, the agent's actions execute inside the confined environment — file changes and commands touch the sandbox, not your host machine directly.

**In team settings:** permission configurations can be shared at the project level so everyone's agent runs under the same rules rather than each person's ad-hoc choices.

**When something goes wrong:** a denied command stops the agent with an error it can respond to. A sandboxed failure — a bad delete, a runaway process, an unexpected network call — stays inside the container instead of propagating outward.

## Practical example

A team lets an agent fix bugs in their web application:

1. They define an allowlist: the agent may run the test suite, the linter, and the build. It's denied permission to install arbitrary packages or push to remote branches.
2. They run the agent inside a container with network access disabled, so it works only from local files and can't send anything out.
3. The agent attempts a command that isn't on the allowlist — say, installing a package it thinks it needs. The permission prompt surfaces, and the developer denies it and instead installs the correct dependency themselves.
4. Later in the session, the agent runs a command that deletes a build directory it shouldn't have. The mistake happens — inside the container. The developer resets the container in seconds rather than repairing their working machine.

No single control caught everything, but each layer shrank the blast radius.

## Explanation guidance

### Essential

- **Least privilege = the agent gets only what the task needs.** Permission prompts, allowlists, and denylists are the practical tools.
- **Sandboxing = a confined environment that bounds the damage of a mistake.** Containers and network-disabled sandboxes are the common forms.
- **These are layered defenses, not either/or choices.** A permission prompt might be missed or misjudged; a denylist might be incomplete; a sandbox is the backstop when the other layers fail.
- Anthropic documents permission systems and a sandboxing mode as real, current Claude Code features — but check official docs for exact configuration, which changes with versions.

### Experienced-user note

- Think of allowlists as policy-as-configuration: they encode team judgment once, so individual humans don't re-litigate the same "should the agent run this?" question on every prompt. Tuning them is iterative — start restrictive, add allowances when the agent is legitimately blocked.
- Network-disabled sandboxes are a particularly strong control against **indirect prompt injection** scenarios, where adversarial content the agent reads tries to make it exfiltrate data — no network, no exfiltration channel.
- Sandbox choice is a tradeoff: too restrictive and the agent can't do real work (constant blocked commands, human interruption tax); too permissive and you've lost the protection. Match the sandbox to the task's actual needs.

### Optional deeper context

- Permission-prompting agent tools are one instance of a broader human-approval gate pattern — the same idea behind branch protection requiring human review before a merge, or staged rollouts before production deploys. Agents don't change the principle, just the frequency and granularity of the gates.
- The computer-use documentation describes an automated classifier that can detect potential prompt injection and trigger a human-confirmation step — an additional automated layer that complements, not replaces, permission controls and sandboxing. It's described in Anthropic's docs as a mitigation, though not a complete defense.
- Anthropic's tool-use documentation notes that tool results should be encapsulated as tool results rather than pasted into system prompts — part of clearly distinguishing trusted instructions from untrusted data. Sandboxing is what bounds the damage if that separation fails.

## Cautions and common failures

- **Over-permissive defaults.** Accepting every permission prompt reflexively trains you to approve anything — the prompt becomes a rubber stamp. Tighten the allowlist so prompts are rare and meaningful.
- **Under-permissive sandboxes that get abandoned.** If the sandbox blocks so much that real work is impossible, teams quietly disable it. A sandbox that's actually used beats a perfect one that's turned off.
- **Assuming the denylist is complete.** New commands, renamed binaries, and indirect paths (a script the agent writes that itself calls a denied command) can slip through list-based rules. Sandboxing is the layer that doesn't depend on enumerating every bad action.
- **Secrets inside the sandbox.** A sandbox limits what an agent's actions can reach, but if credentials are mounted into the sandbox for convenience, the agent (or injected content) can read them. Keep secrets out of the agent's reachable environment.
- **Treating any single control as sufficient.** Injection and mistakes both exploit gaps between controls. The defenses above are designed to be combined.

## Related capabilities

- `tools-and-agent-actions.md` (prompt-engineering module) — covers the framing of agent actions as tool use and the blast-radius concept from the tool-design side; this page covers the operational controls (permissions, sandboxing) that bound that blast radius.
- Verifying-agent-work lesson — reviewing and verifying an agent's actual output, complementing the runtime controls described here.
- Indirect prompt injection coverage in the guardrails lesson — the threat model that makes sandboxing and least privilege especially important.

## Official sources

- Anthropic platform docs — "Mitigate jailbreaks and prompt injections": https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks
- Anthropic platform docs — computer use tool (including the prompt-injection classifier and human-confirmation step): https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool

Note: these are Anthropic platform documentation pages, cited as vendor documentation. For exact Claude Code permission and sandboxing configuration syntax, consult the current official Claude Code documentation directly rather than relying on flags quoted from memory.

## Provenance

The concepts on this page — permission prompts, allowlists/denylists, containers and network-disabled sandboxes as blast-radius bounds — are real, current practice, and Anthropic's own platform docs describe permission systems and a sandboxing mode for Claude Code as real, current features. Per the page contract and grounding facts, this page deliberately does not quote specific flag names or configuration syntax, since those change with tool versions; it points to official docs for exact syntax instead. Cross-vendor practice claims (allowlists, containers, network-disabled environments) are general, well-established agentic-coding practice, not tied to one vendor's docs. The cross-reference to tools-and-agent-actions.md is intentional: that lesson owns the blast-radius framing from the tool-design side; this page owns the operational controls.
---
title: Agent-to-agent handoff protocols (recognition level)
module_id: agentic-ai-development
capabilities:
  - agent-to-agent-handoff
context7_library: /websites/platform_claude_en
context7_queries:
  - What is Google's Agent2Agent protocol and who governs it now?
  - How does agent-to-agent communication differ from agent-to-tool communication (MCP)?
  - Is agent-to-agent interop settled or still young and volatile?
official_sources:
  - https://agents.md
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

Agent-to-agent handoff protocols are emerging standards that let one AI agent hand work to, or talk to, another AI agent — for example, a research agent passing findings to a coding agent. The best-known current effort is Google's **Agent2Agent (A2A) protocol**, an open interoperability initiative that, as of 2025, has been moved under **Linux Foundation governance** so it is no longer controlled by a single vendor.

The key distinction to remember:

- **MCP (Model Context Protocol)** is about *agent-to-tool* communication — an agent calling databases, APIs, file systems, and other tools.
- **Agent-to-agent protocols (like A2A)** are about *agent-to-agent* communication — agents coordinating with each other directly.

These solve different problems, and the terms are often confused in vendor materials.

## When it is useful

At recognition level, this matters most when you're evaluating vendor pitches or architecture decks. If a slide says "we use A2A" or "agent-to-agent interoperability," you should be able to ask sensible questions: Is this the Linux Foundation-governed protocol? Is it for agent-to-agent communication, or is the vendor loosely using the term when they really mean MCP-style tool connections?

For most people building with agents today, you don't need to implement anything here — you need to recognize the term and know it's early.

## Prerequisites

- Awareness of what an AI agent is and that agents can use tools.
- Basic familiarity with MCP as the agent-to-tool connection layer (see Related capabilities).

## Current syntax

Not applicable. This is a recognition-level topic about a young, still-volatile protocol area — there is no syntax to learn, and protocol-level details are deliberately out of scope for this page. The specification itself is still evolving under Linux Foundation governance, so details may change quickly; consult the current spec if you ever genuinely need it.

## What happens (local and remote)

This is a standards and interoperability topic, not a feature you run locally or remotely. In practice: vendors and platforms may adopt A2A so that agents from different providers can discover each other and exchange tasks. Adoption is real but young, and the ecosystem is still settling.

## Practical example

**Recognition scenario:** A vendor presents an architecture where "our orchestrator agent hands tasks to specialist agents via open standards." You now know enough to ask: "Is that agent-to-agent handoff (something like A2A) or agent-to-tool connections (MCP)?" The two are complementary — an agent might use MCP to reach its tools and A2A to talk to a peer agent — and a confident answer to that question tells you whether the vendor understands the distinction.

## Explanation guidance

### Essential

- Agent-to-agent handoff = agents talking to agents. MCP = agents calling tools. Different problems, both real.
- Google's Agent2Agent protocol is the main named effort; it moved under Linux Foundation governance in 2025.
- This area is **young and still changing** — treat anything you hear about it as potentially in flux.

### Experienced-user note

If you're designing multi-agent systems today, direct agent-to-agent protocol adoption is not usually the deciding factor. The more practical question is whether your multi-agent setup actually benefits from parallel fan-out, and whether tasks share context that would be fragmented by splitting (see Related capabilities). Protocols matter at the edges of the problem, not the core.

### Optional deeper context

The broader industry pattern: the tool-connection layer (MCP) matured faster than the agent-coordination layer (A2A and similar). That's typical of interoperability efforts — standards for narrow, well-defined interactions stabilize sooner than standards for open-ended coordination. Expect this space to look different in a year.

## Cautions and common failures

- **Confusing A2A with MCP.** They are complementary but distinct; vendors sometimes blur them.
- **Assuming maturity.** This is a young effort. Don't build critical plans around specific protocol details holding still.
- **Vendor deck jargon.** "Agent interoperability" can be marketing language for simple internal message passing rather than the actual open protocol. Ask what specifically is being used.
- **Over-investing early.** For most teams, recognizing the term is the right level; deep protocol work is premature while the landscape is volatile.

## Related capabilities

- **MCP / tool connectivity** — agent-to-tool communication, the more mature layer.
- **Multi-agent orchestration (honest pros and cons)** — before handoff protocols matter, decide whether fanning out to multiple agents helps or fragments shared context.
- **Reading and debugging an agent's trace** — relevant once agents actually hand work to each other, since handoffs become part of the debugging surface.

## Official sources

- [agents.md](https://agents.md) — cited as an open-format spec, not vendor documentation. (Listed here as a real, named source for open agent interop conventions generally; the Agent2Agent protocol itself is a named industry effort — Google's initiative now under Linux Foundation governance — rather than an Anthropic doc, and no Anthropic platform documentation URL is cited for this topic.)

## Provenance

This page is deliberately at **recognition level** and covers a topic the grounding facts flag as **young/volatile**: Google's Agent2Agent protocol, moved under Linux Foundation governance in 2025, presented as distinct from MCP (agent-to-tool communication). Per the page contract, this is an emerging/young area — there is no settled canonical vendor documentation anchor for it, so citations are kept minimal and plainly attributed (a named industry effort and an open spec site, not implied vendor docs). Nothing here is protocol detail; the goal is that a reader can recognize and ask about the term in a vendor deck.
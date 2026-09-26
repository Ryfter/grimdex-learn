---
title: "Tool and schema design: tool descriptions are prompts"
module_id: agentic-ai-development
capabilities:
  - tool-and-schema-design
context7_library: /websites/platform_claude_en
context7_queries:
  - How should I write names and descriptions for custom tools so an agent uses them correctly?
  - What makes a good error message returned from a failed tool call?
  - How do tool parameter schemas affect how an agent calls a tool?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls
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

When a coding or general-purpose agent calls a custom tool (including a tool exposed through MCP), the tool's **name, description, and parameter schema** function as part of the prompt. The agent has no other source of knowledge about what the tool does, when to use it, or what arguments it expects — so whatever those fields say is exactly what the agent acts on.

This means two things:

1. **An ambiguous or under-described tool gets misused the same way an ambiguous instruction does.** If a tool description is vague ("fetches data"), the agent will guess at what data, when, and why — and its guesses will sometimes be wrong, in ways that look mysterious but trace straight back to the description.
2. **A clear, specific error message from a failed tool call measurably helps the agent recover and retry correctly.** An error that says what went wrong and what a valid input would look like lets the agent fix its next attempt. A bare failure ("error") leaves the agent guessing, often retrying the same mistake or abandoning the task.

This is real, well-established, cross-vendor practice in agentic engineering — not specific to one provider.

## When it is useful

- You are building or configuring custom tools an agent will call — directly, or via MCP servers.
- An agent repeatedly calls a tool with the wrong arguments, calls it at the wrong time, or skips it when it should use it.
- Agents using your tool seem to "flail" after a failure — retrying identically or giving up — rather than correcting course.
- You are reviewing an MCP server or tool integration and want to predict how reliably an agent will use it before wiring it into real work.

## Prerequisites

- Basic familiarity with what an agent is and how tool calls work (the agent receives a description of available tools, chooses one, and supplies arguments).
- For hands-on work: access to whatever platform or framework lets you define a custom tool or MCP server, so you can edit names, descriptions, and schemas.

## Current syntax

There is no single syntax for this capability — it is a design discipline. The fields that matter on any custom tool definition are:

- **Name** — should plainly say what the tool does (e.g., a name like `lookup_customer_order` communicates more than `fetch_data`).
- **Description** — the agent's primary instruction for the tool: what it does, when to use it, when *not* to use it, and what it returns.
- **Parameter schema** — each parameter's name, type, and description should make valid input unambiguous; required vs. optional should be explicit.

For exact schema syntax on a given platform, consult that platform's official tool-use documentation rather than relying on remembered flags. Anthropic's tool-use docs are a reliable anchor for the general shape of tool definitions.

## What happens (local and remote)

Because the tool's name, description, and schema are loaded into the agent's context alongside the user's request, the agent "reads" them the same way it reads instructions. Consequently:

- **Locally (your tool definitions):** ambiguous descriptions produce ambiguous behavior — the agent may pass plausible-but-wrong arguments, conflate two similar tools, or invent parameters that don't exist. Poor error messages compound this: after a bare failure, the agent has no signal about what to change.
- **Remotely / at runtime:** each tool call and result flows back into the conversation. A well-described tool plus a specific error message turns a failed call into a one-step correction. A poorly described tool can cause cascading misuses that consume context and time before anyone notices.

The effect is the same whether the tool is local, remote, or behind MCP: the description *is* the contract the agent operates under.

## Practical example

Suppose you expose a custom tool to an agent:

- **Under-designed version:** name `search`, description "Search for stuff," one parameter `q`. An agent asked "find the invoice from March" may search for the literal string "invoice March," search the wrong source entirely, or pass a malformed query — and if the search errors, it gets back "Error: bad request" and may simply retry identically.

- **Well-designed version:** name `search_customer_invoices`, description "Searches the invoices database by customer name or invoice number. Use this (not `search_payments`) when the user asks about an invoice. Returns at most 20 matching invoice records." Parameter `query` described as "Customer full name or exact invoice number, e.g. 'Acme Corp' or 'INV-2024-0031'." If the agent passes a date range (which the tool doesn't accept), the error returns: "Invalid parameter: 'date_range' is not accepted. Provide 'query' as a customer name or invoice number."

In the second version, the agent both calls the tool correctly more often and, when it errs, corrects itself in one step instead of thrashing.

## Explanation guidance

### Essential

- Treat a tool's name, description, and parameter descriptions as **part of the prompt**, not as inert metadata. Write them with the same care you'd give an instruction.
- An ambiguous tool description gets misused the way an ambiguous instruction does — the agent guesses, and guessing is where misuse begins.
- Make failed tool calls return **specific, actionable error messages** (what was wrong, what valid input looks like) rather than bare failures. This measurably helps the agent recover and retry correctly.
- If an agent misuses your tool, the first thing to check is the tool's description and schema — not the agent.

### Experienced-user note

- Distinguish similar tools explicitly in their descriptions ("use X for A, use Y for B") — tool-confusion between overlapping tools is a common failure pattern when descriptions are written in isolation from each other.
- Returning structured error information (which parameter, what was invalid, what the accepted shape is) tends to outperform a single human-readable sentence, because the agent can map it directly onto its next attempt.
- When designing schemas, think about what an agent would *plausibly guess* wrong and close those gaps proactively — e.g., stating formats, units, and limits in the parameter description.

### Optional deeper context

- The same discipline scales to MCP servers: an MCP tool's published name, description, and input schema are what every connected agent sees, so a well-documented MCP tool benefits every client at once, while a badly described one misleads all of them.
- This connects to the broader principle that an agent optimizes against whatever signals it can observe: a descriptive error is a high-quality signal; a bare failure is noise. (See related capabilities on verification-first loops.)

## Cautions and common failures

- **Writing descriptions for humans, not the agent.** Internal jargon or shorthand that a human teammate would understand may leave the agent with nothing actionable. Write descriptions as instructions.
- **Bare error strings.** Returning "error" or "failed" gives the agent nothing to correct; expect repeated identical retries.
- **Overloading one tool.** A tool that does "search anything" forces the agent to guess intent; several narrowly-scoped tools with explicit descriptions usually behave more predictably.
- **Assuming schema types alone are enough.** A correct type doesn't prevent semantically wrong input — parameter descriptions carry that burden.
- **Don't invent flags or syntax.** Exact schema syntax varies by platform; point to official docs rather than guessing.

## Related capabilities

- **Verifying agent work** — the same "trust the actual observable output, not the narration" discipline applies to whether a tool call did what it claimed.
- **Verification-first loops** — tool results and error messages are part of the feedback signal an agent optimizes against; well-designed errors make the loop work.
- **Tool-use and indirect prompt injection defenses** — tool results are untrusted external data and should be encapsulated as tool results, which also interacts with how tools are designed and described.

## Official sources

- Anthropic platform docs, "Handle tool calls": https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls — real, current Anthropic documentation on tool-use behavior, used here as the vendor anchor for the general tool-call flow. The specific design guidance on this page (descriptions-as-prompts, specific error messages aiding recovery) is well-established cross-vendor practitioner practice presented alongside that anchor.

## Provenance

This page covers real, well-established, cross-vendor practice in agentic tool design: a tool's name, description, and parameter schema function as part of the prompt, and specific error messages from failed tool calls measurably help agents recover versus bare failures. The Anthropic tool-use docs page cited above is a genuine, current official source and anchors the underlying tool-call mechanics; the design guidance itself is practitioner consensus rather than a single vendor's documented rule. Provenance class: practice-guidance-with-official-anchors. No statistics, flags, or citations beyond the grounding facts have been invented; exact schema syntax is deliberately left to official platform docs.
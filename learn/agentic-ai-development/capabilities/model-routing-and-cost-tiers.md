---
title: Model routing and cost-tier optimization
module_id: agentic-ai-development
capabilities:
  - model-routing-and-cost-tiers
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I choose the right Claude model tier for different tasks to manage cost?
  - What is prompt caching and how does it reduce cost on long agent sessions?
  - How does routing simpler sub-tasks to a smaller model compound with caching?
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
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

Model routing and cost-tier optimization is the practice of matching the model tier to the difficulty of the task. Not every step of an agentic workflow needs the most capable (and most expensive) model. Routing simpler, well-defined sub-tasks — formatting, classification, straightforward lookups, routine file edits — to a smaller, cheaper, faster model, and reserving the frontier model for genuinely hard reasoning or architecture decisions, is standard cost-management practice across vendors.

Prompt caching is a related, real, current, documented feature across major AI platforms: previously-processed context (system prompts, long documents, prior conversation turns) is stored so it isn't re-billed and re-processed on every turn of a long session. Caching compounds with routing — a long session where most context is cached, and only the hard decisions go to the expensive model, is dramatically cheaper than sending everything at top tier every turn.

## When it is useful

- Long-running agent sessions where the same context is processed turn after turn.
- Workflows with a mix of easy and hard steps — most of the work is routine, a few moments need deep reasoning.
- Teams running agents at scale, where per-task cost differences multiply across hundreds or thousands of runs.
- Any situation where someone asks "do we really need the most expensive model for this?" — the honest answer is often no, for most steps.

## Prerequisites

- A basic understanding of what an AI model's context window and per-token billing are (no technical depth required).
- Awareness of which model tiers your chosen tool or platform offers. Exact names and pricing vary by vendor and change over time — check the vendor's own pricing and model documentation.

## Current syntax

There is no universal syntax for this capability; it is a design practice rather than a command. Concretely, it appears as:

- Choosing a model tier per task or per sub-agent when configuring a tool or workflow.
- Enabling prompt caching in your platform's API or tooling so repeated context is reused rather than re-billed. Vendors document exact syntax separately — for Anthropic, see the official docs listed below; do not assume flag names from memory.

## What happens (local and remote)

- **Routing:** when a workflow is configured to use a smaller model for simple steps, those steps run faster and cost less per task. The frontier model is invoked only where the work genuinely needs it.
- **Caching:** when a session reuses a large fixed context (a long system prompt, a codebase summary, prior turns), a cache hit means the platform does not re-process that context from scratch, so the turn is cheaper and often faster. Cache entries expire after a period of inactivity, so very sporadic sessions may not benefit.
- The two interact: cached shared context plus tier-appropriate models per step means a long session's cost grows much more slowly than "everything at frontier tier, nothing cached."

## Practical example

Imagine an agent workflow that triages incoming customer emails:

1. A small, cheap model classifies each email by topic and urgency — fast, low cost, and this task does not need deep reasoning.
2. Emails flagged as complex (a contractual complaint, say) are routed to the frontier model for careful analysis.
3. The shared company-policy document attached to every step is prompt-cached, so it is processed and billed once rather than on every turn.

The result: the same quality of final output, at a fraction of the cost of running every email through the frontier model with the full document re-processed each time.

## Explanation guidance

### Essential

- Match the model to the task: cheap models for easy, well-defined steps; the best model for hard reasoning.
- Prompt caching means already-processed context isn't re-billed on every turn — a real, documented feature across major vendors.
- Together they're the two main levers for keeping long agentic sessions affordable.

### Experienced-user note

- Routing decisions should be revisited: a sub-task that seemed easy may quietly need more capability, and a task assumed to be hard may not. Evaluate quality, not just cost, when reassigning tiers.
- Cache benefit depends on session shape — long sessions with stable shared context benefit most; short, one-off sessions benefit least.

### Optional deeper context

- Routing pairs naturally with sub-agent delegation: a sub-agent handling a narrow, independent task is a good candidate for a smaller model, while the orchestrating agent — which needs to hold the whole picture — may warrant the frontier tier. Keep spawn counts low regardless, per Anthropic's prompting best practices.
- If you measure agent quality with a fixed set of golden tasks (see the agent-evals capability), re-run those checks after any routing or caching change to confirm quality did not regress.

## Cautions and common failures

- **Over-optimizing for cost.** A cheap model that produces subtly worse outputs can cost more in rework than it saved. Validate quality when you downgrade a tier.
- **Caching doesn't apply everywhere.** Context that changes every turn (a growing conversation, freshly generated file contents) won't cache; only stable, repeated context does. And caches can expire between infrequent runs.
- **Vendor specifics change.** Model tier names, pricing, and caching mechanics vary by platform and shift over time — always confirm against the vendor's current documentation rather than assuming.

## Related capabilities

- Agent evals: measuring quality over time — use golden-task evals to verify quality after any routing or caching change.
- Context engineering and context window management — caching and compaction both shape what gets re-processed in long sessions.
- Multi-agent orchestration — sub-agent design interacts directly with which model tier each agent uses.
- Tool and schema design — cheaper models benefit even more from clearly described tools.

## Official sources

- Anthropic platform documentation, prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

Note: prompt caching is a real, current, documented feature of Anthropic's platform and other major vendors; consult each vendor's own documentation for exact current syntax and pricing, as specifics change over time.

## Provenance

- Model routing and cost-tier optimization is presented as real, well-established, cross-vendor practice — standard cost management in ML/LLM engineering broadly, not any single vendor's proprietary method.
- Prompt caching is a real, current, documented feature across major vendors and compounds with routing on long sessions.
- The grounding facts anchor this capability to Anthropic's platform documentation for general best practices; no specific statistics or invented syntax are included. Exact model names, prices, and cache parameters vary by vendor and over time and are deliberately left to the official docs.
- Last checked 2026-09-20 against the fall-2026 grounding set for this module.
---
title: Reading and debugging an agent's trace
module_id: agentic-ai-development
capabilities:
  - reading-agent-traces
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I inspect the sequence of tool calls an agent made?
  - How do I debug an agent session that produced a wrong final answer?
  - Where can I see intermediate outputs and reasoning steps from an agent run?
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

When an AI agent works on a task, it usually does more than produce one answer: it calls tools, reads files, runs commands, receives results, and reasons between steps. The full record of that session — the sequence of tool calls, the intermediate outputs the agent received, and the reasoning steps in between — is called the **trace**.

The core idea of this capability: **the trace is the actual debugging surface.** When a session goes wrong, reading only the final answer hides where things actually went off track. A confidently-written final answer can be wrong because of a bad tool call three steps earlier, a misread file, or a misunderstanding formed at the very start. You find that only by walking the trace.

This is general, cross-tool debugging practice for agentic sessions — it applies whether the agent is Claude, another coding agent, or any tool-using assistant — not a feature of one vendor.

## When it is useful

Use trace reading when:

- An agent finished a task but the result is wrong, incomplete, or surprising.
- An agent claims success but you doubt the claim (e.g., "all tests pass") — the trace shows whether the check actually ran and what it actually returned.
- A session took an odd detour, and you want to understand why before re-prompting.
- You want to improve your instructions: the trace shows where the agent first misinterpreted you, which is the right place to intervene.
- You are reviewing agent work generally and want evidence, not narration.

It is less useful for trivial, single-step requests where there is effectively nothing between the prompt and the answer.

## Prerequisites

- Access to a tool or interface that shows the agent's session history (most agentic coding tools expose the conversation/tool-call log; consult your tool's own documentation for where).
- Basic comfort reading tool calls and their outputs — you don't need to write code, but you should be able to tell a successful command result from an error message.

## Current syntax

There is no syntax for this capability — it is a reading and diagnostic practice, not a command or API. The "surface" is the trace your agent tool already records. Exact locations and formatting vary by tool; check your tool's official docs for how to view a session's full history of tool calls and results.

## What happens (local and remote)

Whether the agent runs locally on your machine or as a hosted/remote service, the shape is the same:

1. Your prompt goes in.
2. The agent reasons, then calls a tool (read a file, run a command, search).
3. The tool returns a result, which the agent reads.
4. The agent reasons again, calls the next tool, and so on.
5. It produces a final answer.

Every step in 2–4 is recorded in the trace. When you inspect the trace, you are replaying steps 2–4 in order. Problems typically show up as: a tool call that failed (and the agent ignored or misread the failure), a tool call that succeeded but returned something different from what the agent assumed, a misreading of a file or error message early on that poisoned everything after, or reasoning that confidently asserted something no tool result actually supported.

## Practical example

Suppose an agent reports: "I fixed the bug and the build passes." The build does not pass on your machine. You open the trace and walk it in order:

- **Step 1:** The agent read the file containing the bug — but read the *older* of two similar files. This is where the session went off track; everything after is effort spent "fixing" the wrong thing.
- **Step 2:** The agent edited the wrong file and ran the build. The build output shows an error. The trace shows the agent glancing at the error and describing it as "an unrelated pre-existing warning." That's the second problem: misreading real feedback.
- **Step 3:** The agent re-ran the build, got the same error, and then wrote its final answer claiming success — the narration and the evidence in the trace disagree.

Now you know exactly what to fix: point the agent at the correct file, and tell it to treat the build error as the thing to resolve, not to explain away. Without the trace, you would only know "it claimed success and was wrong," and you'd be guessing where to intervene.

## Explanation guidance

### Essential

- An agent session is a sequence of steps, not a single answer. The record of those steps is the trace.
- When a result is wrong, the final answer is the worst place to look for the cause — it's the agent's polished summary, not its evidence. Walk the trace in order instead.
- The most common failure patterns visible in a trace: an ignored or misread error, a wrong file or wrong target chosen early, or a confident claim with no supporting tool result behind it.
- Reading the trace also tells you *where* to intervene: fix your instruction at the step where the agent first misunderstood, rather than re-explaining everything.

### Experienced-user note

- Traces are also how you evaluate *changes to your setup*. If you change the model, prompt, or tool configuration, comparing traces from before and after shows whether behavior actually improved or just got described more confidently. This connects directly to building a small set of repeatable "golden tasks" you re-run when configuration changes (see Related capabilities).
- Distinguish in the trace between what a tool *actually returned* and what the agent *said* the tool returned. Disagreement between those two is one of the most reliable signals that the session is untrustworthy from that point forward.

### Optional deeper context

- Traces compound with verification loops: the strongest pattern is an agent whose trace includes it actually running tests/builds itself and reading the real results, so you can audit the evidence rather than the assertion.
- Traces are also a lens on cost and efficiency: a trace full of redundant reads, repeated failed calls, or wandering investigation may indicate that the task needs a better plan or better tool descriptions — see Related capabilities on tool and schema design.

## Cautions and common failures

- **Trusting the summary.** Fluent final answers are the agent doing its best narration, not evidence. Narration can be wrong even when every individual step looks plausible.
- **Reading only the tail.** The decisive mistake is often early in the trace (a wrong file, a misunderstood goal). Skimming the last few calls misses it; walk the whole sequence in order.
- **Assuming a "successful" tool call means the right thing happened.** A command can succeed and still return something the agent misinterpreted. Check what came back, not just that it came back.
- **Skipping the trace because it's long.** It's tempting to just re-prompt the agent with "no, do it right." Without reading the trace, you can't tell the agent what specifically went wrong, so the retry often repeats the same mistake.
- **Tool availability varies.** Where and how traces are exposed differs across tools and vendors; if you can't find a session log, consult your specific tool's documentation rather than assuming there is none.

## Related capabilities

- **Verifying agent work** — the discipline of checking claims against the actual diff and actual test runs rather than the agent's narration; trace reading is how you find *where* to verify, and verification is what the trace's evidence should be checked against.
- **Checkpoints, diffs, and rollback** — once a trace shows where a session went wrong, a good checkpoint from an earlier reviewed chunk makes recovery cheap.
- **Tool and schema design** — clear tool descriptions and informative error messages show up as clearer, more recoverable traces; well-designed tools make traces easier to read.
- **Agent evals** — fixed golden tasks plus trace comparison is how you confirm quality improvements are real across configuration changes.
- **Human-in-the-loop interruption and steering** — watching the session as it runs (the live trace) lets you pause and redirect before a long wrong-direction run finishes.

## Official sources

- Anthropic platform docs — handling tool calls (tool results as the agent's input to reason over): https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls

## Provenance

The core claim of this page — the trace (sequence of tool calls, intermediate outputs, reasoning steps) is the real debugging surface for agentic sessions, and reading only the final answer hides where things went off track — is well-established **cross-tool practitioner practice**, not a doctrine from any single vendor's documentation. It is presented here as general debugging practice for agentic sessions.

The linked Anthropic platform-docs page is included as a real, current official anchor on how tool calls and tool results flow through a session (the raw material a trace is made of); it is not cited as the source of the trace-reading practice itself, and no vendor-specific trace-viewing UI or flags are described here beyond what is generally true across tools.
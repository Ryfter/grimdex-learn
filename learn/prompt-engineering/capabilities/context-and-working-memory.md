---
title: Context and working memory
module_id: prompt-engineering
capabilities:
  - context-and-working-memory
context7_library: /websites/platform_claude_en
context7_queries:
  - context window working memory glossary amount of text model can reference
  - context windows progressively accumulate tokens user message assistant response
  - context window input phase prior history current message output phase
  - working with messages API stateless conversation history re-sent each request
  - prompt engineering overview success criteria test empirically first draft
official_sources:
  - https://platform.claude.com/docs/en/about-claude/glossary
  - https://platform.claude.com/docs/en/build-with-claude/context-windows
  - https://platform.claude.com/docs/en/build-with-claude/working-with-messages
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
last_checked: 2026-08-02
last_material_update: 2026-08-02
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

A context window is the amount of text a model can reference when generating a
response. Official documentation describes it as the model's **working memory**
for that interaction: not long-term storage of everything you have ever said
across all sessions, but the finite slice of material available right now.

That window **progressively accumulates** tokens from each user message and each
assistant response. On a multi-turn exchange, earlier turns still occupy space
unless something outside the raw transcript (a tool, a product feature, or you)
removes or summarizes them. Each turn has an input phase — prior history plus the
current message — and an output phase, so both sides of the conversation consume
the same finite budget.

The messages API this module cites is documented as stateless — conversation history is re-sent, not retained server-side. Other providers' APIs vary; check their own docs.

## When it is useful

Use this mental model any time you work with a coding agent or chat assistant
and need to explain why it "forgot" a constraint, invented a detail, or
contradicted an earlier decision. It also guides how you structure long work:
what to put in the first message, when to restate a requirement, and when to
start a clean thread so stale assumptions do not keep occupying the window.

Reach for it before pasting large files, secrets, or proprietary code: anything
you put into the prompt occupies working memory and typically leaves your machine
for the provider on that request.

## Prerequisites

- You can open a chat or agent session with a coding assistant that accepts text
  (and often files or tool results) as input.
- You understand that the assistant's answers are generated from the current
  request context, not from a guaranteed permanent memory of every past session.

## Current syntax

Shape of a request that makes the working set explicit — restate what the model
must see rather than assuming prior turns still carry it:

```
You are helping with a small library change.

Constraints (re-stated this turn):
- Only modify files under src/auth/
- Do not add new dependencies
- Success: existing unit tests for auth still pass

Prior decision to keep:
- Prefer early returns over nested if/else in the touched functions

Task:
- Add a null-check for the session token in refreshSession() and return a clear
  error string if missing.
```

The exact product UI differs; the transferable pattern is: name the constraints,
restate durable decisions, and put the task last so the working set is complete
for this turn.

## What happens (local and remote)

**Locally**, your editor, terminal, and files do not change when you only send a
message. Drafts, open buffers, and uncommitted work stay on your machine until
you (or an agent with tools) write them. The chat transcript may also be stored
by the client application on disk or in its own account history — that is product
behavior, not the model API itself.

**Remotely**, the provider receives the prompt material for the request: system
instructions, conversation history the client re-sends, your new message, and
often tool outputs or attached snippets. Official platform docs describe the
messages path as stateless: history is re-sent rather than magically retained
server-side as a continuous memory. Anything in that payload — including secrets,
API keys, proprietary source, and personal data you pasted — leaves the machine
for that request. Do not treat the chat as a private notepad for credentials.

As turns accumulate, more of the finite context window is occupied by prior
user and assistant text. When important early constraints fall out of the
effective working set (or were never restated), the model can answer with
confidence about a world that no longer matches your intent. Restating beats
assuming.

## Practical example

You told the assistant two turns ago: "Never rename the public `loadConfig`
export." Several tool-heavy turns later you ask it to "clean up the config
module." Without that constraint still in context, a plausible rewrite may rename
the export. The failure is not mysterious malice; the working memory no longer
carries the rule, or never received it on this request.

Recovery pattern:

```
Correction — binding constraints for this turn:
- Public export name loadConfig must not change
- Keep the existing config file path
- Success: Typecheck passes; no rename in the public API

Please undo the rename and show the diff for the config module only.
```

Re-stating the rule and the success check puts them back in the input phase of
the current turn.

## Explanation guidance

### Essential

Context is a finite working memory that fills as you talk. Each turn includes
prior history plus the new message on the way in, then the model's reply on the
way out. APIs are often stateless: clients re-send history. If a detail is not
in the current context, the model cannot reliably use it — and may still produce
a fluent answer. Re-state important constraints. Treat pasted secrets as data
that left your machine.

### Experienced-user note

Long sessions degrade when early decisions are buried under tool logs and
partial drafts. A useful habit is periodic "context hygiene": summarize locked
decisions in one short block, open a fresh thread for a new subtask, or attach
only the files that matter. Prefer explicit restatement over hoping the product
still injects the right history.

### Optional deeper context

Provider docs distinguish the accumulating window from product features that
summarize, pin, or retrieve external memory. Those features still feed text into
the same kind of window; they do not remove the need to know what is actually
present for this request. Avoid memorizing token limits or model version names
for everyday practice — they change; the "finite window that fills" model does
not.

## Cautions and common failures

- **Assuming the model "remembers" forever.** Stateless APIs re-send history; a
  new session or a truncated history has no automatic access to last week's chat.
- **Confident answers from missing facts.** Fluency is not evidence that the
  constraint is still in context.
- **Pasting secrets into the prompt.** Keys, tokens, and private customer data
  in the request leave the machine; use env vars and secret stores instead.
- **Flooding the window with noise.** Huge unrelated logs and files crowd out the
  few lines that define success.
- **Never restating after tool-heavy digressions.** Multi-step agent runs generate
  a lot of intermediate text; re-pin the goal before the next big edit.

## Related capabilities

- Clear and direct instructions — what to put into context so success is defined
  and scope is constrained.
- Tools and agent actions — tool results also consume context and can change
  real files on the machine.
- Verifying agent work — check claims against artifacts when context may be
  incomplete or stale.

## Official sources

- <https://platform.claude.com/docs/en/about-claude/glossary> — context window as
  the text a model can reference; working-memory framing.
- <https://platform.claude.com/docs/en/build-with-claude/context-windows> —
  progressive accumulation of tokens; input and output phases per turn.
- <https://platform.claude.com/docs/en/build-with-claude/working-with-messages> —
  stateless messages API; history re-sent with each request.
- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview>
  — success criteria and empirical testing before deeper prompt work.

## Provenance

Authored 2026-08-02 against the official Anthropic platform documentation cited
above, retrieved via Context7 (`/websites/platform_claude_en`) and aligned with
the verified source notes in the module authoring brief. This page follows the
capability page structure for the `prompt-engineering` module; the module-level
provenance policy and source registry live in `../provenance.md` and
`../source-registry.md`. Concepts such as finite context and restatement apply
across coding agents; Anthropic docs are the cited anchor, not a product lock-in.

---
title: Verifying agent work
module_id: prompt-engineering
capabilities:
  - verifying-agent-work
context7_library: /websites/platform_claude_en
context7_queries:
  - prompt engineering overview success criteria test empirically first draft
  - prompting best practices clear direct desired output scope constraints
  - context window working memory confident answers missing information
  - working with messages stateless history re-sent each request
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
  - https://platform.claude.com/docs/en/build-with-claude/context-windows
  - https://platform.claude.com/docs/en/about-claude/glossary
  - https://platform.claude.com/docs/en/build-with-claude/working-with-messages
last_checked: 2026-08-02
last_material_update: 2026-08-02
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

**Verifying agent work** means checking the claim against the artifact while you
build — not after a long chain of fluent replies has already been trusted.
Plausible output is not verified output. The model can describe a fix, cite a
file, or assert that tests pass; verification is reading the diff, running the
command, and comparing the result to the **success criteria** you defined when
you instructed the task.

Official prompt-engineering guidance puts success criteria and empirical testing
at the front of the loop for improving prompts. The same discipline applies to
accepting agent edits: you are always testing a hypothesis about what changed.

## When it is useful

Verify on every non-trivial agent turn:

- After file edits (what actually changed?).
- After "I ran the tests" (did you run them, and what was the exit code?).
- After refactors that claim behavior is unchanged.
- When the answer is long, confident, and hard to skim — confidence is cheap.

Skip heavy process only for tiny, easily eyeballed answers (a one-line
definition you already know). For repository changes, default to verify.

## Prerequisites

- Success criteria for the task (see clear and direct instructions).
- Access to the artifacts: working tree, `git diff` (or equivalent), test and
  build commands for the project.
- Enough context awareness to notice when the agent may be reasoning from a
  stale or partial view of the project.

## Current syntax

A verification checklist you can paste into the chat or keep beside it:

```
Verification for this turn:

1. Success criteria (from the request):
   - [ ] ...
   - [ ] ...

2. Artifact checks:
   - [ ] git status / git diff — only expected paths changed
   - [ ] Skim the diff for secrets, debug junk, and scope creep
   - [ ] Run the agreed test or build command locally
   - [ ] Confirm the agent's factual claims against the files (names, APIs)

3. Disposition:
   - [ ] Accept and commit, or
   - [ ] Reject / revert and re-prompt with tighter criteria
```

Example re-prompt when verification fails:

```
Verification failed:
- You said tests passed; `npm test -- invoice` exits 1 on my machine
- Diff also touched src/legacy/util.ts which was out of scope

Please restore out-of-scope files, fix until the command above passes, and
report the actual command output.
```

## What happens (local and remote)

**Locally**, verification is where truth lives: the files on disk, the test
process exit code, the typechecker, the running app. An agent's narrative does
not update those systems. Running the same command the agent claims to have run
is the standard check. Diff tools show the blast radius of edits.

**Remotely**, the model may only see what was pasted or returned through tools
in context. It can misread a truncated file, miss an untracked change, or
describe a test run that never happened on your machine. Request and tool
payloads still go to the provider; verification results you paste back also
enter that channel — redacted logs are a useful habit when failures include
secrets.

Stateless APIs re-send history; a claim from an earlier turn is not re-validated
unless you validate it again against the current tree.

## Practical example

Agent: "All billing tests pass and only `invoice.ts` changed."

You:

```
$ git diff --stat
 src/billing/invoice.ts     | 40 ++++++++++++++++++++
 src/billing/invoice.test.ts| 12 ++++++
 src/legacy/util.ts         |  5 +++--
$ npm test -- invoice
# ... failures ...
```

Two verification failures: unexpected path, failing command. You do not merge on
the story. You restore or fix, then re-check the same criteria. That loop is the
empirical counterpart to the "define success, then test" guidance in official
prompt-engineering overviews.

## Explanation guidance

### Essential

Define success before you accept work. Read the diff. Run the tests (or other
checks) yourself. Match claims to files and command output. Plausible prose is
not evidence. When checks fail, re-prompt with the failure facts and tighter
scope.

### Experienced-user note

A useful habit is **verify-as-you-go** on multi-step agent sessions: accept or
reject after each coherent chunk instead of reviewing a massive diff at the end.
Keep a fixed command palette for the repo (test, lint, typecheck) so criteria
stay comparable across prompt iterations. Prefer small commits when a chunk is
good so rollback stays easy.

### Optional deeper context

Some products show tool transcripts that look like proof. Treat them as hints:
replay locally when the stakes matter. Cross-tool practice is the same whether
the assistant is in an IDE, a CLI, or a browser — artifacts beat narration.
Official docs on context and messaging explain why the model can be wrong with
confidence; they do not replace your test runner.

## Cautions and common failures

- **Accepting the story.** "Should work" and "tests passed" without a local run.
- **No pre-stated success criteria.** You cannot decide pass/fail consistently.
- **Diff blindness.** Reviewing only the chat summary, not `git diff`.
- **Scope creep that "still works".** Extra files and refactors land because
  nobody checked path lists.
- **One giant agent session, one giant review.** Errors compound; verify in
  smaller steps.
- **Pasting secret-bearing failure logs back into chat** without redaction.

## Related capabilities

- Clear and direct instructions — where success criteria are defined.
- Tools and agent actions — what must be verified when tools edit and execute.
- Context and working memory — why fluent answers can still miss constraints.

## Official sources

- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview>
  — success criteria and empirical testing against them; first draft then
  iterate.
- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>
  — clear desired output and scope so verification targets stay sharp.
- <https://platform.claude.com/docs/en/build-with-claude/context-windows> —
  accumulating context; incomplete working sets yield poor answers.
- <https://platform.claude.com/docs/en/about-claude/glossary> — context window as
  working memory for what the model can reference.
- <https://platform.claude.com/docs/en/build-with-claude/working-with-messages> —
  stateless requests; history is only what is re-sent.

## Provenance

Authored 2026-08-02. **Most of this page is practice guidance** (diff review,
local re-runs, verify-as-you-go). Official Anthropic platform docs cited above —
retrieved via Context7 (`/websites/platform_claude_en`) — anchor success
criteria, empirical testing, clear outputs, and limits of model context. They
are not a substitute for a project's own test commands. Module policy:
`../provenance.md` and `../source-registry.md`.

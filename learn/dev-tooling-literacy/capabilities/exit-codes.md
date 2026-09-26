---
title: "Exit codes: how commands signal outcomes"
module_id: dev-tooling-literacy
capabilities:
  - exit-codes
context7_library:
context7_queries:
official_sources:
  - https://www.gnu.org/software/bash/manual/
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

When a command-line tool finishes running, it reports a machine-readable completion status called an **exit code** — a number the tool returns to the shell to indicate how things went. By long-standing convention, `0` means success and any non-zero number means some kind of failure or abnormal condition.

Two things trip up beginners:

- **A returned prompt is not a verdict.** When a command finishes, the shell simply shows its prompt again, whether the command succeeded or failed. The prompt itself tells you nothing.
- **Visible output is not a verdict either.** A command can print friendly-looking text and still fail, and a command can succeed while printing nothing at all.

The exit code is the tool's own structured statement about its outcome — which is why an AI coding agent often checks it (or asks you to check it) rather than trusting what appeared on screen.

## When it is useful

Recognition-level understanding of exit codes helps when:

- An agent reports that a command "failed" even though you saw no obvious error message on screen — the non-zero exit code is likely how it knew.
- You want to confirm for yourself whether a step actually succeeded before moving on, instead of relying on impressions from the output.
- An agent proposes to "retry" or "work around" a failed step — the exit code is part of the evidence it is acting on, and you can ask what it was.
- You are reviewing an agent's transcript of a session and want to distinguish commands that completed successfully from those that did not.

## Prerequisites

- Basic familiarity with the terminal as a window and the shell as the program interpreting what you type (covered in this module's terminal-and-shell lesson).
- Awareness that an agent runs commands on your behalf and reacts to their results.
- For reading error text that accompanies a non-zero exit code, see the debugging-recovery module's **read-error-messages** lesson — this page covers the status signal, not how to interpret the message text.

## Current syntax

There is nothing to install or configure. Recognition points:

- Every command that finishes leaves behind an exit status — a number from 0 upward.
- Convention: **0 = success**, **non-zero = something went wrong**. Different tools use different non-zero values to signal different failure categories, but the 0/non-zero split is the widely shared convention.
- In the Bash shell, the exit status of the most recent command is available to check; the Bash manual's "Exit Status" section documents this behavior. You do not need to memorize the checking syntax — recognize that the status exists and that agents (and experienced users) consult it.

## What happens (local and remote)

**Locally:** the shell runs a program; when the program ends, it hands a numeric status back to the shell. The shell uses that status itself (for example, to decide whether to continue a sequence of commands), and it is also how scripts and agents programmatically detect failure.

**With an AI agent:** the agent typically runs commands through a shell and receives the exit code along with any output. A non-zero code is a strong, unambiguous signal that the agent will treat as a failure — often triggering a retry, a different approach, or a request to you. This is a good thing: the agent is reacting to the tool's own structured report rather than guessing from the printed text.

**Remotely:** the same mechanism applies anywhere a shell is involved, including servers and containers. If an agent works in a remote or sandboxed environment, exit codes remain the standard way its commands report outcomes back.

## Practical example

An annotated, recognition-level example — not something to type and implement:

```
$ npm run build
... (build output scrolls by) ...
$ █
```

What a beginner might see versus what is actually knowable:

- **What you see:** output scrolling past, then the prompt returns. It *looks* finished.
- **What is knowable:** the command has ended and left an exit status. If the status was `0`, the build succeeded. If it was non-zero, the build failed — even if the output contained no dramatic error banner.
- **What an agent does:** it inspects that status. If it reports "the build command failed," the non-zero exit code — not the absence of friendly output — is typically why.
- **The reverse case:** a command that prints nothing and returns the prompt may have succeeded perfectly. Silence plus a returned prompt proves nothing in either direction.

The takeaway to recognize: *success and failure are reported through a channel separate from the visible output*, and both you and your agent can consult it.

## Explanation guidance

### Essential

- A finishing command always leaves an exit code: a number reporting how it went.
- By convention, 0 means success; non-zero means failure of some kind.
- A returned prompt and visible output are neither of them proof of success — the exit code is the tool's own machine-readable statement.
- When an agent says a command failed, a non-zero exit code is a common basis for that claim; it is reasonable to ask which code and what it implies.

### Experienced-user note

- Non-zero codes are often tool-specific: different values can distinguish failure categories (for example, "bad arguments" vs. "file not found"), so the specific number can carry diagnostic meaning beyond "failed."
- Scripts and automation chain commands based on exit statuses — which is why one failed step can cause a whole pipeline to stop or take a different path.
- Some tools' documentation lists their exit codes; checking them can sharpen a failure report you give to an agent.

### Optional deeper context

- The Bash manual's "Exit Status" section is the authoritative reference for how the shell records and exposes these statuses, including special statuses the shell itself assigns.
- Exit codes connect to the broader pattern of machine-readable signals (log severity levels, HTTP status codes) covered elsewhere in this module — structured outcome information that should be read as such, not skimmed as prose.

## Cautions and common failures

- **Do not treat a returned prompt as success.** The prompt comes back whether the command succeeded or failed.
- **Do not treat output as success.** Polite or quiet output can accompany a failure; conversely, a successful command may print nothing.
- **Do not over-interpret a non-zero code by itself.** It says something went wrong; the accompanying error text (see the debugging-recovery module's read-error-messages lesson) usually says what.
- **Exit codes are a convention, not a guarantee of uniform meaning.** Beyond 0/non-zero, the specific values and their meanings vary by tool — do not assume a particular number always means the same thing everywhere.
- **Don't disable or ignore failure signals.** If an agent proposes to suppress or ignore exit statuses to "make things work," ask why the underlying failure isn't being addressed instead.

## Related capabilities

- Terminal, shell, and commands — how commands are run in the first place.
- Install, build, run are different steps — exit codes are how each step reports its own outcome.
- Application logs and severity levels — another machine-readable outcome channel.
- Debugging-recovery module: read-error-messages — what to do with the human-readable text that often accompanies a non-zero exit code.

## Official sources

- GNU Bash manual, "Exit Status": https://www.gnu.org/software/bash/manual/

## Provenance

Grounded in the GNU Bash manual's "Exit Status" section as verified during this module's research. Recognition-level practice guidance with an official anchor; no vendor-specific claims beyond the documented 0/non-zero convention and the shell's handling of exit statuses. Cross-references the debugging-recovery module's read-error-messages lesson rather than duplicating its content. Last material update: 2026-09-20.
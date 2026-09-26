---
title: Reading stack traces and agent error output
module_id: debugging-recovery
capabilities:
  - read-error-messages
context7_library:
context7_queries:
official_sources:
  - https://docs.python.org/3/tutorial/errors.html
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

When a program fails, it usually prints diagnostic output. Two things in that output matter most:

- **A stack trace** (also called a traceback in some languages) is the sequence of function or method calls that were active at the moment the error occurred. Think of it as a snapshot of the call chain: the path the program took to arrive at the failure. Reading order (bottom-to-top or top-to-bottom) varies by language and tool, so check the convention for the tool you are using rather than assuming one universal direction.
- **stderr (standard error)** is the output stream where programs conventionally write error and diagnostic messages, separate from stdout (standard output). This is a universal, decades-old Unix convention, not tied to any single language. It is why errors and normal output can be redirected, logged, or captured independently.

The core skill is not memorizing formats -- it is finding the *actual error line* (the error type and message, and the line in your code nearest the failure) inside what may be a long, intimidating wall of text.

## When it is useful

- A command, script, or agent task fails and you need to know *what* went wrong before trying to fix it.
- Output is long and you need to separate the signal (the error message) from the noise (the surrounding call chain and framework internals).
- You are deciding whether output you are looking at is the error itself or just the program's normal output mixed in.
- You need to capture or share the error with someone else -- knowing that errors go to stderr tells you what to capture and what to redact.

## Prerequisites

- Ability to run a command or script in a terminal.
- No specific language knowledge required; the concepts are cross-language and cross-tool.

## Current syntax

There is no command syntax for this capability -- it is a reading and interpretation skill. The relevant conventions are:

- Error/diagnostic output is conventionally written to **stderr**; normal output to **stdout**. (This is a convention, not a guarantee -- some tools write everything to stdout.)
- Stack traces list the active calls at failure time; reading direction depends on the language/tool.

Do not invent or rely on tool-specific flags here; consult the specific tool's documentation for capture or redirection options.

## What happens (local and remote)

- **Locally:** when a program crashes, the runtime prints the stack trace and error message (typically to stderr). You see the call chain, the error type, and the message.
- **With an agent or remote process:** the same applies, but output may be interleaved, truncated, or captured into a log. Errors written to stderr may appear in the same stream as stdout in some capture setups, or may be separated. Either way, the underlying convention is the same: the diagnostic text is the tool telling you what its calls were doing when it failed.
- The trace length scales with how deep the call chain was -- frameworks and libraries can add many frames that are not your code, which is why long traces are common and mostly skimmable.

## Practical example

A generic (not tool-specific) shape of a failing run:

```
Trace text... frame after frame of active calls ...
ErrorType: descriptive message about what went wrong
```

A practical reading routine:

1. **Find the error type and message first.** Scan for a line that reads like `SomethingError: <message>`. That is the actual error.
2. **Find the frame nearest your code.** Among the listed calls, locate the one pointing at a file/line you wrote or recognize, rather than library internals.
3. **Note the reading order for your tool.** Check whether the tool lists the deepest call first or last before interpreting the chain.
4. **Separate stdout from stderr when capturing.** If you are saving or sharing the failure, be aware that the error is conventionally on stderr, so capturing only stdout may silently lose it.

The point of the routine: a 50-line trace usually contains one line that matters most, plus context. Do not be intimidated by length -- skim to the error line, then work outward.

## Explanation guidance

### Essential

- A stack trace shows the sequence of function/method calls active when the error occurred.
- Programs conventionally write errors to stderr, separate from stdout -- a decades-old, cross-language convention.
- The core skill is locating the actual error line/type/message within a long trace, then working outward to the call that led there.
- Reading direction varies by language/tool -- check, don't assume.

### Experienced-user note

- When capturing output for later analysis (e.g., piping or redirecting), remember that stderr and stdout are separate streams; a redirection that only captures stdout can hide the error you were chasing. Conversely, interleaving both streams in one log is common in agent/CI contexts.
- The distinction between "your frame" and "framework frames" in a trace is often the fastest shortcut: frameworks fail because your code called them with something they didn't expect.

### Optional deeper context

- Stack traces reflect the call stack data structure the runtime maintains -- each frame is an entry that was pushed as functions were invoked and not yet returned. That is why a trace is a faithful record of the call chain, not a guess.
- Not all errors produce a stack trace (some tools print a one-line error only), and not all stack traces indicate a fatal error -- some languages print traces as warnings for handled exceptions.

## Cautions and common failures

- **Being intimidated by length.** A long trace does not mean a complex problem; it usually means a deep call chain. Find the error line first.
- **Assuming a universal reading direction.** Bottom-to-top vs. top-to-bottom varies by tool. Verify for the tool at hand.
- **Capturing only stdout.** If you redirect or log only stdout, stderr error messages may be lost, making the failure look silent.
- **Treating the last line as the cause without checking.** The error type/message line is usually the most important, but the frame in your own code tells you where to look in *your* code -- both matter.
- **Sharing raw error output.** Before pasting a trace into a teammate, support channel, or an AI agent, redact credentials, tokens, and other secrets -- see Related capabilities.

## Related capabilities

- **ask-for-help** (debugging-recovery) -- how to escalate a problem effectively: what context to include, and redacting secrets before sharing output.
- **secrets-and-data-hygiene-for-agent-context** (agentic-ai-development module) -- general secrets-hygiene discipline; cross-reference rather than repeat.
- **dotenv-and-secrets** (dev-tooling-literacy module) -- secrets handling in configuration; cross-reference rather than repeat.
- **bisect-and-blame** (debugging-recovery) -- finding *which* change introduced a failure once you can read the error.
- **fix-one-failure** (debugging-recovery) -- applying change-one-variable-at-a-time discipline to test failures.

## Official sources

- <https://docs.python.org/3/tutorial/errors.html> -- Python's own "Errors and Exceptions" tutorial chapter explains tracebacks clearly and is used here as one real, well-known worked example of the concept. Stack traces and stderr are cross-language, decades-old conventions, not specific to Python -- this source illustrates the concept rather than defining a universal standard.

## Provenance

- Grounded in well-established, cross-tool/cross-language engineering practice (stack traces, stderr/stdout convention), not tied to a specific vendor.
- No Context7-verified library documentation was needed for this capability; the concepts are generic and decades-old.
- claim_class: everyday; safety_class: normal.
- Last reviewed: 2026-09-20.
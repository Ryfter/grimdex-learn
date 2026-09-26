---
title: Running processes and stopping a server
module_id: dev-tooling-literacy
capabilities:
  - processes-and-servers
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

A **process** is a program that is currently running. A **dev server** is a common kind of process in development work: it runs in the background (or in a terminal window), listens for requests, and serves the application you are building so you can look at it in a browser.

The key recognition point: **a dev server does not stop when you stop paying attention to it.** It can keep running, occupy the terminal that started it, or continue in the background until someone deliberately stops it. Understanding this explains several everyday situations:

- A terminal that "does nothing" and won't accept new commands — it's occupied by the running server.
- An agent saying a port is already in use — an earlier server instance is still running.
- A change not appearing in the browser — the old server process is still serving the old version, or was never restarted.
- Confusion about "stopping" — ending a command is not the same as stopping a program that is still running.

## When it is useful

This recognition helps when:

- An AI coding agent starts a dev server for you and the terminal seems to "hang."
- You or an agent need to stop a server before starting it again (for example, after a configuration change).
- Something reports that a port is busy and you want to understand why.
- You want to know whether an application is still running after you closed a window — closing a terminal window may not always stop what it started.

## Prerequisites

- Recognition of the terminal as a window and the shell as the program interpreting commands (see the terminal-and-shell lesson in this module).
- Basic awareness that tools are started by commands an agent types, and that those commands create running programs.

## Current syntax

There is no syntax to learn at this level. What a reader should *recognize*:

- **Foreground process**: a command that takes over the terminal. The prompt disappears until the program ends or is stopped. Dev servers typically run this way.
- **Background process**: a program that keeps running without holding the terminal visible, so it can continue after the terminal shows a prompt again.
- **Job control**: the shell's facility for managing running programs — starting them, putting them in the background or foreground, and stopping them. (Reference: the GNU Bash manual, "Job Control Basics.")

An annotated example of what this looks like:

```text
$ npm run dev            ← the command an agent might type to start a server
Server listening on http://localhost:3000

                          ← no prompt appears here: the terminal is
                            occupied by the running server

(ctrl-c pressed)         ← a deliberate stop; the prompt returns
$
```

The reader's goal is to recognize these states — "the terminal is occupied because a server is running" and "the prompt returning means the foreground program ended" — not to memorize commands.

## What happens (local and remote)

Everything here is local to the machine or environment where the command runs:

- When an agent starts a dev server, a new process is created on that machine.
- While it runs in the foreground, the terminal is occupied; the shell cannot accept other commands.
- If the process is moved to the background (or started detached), the terminal is freed but the server keeps running until deliberately stopped.
- Nothing is published remotely by this process itself; whether the running server is reachable from anywhere beyond the local machine depends on how it is exposed — see the localhost-and-ports lesson in this module.
- Stopping the process is a deliberate act: pressing an interrupt, issuing a stop command, or closing/killing it. It does not happen automatically just because you looked away.

## Practical example

Scenario: an agent starts a dev server, makes a change, and reports a port conflict on restart.

```text
[agent] Starting dev server...
Server running at http://localhost:5173

(user later) [agent] Restarting the server...
Error: Port 5173 is already in use
```

What the reader can recognize, step by step:

1. The first start created a running process serving the app on port 5173.
2. That process did not stop on its own — it kept running after the agent moved on.
3. The "port already in use" error is the *old* server still holding the port, not a broken setup.
4. The remedy is to deliberately stop the old server process first, then start the new one — which is exactly why an agent may propose stopping something before restarting.

Recognizing this pattern turns a mysterious error into a normal, explainable situation.

## Explanation guidance

### Essential

- A running program is a **process**; a dev server is a process that stays alive to serve your app.
- A server **occupies the terminal** when it runs in the foreground — the missing prompt is normal, not a freeze.
- It **keeps running until deliberately stopped** — stopping is an action someone must take.
- If the same port or server seems "stuck," the likely cause is a previous instance still running.

### Experienced-user note

- Processes can run in the **background**, freeing the terminal while the program continues — this is standard job control behavior, not a malfunction.
- When several servers have accumulated across a session, only the deliberate stops matter; windows closed long ago don't guarantee the process ended.
- An agent that stops and restarts a server after changes is doing normal lifecycle management, not fixing a crisis.

### Optional deeper context

- The shell's **job control** provides named ways to move processes between foreground and background and to stop them — the GNU Bash manual's "Job Control Basics" section documents the concepts.
- Related recognition topics in this module: exit codes (how a stopped process reports how it finished), localhost and ports (where a running server is reachable), and application logs (interpreting what a running server prints).

## Cautions and common failures

- **Do not treat a busy terminal as broken.** An occupied prompt usually means a foreground program is running, not that the shell crashed.
- **Don't assume closing a window stopped everything.** A process may continue in the background; verify rather than assume.
- **Repeated starts can stack up.** Starting a server again without stopping the old one leads to "port already in use" errors and duplicate processes.
- **Stopping is deliberate.** Before approving an agent's request to stop a process, recognize that "stop" ends that running program — for a dev server this is normally routine, but it is an action with an effect, not a no-op.

## Related capabilities

- terminal-shell-commands (terminal vs. shell vs. invoked programs)
- exit-codes (how processes report completion status)
- localhost-ports-exposed-services (where a running server is reachable)
- app-logs-severity-levels (reading what a running server prints)
- install-build-run-steps (run as a distinct lifecycle step)

## Official sources

- GNU Bash manual — "Job Control Basics": https://www.gnu.org/software/bash/manual/

## Provenance

- Sourced from this module's verified grounding facts (GNU Bash manual, "Job Control Basics" and "Introduction"/"Shell Commands" sections).
- Recognition-level coverage only; cross-references the terminal-and-shell, exit-codes, and localhost-ports lessons rather than repeating them.
- No vendor claims beyond the grounding facts; no commands or flags introduced beyond the annotated, generic example shown.
- Reviewed against the frozen D32 page contract; context7 left empty deliberately, per module convention, with official sources used as anchors.
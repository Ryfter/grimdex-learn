---
title: File permissions and access
module_id: dev-tooling-literacy
capabilities:
  - file-permissions
context7_library:
context7_queries:
official_sources:
  - https://www.gnu.org/software/coreutils/manual/
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

File permissions are the operating system's rules about who can do what with a file or folder: **read** (look at its contents), **write** (change it), and **execute** (run it as a program). Every file carries these settings, and they explain a large family of errors you will see when working with an AI coding agent — "permission denied", "operation not permitted", or a tool that simply cannot open a file.

This is recognition-level content. You do not need to calculate permission numbers or edit access rules by hand. You need to recognize what a permission failure looks like, and recognize when an agent proposes to solve one by escalating privileges.

## When it is useful

- An agent tries to read a file and gets an access error — permissions explain why.
- An agent tries to modify a project file and fails — write permissions may be the reason.
- A script or tool the agent created won't run — the execute permission may be missing.
- An agent proposes a fix involving "sudo", "run as administrator", or similar elevated access — permissions literacy gives you grounds to pause and question rather than approve automatically.

## Prerequisites

- The terminal/shell distinction from the "terminal-shell-commands" capability.
- Awareness of working directories and paths, since permission errors usually name a specific file or folder.

## Current syntax

Permission settings are stable operating-system behavior, not something with versions that change. On Linux and macOS systems they are commonly displayed as strings like:

```
-rw-r--r--
```

Reading that at recognition level, in three groups of three:

- First group (`rw-`): the file's **owner** can read and write, but not execute.
- Second group (`r--`): members of the file's **group** can read only.
- Third group (`r--`): everyone else can read only.

A leading `d` instead of `-` means the entry is a directory. An `x` in a group means execute is allowed for that class of user. That is all you need to recognize: these strings encode exactly who can read, write, and run something.

## What happens (local and remote)

When a process — including one the agent started — tries to open, change, or run a file, the operating system checks the permissions first. If they don't allow the action, the system refuses it and reports an error; the check happens regardless of what the software wanted to do.

Two practical consequences:

- **Local failures are protective, not mysterious.** "Permission denied" usually means the rules genuinely don't allow that action for that user — often a signal worth investigating, not working around.
- **Elevation bypasses the protection.** Running a command with elevated privileges (administrator/root) tells the system to skip the ordinary checks. That is why elevation requests deserve scrutiny: it removes the very safeguard that was reporting the problem.

## Practical example

An agent attempts to modify a configuration file and the terminal shows something like:

```
permission denied: /etc/app/config.yaml
```

An annotated walkthrough of what a reader can recognize here:

- **The file path** (`/etc/app/config.yaml`) points at a system-level location, not the project folder. System locations are typically more tightly restricted by design.
- **The error type** ("permission denied") is an access failure, not a bug in the file's contents. The file might be perfectly fine; the rules simply don't allow the change.
- **A plausible agent response** might be: "This failed due to permissions. I can retry using elevated privileges (sudo) to bypass this."

The literacy move is in that last line. The agent is not wrong that elevation would make the error go away — but the error was the system saying "this is restricted." A thoughtful reply is to ask *why* the project is writing to a restricted system location, or whether the change belongs in a project-local file instead, before approving the escalation. Sometimes elevation is genuinely right; the point is that it should be a considered decision, not an automatic approval.

## Explanation guidance

### Essential

- Permissions are rules on files: **read**, **write**, **execute** — look, change, run.
- Access failures ("permission denied") usually mean the rules blocked an action, which can be a useful signal rather than an obstacle.
- Elevated privileges mean bypassing those rules; approve such a request only when you understand why it's needed, not just to make an error disappear.

### Experienced-user note

Permission strings like `-rw-r--r--` split into owner / group / others, and the `x` position indicates execute. Recognizing this lets you read a permission listing and anticipate what an agent will be able to do — for instance, spotting that a downloaded script lacks execute permission before the agent hits the failure.

### Optional deeper context

The GNU Coreutils manual's "File permissions" section documents the underlying model these conventions come from. If you later work on servers or containers, the same read/write/execute model appears there too, which is one reason this recognition transfers well beyond a single machine.

## Cautions and common failures

- **Approving elevation reflexively.** If an agent's proposed fix is "just run it as administrator/root", that bypasses the protection that reported the error. Ask what it is trying to do and where before approving.
- **Misreading permission errors as bugs.** The file or program is not necessarily broken; the access rules blocked the action. Fixing the wrong thing wastes time and can create real problems.
- **Overcorrecting by loosening everything.** Making a file "writable by everyone" may fix the error but removes the restriction for good. Prefer understanding which specific access was needed.
- **Assuming an agent knows best about system locations.** Agents can propose writing to restricted directories because a tutorial did. A permission failure there is often a hint the change belongs elsewhere.

## Related capabilities

- terminal-shell-commands
- working-directories-paths
- containers-and-sandboxes
- install-build-run-steps

## Official sources

- GNU Coreutils manual — "File permissions": https://www.gnu.org/software/coreutils/manual/

## Provenance

- Grounded in the GNU Coreutils manual's "File permissions" section (gnu.org), verified earlier in this session's research for the dev-tooling-literacy module.
- Recognition-level treatment per the module spec: annotated recognition of permission strings, access failures, and elevated-privilege requests — not permission administration.
- Reviewed 2026-09-20; no vendor-version-specific claims made beyond the documented permission model.
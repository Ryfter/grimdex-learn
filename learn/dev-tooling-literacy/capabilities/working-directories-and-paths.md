---
title: Working directories and paths
module_id: dev-tooling-literacy
capabilities:
  - working-directories-and-paths
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

Every command a coding agent runs happens *somewhere* on your machine -- in a specific folder called the **current working directory**. Paths are the addresses tools use to find files. A path comes in two flavors:

- **Absolute path**: the full address from the root of the file system (on many systems, something starting with `/` or a drive letter like `C:\`). It points to one place no matter where you are.
- **Relative path**: an address *relative to* wherever the command is currently running. The same relative path can point to different files depending on the working directory.

Recognizing the difference is enough. You don't need to master path syntax -- you need to understand why an agent can find a file one moment and "not find" it the next, or why it edited something in an unexpected place.

## When it is useful

This recognition matters whenever:

- An agent says a file "doesn't exist" even though you know it does -- it may simply be looking from the wrong working directory.
- An agent creates or modifies a file in an unexpected folder -- it may have been running from a different directory than you assumed.
- An agent runs a script and the results land somewhere strange, or the script fails because it can't find its own supporting files.
- You're reviewing an agent's plan and see it mention a path; you want to sanity-check whether that address points where you expect.

## Prerequisites

- Basic awareness that your computer organizes files in nested folders.
- Recognition of what a terminal session is (see the terminal/shell lesson in this module).

## Current syntax

There is no syntax to learn here -- only shapes to recognize. In an annotated example of a typical agent transcript:

```
$ cd myproject          ← the agent changes the working directory to the "myproject" folder
$ cat config.yaml       ← a relative path: resolved inside myproject (the working directory)
$ cat /etc/hosts        ← an absolute path: resolved from the file system root,
                          regardless of the working directory
```

Recognizing `cd` as "change directory," and seeing whether an address starts from the root (absolute) or assumes a starting location (relative), is the whole skill.

## What happens (local and remote)

- **Locally**: the working directory is set when a terminal session starts and changes when tools like `cd` are used. Every file lookup with a relative path starts from that spot. If the agent opens a new session or runs a command from a different folder, the same relative path can resolve somewhere else entirely.
- **Remotely / in sandboxes**: when an agent works inside a container or remote environment, it has its own working directory and its own file layout -- which may not match your local folders. "It worked in the sandbox but not on my machine" (or the reverse) often traces back to paths resolving differently in the two environments.

## Practical example

An annotated, recognition-level transcript:

```
$ pwd                   ← "print working directory": shows where the agent currently is
/home/you/projects      ← so the agent is inside the "projects" folder

$ ls src                ← a relative path: looks for "src" inside /home/you/projects
src not found           ← fails! There is no "src" folder here

$ ls projects/app/src   ← still relative, now spelling out the deeper route
app.py  utils.py        ← succeeds; the files were one level deeper all along
```

The failure was never about the files vanishing -- the agent's *starting point* made the relative path point to the wrong place. That's the failure mode to recognize: "wrong place" errors are usually path errors, not missing files.

## Explanation guidance

### Essential

- The current working directory is "where the command is standing" when it runs.
- Absolute paths are full addresses from the root; relative paths depend on where you're standing.
- When an agent can't find a file, or puts something in the wrong folder, the first question is: *what directory was it working from?*

### Experienced-user note

- An agent may open a new session or reset to a default directory mid-task, silently changing how relative paths resolve. Watching for a directory change (or asking the agent to confirm its working directory) resolves a surprising number of "where did that file go?" moments.
- Copying a command that worked for someone else can fail if their path was relative to a different folder layout.

### Optional deeper context

- Different operating systems write paths differently (forward slashes vs. backslashes, drive letters vs. a single root). An agent translating between Windows and Unix-style paths is a common source of small, confusing errors.
- Tools and configuration files sometimes interpret relative paths *relative to the config file's location* rather than the working directory -- one reason behavior can differ even in the same directory. If this matters for a specific tool, its official documentation will say so.

## Cautions and common failures

- **Approving a path change without checking it.** If an agent proposes writing to a path, glance at whether it's inside your project folder or somewhere broader (a system directory, a parent folder). Relative paths that use "go up one level" segments can point outside your project.
- **Assuming failure means the file is gone.** A "file not found" message usually means "not found *from here*."
- **Assuming your local layout matches the agent's environment.** In containers or remote sessions, the same path may resolve differently.
- **Treating absolute paths in a shared project as portable.** An absolute path that works on your machine may not exist on a teammate's machine or in deployment -- a recognition cue for "this might need to be relative."

## Related capabilities

- terminal-shell-commands
- file-permissions
- containers-and-sandboxes
- install-build-run-steps

## Official sources

- GNU Coreutils manual, "Working context" -- https://www.gnu.org/software/coreutils/manual/

## Provenance

Recognition-level content grounded in the GNU Coreutils manual's "Working context" section, cross-checked during this session's openrouter-pareto research. Everyday-claim, normal-safety guidance: no vendor claims beyond the anchored source; annotated examples illustrate recognition, not implementation. Course-independent, public-ready practice guidance with official anchors (fall-2026-0.1.0).
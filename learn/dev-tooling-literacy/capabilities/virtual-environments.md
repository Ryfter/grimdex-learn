---
title: "Virtual environments: keeping dependencies separate"
module_id: dev-tooling-literacy
capabilities:
  - virtual-environments
context7_library:
context7_queries:
official_sources:
  - https://docs.python.org/3/library/venv.html
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

A virtual environment is a project-specific, isolated space for dependencies -- the third-party software a project needs. Instead of installing every package onto the whole machine (a "global" install), a virtual environment keeps a project's packages in its own separate area.

Two consequences follow:

- Two projects can use different versions of the same package without conflicting with each other.
- A project's requirements stay contained, so installing or removing something for one project does not silently affect everything else on the machine.

This page is recognition-level: the goal is to recognize when an agent creates or activates an environment and why, not to learn the commands as an implementation exercise.

## When it is useful

Recognizing virtual environments helps when:

- An agent creates an environment, or "activates" one, before installing anything -- this is standard, careful behavior, not an odd extra step.
- A package seems installed but the project still says it is missing -- a classic symptom of the package landing outside the active environment.
- An agent asks whether to install something globally or in the project's environment.
- You are reviewing work and want to know why project files and setup steps mention an environment at all.

## Prerequisites

- Basic recognition of dependencies and package managers (see the related capability in this module).
- No programming-language knowledge required.

## Current syntax

Recognition cues, not commands to memorize:

- A project folder containing an environment directory (often with a name like `venv`, `.venv`, or `env` -- naming varies by tool).
- Agent messages such as "creating a virtual environment" or "activating the environment" before running an install step.
- Install output that shows packages being added inside the project rather than system-wide.
- Activation is usually a single short command the agent runs in the terminal; its exact wording depends on the operating system and tool, so treat it as a step the agent performs rather than something to recall.

## What happens (local and remote)

- **Local:** The agent creates an isolated space for the project, activates it, and installs dependencies into it. The rest of the machine's software is untouched.
- **Why activation matters:** An environment must be "active" for installs to land inside it. If the agent installs without activating, packages may go somewhere the project does not look -- which is why an install can succeed while the project still fails to find the package.
- **Remote/deployment:** Servers and deployment environments typically have their own environment setup. A project that works locally in its environment still needs its environment recreated (or its dependency list carried over) elsewhere.

## Practical example

An annotated sequence you might see from an agent:

1. **"Setting up a virtual environment for this project"** -- the agent is creating a project-specific container for dependencies, rather than installing to the machine globally.
2. **"Activating the environment"** -- the agent makes that container the active target, so the next install goes into the project's space.
3. **"Installing the required packages"** -- the packages are recorded and placed inside the environment, not scattered system-wide.
4. **Running the project** -- the project finds its dependencies because they are in the active environment.

What to recognize in the failure case: a message like "module not found" *after* a successful-looking install often means the install went into a different (or no) environment. This is an isolation mismatch, not necessarily a broken package.

## Explanation guidance

### Essential

- A virtual environment is a separate room for one project's dependencies, so projects don't interfere with each other or with the machine.
- "Activating" an environment means pointing the terminal at that room, so installs land in the right place.
- A global install goes onto the whole machine; that may be convenient once, but it does not guarantee the *project* can use it -- the project looks in its own environment first.
- When an agent creates or activates an environment, it is doing deliberate, conventional setup -- not padding the task.

### Experienced-user note

- Environment activation is per-terminal, per-session: opening a new terminal may mean the environment is no longer active, which is a frequent source of "it worked yesterday" confusion.
- Different language ecosystems have their own isolation tools with the same underlying idea (Python's `venv` is the canonical documented example); the concept transfers even when names differ.
- Environment directories should usually be excluded from version control (see related capabilities on manifests and lockfiles -- the dependency *list* is shared; the environment itself is rebuilt).

### Optional deeper context

- Isolation is one layer of a broader family: virtual environments isolate *packages*, containers isolate larger chunks of the system (see the containers and sandboxes capability). Neither is automatically a security boundary by itself.
- Version pinning inside an environment pairs with lockfiles and semantic versioning: the environment holds exact versions; the manifest and lockfile record what should be in it.

## Cautions and common failures

- **Install succeeded, project still fails:** the most common symptom of an environment mismatch -- the package went somewhere other than the environment the project is using.
- **Assuming "installed" means "installed for this project":** global and project-local installs are different targets; a global install may not help the project at all.
- **Deleting or moving the environment folder casually:** the environment is rebuildable from the project's dependency list, but removing it mid-session can break the agent's running setup -- ask before touching it.
- **Not confusing isolation with safety:** an isolated environment limits *interference*, not what an agent can do generally -- do not treat "it's in a venv" as a reason to auto-approve actions.

## Related capabilities

- Dependencies and package managers
- Dependency manifests vs. lockfiles
- Semantic versioning
- Containers and sandboxes
- Runtime versions and support lifecycles
- Environment variables

## Official sources

- Python docs, "venv" -- https://docs.python.org/3/library/venv.html

## Provenance

Grounded in the Python documentation on virtual environments (`venv`), verified in this session's earlier research. Recognition-level treatment consistent with the module's grounding facts; no commands, flags, or vendor claims beyond those sources have been introduced. Context7 fields are intentionally empty per the module-wide decision documented in the frozen page contract.
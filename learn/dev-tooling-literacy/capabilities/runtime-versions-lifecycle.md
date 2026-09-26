---
title: Runtime versions and support lifecycles
module_id: dev-tooling-literacy
capabilities:
  - runtime-versions-lifecycle
context7_library:
context7_queries:
official_sources:
  - https://nodejs.org/en/about/previous-releases
  - https://docs.npmjs.com/cli/v11/configuring-npm/package-json#engines
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

A **runtime** is the base software a project runs on — for example, a particular version of Node.js or Python installed on your machine. **Project dependencies** are the third-party packages the project uses, tracked in its manifest and lockfile (see the dependencies and package managers lesson). These are two different layers, and an agent's proposed changes can involve either one.

Runtime versions have **support lifecycles**: each release is actively supported for a period, then moves to maintenance, then stops receiving updates entirely. Node.js documents its release schedule and support phases publicly. A project can also declare which runtime version it expects — for example, npm's `engines` field in `package.json` records the runtime version a package is built for.

## When it is useful

This recognition matters when:

- An agent says a project requires a different runtime version than the one installed (a **compatibility issue**).
- An agent proposes upgrading the runtime, and you want to ask whether the current version is still supported (a **support-lifecycle issue**).
- Something works on your machine but not on another, and the difference turns out to be the runtime version rather than the code.

You don't need to memorize version numbers — you need to recognize which layer (runtime vs. dependencies) a proposed change touches.

## Prerequisites

- Recognition of dependency manifests and package managers (see related capability).
- Awareness of the terminal as the place where installed tool versions can be checked.

## Current syntax

There is no syntax to learn at recognition level. Recognize these patterns in agent output:

- A project file listing an expected runtime version, such as an `engines` entry in `package.json`.
- An agent message like "this project needs Node.js 20; you have 18" — a runtime mismatch.
- A version number written as three parts (for example, `20.11.1`), following the major.minor.patch convention covered in the semantic versioning lesson.

## What happens (local and remote)

**Locally:** the runtime installed on your machine is separate from the project's dependencies. Installing or updating packages does not change the runtime. If a project declares an expected runtime version and your machine has a different one, tools may warn or fail.

**Remotely:** deployment environments run their own runtime version. Code that works locally on one version may behave differently — or not run — on a server using another, which is why runtime version mismatches are a common cross-environment difference.

**Lifecycle effect:** a runtime version past its support window stops receiving fixes. An agent proposing that version isn't necessarily wrong, but it's a reasonable thing to question.

## Practical example

An agent responds during a project setup:

> "This project's `package.json` specifies `engines: { node: ">=20" }`, but the installed runtime is Node.js 18. Either upgrade the runtime to 20+, or the project may need adjustments to run on 18."

An annotated read of that message:

- **`package.json`** — the project's dependency manifest (not the runtime itself).
- **`engines`** — a declared *expectation* about the runtime version, recorded in the manifest.
- **"installed runtime is Node.js 18"** — the actual base software on the machine, a separate layer from the manifest.
- **The mismatch** — a compatibility issue between the two layers, which the agent is surfacing rather than silently working around.

A reader who recognizes this structure can ask sensible follow-up questions: which version does the project really need, is the older version still supported, and who decides which to change — the project or the machine?

## Explanation guidance

### Essential

- The installed runtime and the project's dependencies are two different layers; changing one does not change the other.
- A project can *declare* the runtime version it expects; a mismatch between that declaration and the installed runtime is a compatibility issue.
- Runtime versions have support lifecycles: supported, then maintenance, then end-of-life. Recognizing where a version sits in that lifecycle is grounds to question an agent's proposal, not to panic.

### Experienced-user note

- The same project behaving differently across machines or deployment environments is often a runtime version difference rather than a code difference — checking versions on both sides is a standard first comparison.
- An agent upgrading dependencies to satisfy a new runtime (or vice versa) can touch multiple files; the manifest/lockfile distinction explains why.
- Version constraints like `>=20` in metadata express ranges of acceptable versions, following the major.minor.patch convention — a convention for reading intent, not a guarantee of compatibility.

### Optional deeper context

- Node.js publishes its release schedule, naming active, maintenance, and end-of-life phases, so support status is checkable rather than guesswork.
- Some teams pin exact runtime versions for reproducibility; others accept ranges for flexibility. Recognizing which choice a project has made helps interpret an agent's proposed upgrade.

## Cautions and common failures

- **Confusing layers:** upgrading project dependencies does not upgrade the runtime, and vice versa. If an agent's message blurs them, ask which layer it is changing.
- **Assuming "latest" is required:** some projects deliberately target an older, still-supported version. An agent proposing the newest runtime is making a choice, not following a rule.
- **Ignoring lifecycle:** a runtime version past its support window may still run, but stops receiving fixes — worth questioning before committing to it.
- **Blaming the code:** a "works here, fails there" symptom may be a runtime version difference between the two environments, not a bug in the code.
- **Treating declared versions as guarantees:** a project's declared runtime expectation expresses intent; real compatibility can still require testing.

## Related capabilities

- dependencies-package-managers
- dependency-manifests-lockfiles
- semantic-versioning
- install-build-run-steps

## Official sources

- Node.js — Releases and support lifecycle: https://nodejs.org/en/about/previous-releases
- npm docs — `engines` metadata in package.json: https://docs.npmjs.com/cli/v11/configuring-npm/package-json#engines

## Provenance

- Module: dev-tooling-literacy (fall-2026-0.1.0)
- Capability: runtime-versions-lifecycle
- Claim class: everyday; Safety class: normal
- Sources are real, officially maintained documentation pages (Node.js release/support documentation; npm package.json documentation) verified in this session's research.
- Depth: recognition level only — an annotated example of distinguishing runtime from dependencies and recognizing compatibility/lifecycle issues; no implementation exercise, and no programming-language fundamentals content.
---
title: Dependency manifests vs. lockfiles
module_id: dev-tooling-literacy
capabilities:
  - manifests-vs-lockfiles
context7_library:
context7_queries:
official_sources:
  - https://docs.npmjs.com/cli/v11/configuring-npm/package-json
  - https://docs.npmjs.com/cli/v11/configuring-npm/package-lock-json
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

Many projects use two related files to describe their third-party software:

- **A manifest** (for example, `package.json` in JavaScript/npm projects) records *declared requirements*: which packages the project needs, often with flexible version ranges like "version 4 or later, but within major version 4."
- **A lockfile** (for example, `package-lock.json`) records the *exact resolution*: the specific versions actually chosen, including the dependencies of dependencies, at the last install.

A useful mental model: the manifest is your shopping list ("we need flour"), the lockfile is the receipt ("we bought this exact brand and bag size"). Both belong in the project; they serve different purposes.

## When it is useful

This distinction helps you:

- Recognize why an AI agent may change **more than one file** when installing or upgrading a dependency -- updating the manifest (the declared requirement) and regenerating the lockfile (the recorded resolution) is normal and expected.
- Notice when a teammate or agent committed one file but not the other, which can leave collaborators installing different exact versions.
- Understand conversations about "reproducible installs": with a lockfile, two people installing on different machines get the same exact versions.

## Prerequisites

Recognition-level familiarity with:

- Dependencies and package managers -- the idea that an agent may install third-party software on the project's behalf (see the related capability in this module).
- Config file formats at a glance -- both files are structured text files (JSON in the npm case), so recognizing that format family is enough.

## Current syntax

Recognition cues only -- you are not writing these files by hand.

- `package.json` (the manifest) typically includes a `dependencies` section listing package names with version ranges. A range marker like `^4.2.1` expresses "compatible with 4.2.1" rather than "exactly 4.2.1."
- `package-lock.json` (the lockfile) is usually much longer, because it pins exact resolved versions for the whole dependency tree. It is generally described as generated and maintained by the package manager rather than edited manually.

The same two-file pattern appears in other ecosystems under different names; the key recognition cue is a "requirements/dependencies" file paired with a "lock" file.

## What happens (local and remote)

When an agent installs or upgrades a package:

1. It updates the **manifest** to state the new requirement (for example, adding a package or relaxing a version range).
2. The package manager resolves that requirement against what is available and writes the outcome to the **lockfile**, fixing exact versions for the entire tree.
3. Dependency files are downloaded and set up locally.

This is why an install/upgrade step commonly touches two (or more) files. It is not the agent being sloppy -- the two files record two different things.

Remotely, these files are typically stored with the project so that everyone (and every environment) installs the same exact versions recorded in the lockfile.

## Practical example

Annotated, recognition-level. Suppose an agent reports:

> "Added `left-pad` to package.json and updated package-lock.json, then ran the install."

What you can now recognize:

- **"Added to package.json"** -- the agent declared a new requirement in the manifest. This is the human-readable statement of intent.
- **"Updated package-lock.json"** -- the package manager recorded the exact version it resolved and everything that package itself needs. A large change here is normal even for a small manifest edit.
- **"Ran the install"** -- the step that reads both files and fetches software accordingly (see the "Install, build, run are different steps" capability).

A useful habit when reviewing an agent's work: check that both files changed together when dependencies changed, and ask the agent to explain the manifest change in plain language.

## Explanation guidance

### Essential

- Manifest = what the project says it needs; lockfile = what was actually installed, exactly.
- One install/upgrade legitimately changes both -- that is the system working, not an error.
- If either file is missing, collaborators may end up with different versions of the same software.

### Experienced-user note

- Lockfiles are meant to be shared and committed with the project; the manifest expresses intent, the lockfile records resolution, and keeping both in sync is what makes installs reproducible.
- When an agent proposes an upgrade, the manifest's version-range style is a signal of how broad the requested change is (a within-major-version bump vs. a new major version) -- see the semantic versioning capability in this module.

### Optional deeper context

- Version ranges in the manifest exist so that small compatible updates can be picked up, while the lockfile provides the stability of exact pins for day-to-day installs. The tension between those two goals is a recurring theme in dependency management.
- Different ecosystems (npm, Python packaging, and others) express the same ideas with different file names and formats; the manifest/lockfile division of labor is the transferable concept.

## Cautions and common failures

- **Editing a lockfile by hand.** It records a resolution computed by the package manager; manual edits can desync it from the manifest.
- **Committing the manifest but not the lockfile** (or vice versa). This undermines reproducible installs for teammates and for the agent in future sessions.
- **Assuming the manifest version range is what got installed.** The lockfile is the authoritative record of the exact versions in use.
- **Confusing "lockfile updated" with "everything tested."** A regenerated lockfile records what was installed; it does not establish that the application behaves correctly afterward.

## Related capabilities

- Dependencies and package managers
- Semantic versioning
- Virtual environments
- Install, build, run are different steps
- Reproducing a bug (for establishing consistent starting conditions when dependency changes may be involved)

## Official sources

- npm docs, "Working with package.json": https://docs.npmjs.com/cli/v11/configuring-npm/package-json
- npm docs, "package-lock.json": https://docs.npmjs.com/cli/v11/configuring-npm/package-lock-json

## Provenance

Recognition-level guidance grounded in official npm documentation for `package.json` (dependency declaration) and `package-lock.json` (recorded exact resolution), cross-checked during this session's verified research. Anchored to real vendor documentation rather than an indexed library; per the module contract, Context7 fields are intentionally empty. Content reflects everyday-practice depth (claim_class: everyday, safety_class: normal), stamped fall-2026-0.1.0, and deliberately excludes programming-language fundamentals -- this page covers tooling and workflow recognition only.
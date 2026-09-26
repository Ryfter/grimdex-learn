---
title: Version numbers and semantic versioning
module_id: dev-tooling-literacy
capabilities:
  - semantic-versioning
context7_library:
context7_queries:
official_sources:
  - https://semver.org/
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

Semantic versioning (often shortened to "semver") is a widely-used convention for numbering releases of software as **major.minor.patch** — for example, `4.2.1`. The convention assigns rough meaning to each part:

- **Major** — changes that may break compatibility with earlier versions
- **Minor** — new functionality intended to remain backward-compatible
- **Patch** — fixes that should not change behavior

It is a **convention, not a universal guarantee**. Many projects follow it, some follow it loosely, and some use entirely different numbering schemes. Version numbers are a signal to interpret, not a promise to rely on blindly.

## When it is useful

When an AI coding agent proposes to upgrade a dependency — say, from `4.2.1` to `5.0.0` — the version numbers help you interpret what kind of change is being proposed:

- A jump to a new **major** version deserves extra attention: the convention says something may break.
- A **minor** bump usually means new features, with the old behavior expected to keep working.
- A **patch** bump is usually a safe, low-risk fix.

This lets you ask better questions of the agent ("is this a breaking upgrade?") instead of approving a change you can't interpret.

## Prerequisites

- Recognition of dependency manifests and lockfiles (see the related capability on dependency files), since version numbers usually appear there.

## Current syntax

The conventional format is three numbers separated by dots:

```
4.2.1
│ │ └── patch
│ └──── minor
└────── major
```

You may also see additions after the main three numbers, such as pre-release labels (for example, a hyphenated suffix like `-beta`). These indicate versions that are not yet considered final.

## What happens (local and remote)

- **Locally:** when an agent upgrades a dependency, the version numbers recorded in the project's manifest and lockfile change. The actual software is retrieved from a package registry or repository.
- **Remotely:** the maintainers of each dependency decide what their version numbers mean. There is no central authority enforcing the convention — which is why it should be read as a strong signal rather than a guarantee.

## Practical example

Suppose an agent proposes this change to a project's manifest:

```json
{
  "dependencies": {
    "example-tool": "4.2.1"   // before
  }
}
```

becomes:

```json
{
  "dependencies": {
    "example-tool": "5.0.0"   // after
  }
}
```

Annotated, what a reader can recognize:

- The **major** number changed from 4 to 5 — under the convention, this signals possible breaking changes.
- A reasonable question to the agent: "What breaking changes does version 5 introduce, and what did you adjust to handle them?"
- By contrast, a change from `4.2.1` to `4.2.2` would be a **patch** bump — likely a small fix, lower risk.

Recognizing the shape of the number is enough; no implementation is required.

## Explanation guidance

### Essential

- Version numbers commonly follow the major.minor.patch pattern.
- Major = possibly breaking; minor = new features; patch = fixes.
- This is a convention many projects follow — not a rule, and not a guarantee.
- When an agent proposes an upgrade, the part of the number that changed tells you how much scrutiny the change may deserve.

### Experienced-user note

- Some projects publish changelogs or release notes describing what changed in each version; asking the agent to point at those notes for a major upgrade is a reasonable, low-effort check.
- Version ranges (allowing "any 4.x version," for instance) can appear in manifests; the agent's changes there interact with lockfiles, which record the exact resolved versions.

### Optional deeper context

- The Semantic Versioning specification (semver.org) defines the convention in detail, including pre-release labels and build metadata.
- Related but distinct practices exist — such as calendar-based versioning used by some projects — which is another reason the convention is a signal, not a universal standard.

## Cautions and common failures

- **Treating semver as a guarantee.** A minor or patch bump can still introduce problems if the maintainers made a mistake or don't strictly follow the convention.
- **Assuming all projects use semver.** Some use different numbering schemes where the numbers mean something else, or nothing systematic at all.
- **Approving major upgrades without questions.** A major-version jump is exactly the case where the convention says to look closer — asking the agent what changed is worthwhile.
- **Confusing a version bump with a verified improvement.** The number describes the kind of change, not whether the change works correctly in your project.

## Related capabilities

- Dependency manifests vs. lockfiles
- Dependencies and package managers
- Runtime versions and support lifecycles
- License files

## Official sources

- Semantic Versioning specification: https://semver.org/

## Provenance

- Anchored to the Semantic Versioning specification (semver.org) as listed in the dev-tooling-literacy grounding facts; cross-checked in this session's earlier research.
- Recognition-level treatment consistent with the module contract: an annotated example, not an implementation tutorial.
- No vendor claims beyond the grounding facts; the module deliberately uses official source URLs rather than a Context7 library mapping.
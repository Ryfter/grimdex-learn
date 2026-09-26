---
title: License files and third-party obligations
module_id: dev-tooling-literacy
capabilities:
  - license-files
context7_library:
context7_queries:
official_sources:
  - https://spdx.org/licenses/
  - https://opensource.org/licenses
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

A license file is a text file, usually named something like `LICENSE` or `LICENSE.txt`, that states the conditions under which a piece of software may be used, modified, and redistributed. Nearly every third-party package, library, or code snippet an AI coding agent installs or copies into a project comes with one.

Two widely referenced resources for recognizing license names are:

- The **SPDX License List** (spdx.org/licenses) — a catalog of common license identifiers such as `MIT`, `Apache-2.0`, and `GPL-3.0-only`. These short identifiers appear frequently in package metadata and license files.
- The **Open Source Initiative** (opensource.org/licenses) — the list of licenses that meet the open source definition.

Recognition-level takeaway: a license is not decoration. It is a set of conditions attached to code that is otherwise convenient to install.

## When it is useful

License recognition matters whenever:

- An agent installs a third-party dependency and the project will be distributed, deployed publicly, or used in a business context.
- An agent suggests copying a code snippet from an online source into the project.
- Someone asks whether the team is allowed to use, modify, or ship a particular piece of software.
- An agent proposes an upgrade or a swap to a different package with a different license.

The core habit being built: **publicly available or freely installable does not mean condition-free.** A package can be trivially easy to install and still carry obligations you must honor.

## Prerequisites

- Awareness of what a project's dependencies are (see the dependencies and package managers capability in this module).
- Ability to recognize common file listings a project contains — no programming knowledge needed.

## Current syntax

There is no syntax to learn. What to recognize:

- Files named `LICENSE`, `LICENSE.txt`, `LICENSE.md`, `COPYING`, or `NOTICE` at the top level of a project or package.
- License identifiers in package metadata — for example, a `license` field in a `package.json` manifest, often using SPDX identifiers such as `MIT` or `Apache-2.0`.
- License headers at the top of source files (a block of comment text naming a license).

Common broad categories worth recognizing by name:

- **Permissive licenses** (e.g., MIT, Apache-2.0): few restrictions, typically requiring attribution — keeping the license/copyright notice.
- **Copyleft licenses** (e.g., GPL family): typically require that derivative works be shared under the same license. These can impose significant obligations on a product built with them.

The exact legal terms live in the license text itself; recognition of the identifier and its broad category is the goal here.

## What happens (local and remote)

- **Locally:** installing a package typically copies the license into the package's folder inside the dependency tree. Nothing on your machine enforces the license — compliance is the user's and organization's responsibility.
- **Remotely / at build time:** when a project is built or published, its dependency licenses travel with it. License obligations do not disappear because the code passed through an AI agent, a build pipeline, or a deployment step.

## Practical example

An agent installs a package into a project. A beginner might see something like this in the project's dependency manifest:

```json
{
  "dependencies": {
    "left-pad": "^1.3.0"
  }
}
```

Annotated, recognition-level reading:

- The manifest declares a dependency — but says nothing about its license.
- Opening the installed package's folder would reveal a `LICENSE` file.
- That file might begin with a recognizable pattern, e.g. the MIT license text naming the copyright holder and granting permission "to use, copy, modify, merge, publish, distribute… subject to the following conditions" — with the condition typically being to include the original copyright notice.
- If instead the file were headed "GNU GENERAL PUBLIC LICENSE," that identifier signals copyleft obligations worth checking before the software ships in a product.

The skill is not interpreting the full legal text — it is noticing that a license exists, recognizing common identifiers, and knowing that obligations may apply.

## Explanation guidance

### Essential

- License files state conditions for using someone else's code; "free to download" is not "free of conditions."
- Recognize the file names (`LICENSE`, `COPYING`, `NOTICE`) and common SPDX identifiers (`MIT`, `Apache-2.0`, `GPL`).
- Permissive licenses generally require keeping attribution notices; copyleft licenses can impose stronger sharing obligations.
- An AI agent installing or copying code does not remove these obligations — the person approving the change remains responsible.

### Experienced-user note

- License obligations can propagate through the dependency tree: a direct dependency's own dependencies may carry licenses too. Teams doing this seriously use automated license scanning of the full dependency list.
- License compatibility matters in both directions — a project's chosen license constrains which dependencies it can accept, not just the reverse.

### Optional deeper context

- SPDX identifiers are the de facto standard shorthand for licenses and appear in many package ecosystems' metadata.
- The Open Source Initiative maintains the list of licenses officially approved as open source; some "source available" licenses do not appear there and impose usage restrictions.
- Notice files and copyright notices serve related but distinct roles from the license file itself.

## Cautions and common failures

- **Assuming installability implies permission.** A package being one command away from installation says nothing about permitted use in your context.
- **Assuming the agent handled it.** An agent may install a package without mentioning its license; approval of the install is not a license review.
- **Copying snippets without checking origin.** Code from tutorials, forums, or AI suggestions can carry license obligations from its original source.
- **Confusing "free" with "public domain."** Many free licenses still require attribution or share-alike terms.
- **Treating one license as all licenses.** Two packages with different licenses in the same project can create conflicting obligations.
- **Overclaiming legal certainty.** Recognizing a license identifier is not legal advice; significant commercial or distribution decisions warrant qualified legal review.

## Related capabilities

- dependencies-and-package-managers — licenses arrive with installed dependencies.
- dependency-manifests-vs-lockfiles — where declared dependencies (and their metadata) are recorded.
- runtime-versions-and-support-lifecycles — another "check the fine print" dimension of adopting a dependency.

## Official sources

- SPDX License List — https://spdx.org/licenses/
- Open Source Initiative, licenses — https://opensource.org/licenses

## Provenance

- Module: dev-tooling-literacy, capability `license-files`.
- Recognition-level content grounded in the SPDX License List and Open Source Initiative license listings, per this module's cross-checked research.
- Scope deliberately excludes license-interpretation tutorials, legal analysis, and programming-language fundamentals; the aim is recognition of license information and the habit of not assuming condition-free use.
- Last human review of material: 2026-09-20; claim class `everyday`, safety class `normal`.
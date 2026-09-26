---
title: Student zone vs generated vs config
module_id: grimdex-harness
capabilities:
  - student-zone-layout
context7_library:
context7_queries:
official_sources:
  - https://github.com/Ryfter/Grimdex
  - https://github.com/Ryfter/grimdex-learn
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-product-decision-record
---

## What it is

A student Grimdex install is one folder tree made of pieces owned by different parties. The layout contract (decision record D28) partitions the tree by **ownership**: who owns each path, and what happens to it during install, update, graduation, or removal.

There are four owners:

- **base** — stock Grimdex, the harness itself.
- **learn/** — the Learn module's own files. This is the only folder the module adds to disk (plus the reserved-but-unpopulated `course/`).
- **course/** — reserved space for a professor/class pack. Grimdex-edu does not populate it.
- **student** — `projects/**`, including your personal knowledge base, review inbox, and journal-type content. This is yours.

Layered on top of those paths are two **handling attributes** (not owners — they can apply to any zone):

- **generated** — regenerable files such as logs and indexes. Safe to purge; the system rebuilds them.
- **neverShip** — secret/local state kept locally and excluded from every package, export, or mirror. Examples include `config/fleet.json`, `config/learn-progress.json`, `config/quota.json`, and `config/settings.json`.

## When it is useful

Read this page when you want to know:

- Which files in your install are safe to delete and which are not.
- Why your own notes under `projects/` are never touched by install, update, graduate, or remove.
- What "never ships" means for your config files, and why some folders can be purged without consequence.
- How to tell, for any given path, who owns it and how it is treated.

## Prerequisites

- A completed install (see the install-and-bootstrap capability page).
- Familiarity with what Learn is and does (see the what-is-grimdex page in this module).

## Current syntax

This capability is about layout, not commands. The things to know by name:

- `learn/manifest.json` — a pure-data file (no executable hooks) that declares, among other things: `ownedPaths`, `neverShip` (e.g. `config/fleet.json`, `config/learn-progress.json`, `config/quota.json`, `config/settings.json`), `studentRoots` (e.g. `projects/**`), `generatedRoots` (e.g. `logs/`, `.index/`), and a lifecycle matrix for install/update/graduate/remove.
- Pointer stanzas — `<!-- grimdex-learn:start -->` and `<!-- grimdex-learn:end -->` markers inside `GRIMDEX.md`. These are the **sole legal cross-zone write**: base owns the file, and Learn owns only the bytes between its markers.
- Handling attributes — `generated` and `neverShip`, layered over paths, describing how files are treated regardless of who owns them.

## What happens (local and remote)

Nothing happens remotely. The layout contract is enforced locally by the module's lifecycle operations:

- The module adds **only** `learn/` and `course/` to disk. `base`, `student`, `generated`, and `secret` are classifications of the stock tree, not things the module invents.
- On install, update, graduate, or remove, student roots (`projects/**`) are **always "never-touch."** The lifecycle matrix in `learn/manifest.json` declares this explicitly.
- `neverShip` files stay present locally and are verified absent from every produced bundle, export, or mirror.
- `generated` roots (`logs/`, `.index/`) are regenerable and safe to purge at any time.
- At graduation-verify time, the install checks each zone: base coherent, no leftover learn markers if Learn was removed, `course/` detached, student roots untouched (the single most important check — a semester's worth of knowledge base is the one unrecoverable asset), generated purgeable, and neverShip files local-but-never-shipped.
- If a lifecycle operation encounters a foreign-owner collision on a path, it hard-fails with a path list rather than silently merging. Base always wins a contested path.

## Practical example

Suppose your install folder contains:

```
GRIMDEX.md                  <- base owns it; Learn owns only the bytes between
                               <!-- grimdex-learn:start --> and :end markers
learn/manifest.json         <- learn/ owns it (pure data)
projects/my-notes/          <- yours. Never touched by install/update/graduate/remove
projects/my-notes/kb.md     <- yours (personal knowledge base)
logs/                       <- generated. Safe to delete; rebuilt as needed
.index/                     <- generated. Safe to delete; rebuilt as needed
config/fleet.json           <- neverShip. Stays on your machine; never in any export
config/learn-progress.json  <- neverShip
config/settings.json        <- neverShip
```

If you decide to graduate or remove the module, `projects/my-notes/` is left exactly as it was. If you delete `logs/` and `.index/` to free space, nothing is lost — they are regenerated. If you zip up your install to share it, `config/fleet.json` and the other neverShip files are not included in the bundle.

## Explanation guidance

### Essential

- Four owners: base, learn/, course/, student. Your work lives under `projects/**` and belongs to the student owner.
- Two handling attributes layered over paths: generated (safe to purge) and neverShip (stays local, never exported).
- The module touches only `learn/` (plus `course/`, which it reserves but does not populate) and the marker bytes inside `GRIMDEX.md`. Nothing else.
- Deleting `logs/` or `.index/` is safe; deleting `projects/**` or `config/` is not.
- neverShip files are excluded from every package, export, or mirror — they stay on your machine.

### Experienced-user note

- `learn/manifest.json` is the authoritative declaration of all of the above: owned paths, neverShip list, student roots, generated roots, and the per-operation lifecycle matrix. If you are unsure how a path will be treated, that file is where the answer lives.
- The pointer stanza is deliberately narrow: base owns `GRIMDEX.md`, and Learn owns only the bytes between its start/end markers. If the module is removed, the markers and their contents are removed and base's file is left coherent — graduation-verify checks for this.
- Collisions between owners are hard failures with a path list, not silent merges. Base always wins a contested path, so a rogue tool cannot quietly claim a Grimdex-owned file.

### Optional deeper context

- The graduation-verify step treats "student roots verified untouched" as the single most important check, because a semester's accumulated knowledge base is the one asset that cannot be regenerated or recovered from anywhere else.
- Course-pack content (if a class provides it) lands under `course/` as agent-consumed, non-executable Markdown. It cannot declare lifecycle behavior or request access to secret files.

## Cautions and common failures

- Do not delete or hand-edit `learn/manifest.json`. It is the contract that makes all the guarantees above verifiable.
- Do not put personal notes anywhere except under `projects/`. Paths outside your zone may be owned by base or learn/ and could be replaced by an update.
- Do not assume that deleting a config file is harmless. Files in the neverShip list are local state, not regenerable caches.
- If a lifecycle command stops with a list of colliding paths, that is a hard-fail by design — it is telling you something contested the tree rather than silently overwriting it.
- If you see learn markers in `GRIMDEX.md` after removing the module, that is a verify failure, not expected behavior.

## Related capabilities

- what-is-grimdex — the introduction to Learn and how it relates to base Grimdex and the wiki.
- install-and-bootstrap — the install procedure that creates the layout described here.

## Official sources

- https://github.com/Ryfter/Grimdex — the public Grimdex engine repository (base harness).
- https://github.com/Ryfter/grimdex-learn — the public release repository for the Learn module (manifest, installer, and this capability set).

## Provenance

This page was authored against this product's own locked decision records, specifically D28 (path and ownership contract), with supporting context from D36 (three-layer ladder) and D41 (what Grimdex-edu is). It is not derived from an external vendor document. It should be fact-checked against those decision records before shipping.

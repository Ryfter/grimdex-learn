---
title: Large files and Git LFS (recognition level)
module_id: git-and-github
capabilities:
  - git-lfs-basics
context7_library: /websites/github_en
context7_queries:
  - How does Git LFS store large files in a repository?
  - Why do large binary files make git clones slow?
  - What is a Git LFS pointer file?
official_sources:
  - https://docs.github.com/en/repositories/working-with-files/using-large-files/about-large-files-on-github
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

Git Large File Storage (LFS) is an extension that addresses a real weakness of plain Git: storing large binary files. In ordinary Git, every version of every file is stored in the repository history, so a folder of videos, design files, or datasets quickly makes the repository enormous and slow to clone or fetch. Git LFS replaces those large binary files in the repository with small text pointers, while the actual file content is stored on a separate LFS server. When your working copy needs the file, the pointer is swapped for the real content.

## When it is useful

Recognize this pattern when a project includes files like video, audio, large images, design artifacts (Photoshop, 3D models), or datasets — file types that are large, binary, and change over time. Committing those files normally bloats the repository for everyone: every clone and every fetch downloads all historical versions of those files, even if a person only needs the latest one. LFS keeps the Git repository small and makes large assets available on demand.

## Prerequisites

- Basic Git familiarity: commits, clone, fetch.
- Awareness that Git stores full history locally, which is why file size affects clone/fetch performance.

## Current syntax

Recognition level only — no setup or administration detail is required at this tier. The essential concept to know is:

- Large files are tracked by LFS rather than committed as ordinary blobs.
- In the repository, what gets stored is a small text pointer (metadata referencing the content on the LFS server), not the binary itself.

## What happens (local and remote)

- Locally: when you clone or pull a repository that uses LFS, the large files in the repo are represented by small pointer files; the actual binary content is fetched separately from the LFS server as needed.
- Remotely: the Git repository history stays small because it only contains pointers. The real file content lives on a separate LFS server, so clones and fetches remain fast.

The net effect: people who don't need a particular large file's full history avoid downloading every version of it.

## Practical example

A design team commits a 200 MB video file directly to Git. Every teammate's next clone downloads all prior versions of that video too — the repository grows by hundreds of megabytes per edit. With Git LFS, the repository stores only a tiny pointer to the video; the binary content is fetched from the LFS server on demand. Clone times stay small, and the repo history doesn't balloon.

## Explanation guidance

### Essential

- Git stores every historical version of every file locally; large binaries make clones and fetches slow and huge.
- Git LFS replaces large binary files in the repo with small text pointers; the real content lives on a separate LFS server.
- Recognize the symptom: a repo that's slow to clone because of videos, design files, or datasets.

### Experienced-user note

- LFS changes the storage location, not the workflow — users still commit and pull normally; the pointer-to-content swap happens behind the scenes.
- Teams typically declare which file types LFS handles so the split is automatic rather than per-file decisions.

### Optional deeper context

- The pointer is plain text containing metadata about the file and where to retrieve it, which is why it stays small regardless of the binary's size.
- Because content is external to Git history, deleting a large file from the repo doesn't automatically address how it was stored historically — a reason to adopt LFS before large binaries accumulate in history.

## Cautions and common failures

- Committing a large binary normally (not via LFS) puts it into history permanently; later removing the file does not shrink existing clones that already downloaded it.
- A clone of an LFS repo without LFS handling yields pointer files instead of usable binaries — seeing small text files where videos or images should be is the classic sign.
- This page is recognition level only: actual LFS setup, server administration, and quota management are out of scope.

## Related capabilities

- tags-and-releases — releases can package build assets for distribution
- partial-staging — controlling what goes into a commit
- git-lfs-basics (this page) — companion topics in the same module include secret-scanning-push-protection for what shouldn't be committed at all

## Official sources

- https://docs.github.com/en/repositories/working-with-files/using-large-files/about-large-files-on-github — GitHub's documentation on large files in repositories and how Git LFS addresses them.

## Provenance

This page was authored against GitHub's official documentation ("About large files on GitHub", docs.github.com), retrieved via Context7. It should be spot-checked against current docs before shipping, since GitHub's documentation paths reorganize periodically. Scope is recognition-level per the grounding facts: pointer files replacing large binaries and why clone/fetch size is the problem LFS solves; no setup or administration content is claimed.
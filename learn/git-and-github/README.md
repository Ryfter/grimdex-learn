# Git and GitHub field guide

Audience-generic capability reference for Git and GitHub. This is a **Learn module**:
best-practice explainers any Grimdex user can install to learn while building. It is not
course material — anything course-scented lives in `course/`, never here.

## What this module is

- Transferable git concepts first; GitHub is one forge dialect. Other forges appear only
  as cross-tool vocabulary rows.
- Facts live in `capabilities/*.md`, one page per capability group, each following the
  frozen 12-section page contract (YAML front matter + eleven fixed sections).
- Normalized claims with primary-source pointers live in `claims/baseline.yaml`.
- Sources, refresh rules, and provenance are documented in `source-registry.md`,
  `refresh-policy.md`, and `provenance.md`.

## Content admission

Every page passes the content-admission test before it lands: useful without any
specific course or professor; public-ready from its first reviewed version; claims about
Grimdex behavior are version-stamped; provenance is honest; the module is removable via
`learn/manifest.json`.

## Reading order

Start with `capabilities/commits-and-history.md` if you are new to version control
history; each page lists its prerequisites and related capabilities.

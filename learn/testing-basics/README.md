# Testing basics for non-CS majors

This is a **Learn module**: essentials-depth explainers any Grimdex user can install to
learn while building. It is not course material — anything course-scented lives in
`course/`, never here.

## What this module is

- One page per capability in `capabilities/*.md`, each following the frozen D32 page
  contract (YAML front matter + eleven fixed sections).
- Sources, refresh rules, and provenance are documented in `source-registry.md`,
  `refresh-policy.md`, and `provenance.md`.
- Depth discipline: pages stop at what/why plus a bit of how, then link to official
  documentation.

## Content admission

Every page passes the content-admission test before it lands: useful without any
specific course or professor; public-ready from its first reviewed version; claims about
vendor behavior are version-stamped and source-linked; provenance is honest; the module
is removable via `learn/manifest.json`.

## Pages (3)

- `capabilities/fix-one-failure.md` — Fixing one failing test at a time
- `capabilities/run-tests-locally.md` — Running pytest/Pester and reading pass-fail
- `capabilities/why-tests-exist.md` — Tests as save points for behavior

Each page lists its own prerequisites and related capabilities.

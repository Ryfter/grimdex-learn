# Prompt engineering field guide

Audience-generic capability reference for working with coding agents: context,
instructions, tools, and verification. This is a **Learn module**: best-practice
explainers any Grimdex user can install to learn while building. It is not course
material — anything course-scented lives in `course/`, never here.

## What this module is

- Transferable agent-workflow concepts first; vendor documentation is an anchor for
  verified facts, not a product pitch. The ideas apply across tools that use large
  language models as assistants.
- Facts live in `capabilities/*.md`, one page per capability group, each following the
  frozen 12-section page contract (YAML front matter + eleven fixed sections).
- Normalized claims with primary-source pointers live in `claims/baseline.yaml`.
- Sources, refresh rules, and provenance are documented in `source-registry.md`,
  `refresh-policy.md`, and `provenance.md`.

## Content admission

Every page passes the content-admission test before it lands: useful without any
specific course or professor; public-ready from its first reviewed version; claims about
provider behavior are version-stamped and source-linked; provenance is honest; the module
is removable via `learn/manifest.json`.

## Reading order

Start with `capabilities/context-and-working-memory.md` if you are new to how models
use conversation history; each page lists its prerequisites and related capabilities.

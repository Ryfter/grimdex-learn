---
title: Recognizing JSON, YAML, and TOML config files
module_id: dev-tooling-literacy
capabilities:
  - config-file-formats
context7_library:
context7_queries:
official_sources:
  - https://www.rfc-editor.org/rfc/rfc8259
  - https://yaml.org/spec/1.2.2/
  - https://toml.io/en/
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

Configuration files are the settings files a tool reads to know how a project should behave -- which options are on, where things live, how a service connects. Three file formats appear over and over in real projects:

- **JSON** (`.json`) -- curly braces, colons, quoted names, commas. Example: `package.json`, most API request/response payloads.
- **YAML** (`.yaml` or `.yml`) -- indented lines, no mandatory braces or quotes. Example: CI pipeline files, deployment manifests.
- **TOML** (`.toml`) -- `key = "value"` lines under `[section]` headings. Example: `pyproject.toml`, `Cargo.toml`.

Recognizing which format a file is in lets you understand what an AI coding agent is configuring and why it cares about exact formatting -- without you needing to write these files by hand. This is recognition, not a syntax course.

## When it is useful

- An agent opens or edits a settings file and you want to follow what is being changed and why.
- An agent says a config change "didn't take" -- often the issue is that the tool reading the file is strict about format, not that the setting is wrong.
- You are reviewing agent-proposed changes to files like `package.json`, a pipeline file, or `pyproject.toml` before approving them.
- A file name ends in one of these extensions and you want a rough idea of what kind of content to expect.

## Prerequisites

- General awareness that projects contain files with settings in addition to the application's own code (the dependency-manifests lesson covers a concrete example).
- No coding, shell, or format-writing knowledge required.

## Current syntax

Not applicable at recognition level -- the point is to *identify* the formats, not learn their syntax. The "Practical example" below shows each format's recognizable look.

## What happens (local and remote)

All three formats are read locally by tools on your machine or by services that receive the file. The tool parses the file -- converts the text into structured settings it can act on. Parsing is unforgiving: a missing quote, wrong indentation, or stray character can make the whole file unreadable to the tool, which then reports a format/parse error. Nothing is transmitted anywhere just because a config file exists remotely or in the cloud; but files placed in shared repositories are visible to whoever can access that repository, which matters if settings ever include anything sensitive.

## Practical example

Three files that each express the same setting ("the app name is storefront and retries are enabled"), shown side by side so you can recognize the differences:

```json
{
  "name": "storefront",
  "retries": true
}
```

```yaml
name: storefront
retries: true
```

```toml
name = "storefront"
retries = true
```

How to tell them apart at a glance:

- **JSON**: everything wrapped in `{ }`, names in double quotes, colons between name and value, commas between entries. Its formatting rules are strict -- the parser expects exact quoting and punctuation.
- **YAML**: plain lines with no braces. Indentation (how far a line is pushed in) carries meaning -- the tool uses it to understand what belongs to what. A line indented incorrectly can silently change the meaning.
- **TOML**: `name = value` pairs, often organized under bracketed section headings like `[server]`.

When an agent edits one of these files, small formatting details are the *mechanism*, not pedantry: they are how the file communicates structure to the tool reading it.

## Explanation guidance

### Essential

- These are three common formats for the same kind of thing: settings a tool reads.
- Formatting rules matter because the file is parsed mechanically -- the tool does not "get the gist" the way a human reader would.
- Recognizing the format from the file extension or the look of the content is enough for most collaboration with an agent.

### Experienced-user note

- The same setting can usually be expressed in any of the three formats -- projects pick based on the tool that reads the file, not because one is "better."
- If an agent's config edit produces a parse error, the error usually names the file and line; the fix is typically a formatting correction, not a change of intent.

### Optional deeper context

- Each format is defined by an independent specification maintained by a standards or community body -- JSON by an IETF standards document (RFC 8259), YAML by its published 1.2.2 specification, TOML by its own specification at toml.io. Tools aim to conform to these specs, which is why strictness varies slightly between them.
- Config files are one entry in a broader family: dependency manifests (covered in the dependencies lesson) are config files with a specific job.

## Cautions and common failures

- **Assuming a config edit is safe because it's "just settings."** Settings can change what a tool connects to, installs, or exposes. Review what the setting does, not just whether the format looks right.
- **Treating a parse error as a broken tool.** Most often the file's formatting is at fault, not the tool.
- **YAML indentation traps.** Because indentation carries meaning, a visually small reformat can change what a file says. This is a reason to look carefully at agent-proposed YAML edits, not to avoid them.
- **Secrets in config files.** Some tools offer putting credentials in config files; that overlaps with the secrets-management cautions in the environment-variables lesson -- don't hard-code credentials or casually share files containing them.

## Related capabilities

- dependency-manifests-vs-lockfiles
- environment-variables-and-env-files
- install-build-run-steps
- database-connections-and-connection-strings

## Official sources

- JSON: RFC 8259 -- https://www.rfc-editor.org/rfc/rfc8259
- YAML specification 1.2.2 -- https://yaml.org/spec/1.2.2/
- TOML specification -- https://toml.io/en/

## Provenance

- Capability scoped to recognition-level identification of JSON, YAML, and TOML per the dev-tooling-literacy grounding facts; sources are the official specification documents for each format.
- Deliberately excludes syntax instruction and programming-language fundamentals; depth is "recognize the format and why strict formatting matters."
- context7_library left empty by design: this topic spans independent specification bodies rather than one indexed vendor library; official source URLs are used instead.
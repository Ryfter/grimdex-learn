---
title: ".env files and keeping secrets out of code"
module_id: dev-tooling-literacy
capabilities:
  - dotenv-and-secrets
context7_library:
context7_queries:
official_sources:
  - https://nodejs.org/api/environment_variables.html
  - https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
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

A `.env` file is a plain text file, conventionally named `.env`, where a project stores configuration values — most importantly credentials such as API keys, database passwords, and access tokens — outside the source code itself. Tools and frameworks in many ecosystems (Node.js, Python projects, and others) will read these values and supply them to the running program as environment variables.

Two recognition points matter here:

- **It is a convention, not a standard.** Different tools and frameworks handle `.env` files differently — where the file lives, its exact format, and which names they expect can all vary by tool. Recognizing "this is configuration supplied to the program" is enough; you do not need to learn the syntax.
- **It is not a secure vault.** A `.env` file is unencrypted text sitting on disk. Putting a secret in it keeps the secret out of the source code, but it does not make the secret safe to publish, share, or commit carelessly.

## When it is useful

This literacy matters when:

- An AI agent proposes creating a `.env` file, or asks you to "add your API key to the environment" — you should be able to recognize what that request means and where the secret will live.
- An agent asks you to paste a credential into a source file directly (hard-coding). This is the pattern to question.
- A project fails to start because a value "isn't set" — the likely cause is a missing or differently-named configuration value, not a broken program.
- You are deciding what to share: a `.env` file containing real credentials should not be pasted into chat, email, or screenshots.

## Prerequisites

Recognition-level familiarity with:

- **Environment variables** — settings supplied to a program from outside its code; a `.env` file is one common way of getting those values loaded. (See the environment-variables capability in this module.)
- **Files and directories** — knowing that a hidden dotfile like `.env` sits in the project folder alongside the code.

## Current syntax

A minimal annotated example of the shape of a `.env` file:

```text
# Lines like these: a name, an equals sign, a value.
# Names are conventionally UPPERCASE; values are plain text.

DATABASE_URL=postgresql://user:password@db.example.com:5432/mydb
API_KEY=sk-example-1234567890abcdef
DEBUG=true

# The names a program expects are defined by the tool or project,
# not by a universal rule — the app reads the names it was written to read.
```

You never need to write this file by hand as a reader of this lesson — you need to recognize what an agent is doing when it creates one, fills one in, or asks you for a value to put in it.

## What happens (local and remote)

**Locally.** A tool loads the `.env` file's values and supplies them to the running program as environment variables. The program behaves differently based on those values — which database it connects to, which API it calls — without any change to the source code.

**In version control and sharing.** Projects conventionally exclude `.env` files from version control (a `.gitignore` entry). This is why an agent may create a `.env.example` file alongside it: a template showing which names the project expects, with placeholder values, safe to commit. Recognizing that pattern — a real `.env` kept private, a template committed publicly — is the recognition goal.

**Remotely.** When the app is deployed, the values must be provided another way (typically through the hosting service's configuration settings). A secret that worked locally will not automatically follow the app to a server, and a casually shared `.env` file can expose live credentials to anyone who receives it.

## Practical example

An agent is building a small app that fetches weather data. You give it an API key from a weather service. Compare two ways the agent might handle it:

**Hard-coded (the pattern to question):**

```text
// in the program's source code
const apiKey = "sk-example-1234567890abcdef"
```

The secret is now part of the code itself. If that file is shared, committed, or shown in a demo, the credential goes with it, and replacing it means editing code.

**Configuration file (the recognized pattern):**

```text
# .env
WEATHER_API_KEY=sk-example-1234567890abcdef
```

The code reads the name `WEATHER_API_KEY` from the environment; the value stays in the local file, which is kept out of version control. The agent may also create a `.env.example` with the same name and a placeholder value, so teammates know which settings the project needs without seeing real credentials.

Both versions run identically. The difference is what happens when the code is shared, committed, or reused — and that difference is the whole point.

## Explanation guidance

### Essential

- A `.env` file keeps secrets out of source code by holding them as configuration supplied to the program at runtime.
- It is a convention that varies by tool, not a guaranteed standard — names and loading behavior depend on the framework.
- A `.env` file is plain text, not encryption. "It's in the .env file" does not mean "the secret is safe to share."
- Credentials should not be hard-coded into program files, and a `.env` file containing real credentials should not be pasted into chats, emails, tickets, or screenshots.

### Experienced-user note

Experienced teams pair the private `.env` file with a committed `.env.example` template listing the names the project expects with placeholder values, and treat any credential that has ever appeared in a commit, log, or shared file as compromised — rotating it rather than deleting the evidence. Some platforms offer dedicated secret managers for higher-stakes credentials; a local `.env` is a hygiene practice, not a security system. You do not need to operate any of these to collaborate well — you need only recognize that "move the secret out of the code" is the shape of good practice, and that "bigger secrets management" exists as the next step.

### Optional deeper context

The OWASP Secrets Management Cheat Sheet treats hard-coded credentials and secrets in shared files as a recognized class of security failure, and outlines dedicated secrets-management systems for organizations that need them. The Node.js documentation describes how programs receive configuration through environment variables — the mechanism a `.env` file feeds into. Reading either is optional; both are official and linked below.

## Cautions and common failures

- **Assuming ".env" means secure.** The file is unencrypted text. Its value is keeping secrets out of code and version control, not protecting them from anyone who can read the disk or receive a copy.
- **Pasting real credentials into chat with an agent.** A value shared in a conversation, screenshot, or ticket is casually shared. Prefer putting the value in the `.env` file yourself and letting the agent reference it by name, or use a placeholder during development and add the real credential last.
- **Committing the real file.** If a `.env` file with real credentials lands in version control, the credential should be treated as exposed and replaced — removal from the repository afterward does not undo the exposure.
- **Name mismatches.** A program reads the specific names it was written to read; a typo or different name means the value is silently absent, and the app misbehaves without a clear error.
- **Placeholder confusion.** A `.env.example` contains fake values; copying it as your real `.env` and forgetting to replace the placeholders is a common way an app "runs but does nothing useful."

## Related capabilities

- environment-variables — how a program receives configuration values from its surroundings; the `.env` file is one common delivery mechanism.
- config-file-formats — recognizing JSON/YAML/TOML configuration; a `.env` file is a related but distinct, tool-dependent convention.
- api-credentials-authentication — where the credentials stored in a `.env` file are typically used, and the difference between authentication and permission.
- database-connection-strings — a common kind of value found in a `.env` file, and why it deserves the same care.
- version-control-basics — why keeping the real `.env` out of committed history matters.

## Official sources

- Node.js documentation, "Environment variables": https://nodejs.org/api/environment_variables.html
- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html

## Provenance

Module: dev-tooling-literacy. Capability: dotenv-and-secrets. Grounded in this session's verified research (openrouter-pareto, cross-checked) using two real official anchors: the Node.js documentation on environment variables (the mechanism `.env` files feed into) and the OWASP Secrets Management Cheat Sheet (the security guidance on not hard-coding or casually sharing credentials). Depth is recognition-level per the frozen page contract: an annotated example, not an implementation exercise. context7_library is deliberately empty for this module — the topics span vendor docs that do not map to a single indexed library, so official source URLs are used instead. Version stamp: fall-2026-0.1.0; checked 2026-09-20.
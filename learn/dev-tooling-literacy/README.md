# Developer tooling literacy

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

## Pages (25)

- `capabilities/api-auth-and-permissions.md` — API credentials, authentication, and permissions
- `capabilities/apis-endpoints-rest.md` — APIs, endpoints, and REST
- `capabilities/config-file-formats.md` — Recognizing JSON, YAML, and TOML config files
- `capabilities/containers-and-sandboxes.md` — Containers, sandboxes, and isolation boundaries
- `capabilities/database-connections.md` — Database connections and connection strings
- `capabilities/database-migrations.md` — Database migrations: changes to stored structure
- `capabilities/dependencies-and-package-managers.md` — Dependencies and package managers
- `capabilities/dotenv-and-secrets.md` — .env files and keeping secrets out of code
- `capabilities/environment-variables.md` — Environment variables
- `capabilities/exit-codes.md` — Exit codes: how commands signal outcomes
- `capabilities/file-permissions.md` — File permissions and access
- `capabilities/formatters-and-linters.md` — Formatters and linters: different kinds of cleanup
- `capabilities/http-requests-responses.md` — HTTP requests and responses
- `capabilities/install-build-run.md` — Install, build, and run are different steps
- `capabilities/license-files.md` — License files and third-party obligations
- `capabilities/localhost-and-ports.md` — Localhost, ports, and exposed services
- `capabilities/logs-and-severity-levels.md` — Application logs and severity levels
- `capabilities/manifests-vs-lockfiles.md` — Dependency manifests vs. lockfiles
- `capabilities/processes-and-servers.md` — Running processes and stopping a server
- `capabilities/reproducing-a-bug.md` — Reproducing a bug: making a symptom repeatable
- `capabilities/runtime-versions-lifecycle.md` — Runtime versions and support lifecycles
- `capabilities/semantic-versioning.md` — Version numbers and semantic versioning
- `capabilities/terminal-shell-commands.md` — Terminal, shell, and commands
- `capabilities/virtual-environments.md` — Virtual environments: keeping dependencies separate
- `capabilities/working-directories-and-paths.md` — Working directories and paths

Each page lists its own prerequisites and related capabilities.

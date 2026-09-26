# Under the hood: the agent ecosystem

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

## Pages (15)

- `capabilities/agent-ecosystem-map.md` — One map: CLIs, MCP, Skills, and plugins
- `capabilities/api-keys-static-credential.md` — API keys: the static master key
- `capabilities/choosing-the-right-component.md` — Which one when: a routing table for CLI/MCP/Skill/plugin
- `capabilities/cli-tools-as-agent-capabilities.md` — CLI tools: capabilities your agent already has
- `capabilities/mcp-host-client-server.md` — Host, client, server: who talks to whom in MCP
- `capabilities/mcp-servers-standardized-connectors.md` — MCP servers: standardized connectors
- `capabilities/mcp-vs-cli-tradeoffs.md` — MCP vs. shelling out: when each wins
- `capabilities/name-that-component-practicum.md` — Practicum: name that component from a real config
- `capabilities/oauth-delegated-scoped-access.md` — OAuth: borrowed, scoped, revocable access
- `capabilities/oauth-mcp-and-agent-login.md` — Where it meets: OAuth, MCP, and your agent's own login
- `capabilities/oauth-scopes-read-before-allow.md` — Scopes: read before you click Allow
- `capabilities/plugins-are-packaging-not-rivals.md` — Plugins: packaging, not a rival to MCP
- `capabilities/revocation-lives-with-provider.md` — Revocation lives with the provider, not the agent
- `capabilities/skills-packaged-know-how.md` — Skills: packaged know-how the agent loads on demand
- `capabilities/token-expiry-recognition.md` — When tokens expire (and how it looks)

Each page lists its own prerequisites and related capabilities.

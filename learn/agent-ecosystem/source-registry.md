# Source registry — agent-ecosystem

Priority order (canonical facts come only from tiers 1–3):

1. **Official vendor or specification documentation**
2. **Official related product documentation** (not marketing copy)
3. **Cross-tool practice guidance** — always labeled as guidance, never as vendor fact
4. Third-party tutorials — teaching questions only, **never** canonical facts.

## Registered sources

Generated from each page's `official_sources` front matter.

| Source | Pages |
|---|---|
| <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview> | `agent-ecosystem-map`, `choosing-the-right-component`, `cli-tools-as-agent-capabilities`, `mcp-host-client-server`, `mcp-servers-standardized-connectors`, `mcp-vs-cli-tradeoffs`, `name-that-component-practicum`, `oauth-scopes-read-before-allow`, `revocation-lives-with-provider`, `skills-packaged-know-how`, `token-expiry-recognition` |
| <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill> | `agent-ecosystem-map`, `api-keys-static-credential`, `plugins-are-packaging-not-rivals` |
| <https://modelcontextprotocol.io> | `agent-ecosystem-map`, `choosing-the-right-component`, `mcp-host-client-server`, `mcp-servers-standardized-connectors`, `mcp-vs-cli-tradeoffs`, `name-that-component-practicum`, `oauth-mcp-and-agent-login` |
| <https://oauth.net/2/> | `api-keys-static-credential`, `choosing-the-right-component`, `mcp-vs-cli-tradeoffs`, `name-that-component-practicum`, `oauth-delegated-scoped-access`, `oauth-mcp-and-agent-login`, `oauth-scopes-read-before-allow`, `revocation-lives-with-provider`, `token-expiry-recognition` |
| <https://datatracker.ietf.org/doc/html/rfc6749> | `oauth-delegated-scoped-access`, `oauth-mcp-and-agent-login`, `oauth-scopes-read-before-allow`, `revocation-lives-with-provider`, `token-expiry-recognition` |

## Context7 libraries

Pages record their own `context7_library` and stored `context7_queries` in front matter
so refresh checks are reproducible. Libraries used in this module: `/websites/platform_claude_en`.

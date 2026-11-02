# OpenCode v2 + Claude Agent sandbox kit

A Docker Sandboxes (`sbx`) v3 workload kit that runs **OpenCode v2** with
**Claude Code** inside, pre-connected through OpenCode's built-in
**Claude Agent** provider (OpenCode drives `claude` via the Claude Agent SDK;
Claude uses OpenCode's tools and permission system).

| File | Purpose |
|---|---|
| `opencode-claude.yaml` | Kit descriptor: credentials, network policy, volumes, hooks |
| `opencode-claude.dockerfile` | Image: `docker/sandbox-templates:claude-code` + pinned Claude Code + OpenCode v2 (`@opencode/cli`) |

Pinned versions: OpenCode `2.2.5`, Claude Code `2.1.316` (the provider needs ≥ 2.1.248).

## Credentials

Give `sbx` an Anthropic credential on the host. Inside the sandbox you only ever see sentinels:

```bash
sbx secret set anthropic -t "sk-ant-..."   # API key
# or log in with your claude.ai subscription (OAuth) using sbx's anthropic login flow
```

- **OAuth / subscription**: rendered into `~/.claude/.credentials.json`, which `claude` reads.
- **API key**: an install hook writes `providers.claude-agent.settings.apiKey` into
  `~/.config/opencode/opencode.json`. This is needed because the provider launches
  `claude` with `settingSources: []`, which ignores `apiKeyHelper`.
- **None**: run `claude auth login` in a sandbox shell, then `/connect` → *Claude Agent*.

## Run

```bash
cd /path/to/your/project
sbx kit validate /path/to/sbx-kits/opencode-claude   # optional
sbx run /path/to/sbx-kits/opencode-claude .          # builds the kit and opens OpenCode
```

OpenCode defaults to **Claude Agent → Opus** (`claude-agent/opus`, which is Opus 5.5
on the pinned Claude Code). The install hook sets `"model"` in
`~/.config/opencode/opencode.json` only if it isn't already set. To switch models,
open `/models`. The list fills in after the provider's first probe of `claude`.

Override versions at create time:

```bash
sbx run /path/to/sbx-kits/opencode-claude --kit-arg opencodeVersion=2.2.6 --kit-arg claudeVersion=2.1.320 .
```

## Plain image (no kit)

```bash
docker buildx build -f opencode-claude.dockerfile \
  --build-arg OPENCODE_VERSION=2.2.5 --build-arg CLAUDE_VERSION=2.1.316 \
  -t opencode-claude:latest .
```

Note that the credential wiring above lives in the kit descriptor. The bare image
only gets it when it runs as a kit.

## Notes

- OpenCode starts with `--auto`, which auto-approves permissions that are not
  explicitly denied. The sandbox is the boundary, the same way the Claude kit runs
  `--dangerously-skip-permissions`.
- `~/.local/share/opencode` (sessions, integration state) and `~/.claude/projects`
  (the SDK transcripts behind them) are volumes.
- Check Anthropic's terms before routing a claude.ai *subscription* through a
  third-party tool. An API key has no such ambiguity.

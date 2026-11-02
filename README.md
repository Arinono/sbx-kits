# sbx kits

Docker Sandboxes (`sbx`) v3 workload kits.

| Kit | What it runs | Credential |
|---|---|---|
| [`opencode-claude/`](opencode-claude/README.md) | OpenCode v2 driving Claude Code through its Claude Agent provider (default model: Opus) | API key or claude.ai subscription; proxy-managed, no secret in the sandbox |
| [`claude-chrome/`](claude-chrome/README.md) | Claude Code with Claude in Chrome (drives the Chrome on your host) | claude.ai subscription only; **the real OAuth token enters the sandbox** |
| [`forgejo/`](forgejo/README.md) | *Mixin*: `fj` (forgejo-cli) and git-over-HTTPS access to one private Forgejo instance, set with `--kit-arg forgejo.host=…` | Forgejo access token (`sbx secret set forgejo`); proxy-managed, no secret in the sandbox |

```bash
sbx run /path/to/sbx-kits/opencode-claude .
sbx run /path/to/sbx-kits/claude-chrome .

# either workload, plus Forgejo access
sbx run /path/to/sbx-kits/opencode-claude \
  --kit /path/to/sbx-kits/forgejo --kit-arg forgejo.host=git.example.com .
```

`mise run validate` validates all kits. `mise run build:opencode`,
`mise run build:claude-chrome` and `mise run build:forgejo` build the plain
images.

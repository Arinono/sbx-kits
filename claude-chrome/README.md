# Claude Code + Claude in Chrome sandbox kit

A Docker Sandboxes (`sbx`) v3 workload kit that runs **Claude Code** with
**Claude in Chrome** turned on, so the agent can drive the Chrome on your host
for visual reviews, screenshots and browsing.

| File | Purpose |
|---|---|
| `claude-chrome.yaml` | Kit descriptor: credential, network policy, volumes, hooks |
| `claude-chrome.dockerfile` | Image: `docker/sandbox-templates:claude-code` + pinned Claude Code, started with `--chrome` |

Pinned version: Claude Code `2.1.316`. The default model is `opus`.

## How it connects

Chrome stays on your Mac. `claude` in the sandbox and the Claude extension in
Chrome both connect to Anthropic's relay, `wss://bridge.claudeusercontent.com`.
They pair when both are signed into the **same claude.ai account**. The
sandbox never reaches Chrome directly.

## Requirements and trade-off

- **claude.ai subscription only.** The kit declares no API-key credential. The
  relay pairs with a claude.ai account, so an API key can't work.
- **The real OAuth token enters the sandbox.** The relay reads the token from
  the WebSocket's first message, not from an HTTP header, so the `sbx` proxy
  can't swap a placeholder for it. A placeholder token gets
  `OAuth token rejected (401)`. The kit therefore sets
  `oauth.passthrough: true`, which makes `sbx` hand your real token to
  the sandbox. Anything in the sandbox, including the model, can read it. You
  still sign in on the host. Use the `opencode` kit when you don't need the
  browser.

## Setup

1. In Chrome, install the Claude extension (<https://claude.ai/chrome>) and sign
   in with your claude.ai account.
2. Sign `sbx` in to the same account with its Anthropic OAuth flow on the host.
   Approve the credential when the kit asks for it on first run.
3. Run the kit:

   ```bash
   cd /path/to/your/project
   sbx kit validate /path/to/sbx-kits/claude-chrome   # optional
   sbx run /path/to/sbx-kits/claude-chrome .
   ```

4. In Claude Code, run `/chrome` to check the connection, or ask something like
   "open https://example.com and screenshot it".

Override the version or model:

```bash
sbx run /path/to/sbx-kits/claude-chrome --kit-arg version=2.1.320 --kit-arg model=sonnet .
```

### Reviewing a dev server running in the sandbox

The browser runs on your host, so it can only open a sandbox server whose port
is published. The server must listen on `0.0.0.0`:

```bash
sbx ports <sandbox-name> --publish 3000:3000
```

Then ask Claude to open `http://localhost:3000`.

## If `sbx` refuses passthrough

The spec lets a runtime refuse `passthrough`. If Claude then reports the
extension as "not connected" and `~/.claude/.credentials.json` still holds
`sk-ant-oat01-proxy-managed`, use a long-lived subscription token instead. It
is still a subscription token, not an API key:

```bash
# on the host
claude setup-token
# in the sandbox shell
echo 'export CLAUDE_CODE_OAUTH_TOKEN=<token>' >> /etc/sandbox-persistent.sh
```

Then start `claude --chrome` from a sandbox shell.

## Status

Tested: with the placeholder token, the relay connection opens and is
rejected with a 401. Not yet tested end to end: passthrough with a real
token, then pairing with the extension.

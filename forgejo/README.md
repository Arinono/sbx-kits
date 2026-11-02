# Forgejo CLI (`fj`) sandbox mixin

A Docker Sandboxes (`sbx`) v3 **mixin** that adds
[forgejo-cli](https://codeberg.org/forgejo-contrib/forgejo-cli) (`fj`) to a
workload and gives it, and plain `git` over HTTPS, access to one private
Forgejo instance. You set the instance per sandbox with a kit arg. The access
token stays on your host.

| File | Purpose |
|---|---|
| `forgejo.yaml` | Kit descriptor: args, network policy, credential, startup hook, agent context |
| `forgejo.dockerfile` | Overlay: `fj` built from crates.io (`--locked`) plus a small wrapper at `/usr/local/bin/fj` |

Pinned version: forgejo-cli `0.7.0`.

## Args

| Arg | Default | Purpose |
|---|---|---|
| `host` | *(required)* | Instance host name, e.g. `git.example.com`. The instance URL is `https://<host>` (port 443). Lowercase. |
| `version` | `0.7.0` | forgejo-cli release to build |

`host` is a create-time arg. It is expanded into the network allow rule, the
token-injection rule, `fj`'s key store and the agent instructions. It is also
exported as `FORGEJO_HOST`. The `fj` wrapper turns that into
`FJ_FALLBACK_HOST=https://<host>`, so `fj` targets the instance even outside
a clone.

## Setup

1. On the Forgejo instance, create an access token under *Settings →
   Applications → Access tokens*. Give it the scopes the agent needs, for
   example `repository` and `issue` read/write, plus `user` read for
   `fj whoami`.
2. Store it on the host under the `forgejo` service:

   ```bash
   sbx secret set forgejo
   # or from a password manager / helper:
   sbx secret set forgejo --ref 'op://Work/Forgejo/token'
   ```

3. Add the mixin to a workload and point it at your instance. `forgejo.` targets
   this kit's arg; the handle is the directory name:

   ```bash
   cd /path/to/your/project
   sbx run /path/to/sbx-kits/opencode-claude \
     --kit /path/to/sbx-kits/forgejo \
     --kit-arg forgejo.host=git.example.com .
   ```

   Approve the `forgejo` credential binding when `sbx` asks for it on first run.

4. In the sandbox: `fj whoami`.

To avoid retyping the host, put it in a kit-args file and pass
`--kit-args-file`:

```bash
echo 'forgejo.host=git.example.com' > ~/.config/sbx/forgejo.args
sbx run ... --kit /path/to/sbx-kits/forgejo --kit-args-file ~/.config/sbx/forgejo.args .
```

## How auth works

- The kit declares the `forgejo` credential with
  `Authorization: token %s` injection on `<host>`. Forgejo accepts that header
  on the API and on git smart-HTTP routes, so both `fj` and
  `git clone/fetch/push https://<host>/…` are authenticated.
- In the sandbox, `FORGEJO_TOKEN` holds a sentinel, not the token. At startup,
  a hook writes that sentinel for `<host>` into
  `~/.local/share/forgejo-cli/keys.json`, so `fj` behaves as logged in. The
  proxy replaces the header on the way out.
- When no `forgejo` secret is bound, the credential is skipped and
  `keys.json` isn't seeded. `fj` and `git` then work anonymously, which is
  enough for public repositories.
- Only HTTPS on 443 to `<host>` is allowed. SSH remotes are not supported;
  use HTTPS remote URLs.

## Build the overlay alone

```bash
mise run build:forgejo
```

## Status

Not yet tested end to end: building and running the mixin with a real
instance and token.

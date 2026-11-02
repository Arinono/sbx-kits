# syntax=docker/dockerfile:1
# forgejo-cli (`fj`) as a mixin overlay. Upstream publishes release
# binaries on codeberg.org only; building the pinned crate from crates.io
# with --locked keeps the version authority in one build arg and gives
# both arm64 and amd64 (upstream ships no arm64 musl/static build).
#
# Built on bookworm so the binary needs glibc >= 2.36 and libssl3, which
# the docker/sandbox-templates:claude-code base the workloads here sit on
# already provides. Rust >= 1.88 is needed (edition 2024, let chains).
FROM rust:1-bookworm AS build
ARG FJ_VERSION
RUN cargo install --locked --root /tmp/fj "forgejo-cli@${FJ_VERSION}" \
 && /tmp/fj/bin/fj version | grep -F "${FJ_VERSION}" \
 && install -D -m 0755 /tmp/fj/bin/fj /out/usr/local/libexec/forgejo-cli/fj \
 && rm -rf /tmp/fj

# fj falls back to FJ_FALLBACK_HOST when it can't infer the instance from
# a git remote (e.g. outside a repository). Derive it from the kit's
# FORGEJO_HOST so `fj` targets the configured instance by default; an
# explicit FJ_FALLBACK_HOST or `fj -H <host>` still wins.
COPY --chmod=0755 <<'EOF' /out/usr/local/bin/fj
#!/bin/sh
if [ -z "${FJ_FALLBACK_HOST:-}" ] && [ -n "${FORGEJO_HOST:-}" ]; then
  FJ_FALLBACK_HOST="https://${FORGEJO_HOST}"
  export FJ_FALLBACK_HOST
fi
exec /usr/local/libexec/forgejo-cli/fj "$@"
EOF

# The overlay: just the binary and its wrapper, landing on the workload.
FROM scratch
COPY --from=build /out /
ENTRYPOINT ["fj"]
CMD ["--help"]

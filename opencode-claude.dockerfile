# syntax=docker/dockerfile:1
# OpenCode v2 on top of the Claude Code sandbox template. OpenCode's
# built-in "Claude Agent" provider drives the claude binary through the
# Claude Agent SDK (bundled in the opencode binary), so both have to live
# in one image: claude for the model connection, opencode for the TUI.
FROM docker/sandbox-templates:claude-code
ARG CLAUDE_VERSION
ARG OPENCODE_VERSION
ARG TARGETARCH
USER root

# Re-pin claude to the release the kit declares. Fetch the native binary
# directly into the layout install.sh leaves, skipping its Bun step
# (which aborts under QEMU when cross-building).
RUN case "$TARGETARCH" in \
      amd64) platform=linux-x64 ;; \
      arm64) platform=linux-arm64 ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && mkdir -p /home/agent/.local/share/claude/versions /home/agent/.local/bin \
 && curl -fsSL "https://downloads.claude.ai/claude-code-releases/${CLAUDE_VERSION}/${platform}/claude" \
      -o "/home/agent/.local/share/claude/versions/${CLAUDE_VERSION}" \
 && chmod 0755 "/home/agent/.local/share/claude/versions/${CLAUDE_VERSION}" \
 && ln -sfn "/home/agent/.local/share/claude/versions/${CLAUDE_VERSION}" /home/agent/.local/bin/claude \
 && chown -R agent:agent /home/agent/.local

# OpenCode v2 is published as @opencode/cli (opencode-ai is the 1.x line).
# Pull the platform binary package with npm pack and skip install hooks,
# for the same emulation reason. The x64 baseline build runs without AVX2.
RUN case "$TARGETARCH" in \
      amd64) package=@opencode/cli-linux-x64-baseline ;; \
      arm64) package=@opencode/cli-linux-arm64 ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && export HOME=/root \
 && mkdir -p /tmp/opencode && cd /tmp/opencode \
 && archive=$(npm pack --ignore-scripts --silent "${package}@${OPENCODE_VERSION}") \
 && tar -xzf "$archive" \
 && node -e 'if (require("./package/package.json").version !== process.env.OPENCODE_VERSION) throw new Error("OpenCode package version differs from the kit pin")' \
 && install -m 0755 package/bin/opencode /usr/local/bin/opencode \
 && ln -sfn /usr/local/bin/opencode /usr/local/bin/opencode2 \
 && cd / && rm -rf /tmp/opencode /root/.npm /root/.cache \
 && ! find /home/agent -uid 0 | grep -q .

# Point the Claude Agent provider at the pinned claude explicitly, rather
# than relying on PATH lookup from whatever shell launched opencode.
ENV OPENCODE_CLAUDE_PATH=/home/agent/.local/bin/claude
ENV IS_SANDBOX=1
USER agent
WORKDIR /home/agent/workspace
# --auto approves every permission not explicitly denied: the sandbox is
# the boundary, as with claude --dangerously-skip-permissions.
ENTRYPOINT ["opencode", "--auto"]

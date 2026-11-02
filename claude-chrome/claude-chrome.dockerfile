# syntax=docker/dockerfile:1
# Claude Code with Claude in Chrome turned on. The browser side lives on
# the host: the Chrome extension and this claude meet on Anthropic's
# relay (bridge.claudeusercontent.com), so the image needs nothing beyond
# claude itself.
FROM docker/sandbox-templates:claude-code
ARG CLAUDE_VERSION
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

ENV IS_SANDBOX=1
# Claude in Chrome for every claude in the sandbox, including `claude -p`
# sessions and ones started from a shell, not only the entrypoint.
ENV CLAUDE_CODE_ENABLE_CFC=1
USER agent
WORKDIR /home/agent/workspace
ENTRYPOINT ["claude", "--dangerously-skip-permissions", "--chrome"]

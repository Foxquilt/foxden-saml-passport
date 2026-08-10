#!/bin/bash
#
# Install the Claude Code plugins this repo declares in .claude/settings.json.
#
# Remote containers (Claude Code on the web) start with an empty plugin cache.
# `enabledPlugins` and `extraKnownMarketplaces` in project settings say what we
# want, but nothing fetches it there, so every plugin-provided skill is silently
# missing — no jira-housekeeping, no superpowers. This hook does the fetching.
#
# Local machines install plugins interactively and keep them in ~/.claude, so
# this no-ops off the web rather than mutating a developer's own setup.
#
# Runs synchronously on purpose: plugins are enumerated as the session starts,
# so an async fetch would usually lose the race and land too late to be used.
#
set -uo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

# Anchored on this script's own location, not CLAUDE_PROJECT_DIR: in a
# multi-repo session that variable can point at the session root rather than
# this repo, and we would read the wrong settings file (or none).
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SETTINGS="$REPO_DIR/.claude/settings.json"

log() { echo "plugin-bootstrap: $*" >&2; }

[ -f "$SETTINGS" ] || exit 0
command -v jq >/dev/null 2>&1 || { log "jq not found, skipping"; exit 0; }
command -v claude >/dev/null 2>&1 || { log "claude CLI not found, skipping"; exit 0; }

# Marketplaces first — an install only resolves a plugin whose marketplace is
# already known.
while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  claude plugin marketplace add "$repo" >/dev/null 2>&1 ||
    log "could not add marketplace $repo"
done < <(jq -r '.extraKnownMarketplaces // {} | .[] | .source.repo // .source.url // empty' "$SETTINGS")

# claude-plugins-official is a built-in, so it is not in extraKnownMarketplaces —
# but the container registers it in the background while this hook is already
# running, so an install naming it loses that race and fails to resolve. Adding
# it here is idempotent when it has landed and unblocks us when it has not.
claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 ||
  log "could not add marketplace anthropics/claude-plugins-official"

while IFS= read -r plugin; do
  [ -n "$plugin" ] || continue
  claude plugin install "$plugin" >/dev/null 2>&1 ||
    log "could not install $plugin"
done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$SETTINGS")

# Never fail the session over a plugin that would not fetch — a missing skill is
# a degraded session, an aborted hook is no session at all.
exit 0

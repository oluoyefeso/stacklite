#!/usr/bin/env bash
set -euo pipefail

# stacklite installer — copies commands to .claude/commands/
# Run from the stacklite directory, or pass your project path as an argument.

TARGET="${1:-.}"
COMMANDS_DIR="$TARGET/.claude/commands"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$COMMANDS_DIR"

count=0
for cmd in "$SCRIPT_DIR/commands/"*.md; do
  [ -f "$cmd" ] || continue
  cp "$cmd" "$COMMANDS_DIR/"
  name=$(basename "$cmd" .md)
  echo "  /$name"
  count=$((count + 1))
done

echo ""
echo "Installed $count commands to $COMMANDS_DIR/"
echo ""
echo "Available in Claude Code:"
echo "  /plan           — product thinking before code"
echo "  /eng-review     — architecture, tests, performance review"
echo "  /review         — pre-landing code review with fix-first"
echo "  /secure         — OWASP + STRIDE security audit"
echo "  /perf           — performance-focused review"
echo "  /ship           — test, review, and open PR"
echo "  /investigate    — systematic root-cause debugging"
echo "  /retro          — weekly retrospective from git"
echo "  /doc            — auto-update docs after shipping"
echo ""
echo "Optional: copy CLAUDE.md.example routing rules into your project's CLAUDE.md"

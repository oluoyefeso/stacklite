# Upgrade Stacklite

Upgrades stacklite to the latest version by downloading fresh copies from GitHub. Detects your IDE, shows what changed, and replaces the command files.

## Step 1: Detect Current Version

```bash
# Check if VERSION tracking exists locally
if [ -f .claude/commands/sl-plan.md ] || [ -f .github/prompts/sl-plan.prompt.md ] || [ -f .cursor/rules/sl-plan.mdc ] || [ -f .windsurf/rules/sl-plan.md ]; then
  echo "stacklite installation detected"
else
  echo "No stacklite installation found"
fi
```

Read the current VERSION from one of the installed command files if available, or note that version tracking isn't present.

## Step 2: Download Latest

```bash
rm -rf /tmp/stacklite
git clone https://github.com/oluoyefeso/stacklite.git /tmp/stacklite
cat /tmp/stacklite/VERSION
```

Read the new VERSION and compare with the current version (if known).

## Step 3: Detect IDE

Check which IDE directories exist in the current project:

```bash
ls -d .claude 2>/dev/null && echo "claude-code"
ls -d .github/prompts 2>/dev/null && echo "copilot"
ls -d .cursor 2>/dev/null && echo "cursor"
ls -d .windsurf 2>/dev/null && echo "windsurf"
```

If multiple are detected, upgrade all of them. If none are detected, ask the user which IDE they use.

## Step 4: Show What Changed

```bash
# Show CHANGELOG diff between current and latest
cat /tmp/stacklite/CHANGELOG.md
```

Summarize what's new: added commands, changed behavior, removed features. Keep it short — bullet points only.

## Step 5: Remove Stale Commands, Then Copy New Files

Before copying, remove old stacklite command files that may have been renamed or deleted between versions. This prevents duplicate commands (e.g., both old unprefixed `plan.md` and new `sl-plan.md` coexisting).

```bash
# Claude Code — remove any stacklite commands not in the new version
rm -f .claude/commands/{plan,eng-review,review,secure,perf,ship,investigate,retro,doc}.md 2>/dev/null

# VS Code Copilot
rm -f .github/prompts/{plan,eng-review,review,secure,perf,ship,investigate,retro,doc}.prompt.md 2>/dev/null

# Cursor
rm -f .cursor/rules/{plan,eng-review,review,secure,perf,ship,investigate,retro,doc}.mdc 2>/dev/null

# Windsurf
rm -f .windsurf/rules/{plan,eng-review,review,secure,perf,ship,investigate,retro,doc}.md 2>/dev/null
```

Run only the cleanup commands for the detected IDE(s). Then copy the new files:

```bash
# Claude Code
cp -r /tmp/stacklite/targets/claude-code/.claude/commands/ .claude/commands/

# VS Code Copilot
cp -r /tmp/stacklite/targets/copilot/.github/prompts/ .github/prompts/

# Cursor
cp -r /tmp/stacklite/targets/cursor/.cursor/rules/ .cursor/rules/

# Windsurf
cp -r /tmp/stacklite/targets/windsurf/.windsurf/rules/ .windsurf/rules/
```

Run only the copy commands for the detected IDE(s).

## Step 6: Verify & Clean Up

```bash
rm -rf /tmp/stacklite
```

List the installed commands and confirm the upgrade:

```
STACKLITE UPGRADE
═════════════════
Previous version: {old or unknown}
New version:      {new}
IDE(s) updated:   {list}
Commands:         {count} installed
What's new:       {brief summary}
```

If already on the latest version: "Already up to date (v{version})."

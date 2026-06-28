---
name: multi-agent-worktrees
description: Detect concurrent agent sessions sharing a repo, then create or join isolated worktrees with agent-id naming and status tracking
---

# Multi-Agent Worktrees

## Overview

Extends the standard worktree pattern with **multi-agent awareness**. When multiple agents (opencode, codex, gh CLI, etc.) share a repo, this skill:

1. **Detects** all active worktrees and their agent owners
2. **Names** worktrees by `<agent-id>-<branch>` for clear ownership
3. **Tracks** status via a sentinel file so every agent can see live vs stale sessions
4. **Creates** isolated worktrees only when no existing one covers the task

**Core principle:** Detect first, name consistently, report conflicts, isolate safely.

**Agent-agnostic:** The convention uses no tool-specific paths or configs. Any agent, script, or human can read the same info from `git worktree list`.

**Announce at start:** "Using multi-agent-worktrees skill to check for concurrent sessions."

---

## Naming Convention

```
.worktrees/<agent-id>-<branch>/
```

| Part | Meaning | Example |
|------|---------|---------|
| `agent-id` | Short identifier for the agent/session | `ghost-potato`, `codex-sess-abc`, `claude-dev` |
| `branch` | Git branch the worktree is on | `feat-telemetry`, `fix-memory-leak` |

Within each worktree, a sentinel file tracks session metadata:

```
.worktrees/<agent-id>-<branch>/.worktree-session
```

The sentinel is JSON (one line, no trailing newline ambiguity):

```json
{"agent_id":"ghost-potato","branch":"feat-telemetry","status":"active","pid":1234,"created_at":"2026-06-27T12:00:00Z","heartbeat":"2026-06-27T12:05:00Z"}
```

**Status values:** `active` (live session), `done` (completed), `stale` (abandoned — detected by heartbeat expiry, see Step 4).

---

## Step 0: Detect All Active Worktrees

Before creating or joining anything, scan the repo for existing worktrees:

```bash
git worktree list --porcelain
```

Parse the output to discover all active worktrees and their branches:

```bash
declare -A WORKTREES
while IFS= read -r line; do
  case "$line" in
    worktree\ *)
      wt_path="${line#worktree }"
      ;;
    HEAD\ *)
      wt_head="${line#HEAD }"
      ;;
    branch\ *)
      wt_branch="${line#refs/heads/}"
      WORKTREES["$wt_branch"]="$wt_path"
      ;;
  esac
done < <(git worktree list --porcelain)
```

**Check if you are already in a worktree:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` also fires inside submodules:

```bash
git rev-parse --show-superproject-working-tree 2>/dev/null
```

### Report findings

| Scenario | Action |
|----------|--------|
| Already in a linked worktree | Report path and branch. Skip creation. |
| In a submodule | Treat as normal repo. Proceed to Step 0b. |
| No existing worktrees on target branch | Proceed to Step 0b for consent, then Step 1. |
| Existing worktree on same branch | Warn: "Agent `<other-id>` already on `<branch>` at `<path>`." Ask before creating a second. |
| Multiple agent worktrees found | List all: "N active agent sessions: ..." Proceed with awareness. |

### Step 0b: Consent

If no worktree preference exists in instructions, ask:

> "N other agent worktrees detected. Create an isolated worktree? Protects your current branch."

If consent declined, work in place and skip to Step 2.

---

## Step 1: Create Isolated Workspace

### 1a. Native Worktree Tools (preferred)

If the platform has a native worktree tool (`EnterWorktree`, `/worktree`, `--worktree` flag), use it and skip to Step 2. The naming convention still applies — apply the convention to the native tool's output path if possible.

### 1b. Git Worktree Fallback

**Directory selection (priority order):**

1. **Declared preference** in instructions — use without asking.
2. **Existing project-local directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   `.worktrees` wins if both exist.
3. **Default:** `.worktrees/` at project root.

**Safety verification:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If NOT ignored: add to `.gitignore`, commit, then proceed.

**Create the worktree:**

```bash
AGENT_ID="${AGENT_ID:-$(hostname)-$$}"  # override via env or instruction
BRANCH_NAME="${BRANCH_NAME:-$(git branch --show-current)}"
WORKTREE_PATH="${LOCATION}/${AGENT_ID}-${BRANCH_NAME}"

git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
cd "$WORKTREE_PATH"
```

**Write sentinel file:**

```bash
cat > .worktree-session <<'EOF'
{"agent_id":"'"$AGENT_ID"'","branch":"'"$BRANCH_NAME"'","status":"active","pid":$$,"created_at":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","heartbeat":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}
EOF
```

**Sandbox fallback:** If `git worktree add` fails (permission error), report it, work in place, and still write a `.worktree-session` to the current directory for detection purposes.

---

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f pyproject.toml ]; then pip install -e .; fi
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

---

## Step 3: Verify Clean Baseline

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Active agents in this repo: N
Tests passing (<N> tests, 0 failures)
Ready on branch <branch>
```

---

## Step 4: Heartbeat & Staleness Detection

**Update heartbeat** periodically (every ~60s if practical) to mark the session as live:

```bash
sed -i 's/"heartbeat":"[^"]*"/"heartbeat":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"/' .worktree-session
```

**Mark done on completion:**

```bash
sed -i 's/"status":"active"/"status":"done"/' .worktree-session
```

**Detect stale sessions** (for other agents, not yourself):

```bash
for wt in $(git worktree list --porcelain | grep '^worktree' | cut -d' ' -f2-); do
  sf="$wt/.worktree-session"
  [ -f "$sf" ] || continue
  status=$(jq -r '.status' "$sf")
  heartbeat=$(jq -r '.heartbeat' "$sf")
  if [ "$status" = "active" ]; then
    age=$(( $(date +%s) - $(date -d "$heartbeat" +%s) ))
    if [ $age -gt 300 ]; then  # 5 min threshold
      echo "Stale session: $(jq -r '.agent_id' "$sf") on $(jq -r '.branch' "$sf") (no heartbeat for ${age}s)"
    fi
  fi
done
```

---

## Step 5: Cleanup

When work is done:

```bash
# Mark finished
sed -i 's/"status":"active"/"status":"done"/' .worktree-session

# Remove worktree (from primary repo, not inside the worktree itself)
git worktree remove "$WORKTREE_PATH"
```

If the worktree is dirty and removal fails:

```bash
git worktree remove --force "$WORKTREE_PATH"
```

**Ignore sentinel file in parent repo** (add once per repo):

```bash
# Already done if .worktrees/ is gitignored
```

---

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in a linked worktree | Report it, skip creation (Step 0) |
| Worktree exists on target branch | Warn about other agent, ask before creating second |
| No existing worktrees | Proceed to create (Step 1) |
| Sentinel file found in current dir | You're in a tracked session already |
| Sentinel heartbeat >5min stale | Flag as abandoned (Step 4) |
| Native worktree tool available | Use it, apply convention afterward (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Directory not ignored | Add to .gitignore, commit, proceed |
| Permission error on create | Work in place, write sentinel (sandbox fallback) |
| Tests fail at baseline | Report, ask for consent |

---

## Common Mistakes

### Skipping multi-agent detection

- **Problem:** Creating a second worktree on the same branch without knowing another agent is on it.
- **Fix:** Always run `git worktree list` (Step 0) before creating.

### Stale session noise

- **Problem:** Abandoned agent worktrees clutter `git worktree list`.
- **Fix:** Sentinel heartbeat detects staleness. Clean up with `git worktree remove`.

### Agent-id collision

- **Problem:** Two sessions from the same agent on the same branch.
- **Fix:** Append a session suffix: `<agent-id>-<branch>-<session>`.

### Ignoring sentinel files

- **Problem:** `.worktree-session` gets tracked by git (pollutes main repo).
- **Fix:** The parent `.worktrees/` directory must be gitignored. Verify with `git check-ignore`.

### Platform-native worktrees not visible

- **Problem:** Some platforms create worktrees outside `.worktrees/`.
- **Fix:** `git worktree list` finds them regardless. Always use `git worktree list --porcelain`, not filesystem globbing.

---

## Red Flags

**Never:**
- Create a worktree without running `git worktree list` first
- Assume you're the only agent on the repo
- Use agent-specific paths or configs (defeats multi-agent portability)
- Skip the sentinel file (loses status and heartbeat tracking)
- Commit or push the sentinel file (it's transient session state)
- Rely on filesystem `ls` to discover worktrees — always use `git worktree list`

**Always:**
- Run Step 0 detection before creating anything
- Write a `.worktree-session` sentinel on creation
- Update heartbeat periodically
- Mark `done` on cleanup
- Check `git worktree list` to find worktrees, not filesystem paths
- Verify `.worktrees/` is gitignored for project-local directories

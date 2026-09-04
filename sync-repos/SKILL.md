---
name: sync-repos
description: Syncs all git repositories in a multi-repo workspace to their non-prod branch. Discovers branching strategy by reading AGENT.md (workspace root), then CONTRIB.md / README.md / CONTEXT.md in each repo, then grilling the user if still unknown, and persisting the result. Use when the user wants to sync, update, pull, or refresh all repos, start a coding session, end a session, or ensure the whole codebase is up to date.
---

# Sync Repos

Keeps every repository in a multi-repo workspace up to date on its non-prod branch. Works on macOS, Linux, and Windows.

## Step 1 — Discover branching strategy

Work through these sources **in order**, stopping as soon as you have a definitive answer.

### 1a. Workspace-level AGENTS.md
Read `AGENTS.md` in the workspace root. Look for a branching strategy section describing which branch is used for non-prod / development work across all repos.

### 1b. Per-repo docs
For each repo that doesn't yet have a known branch, search these files **in order** (stop at the first hit):
1. `CONTRIB.md`
2. `README.md`
3. `CONTEXT.md`

Look for mentions of: branching strategy, gitflow, develop branch, non-prod, staging, feature workflow.

### 1c. Grill the user
If any repos still have no known non-prod branch, activate the `grilling` skill and ask targeted questions:
- Does this project follow gitflow (develop → main)?
- Is there a shared staging or pre-prod branch?
- Are all repos on the same strategy or do some differ?

Never assume `main` or `master` is the non-prod branch — these are typically production.

### 1d. Persist the result
After discovery, store what you learned so future runs skip this step:

| Scenario | Where to write |
|----------|---------------|
| All repos share the same branching strategy | Append a `## Branching Strategy` section to workspace `AGENTS.md` |
| Repos differ | Append / create `CONTRIB.md` in each affected repo with a `## Branching Strategy` section |
| User specifies a different location | Follow their instruction |

---

## Step 2 — Detect OS and run the right script

Before running, detect the operating system and invoke the appropriate script:

**macOS / Linux:**
```bash
bash ~/.bob/skills/sync-repos/scripts/sync-repos.sh
```

**Windows (PowerShell):**
```powershell
pwsh ~/.bob/skills/sync-repos/scripts/sync-repos.ps1
```

> On Windows, if `pwsh` (PowerShell 7+) is not available, fall back to `powershell`. Both scripts require `git` to be on the system PATH.

The script (per repo):
1. Stashes any uncommitted changes with a timestamped message
2. Checks out the discovered non-prod branch
3. Runs `git pull --ff-only`
4. Reports result: `[OK]` / `[STASHED]` / `[ERROR]` / `[UNKNOWN]`

---

## Step 3 — Report

Parse the script output and present a clean table:

| Repo | Branch | Status | Notes |
|------|--------|--------|-------|
| ... | develop | ✅ updated | |
| ... | staging | ⚠️ stashed | run `git stash pop` to restore |
| ... | develop | ❌ error | pull failed — diverged or conflict |
| ... | — | ❓ unknown | branch not found — see Step 1 |

Remind the user to `git stash pop` in any repo where changes were stashed.

---

## Options

**macOS / Linux:**
```bash
# Dry run — report what would happen without making changes
bash ~/.bob/skills/sync-repos/scripts/sync-repos.sh --dry-run

# Sync a single repo only
bash ~/.bob/skills/sync-repos/scripts/sync-repos.sh --repo <repo-name>
```

**Windows:**
```powershell
.\sync-repos.ps1 -DryRun
.\sync-repos.ps1 -Repo <repo-name>
```

---

## Notes

- `main` / `master` are **never** selected as the non-prod target — they are production
- Repos in detached HEAD state are skipped and flagged `[ERROR]`
- Stashed changes are never auto-popped; the user must review and pop manually
- The script is idempotent — safe to run at the start and end of every session
- Both scripts require only `git` on the PATH — no other dependencies

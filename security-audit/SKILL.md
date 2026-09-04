---
name: security-audit
description: Run a full security audit across all repos in a multi-repo workspace. Discovers configured security tools from each repo's .pre-commit-config.yaml, installs missing tooling with user consent, creates issues for each finding (deduplicating against existing ones), and produces a shareable HTML summary report. Use when the user invokes /security-audit, asks to audit dependencies, wants to find vulnerabilities, or wants to create security issues from audit findings.
---

# Security Audit

Audits every repository in a multi-repo workspace for security vulnerabilities, creates issues for each finding, and produces a summary report.

## Options

| Option | Default | Meaning |
|---|---|---|
| `--level=<all\|critical\|high\|moderate\|low>` | `all` | Minimum severity to report and ticket |
| `--repo=<name>` | all repos | Scope audit to a single repo |
| `--dry-run` | off | Report findings without creating issues |

## Phase 1 — Discovery

Run once per workspace. Results are persisted so future runs skip this phase.
Full instructions: [DISCOVERY.md](DISCOVERY.md)

**Steps (in order):**
1. Locate workspace-level `AGENTS.md` — search recursively outside repo directories. If not found, ask the user where workspace context lives. Never auto-create.
2. Check `AGENTS.md` for a `## Security Audit` section. If present, load context and skip to Phase 2.
3. Per repo: read `.pre-commit-config.yaml` → extract configured security hooks (tool IDs + flags).
4. **No security hooks in a repo = HIGH-severity finding.** Walk the user through setup. See [DISCOVERY.md § Setup Walkthrough](DISCOVERY.md#setup-walkthrough).
5. `detect-secrets`: install during setup unless user overrules. **Never create issues for its findings.** Remind the user to run `detect-secrets audit` before committing.
6. Discover issue tracker per repo. See [DISCOVERY.md § Issue Tracker Discovery](DISCOVERY.md#issue-tracker-discovery).
7. Discover available labels via `gh` CLI if available; otherwise ask user.
8. Persist all discovered context. See [DISCOVERY.md § Persisting Context](DISCOVERY.md#persisting-context).

## Phase 2 — Audit (repo by repo)

Full instructions: [AUDIT.md](AUDIT.md)

**For each repo:**
1. Run each configured security tool directly (not via `pre-commit run`) with JSON output flags.
2. Filter findings by `--level` (default: all severities).
3. For each finding, search existing open AND closed issues for CVE ID + package name before creating.
4. Create issues using the template in [ISSUE-TEMPLATE.md](ISSUE-TEMPLATE.md).
5. Apply discovered labels (severity + `security`).
6. After all findings for the repo are processed, present a checkpoint:

```
Repo: san-automation-backend
Findings: 2 CRITICAL, 1 HIGH, 3 MODERATE
Issues created: 4 | Already existed: 2

[Continue] [Handoff] [Terminate]
```

**Handoff:** Check for a `/handoff` skill. If present, invoke it. If not, write a structured handoff note in chat summarising work done and remaining repos.

## Phase 3 — Summary

After all repos (or on Terminate):
- Present an in-chat findings table (repos, severities, issues created vs. skipped).
- Call `create_html_artifact` with a full shareable one-pager: per-repo sections, severity badges, CVE links, issue links.

## Key rules

- **Never run tools outside the repo's `.pre-commit-config.yaml`** — it is the team's agreed security contract.
- **Never create a secret in code.** Any tracker credentials go in a gitignored `.env` file; the agent uses only the env var name.
- **Never assume tooling is installed** — discover first, check PATH, offer to install with user consent.
- Impact analysis depth: CRITICAL/HIGH → deep (call graph, blast radius); MODERATE/LOW → shallow (grep imports). See [AUDIT.md § Impact Analysis](AUDIT.md#impact-analysis).

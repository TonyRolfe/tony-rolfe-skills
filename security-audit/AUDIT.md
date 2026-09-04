# Audit Reference

Full instructions for Phase 2 of the security-audit skill.

---

## Running Audit Tools

Run each tool **directly** (not via `pre-commit run`) to get structured JSON output. Use the flags from the repo's `.pre-commit-config.yaml` as the baseline, then add JSON output flags.

### Detect OS

```bash
# macOS / Linux
uname -s

# Windows (PowerShell)
$PSVersionTable.OS
```

Use the appropriate shell syntax for all subsequent commands.

### Tool invocation patterns

#### pip-audit
```bash
pip-audit -r requirements.txt --format json --output audit-results.json
# Then read audit-results.json
```

#### npm audit
```bash
npm audit --json > audit-results.json
# Then read audit-results.json
```

#### govulncheck (Go)
```bash
govulncheck -json ./... > audit-results.json
```

#### cargo audit (Rust)
```bash
cargo audit --json > audit-results.json
```

#### trivy (filesystem / JVM / C++)
```bash
trivy fs --format json --output audit-results.json .
```

#### bundler-audit (Ruby)
```bash
bundle-audit check --format json > audit-results.json
```

#### dotnet (C#/.NET)
```bash
dotnet list package --vulnerable --format json > audit-results.json
```

For any tool not listed above: run it with whatever JSON/machine-readable output flag it supports. If no structured output is available, run in verbose mode and parse the human-readable output carefully.

---

## Filtering by Severity

Apply the `--level` filter after collecting all findings. Map tool-specific severity names to the canonical levels:

| Canonical | pip-audit | npm audit | govulncheck | trivy | cargo audit |
|---|---|---|---|---|---|
| `critical` | CRITICAL | critical | — | CRITICAL | — |
| `high` | HIGH | high | HIGH | HIGH | — |
| `moderate` | MODERATE | moderate | MEDIUM | MEDIUM | medium |
| `low` | LOW | low | LOW | LOW | low |

Keep only findings at or above the requested level. `all` keeps everything.

---

## Deduplication

Before creating any issue, search existing issues:

**GitHub Issues:**
```bash
gh issue list --repo <owner/repo> --state all --search "<CVE-ID> <package-name>" --json number,title,state,url
```

If any result contains both the CVE ID and the package name in the title or body, skip creation and record as "already existed."

**Local file tracker:** grep the file for the CVE ID. If found, skip.

**Other trackers:** use the tracker's search API with CVE ID + package name as the query. Refer to instructions persisted in `AGENTS.md`.

---

## Impact Analysis

### CRITICAL and HIGH — Deep analysis

For each vulnerable package:

1. **Find direct imports:**
```bash
# Python
grep -rn "import <package>" --include="*.py" .
grep -rn "from <package>" --include="*.py" .

# Node.js
grep -rn "require('<package>')" --include="*.js" --include="*.ts" .
grep -rn "from '<package>'" --include="*.js" --include="*.ts" .
```

2. **Trace call sites:** For each file that imports the package, identify which functions/methods from the package are called, and which of your own functions call them.

3. **Assess blast radius:**
   - Is the vulnerable code path reachable from a public API endpoint?
   - Is the vulnerable code path triggered by user-supplied input?
   - What data could be exposed or corrupted?

4. **Document findings** in the issue body under `## Impact Analysis`.

### MODERATE and LOW — Shallow analysis

```bash
# Count files that directly import the package
grep -rl "<package>" --include="*.py" . | wc -l
```

Report: "Used in N files. Update when upstream ships a fix."

---

## Third-party / Transitive Vulnerabilities

If the vulnerable package is a transitive dependency (not directly in `requirements.txt` / `package.json`):

1. Identify the direct dependency that pulls it in:
```bash
# Python
pip show <vulnerable-package> | grep "Required-by"

# Node.js
npm why <vulnerable-package>
```

2. Frame the issue as "waiting on upstream" — see [ISSUE-TEMPLATE.md § Transitive Vulnerability](ISSUE-TEMPLATE.md#transitive-vulnerability).

3. Check if the direct dependency has already released a version that pins to a safe transitive version:
```bash
# Python
pip index versions <direct-dependency>

# Node.js
npm view <direct-dependency> versions --json
```

4. If a safe version of the direct dependency exists, frame as a direct upgrade issue instead.

---

## Breaking Change Detection

For each recommended version upgrade, check the semver delta:

| Delta | Classification | Action |
|---|---|---|
| Patch (x.x.N) | Non-breaking | No warning needed |
| Minor (x.N.0) | Usually non-breaking | Note: "minor bump — review changelog" |
| Major (N.0.0) | Potentially breaking | Warn: "MAJOR version upgrade — review breaking changes before updating" |

Link to the package changelog:
- PyPI: `https://pypi.org/project/<package>/#history`
- npm: `https://www.npmjs.com/package/<package>?activeTab=versions`
- GitHub releases: extract from package metadata if available

---

## Per-repo Checkpoint

After processing all findings for a repo, present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Repo: <repo-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Findings:   2 CRITICAL  |  1 HIGH  |  3 MODERATE  |  5 LOW
Issues:     Created: 4  |  Already existed: 2  |  Skipped (dry-run): 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Continue]   Proceed to next repo
[Handoff]    Hand off remaining work
[Terminate]  Stop and generate summary
```

**Handoff flow:**
1. Check if a `/handoff` skill is installed (look in `~/.bob/skills/` and `.bob/skills/`).
2. If found: invoke it.
3. If not found: write a structured handoff note:

```markdown
## Security Audit Handoff

**Completed repos:** <list>
**Remaining repos:** <list>
**Current state:** Discovery complete. Audit tool context persisted in AGENTS.md.
**Resume with:** `/security-audit --repo=<next-repo-name>`
**Notes:** <any relevant context, e.g. label IDs discovered, tracker auth method>
```

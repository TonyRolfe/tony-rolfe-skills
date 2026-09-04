# Issue Templates

Templates for security findings issues created by the security-audit skill.

---

## Standard Vulnerability

Use for direct dependency vulnerabilities where a fix is available.

```markdown
## Vulnerability

**Package:** `<package-name>` <current-version>
**CVE:** <CVE-ID> (or "No CVE assigned")
**Severity:** <CRITICAL|HIGH|MODERATE|LOW> (CVSS <score>)
**Affected repo:** <repo-name>
**Audit tool:** <pip-audit|npm-audit|govulncheck|cargo-audit|trivy|...>

## Description

<CVE description from audit output. Include the nature of the vulnerability:
e.g. "Remote code execution via malformed input in the JSON parser.">

## Fix

**Action:** Update `<package-name>` from `<current-version>` to `<fixed-version>`
**Semver delta:** <patch|minor|MAJOR>
**Breaking change:** <Yes — review breaking changes before updating | No>
**Changelog:** <link to PyPI history / npm versions / GitHub releases>

## Impact Analysis

<For CRITICAL/HIGH — deep analysis:>
**Direct imports found in:**
- `path/to/file.py` — `function_name()` calls `<package>.vulnerable_method()`
- `path/to/other.py` — `another_function()` calls `<package>.affected_api()`

**Blast radius:**
- Reachable from public API: <Yes|No|Unknown>
- Triggered by user input: <Yes|No|Unknown>
- Potential exposure: <describe data or system impact>

<For MODERATE/LOW — shallow analysis:>
Used in <N> files. Update when convenient.

## Acceptance Criteria

- [ ] `<requirements.txt|package.json>` updated to `<package-name>>=<fixed-version>`
- [ ] `<pip-audit|npm audit>` passes with no findings for <CVE-ID>
- [ ] All tests pass after upgrade
- [ ] <If MAJOR bump:> Breaking changes reviewed and any required code changes made

## Context for Fixing Agent

- **Dependency type:** Direct
- **Fix approach:** Version bump in `<requirements.txt|package.json>`
- **Risks:** <Any known risks with the upgrade, e.g. API changes, removed methods>
- **References:** <CVE link, advisory link, package changelog>
```

---

## Transitive Vulnerability

Use when the vulnerable package is a transitive (indirect) dependency.

```markdown
## Vulnerability

**Package:** `<vulnerable-package>` <current-version> (transitive)
**Pulled in by:** `<direct-dependency>` <version>
**CVE:** <CVE-ID>
**Severity:** <CRITICAL|HIGH|MODERATE|LOW> (CVSS <score>)
**Affected repo:** <repo-name>
**Audit tool:** <tool>

## Description

<CVE description. Note that this is a transitive dependency — the vulnerable
package is not directly declared but is pulled in by a dependency.>

## Fix

<If a safe version of the direct dependency exists:>
**Action:** Update `<direct-dependency>` from `<current-version>` to `<safe-version>`
which pins `<vulnerable-package>` to `<safe-transitive-version>` or later.
**Semver delta:** <patch|minor|MAJOR>
**Breaking change:** <Yes|No>
**Changelog:** <link>

<If no safe version exists yet:>
**Action:** Waiting on upstream. `<direct-dependency>` must release a version that
pins `<vulnerable-package>` >= `<fixed-version>`. Monitor:
- <direct-dependency> releases: <link>
- CVE advisory: <link>
When a safe release is published, update `<direct-dependency>` to that version.

## Impact Analysis

**Vulnerable package used by:** `<direct-dependency>`
**Direct dependency imported in:**
- `path/to/file.py`

<For CRITICAL/HIGH — trace further:>
**Call path to vulnerable code:**
- `your_code.py:function()` → `<direct-dependency>.method()` → `<vulnerable-package>.vulnerable_api()`

## Acceptance Criteria

<If fix available:>
- [ ] `<direct-dependency>` updated to `<safe-version>` in `<requirements.txt|package.json>`
- [ ] `<audit-tool>` passes with no findings for <CVE-ID>
- [ ] All tests pass after upgrade

<If waiting on upstream:>
- [ ] Monitor `<direct-dependency>` releases for a version that resolves <CVE-ID>
- [ ] Update `<direct-dependency>` to the safe version once published
- [ ] `<audit-tool>` passes with no findings for <CVE-ID>
- [ ] All tests pass after upgrade

## Context for Fixing Agent

- **Dependency type:** Transitive (via `<direct-dependency>`)
- **Upstream status:** <Fix available as of <date> | Pending upstream fix>
- **References:** <CVE link, direct-dependency release notes, advisory>
```

---

## Missing Security Hooks

Use when a repo has no security hooks configured in `.pre-commit-config.yaml`.

```markdown
## Security Gap: No Security Hooks Configured

**Affected repo:** <repo-name>
**Severity:** HIGH
**Type:** Missing security tooling

## Description

`<repo-name>` has no security audit hooks configured in `.pre-commit-config.yaml`.
This means dependency vulnerabilities and hardcoded secrets are not caught at
commit time, leaving the repo unprotected against known CVEs and credential leaks.

## Fix

Configure the following pre-commit security hooks appropriate for this repo's stack:

<list recommended tools from TOOL-REGISTRY.md for detected stack>

The `/security-audit` skill can walk through installation interactively.

## Acceptance Criteria

- [ ] `.pre-commit-config.yaml` updated with appropriate security hooks
- [ ] `pre-commit install` run in the repo
- [ ] `detect-secrets scan > .secrets.baseline` run and baseline committed
- [ ] Pre-commit hooks verified to run on next commit

## Context for Fixing Agent

- **Stack detected:** <Python|Node.js|Go|...>
- **Recommended tools:** <from TOOL-REGISTRY.md>
- **Install guide:** Run `/security-audit --repo=<repo-name>` for interactive setup
```

---

## Issue Title Conventions

| Type | Title format |
|---|---|
| Standard | `[SEVERITY] CVE-YYYY-NNNNN: <package-name> <current-version> → <fixed-version>` |
| Transitive (fix available) | `[SEVERITY] CVE-YYYY-NNNNN: <direct-dep> pulls vulnerable <vulnerable-package>` |
| Transitive (waiting) | `[SEVERITY] CVE-YYYY-NNNNN: <vulnerable-package> — waiting on upstream fix in <direct-dep>` |
| Missing hooks | `[HIGH] Security: No pre-commit security hooks configured in <repo-name>` |

**Examples:**
- `[HIGH] CVE-2024-35195: requests 2.28.0 → 2.31.0`
- `[CRITICAL] CVE-2024-21503: black pulls vulnerable virtualenv 20.24.0`
- `[HIGH] CVE-2024-21503: virtualenv — waiting on upstream fix in black`
- `[HIGH] Security: No pre-commit security hooks configured in onesan-platform`

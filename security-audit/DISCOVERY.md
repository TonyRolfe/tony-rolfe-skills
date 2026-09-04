# Discovery Reference

Full instructions for Phase 1 of the security-audit skill. The agent works through these steps in order and stops as soon as it has a complete picture for each repo.

---

## Locating Workspace Context

Search recursively for `AGENTS.md` **outside** of any git repository directories (i.e. not inside a `.git` subtree). Common locations: workspace root, `.agents/`, `.ai-instructions/`, `docs/`.

If no `AGENTS.md` is found, ask the user:
> "I couldn't find a workspace-level AGENTS.md. Where should I look for — or create — workspace-wide agent context?"

Do **not** auto-create any file without explicit direction from the user.

If `AGENTS.md` exists and contains a `## Security Audit` section, load that context and skip to Phase 2. Otherwise proceed through the steps below and persist the results at the end.

---

## Extracting Configured Tools

For each repo, read `.pre-commit-config.yaml` and extract:
- Hook IDs that correspond to security tools
- The command or `args` each hook runs (this gives audit level, output flags, target files)

Map hook IDs to executable tool names using the [Tool Registry](TOOL-REGISTRY.md). If a hook ID is not in the registry, extract the `entry` or `language` field from the config to determine what binary is actually invoked.

**Check each tool is on the PATH:**
```bash
# macOS / Linux
which <tool-name>

# Windows (PowerShell)
Get-Command <tool-name> -ErrorAction SilentlyContinue
```

If a tool is configured but not installed, offer to install it. Show the install command, confirm with the user, then run it.

---

## Setup Walkthrough

Triggered when a repo has **no security hooks at all**. Treat this as a HIGH-severity finding in the summary.

### 1. Detect stack
Check for the following files in the repo root (and one level deep):

| File | Stack |
|---|---|
| `requirements.txt`, `pyproject.toml`, `setup.py` | Python |
| `package.json` | Node.js |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml`, `build.gradle` | JVM |
| `*.csproj`, `*.sln` | .NET |
| `Gemfile` | Ruby |
| `conanfile.txt`, `CMakeLists.txt` | C/C++ |

A repo may match multiple stacks (polyglot). List all matches.

### 2. Recommend tools
Consult [TOOL-REGISTRY.md](TOOL-REGISTRY.md) for the recommended tool(s) per stack. Present recommendations to the user:
> "I detected a Python repo. I recommend adding `pip-audit` for dependency scanning and `detect-secrets` for secret detection. Shall I install and configure these?"

If the stack is unrecognised, ask the user what security tooling they want to use.

### 3. User chooses
User selects which tools to install. Agent does the following with user confirmation at each step:
1. Install the tool (show the install command first).
2. Generate the `.pre-commit-config.yaml` snippet.
3. Write the snippet to the file (create the file if it doesn't exist).
4. Run `pre-commit install` to register the hooks.

### 4. detect-secrets baseline
If `detect-secrets` was added and no baseline file (`.secrets.baseline`) exists:
```bash
detect-secrets scan > .secrets.baseline
```
Inform the user: "A baseline has been created. Run `detect-secrets audit .secrets.baseline` to review any initial findings before your first commit."

---

## Issue Tracker Discovery

For each repo, search these files **in order**, stopping at the first hit:
1. `AGENTS.md` (repo-level)
2. `README.md`
3. `CONTRIB.md`
4. `CONTEXT.md`

Look for: issue tracker URL, GitHub Issues link, Jira project key, or explicit instructions on how to file issues.

### GitHub Issues
If the tracker is GitHub Issues (on `github.com` or a GHE instance):
1. Check for `gh` CLI: `gh auth status`
2. If authenticated, use `gh` for all issue operations.
3. If not authenticated, look for `GH_TOKEN` or `GITHUB_TOKEN` env vars.
4. If neither is available, instruct the user to run `gh auth login` or set the env var.

Discover available labels:
```bash
gh label list --repo <owner/repo> --json name,color,description
```
Persist the label list in the `## Security Audit` section of `AGENTS.md`.

### Other trackers (Jira, Linear, etc.)
Ask the user for:
- Tracker URL / project key
- API endpoint for issue creation and search
- Required authentication (API token, OAuth, etc.)
- Env var name to use for the secret (e.g. `JIRA_API_TOKEN`)

Tell the user: "Please add `<ENV_VAR_NAME>=<your-token>` to a `.env` file in the repo root. Ensure `.env` is in `.gitignore`."

Verify `.gitignore` includes `.env` — if not, add it.

### Local file fallback
If no tracker is found and the user opts for local tracking:
- Ask the user for their preferred format (e.g. `SECURITY-FINDINGS.md`, `.issues/` directory, etc.)
- Record their choice and use it consistently.

---

## Persisting Context

After discovery, write a `## Security Audit` section to `AGENTS.md`. Choose the location:

| Scenario | Where to write |
|---|---|
| All repos share the same tooling and tracker | Workspace-level `AGENTS.md` |
| Repos differ | Repo-level `AGENTS.md` (or whichever file the repo uses) |
| User specifies a different location | Follow their instruction |

### Section template

```markdown
## Security Audit

### Tooling
<!-- One entry per repo, or "all repos" if uniform -->
- **san-automation-backend**: pip-audit (requirements.txt), detect-secrets
- **san-automation-frontend**: npm audit (--audit-level=high), detect-secrets

### Issue Tracker
- **Provider**: GitHub Issues
- **Repo**: github.ibm.com/OneIT/san-automation-backend
- **Auth**: gh CLI (authenticated) | fallback: GH_TOKEN env var
- **Labels**: security, severity:critical, severity:high, severity:moderate, severity:low, ready-for-agent

### Notes
<!-- Any per-repo exceptions, custom instructions, or user preferences discovered during setup -->
```

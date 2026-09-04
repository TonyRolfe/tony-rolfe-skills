# Tool Registry

Reference used during the setup walkthrough (Phase 1) when a repo has no security hooks configured. The agent consults this registry to recommend appropriate tools based on detected stack indicators.

This registry is a **fallback for setup only**. At audit time, the agent always uses what is declared in the repo's `.pre-commit-config.yaml` — never this file.

---

## Stack Detection → Tool Recommendations

| Stack indicator | Stack | Recommended tool(s) | Install command |
|---|---|---|---|
| `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg` | Python | `pip-audit` | `pip install pip-audit` |
| `package.json` | Node.js | `npm audit` | Built into npm (no install needed) |
| `go.mod`, `go.sum` | Go | `govulncheck` | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| `Cargo.toml`, `Cargo.lock` | Rust | `cargo audit` | `cargo install cargo-audit` |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | JVM (Java/Kotlin) | `trivy` | See trivy install below |
| `*.csproj`, `*.sln`, `global.json` | .NET / C# | `dotnet list package --vulnerable` | Built into .NET SDK |
| `Gemfile`, `Gemfile.lock` | Ruby | `bundler-audit` | `gem install bundler-audit` |
| `conanfile.txt`, `conanfile.py`, `CMakeLists.txt` | C / C++ | `trivy` (filesystem scan) | See trivy install below |
| `composer.json` | PHP | `composer audit` | Built into Composer |
| `pubspec.yaml` | Dart / Flutter | `dart pub audit` | Built into Dart SDK |
| Multiple of the above | Polyglot | All applicable tools | Install each separately |
| None of the above | Unknown | Ask user | — |

---

## detect-secrets (All stacks)

`detect-secrets` should be configured for **all repos regardless of stack** unless the user explicitly opts out.

| Item | Value |
|---|---|
| Purpose | Prevent hardcoded secrets from reaching remote repos |
| Install | `pip install detect-secrets` |
| Baseline init | `detect-secrets scan > .secrets.baseline` |
| User action | Run `detect-secrets audit .secrets.baseline` before first commit |
| Issue creation | **Never** — findings are a commit gate only |

---

## pre-commit Hook Snippets

### pip-audit (Python)
```yaml
- repo: https://github.com/pypa/pip-audit
  rev: v2.7.3
  hooks:
    - id: pip-audit
      args: ["-r", "requirements.txt"]
```

### npm audit (Node.js)
```yaml
- repo: local
  hooks:
    - id: npm-audit
      name: npm audit
      language: system
      entry: npm
      args: ["audit", "--audit-level=high"]
      pass_filenames: false
```

### govulncheck (Go)
```yaml
- repo: local
  hooks:
    - id: govulncheck
      name: govulncheck
      language: system
      entry: govulncheck
      args: ["./..."]
      pass_filenames: false
```

### cargo audit (Rust)
```yaml
- repo: local
  hooks:
    - id: cargo-audit
      name: cargo audit
      language: system
      entry: cargo
      args: ["audit"]
      pass_filenames: false
```

### trivy (JVM / C++)
```yaml
- repo: local
  hooks:
    - id: trivy
      name: trivy filesystem scan
      language: system
      entry: trivy
      args: ["fs", "--exit-code", "1", "--severity", "HIGH,CRITICAL", "."]
      pass_filenames: false
```

### bundler-audit (Ruby)
```yaml
- repo: local
  hooks:
    - id: bundler-audit
      name: bundler-audit
      language: system
      entry: bundle-audit
      args: ["check", "--update"]
      pass_filenames: false
```

### dotnet vulnerable packages (.NET)
```yaml
- repo: local
  hooks:
    - id: dotnet-audit
      name: dotnet audit
      language: system
      entry: dotnet
      args: ["list", "package", "--vulnerable", "--include-transitive"]
      pass_filenames: false
```

### detect-secrets (All stacks)
```yaml
- repo: https://github.com/ibm/detect-secrets
  rev: 0.13.1+ibm.62.dss
  hooks:
    - id: detect-secrets
      args: ["--baseline", ".secrets.baseline"]
      exclude: package-lock.json
```

> **Note on versions:** The hook `rev` values above are examples. Always check for the latest stable release before writing to a repo's config:
> - pip-audit: https://github.com/pypa/pip-audit/releases
> - detect-secrets (IBM fork): https://github.com/ibm/detect-secrets/releases

---

## trivy Install

trivy is not pip/npm installable — install via the appropriate package manager:

**macOS:**
```bash
brew install aquasecurity/trivy/trivy
```

**Linux:**
```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

**Windows (PowerShell):**
```powershell
winget install aquasecurity.trivy
```

---

## Extending the Registry

If the agent encounters a stack or tool not listed here, it should:
1. Ask the user what tool they want to use.
2. Ask for the install command and the pre-commit hook snippet.
3. Use that information for the current setup.
4. **Not** update this file — the registry is part of the installed skill. Users should contribute new entries via a pull request to the `tony-rolfe-skills` repo.

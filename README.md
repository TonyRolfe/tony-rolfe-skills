# tony-rolfe-skills

A collection of AI agent skills for AI coding assistants.

Inspired by [Matt Pocock's skills collection](https://github.com/mattpocock/matt-pocock-skills).

---

## Skills

| Skill | Description |
|-------|-------------|
| [sync-repos](./sync-repos/SKILL.md) | Sync all git repositories in a multi-repo workspace to their non-prod branch. Discovers branching strategy from docs before asking. |

---

## Installation

### macOS / Linux — global install (available in all workspaces)

```bash
git clone https://github.ibm.com/tony-rolfe/tony-rolfe-skills.git ~/.bob/skills-src/tony-rolfe-skills
ln -s ~/.bob/skills-src/tony-rolfe-skills/sync-repos ~/.bob/skills/sync-repos
```

### macOS / Linux — workspace-scoped install

```bash
# From your workspace root
git clone https://github.ibm.com/tony-rolfe/tony-rolfe-skills.git .bob/skills-src/tony-rolfe-skills
ln -s .bob/skills-src/tony-rolfe-skills/sync-repos .bob/skills/sync-repos
```

### Windows (PowerShell) — global install

```powershell
git clone https://github.ibm.com/tony-rolfe/tony-rolfe-skills.git "$env:USERPROFILE\.bob\skills-src\tony-rolfe-skills"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.bob\skills\sync-repos" `
  -Target "$env:USERPROFILE\.bob\skills-src\tony-rolfe-skills\sync-repos"
```

> Windows does not support symlinks without admin rights. Directory junctions (`New-Item -ItemType Junction`) work without elevation and are functionally equivalent for this use case.

### Windows (PowerShell) — workspace-scoped install

```powershell
# From your workspace root
git clone https://github.ibm.com/tony-rolfe/tony-rolfe-skills.git .bob\skills-src\tony-rolfe-skills
New-Item -ItemType Junction -Path .bob\skills\sync-repos `
  -Target .bob\skills-src\tony-rolfe-skills\sync-repos
```

### Requirements

| Platform | Requirements |
|----------|-------------|
| macOS | `git`, `bash` (pre-installed) |
| Linux | `git`, `bash` (pre-installed on most distros) |
| Windows | `git` on PATH, PowerShell 5.1+ or [PowerShell 7+](https://github.com/PowerShell/PowerShell) (`pwsh`) |

---

## Contributing

Each skill lives in its own directory:

```
skill-name/
├── SKILL.md          # Agent instructions (required)
├── scripts/          # Utility scripts (optional)
│   └── *.sh
└── EXAMPLES.md       # Usage examples (optional)
```

`SKILL.md` must include a YAML frontmatter block with `name` and `description` fields. The `description` is what the agent reads to decide whether to load the skill — make it specific.

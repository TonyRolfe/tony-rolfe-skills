# tony-rolfe-skills

A collection of AI agent skills for [Bob](https://github.ibm.com/ibm-bob/bob) — IBM's AI coding assistant.

Inspired by [Matt Pocock's skills collection](https://github.com/mattpocock/matt-pocock-skills).

---

## Skills

| Skill | Description |
|-------|-------------|
| [sync-repos](./sync-repos/SKILL.md) | Sync all git repositories in a multi-repo workspace to their non-prod branch. Discovers branching strategy from docs before asking. |

---

## Installation

### Install a skill globally (available in all workspaces)

```bash
# Clone this collection
git clone https://github.ibm.com/tony-rolfe/tony-rolfe-skills.git ~/.bob/skills-src/tony-rolfe-skills

# Symlink the skill you want into ~/.bob/skills/
ln -s ~/.bob/skills-src/tony-rolfe-skills/sync-repos ~/.bob/skills/sync-repos
```

### Install a skill into a specific workspace

```bash
# From your workspace root
git clone https://github.ibm.com/tony-rolfe/tony-rolfe-skills.git .bob/skills-src/tony-rolfe-skills
ln -s .bob/skills-src/tony-rolfe-skills/sync-repos .bob/skills/sync-repos
```

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

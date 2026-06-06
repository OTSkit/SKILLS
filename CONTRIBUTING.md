# Contributing

Contributions are welcome. This repo follows a simple structure: one skill per folder at the repo root.

## Adding a new skill

1. Create a folder with the skill name (e.g. `my-skill/`)
2. Add a `SKILL.md` with YAML frontmatter (`name` and `description` fields required)
3. Add a `README.md` explaining what the skill does and how to use it
4. Add a `.claude-plugin/plugin.json` manifest
5. Open a pull request

## Improving an existing skill

- Edit `SKILL.md` directly and open a pull request
- Keep changes focused: one concern per PR
- Test the skill with the target agent before submitting

## Skill quality guidelines

- The skill must work with at least one supported agent (Claude Code or Codex)
- Use careful language around legal or evidentiary claims — never say "notarized" or "legally certified"
- Include a `Common Mistakes` section if the workflow has non-obvious failure modes

## Questions

Open an issue on GitHub.

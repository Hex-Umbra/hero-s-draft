# Hero's Draft — Gemini CLI

> **`CLAUDE.md` is the authoritative instruction file for this repository.** Read it first — project overview, commands, architecture, documentation map and conventions all live there. This file only records what is specific to the Gemini CLI.

## Language Rule

All responses, plans, summaries and questions addressed to the user must be written in **French**, without exception.

## Notes

- The `.agents/` directory holds a single active skill, `game_designer.md`. The `orchestrator/`, `worker_m1/`, `explorer_m1_*/`, `challenger_m1_*/`, `reviewer_m1_*/` and `auditor_m1/` folders are empty artefacts of a past multi-agent run — not templates, not active sub-agents.
- Documentation skills live in `.claude/skills/` (`memory-bank-sync`, `patch-notes-writer`). See `CLAUDE.md` for what each one owns.

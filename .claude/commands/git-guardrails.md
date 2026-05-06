---
name: git-guardrails
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
---

Read the file at `.claude/skills/misc/git-guardrails-claude-code/SKILL.md` and follow its instructions exactly.
The bundled hook script is at `.claude/skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh`.

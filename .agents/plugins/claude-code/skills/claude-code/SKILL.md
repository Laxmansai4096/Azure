---
name: claude-code
description: >-
  Claude Code Dual-Agent Integration Plugin for Antigravity. Use this skill when delegating coding,
  code review, or CLI tasks to Claude Code, or coordinating pair programming between Antigravity and Claude Code.
---

# Claude Code Dual-Agent Skill

Allows Antigravity to coordinate with Claude Code as an auxiliary coding agent.

## Execution Bridge
Antigravity can dispatch queries and tasks directly to Claude Code using:
```powershell
powershell -ExecutionPolicy Bypass -File .agents/plugins/claude-code/scripts/run_claude.ps1 -Prompt "<task-prompt>"
```

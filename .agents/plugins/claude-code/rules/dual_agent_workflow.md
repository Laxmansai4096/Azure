# Dual-Agent Collaboration Rule: Antigravity + Claude Code

## Objective
Enable seamless co-working between **Antigravity** (IDE orchestrator, planning, full-stack browser/diff analysis) and **Claude Code** (CLI agent running via OpenRouter).

## Responsibilities & Division of Labor

| Role | Antigravity IDE | Claude Code CLI |
| :--- | :--- | :--- |
| **Workspace Architecture & Planning** | Primary: Large codebase context, artifacts, project plans, multi-port services. | Consulted: Generates secondary perspectives or implementation ideas. |
| **Terminal & Shell Execution** | Manages server processes, test scripts, background daemons. | Headless or interactive file modification tasks and focused refactorings. |
| **Visual Testing & Browser** | Browser subagents, screenshots, DOM inspections. | CLI linting, unit test execution. |
| **Code Review & Audits** | Dual review: Antigravity and Claude Code cross-check each other's changes. | High-speed CLI reviews. |

## Delegating Tasks to Claude Code from Antigravity
When the user asks Antigravity to run a task with Claude Code, run:
```powershell
powershell -ExecutionPolicy Bypass -File .agents/plugins/claude-code/scripts/run_claude.ps1 -Prompt "<task-prompt>"
```
This executes non-interactively via OpenRouter's configured models, captures the response, and integrates the results back into the Antigravity workflow.

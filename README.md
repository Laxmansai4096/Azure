# Claude Code Integration Plugin for Google Antigravity

[![Antigravity Compatible](https://img.shields.io/badge/Antigravity-Plugin-blue.svg)](https://antigravity.google)
[![OpenRouter Powered](https://img.shields.io/badge/Gateway-OpenRouter-purple.svg)](https://openrouter.ai)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A turnkey plugin and skill pack that connects **Anthropic's Claude Code** coding agent directly inside **Google Antigravity IDE**, routed with high reliability and zero-cost options via **OpenRouter**.

---

## Features

- **Dual-Agent Architecture**: Pair-program with **Google Antigravity** (IDE orchestrator, code browser, multi-file planning) and **Claude Code** (command-line code refactoring, subagent CLI tasks) simultaneously.
- **100% Free Tier Supported**: Out-of-the-box configuration for OpenRouter's active free models (`cohere/north-mini-code:free`, `nvidia/nemotron-3-super-120b-a12b:free`, `liquid/lfm-2.5-2.6b:free`).
- **Autonomous Delegation Bridge**: Antigravity can dispatch tasks directly to Claude Code headlessly and ingest the output back into the chat.
- **OpenRouter Failover & Quota Management**: Built-in scripts to inspect key quotas (`/api/v1/key`), track in-flight token holds (402), guardrail spend (403), and rate limits (429).
- **Universal Portability**: Fully compatible with Windows PowerShell, macOS, and Linux.

---

## Directory Structure

```text
claude/
├── .agents/
│   ├── plugins/
│   │   └── claude-code/
│   │       ├── plugin.json              # Antigravity plugin manifest
│   │       ├── rules/
│   │       │   └── dual_agent_workflow.md # Multi-agent collaboration rules
│   │       ├── skills/
│   │       │   └── claude-code/SKILL.md  # Bridge skill definition
│   │       └── scripts/
│   │           └── run_claude.ps1        # Headless Antigravity->Claude bridge
│   └── skills/
│       └── claude-code/
│           ├── SKILL.md                 # Full operational runbook
│           ├── references/
│           │   └── openrouter_limits.md # In-depth limits and quota docs
│           └── scripts/
│               ├── setup_openrouter.ps1      # Standard / Paid OpenRouter setup
│               ├── setup_free_openrouter.ps1 # 100% Free-tier configuration
│               └── check_key_limits.ps1      # Real-time credit/quota checker
├── CLAUDE.md                            # Claude Code project guidelines template
└── README.md
```

---

## Quickstart

### 1. Install Claude Code (Once per machine)

- **Windows PowerShell**:
  ```powershell
  irm https://claude.ai/install.ps1 | iex
  ```
- **macOS / Linux / WSL**:
  ```bash
  curl -fsSL https://claude.ai/install.sh | bash
  ```

### 2. Add to Your Workspace

Copy `.agents/` and `CLAUDE.md` to any project root:
```bash
git clone https://github.com/Laxmansai4096/claude.git temp-claude
cp -r temp-claude/.agents ./
cp temp-claude/CLAUDE.md ./
rm -rf temp-claude
```
Or to install **globally** across all projects on your machine:
- **Windows**: Copy `.agents/plugins/claude-code` to `%USERPROFILE%\.gemini\config\plugins\`
- **macOS / Linux**: Copy `.agents/plugins/claude-code` to `~/.gemini/config/plugins/`

### 3. Configure Your OpenRouter Key

#### Free Models (50 requests/day):
```powershell
.agents/skills/claude-code/scripts/setup_free_openrouter.ps1 -ApiKey "sk-or-v1-YOUR-KEY"
```

#### Standard / Paid Anthropic Models:
```powershell
.agents/skills/claude-code/scripts/setup_openrouter.ps1 -ApiKey "sk-or-v1-YOUR-KEY"
```

### 4. Check Your Remaining Limits Anytime
```powershell
.agents/skills/claude-code/scripts/check_key_limits.ps1
```

---

## Dual-Agent Workflows in Antigravity

1. **Integrated Terminal**: Run `claude` in your Antigravity terminal side-by-side with your chat canvas.
2. **Chat Delegation**: Ask Antigravity:
   > *"Have Claude Code review this pull request / file."*
   Antigravity will run `.agents/plugins/claude-code/scripts/run_claude.ps1` in the background and present the findings.

---

## License
MIT License. Created for pairing Antigravity IDE and Claude Code via OpenRouter.

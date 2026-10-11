---
name: claude-code
description: >-
  Comprehensive guide and operational runbook for configuring, running, and troubleshooting
  Anthropic's Claude Code coding agent routed through OpenRouter. Use this skill when the user
  wants to set up, configure environment variables for, debug, or coordinate coding tasks with
  Claude Code powered by OpenRouter (especially on Windows PowerShell and Unix).
---

# Claude Code with OpenRouter Integration Skill

This skill provides step-by-step guidance on running **Claude Code** through **OpenRouter** as an LLM gateway for coding workflows, failover reliability, budget controls, and analytics.

---

## 1. Why Route Claude Code through OpenRouter?

- **Provider Failover & High Availability**: Automatically fails over across Anthropic providers if rate limits or upstream outages occur.
- **Budget & Cost Controls**: Centralized team spending caps and credit allocation via OpenRouter.
- **Unified Analytics**: Real-time cost, token usage, and request tracking in the OpenRouter Activity Dashboard.
- **Model Flexibility**: Ability to map task classes (Fable, Opus, Sonnet, Haiku, Subagents) to specific models or aliases.

---

## 2. Surfaces & Installation

Claude Code runs across multiple surfaces: **Terminal CLI**, **VS Code**, **JetBrains**, **Desktop app**, and **Web / Mobile**. All surfaces respect repository `CLAUDE.md` files, settings, and MCP servers.

### Native Terminal CLI Install

#### Windows PowerShell (Recommended)
```powershell
irm https://claude.ai/install.ps1 | iex
```
*Note: If you see `'irm' is not recognized`, you are in CMD instead of PowerShell.*

#### Windows Command Prompt (CMD)
```cmd
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```
*Note: If you see `'&&' is not a valid statement separator`, you are in PowerShell instead of CMD.*

#### macOS / Linux / WSL
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

#### Package Managers (Homebrew / WinGet / npm)
- **WinGet**: `winget install Anthropic.ClaudeCode`
- **Homebrew**: `brew install claude-code`
- **npm**: `npm install -g @anthropic-ai/claude-code`

> [!TIP]
> **Windows Shell Tooling**: On native Windows, installing [Git for Windows](https://git-scm.com/downloads/win) is recommended so Claude Code can utilize its Bash tool. If Git for Windows is absent, Claude Code defaults to PowerShell as the shell execution tool.

### Verifying Installation & PATH
```powershell
claude --version
```
If `claude` is not recognized after installation, ensure the install directory is added to your user `PATH` environment variable and restart your terminal.

---

## 3. Core Ecosystem Features

| Capability | Purpose & Usage |
| :--- | :--- |
| **`CLAUDE.md` Persistent Memory** | Repo-level instructions, build commands, and conventions placed in the root directory. Auto-read across all surfaces. |
| **MCP Integration** | Connect tools and databases via Model Context Protocol servers in `settings.json`. |
| **Remote Control & Mobile** | Continue terminal sessions on phone via `claude --cloud` and Claude mobile app. |
| **Channels** | Inject external events from webhooks, Telegram, Discord into Claude Code sessions. |
| **Routines / Scheduled Tasks** | Run recurring automated maintenance, tests, or code audits. |
| **Agent SDK** | Build custom programmatic agents in Python/TypeScript using Claude Code as the runtime. |


---

## 4. Environment Variable Configuration

OpenRouter uses Bearer token authentication compatible with Anthropic's Messages API gateway protocol.

### Critical Auth Rules
1. **`ANTHROPIC_BASE_URL`**: Must be `https://openrouter.ai/api`.
2. **`ANTHROPIC_AUTH_TOKEN`**: Set to your OpenRouter API key (`sk-or-...`). Claude Code sends this as `Authorization: Bearer <token>`.
3. **`ANTHROPIC_API_KEY`**: **MUST BE EXPLICITLY EMPTY (`""`)**. If set to an actual Anthropic key, Claude Code sends `x-api-key` and bypasses OpenRouter or triggers auth conflicts.
4. **No `.env` files**: Native Claude Code does not automatically load project `.env` files. Set these in your shell profile or terminal session.

---

### Configuration by Operating System / Shell

#### Windows PowerShell (Current session)
```powershell
$env:OPENROUTER_API_KEY = "<your-openrouter-api-key>"
$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $env:OPENROUTER_API_KEY
$env:ANTHROPIC_API_KEY = ""
$env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"
```

#### Windows PowerShell Profile (Persistent)
Edit `$PROFILE` (e.g. `notepad $PROFILE`):
```powershell
$env:OPENROUTER_API_KEY = "<your-openrouter-api-key>"
$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $env:OPENROUTER_API_KEY
$env:ANTHROPIC_API_KEY = ""
$env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"
```

#### Linux / macOS / WSL (`~/.bashrc` or `~/.zshrc`)
```bash
export OPENROUTER_API_KEY="<your-openrouter-api-key>"
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""
export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1
```
*Reload shell:* `source ~/.bashrc` or `source ~/.zshrc`.

---

## 5. Model Class Configuration

Claude Code routes different tasks to different model classes. Map them using these environment variables:

| Environment Variable | Role | Recommended OpenRouter Model Slug |
| :--- | :--- | :--- |
| `ANTHROPIC_DEFAULT_FABLE_MODEL` | Hardest reasoning & long-horizon tasks | `~anthropic/claude-fable-latest[1m]` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Complex reasoning / architecture | `~anthropic/claude-opus-latest[1m]` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Everyday code generation & edits | `~anthropic/claude-sonnet-latest[1m]` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Fast lightweight completions | `~anthropic/claude-haiku-latest` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Sub-agents spawned by Claude Code | `~anthropic/claude-opus-latest[1m]` |

> [!TIP]
> **1M Context Window**: Claude Code defaults to 200k context unless the model slug ends with `[1m]`. Appending `[1m]` signals Claude Code to support the extended context window before compacting. OpenRouter strips this marker prior to backend routing.

---

## 6. Fast Mode Configuration

Anthropic Fast Mode gives up to 2.5x faster output on Opus models (available for Opus 4.6, 4.7, 4.8, and 5).

To enable fast mode through OpenRouter:
1. Set the bypass flag:
   ```bash
   export CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1
   ```
   *(PowerShell: `$env:CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK = "1"`)*
2. Pin `ANTHROPIC_DEFAULT_OPUS_MODEL` to a concrete Opus version (e.g., `anthropic/claude-opus-5` instead of `latest` alias) so Claude Code attaches `speed: "fast"`.
3. In Claude Code, run `/fast` to toggle.

---

## 7. Clearing Cached Anthropic Logins & Verification

If previously logged in directly with an Anthropic account:
1. Run `/logout` inside Claude Code.
2. Confirm credentials removal:
   - **macOS**: `security find-generic-password -s "Claude Code-credentials"` (delete if present: `security delete-generic-password -s "Claude Code-credentials"`).
   - **Windows**: Clear cached Claude credentials in Windows Credential Manager if present.
3. Relaunch `claude`.
4. Verify connection using `/status`:
   ```text
   > /status
   Auth token: ANTHROPIC_AUTH_TOKEN
   Anthropic base URL: https://openrouter.ai/api
   ```
   *If `ANTHROPIC_API_KEY` appears or a direct Claude account appears, reload shell and re-verify env vars.*

---

## 8. CI/CD & GitHub Actions

Adapt the official `anthropics/claude-code-action@v1`:
```yaml
- name: Run Claude Code
  uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.OPENROUTER_API_KEY }}
  env:
    ANTHROPIC_BASE_URL: https://openrouter.ai/api
    ANTHROPIC_AUTH_TOKEN: ${{ secrets.OPENROUTER_API_KEY }}
```

---

## 9. Common Troubleshooting

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| **Model not found** (e.g., `openrouter/auto`) | Credential conflict between cached OAuth and OpenRouter | Run `/logout`, verify `ANTHROPIC_API_KEY=""`, restart terminal session. |
| **Auth Error / 401 Unauthorized** | `ANTHROPIC_AUTH_TOKEN` is unset or `ANTHROPIC_API_KEY` contains an old key | Check variable expansion order; ensure `ANTHROPIC_API_KEY=""`. |
| **Context Compacts at 200k** | Model name missing 1M context suffix | Append `[1m]` to model slug in env vars (e.g., `~anthropic/claude-sonnet-latest[1m]`). |
| **`/fast` shows ON but runs standard speed** | Using model alias instead of pinned model ID | Pin `ANTHROPIC_DEFAULT_OPUS_MODEL` to explicit model ID (e.g., `anthropic/claude-opus-5`). |
| **HTTP 402 Payment Required** | Account credits empty or in-flight hold exhausted | Check `error.metadata.limit_source`. If `openrouter_in_flight_budget`, wait for `Retry-After`. If `openrouter_credits`, add credits or reduce `max_tokens`. |
| **HTTP 403 Forbidden** | Org guardrail or workspace budget exceeded | Inspect `error.metadata.resets_at` and `scope`. Budget resets on UTC boundaries. |
| **HTTP 429 Rate Limit** | Platform or upstream provider rate limit | Check `X-RateLimit-*` and `Retry-After`. Use exponential backoff or provider fallbacks. |

---

## 10. Limits, Budgets & Monitoring

For in-depth details on how OpenRouter calculates holds, guardrails, and free-model quotas, refer to:
- [OpenRouter Limits Reference](./references/openrouter_limits.md)

### Proactive Monitoring Script
To verify current credit balances, active guardrails, and daily quotas before running demanding agent sessions:
```powershell
.agents/skills/claude-code/scripts/check_key_limits.ps1
```
Or query directly via `curl` / REST:
```bash
curl -H "Authorization: Bearer $OPENROUTER_API_KEY" https://openrouter.ai/api/v1/key
```


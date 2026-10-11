# CLAUDE.md - Guidelines for Claude Code

## Project Overview
This repository (**BRD-gen**) is an AI-powered Business Requirement Document (BRD) generation platform. It transforms unstructured business requirements, user questionnaires, and domain data into comprehensive, standardized BRD artifacts with multi-agent workflows and export capabilities (DOCX, PDF, JSON).

## Key Architecture & Core Files
- `app.py`: Main Flask application handling questionnaire flows, generation endpoints, and exports.
- `run_multi_port.py`: Multi-port development and production server runner.
- `backend/`: Core logic modules (domain agent discovery, prompt templates, validation, LLM routing).
- `tests/`: Automated test suite (`qa_comprehensive_audit.py`, `test_multi_port_servers.py`, `test_verification.py`).
- `static/` & `templates/`: Frontend UI assets (Vanilla JS, CSS, responsive dashboard).

## Development & Test Commands
```powershell
# Run the application
python app.py

# Run multi-port server instances
python run_multi_port.py

# Run comprehensive QA tests
python tests/qa_comprehensive_audit.py
pytest tests/
```

## Environment & Gateway Settings (OpenRouter)
When running Claude Code with OpenRouter on this project:
- `ANTHROPIC_BASE_URL`: `https://openrouter.ai/api`
- `ANTHROPIC_AUTH_TOKEN`: `$env:OPENROUTER_API_KEY`
- `ANTHROPIC_API_KEY`: `""` (Must remain explicitly empty)
- Context Marker: Always configure models with `[1m]` suffix (e.g., `~anthropic/claude-sonnet-latest[1m]`).

## Coding & Style Guidelines
- **Python**: Standard PEP 8 conventions. Maintain modular functions with clear type hints and docstrings.
- **Frontend**: Clean Vanilla JavaScript and semantic CSS. Avoid ad-hoc bloated libraries.
- **Documentation**: Keep `PROJECT_OVERVIEW_AND_ARCHITECTURE.md` and `STANDARDIZED_BRD.md` updated when modifying data models or questionnaire formats.

# Contributing

Thanks for wanting to improve Claude Multi-Agent Orchestration!

## Areas for Contribution

### ✅ Agents

Add new custom agents or improve existing ones:
- Create new agents in `agents/`
- Each agent should have:
  - Clear, focused purpose (one main task type)
  - Restricted toolset (only necessary tools)
  - System prompt optimized for the task
  - Description in frontmatter

Example PR: "Add data-analyst agent for SQL/data exploration"

### ✅ Models & Routing

- Add support for new free LLM APIs
- Improve classifier logic (`scripts/mcp_server.py`)
- Add fallback chains in `config/litellm_config.yaml`
- Test with different model combinations

Example PR: "Add support for Together AI models"

### ✅ Documentation

- Improve README with examples
- Add troubleshooting section entries
- Create setup guides for specific platforms
- Write tutorials for custom workflows

Example PR: "Add macOS-specific setup instructions"

### ✅ Token Monitoring

- Enhance `scripts/token_monitor.py`
- Add cost estimation
- Create visualization tools
- Add per-agent usage tracking

Example PR: "Add cost breakdown by agent type"

### ✅ Status Line Features

- Improve `scripts/statusline-command.sh`
- Add more metrics (cost, queue length, etc.)
- Create alternative display formats

Example PR: "Add real-time cost display to status line"

### ✅ Installation & Setup

- Improve `install.sh` for more platforms
- Add detection for existing installations
- Create Docker-based setup option
- Add uninstall script

Example PR: "Add Docker support for LiteLLM"

## How to Contribute

1. **Fork the repo** and create your branch
2. **Make your changes** with clear commit messages
3. **Test thoroughly** on your system
4. **Update README** if adding features
5. **Submit PR** with description of changes

## Testing Your Changes

Before submitting:

```bash
# Test installation
./install.sh

# Verify agents load
claude agent list

# Check API connection
curl -s http://localhost:4000/v1/models

# Test prompt engineer
echo '{"prompt":"test"}' | python3 scripts/prompt_engineer.py
```

## Code Style

- **Python:** Follow PEP 8, use f-strings
- **Bash:** Use set -e, quote variables
- **Markdown:** Keep line length ~80 chars
- **YAML:** 2-space indentation

## Issues

Found a bug? Create an issue with:
- What you expected
- What actually happened
- Steps to reproduce
- Your setup (OS, Python version, etc.)

## Questions?

Open a discussion! We're here to help.

Thanks for contributing! 🎉

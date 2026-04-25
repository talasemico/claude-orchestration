# Quick Start Guide

Get Claude Multi-Agent Orchestration running in 5 minutes.

## Prerequisites

- Python 3.8+
- Bash shell
- One free API key minimum (Groq recommended)

**Get free API keys (5 min):**

1. **Groq** (classifier) — https://console.groq.com/keys
2. **Cerebras** (executor) — https://console.cerebras.ai
3. **NVIDIA NIM** (executor) — https://www.nvidia.com/en-us/ai-data-science/solutions/ai-inference/
4. *Optional:* Gemini, OpenRouter, SambaNova

## Installation (2 min)

```bash
# Clone repo
git clone https://github.com/yourusername/claude-orchestration
cd claude-orchestration

# Run installer
chmod +x install.sh
./install.sh
```

## Configuration (2 min)

Add API keys to `~/.bashrc`:

```bash
export GROQ_API_KEY="gsk_..."
export CEREBRAS_API_KEY="..."
export NVIDIA_API_KEY="..."
```

Reload: `source ~/.bashrc`

## Verify (1 min)

```bash
# Check service
systemctl --user status litellm

# Verify API
curl -s http://localhost:4000/v1/models | jq '.data | length'

# Test agents
claude agent list

# Restart Claude Code to load agents
```

## Use It

In Claude Code, mention an agent:
```
@scout explore the project structure
@builder run cargo tests
@documenter write API docs for this function
```

Or just write naturally — the prompt engineer will improve clarity, and the router will use the best model.

## Monitor

```bash
# Check token usage
python3 ~/orchestrator/token_monitor.py today
```

Watch your Claude Code status bar: `68% ctx | 12.4K tok | Claude Sonnet 4.6 | agent:scout`

## Done! 🎉

You now have:
- ✅ Multi-model routing
- ✅ 5 custom agents
- ✅ Automatic prompt improvement
- ✅ Real-time monitoring
- ✅ ~70% token cost reduction

For details, see **[README.md](README.md)**

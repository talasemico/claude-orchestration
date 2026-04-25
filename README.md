# Claude Multi-Agent Orchestration

A complete setup for intelligent multi-model task routing in Claude Code using free LLM APIs and custom agents.

## What This Does

Automatically routes your coding tasks to the right model:
- **Complex tasks** (refactoring, architecture) → Claude Sonnet 4.6 (powerful)
- **Simple tasks** (code reading, summaries) → Free models (Cerebras, NVIDIA, Gemini, Groq, etc.)
- **Prompt reformulation** → Groq Llama 70B (automatically improves clarity)

**Result:** Same quality, fraction of the token cost.

## Features

✅ **5 Custom Agents** — Task-specific agents with restricted toolsets
- `scout` — Code exploration & structure mapping
- `researcher` — Web research & information synthesis
- `builder` — Build/test running & error parsing
- `documenter` — Documentation generation
- `planner` — Architecture & strategy design

✅ **Automatic Prompt Engineering** — Groq Llama 70B reformulates every prompt before processing

✅ **Multi-Model Orchestration** — Intelligently routes to 7+ free LLM APIs

✅ **Real-Time Monitoring** — Context %, token usage, current model/agent in Claude Code status line

✅ **Reduced Permission Prompts** — Pre-approved commands for common workflows

✅ **Token Tracking** — Complete visibility into usage & cost savings

## Prerequisites

- Claude Code (desktop, web, or IDE extension)
- Bash shell (Linux, macOS)
- Python 3.8+
- Free API keys (all free tier):
  - Groq (for classifier)
  - Cerebras (for executor)
  - NVIDIA NIM (for executor)
  - Google Gemini (optional backup)
  - OpenRouter (optional backup)
  - SambaNova (optional backup)

## Quick Start

### 1. Clone & Install

```bash
git clone https://github.com/yourusername/claude-orchestration
cd claude-orchestration
chmod +x install.sh
./install.sh
```

The installer will:
- Create `~/.claude/agents/` with 5 custom agents
- Set up LiteLLM proxy on localhost:4000
- Configure Claude Code settings (hooks, permissions, status line)
- Enable prompt engineering
- Create systemd user service for auto-start

### 2. Add API Keys

Edit `~/.bashrc` and add your free API keys:

```bash
# Groq (classifier)
export GROQ_API_KEY="gsk_..."

# Cerebras (executor)
export CEREBRAS_API_KEY="..."

# NVIDIA NIM (executor)
export NVIDIA_API_KEY="..."

# Optional: Google Gemini
export GEMINI_API_KEY="..."

# Optional: OpenRouter
export OPENROUTER_API_KEY="..."

# Optional: SambaNova
export SAMBANOVA_API_KEY="..."
```

Reload your shell: `source ~/.bashrc`

### 3. Start Services

```bash
# Enable auto-start
systemctl --user enable litellm

# Start now
systemctl --user start litellm

# Verify running
systemctl --user status litellm
```

### 4. Verify Setup

```bash
# Check agents are discoverable
claude agent list

# Check LiteLLM is responding
curl -s http://localhost:4000/v1/models | jq '.data | length'

# Test prompt engineer
echo '{"prompt":"un prompt vago"}' | python3 ~/orchestrator/prompt_engineer.py
```

## How It Works

### Task Routing

1. **You write a prompt**
2. **Prompt Engineer** (Groq Llama 70B) reformulates it for clarity (~200ms)
3. **Classifier** (Groq Llama 70B) analyzes complexity
4. **Router** decides:
   - ✅ Simple task → Use free model (Cerebras, NVIDIA, etc.)
   - ⚙️ Complex task → Use Claude Sonnet 4.6
5. **Task runs** with appropriate model & agent

### Multi-Model Orchestration

LiteLLM proxy abstracts 7+ free APIs behind a single endpoint:

```
http://localhost:4000/v1/chat/completions
```

Each model configured with fallback chains for resilience:

```yaml
classifier-groq:        Groq Llama 70B (primary)
  └─ fallback → classifier-gemini (Google Gemini)

executor-cerebras:      Cerebras Llama 70B (primary)
  └─ fallback → executor-sambanova (SambaNova Llama 70B)
  └─ fallback → executor-nvidia-70b (NVIDIA Nemotron 70B)
```

### Custom Agents

Each agent is a Markdown file with:
- YAML frontmatter (name, model, description)
- System prompt (specialized for the task)
- Restricted toolset (no unnecessary access)

**Example:** `scout.md`
```yaml
---
name: scout
model: claude-haiku-4-5-20251001
description: Explore directory structure, find files, summarize code
allowed-tools:
  - Read
  - Bash(find *)
  - Bash(grep *)
---

# Scout Agent

You are a code explorer...
```

When you use `--agent scout`, Claude Code loads this system prompt and tool restrictions.

### Status Line Monitoring

Claude Code status bar shows real-time:

```
68% ctx | 12.4K tok | Claude Sonnet 4.6 | agent:scout | [build-fix]
```

- **Context %** — How much of context window is used
- **Token count** — Total input+output tokens this session
- **Model** — Currently active model
- **Agent** — Which agent is running (if any)
- **Task label** — Your session name (use `/rename` to set)

### Token Tracking

Monitor usage and cost savings:

```bash
# Today's usage
python3 ~/orchestrator/token_monitor.py today

# Weekly summary
python3 ~/orchestrator/token_monitor.py week

# Output example:
# Model                  Tokens        Cost
# groq/llama-70b-chat   45,230      $0.00
# cerebras/llama-70b    12,100      $0.00
# claude-sonnet-4.6     28,900      $0.87
# Total               86,230      $0.87
```

## File Structure

```
~/.claude/
├── agents/                    # 5 custom agents
│   ├── scout.md
│   ├── researcher.md
│   ├── builder.md
│   ├── documenter.md
│   └── planner.md
├── settings.json              # Claude Code config
├── statusline-command.sh       # Status line monitor
└── projects/
    └── <project-dir>/
        └── .claude/
            └── settings.json   # Per-project overrides

~/.config/systemd/user/
└── litellm.service            # Auto-start service

~/litellm/
├── litellm_config.yaml        # Model endpoints & fallbacks
└── logs/

~/orchestrator/
├── prompt_engineer.py         # Groq Llama 70B reformulation
├── mcp_server.py              # Task router & classifier
├── token_monitor.py           # Token tracking
└── token_logs.jsonl           # Usage history
```

## Configuration

### Adding a New Model

Edit `~/litellm/litellm_config.yaml`:

```yaml
model_list:
  - model_name: my-custom-model
    litellm_params:
      model: openai/my-model
      api_base: https://api.example.com/v1
      api_key: ${MY_API_KEY}
```

Then restart: `systemctl --user restart litellm`

### Creating a Custom Agent

1. Create `~/.claude/agents/my-agent.md`:

```yaml
---
name: my-agent
model: claude-haiku-4-5-20251001
description: Agent description
allowed-tools:
  - Read
  - Bash(find *)
---

# My Agent

Your system prompt here...
```

2. Use it: `claude code --agent my-agent`

### Modifying Permissions

Edit `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Bash(cargo build *)",
      "Bash(npm run test)"
    ],
    "deny": [
      "Bash(rm:*)",
      "Bash(git push --force:*)"
    ]
  }
}
```

## pi.dev Setup (Alternative to Claude Code)

Want to use **pi.dev** instead of Claude Code? The same orchestration infrastructure works with pi.dev!

### Installation

Pi.dev requires Node.js >=20.0.0. After upgrading Node:

```bash
./install-pi.sh
```

Or manually:

```bash
npm install -g @mariozechner/pi-coding-agent
mkdir -p ~/.pi/skills
cp pi-setup/config/config.yaml ~/.pi/config.yaml
cp pi-setup/skills/*.md ~/.pi/skills/
cp pi-setup/pi_wrapper.sh ~/orchestrator/
```

### Usage

```bash
# Single-shot prompts (with prompt engineering)
pi "analyze the project structure"
pi "run tests and fix errors"

# With specific agent/skill
pi --skill scout "show directory tree"
pi --skill planner "design the architecture"

# Interactive mode (no prompt engineering in TUI)
pi
```

### How It Works

- **Same LiteLLM proxy** — Pi connects to `localhost:4000` as an OpenAI-compatible endpoint
- **Same models** — All 7 free APIs available: Cerebras, NVIDIA, Groq, SambaNova, OpenRouter, Gemini
- **Prompt engineering** — The `pi` alias wrapper pipes prompts through Groq Llama 70B before execution
- **Same agents/skills** — The 5 specialized agents (scout, researcher, builder, planner, documenter) ported to Pi format
- **Token tracking** — Usage logs visible in `~/.pi/sessions/` and can be monitored with `token_monitor.py`

### pi.dev vs. Claude Code

| Feature | Claude Code | Pi.dev |
|---------|-----|----|
| **Setup** | Easy (built-in agent system) | Medium (Node 20+ required) |
| **Model flexibility** | Limited to configured Claude models | 15+ providers natively |
| **Prompt engineering** | Via hook system | Via wrapper script |
| **Session history** | Linear | Tree-based (branching) |
| **Cost** | $0 (free models only) | $0 (free models only) |
| **Primary interface** | GUI/Web | Terminal |

### Known Limitations

- **Interactive TUI mode** doesn't get prompt engineering (wrapper only works for command-line args)
- **Tool restrictions** are less granular in Pi than Claude Code's per-tool patterns
- **Requires Node.js 20+** (system in this example has 18, upgrade needed to run)

### Migration Guide

When fully switching from Claude Code to pi.dev:

1. Keep LiteLLM running (serves both tools)
2. Set `~/.bashrc` default to `pi` sessions instead of `claude` sessions
3. Use pi's session branching feature to organize work

---

## Troubleshooting

### LiteLLM not starting

```bash
# Check logs
journalctl --user -u litellm -n 50

# Manual start (debug)
litellm --config ~/litellm/litellm_config.yaml --port 4000
```

### API key errors

Verify keys are exported:
```bash
echo $GROQ_API_KEY
echo $CEREBRAS_API_KEY
```

Add them to `~/.bashrc` and reload: `source ~/.bashrc`

### Prompt engineer not reformulating

```bash
# Test directly
echo '{"prompt":"test"}' | python3 ~/orchestrator/prompt_engineer.py

# Check LiteLLM is running
curl -s http://localhost:4000/v1/models | jq .
```

### Status line not showing

Claude Code needs restart. Close and reopen the application.

## Costs & Savings

**Before:** Everything on Claude Sonnet 4.6
- ~1M tokens/month = $30 USD

**After:** Intelligent routing
- Simple tasks on free models = $0
- Complex tasks on Sonnet = ~$8-12 USD
- **Savings: ~70% month-to-month**

Actual savings depend on your task mix. More code reading/exploration = higher savings.

## API Limits & Rate Limits

All free tier APIs have rate limits. LiteLLM handles:
- **Automatic fallback** if rate limit hit
- **Exponential backoff** for retries
- **Request queuing** to avoid hitting limits

For production use, consider paid tiers or additional API keys.

## Next Steps

1. ✅ Complete installation
2. 📊 Monitor token usage for first week
3. 🔧 Tune classifier thresholds if needed
4. 📝 Customize agent system prompts for your workflow
5. 🚀 Share savings with team or friends

## Support

- **Issues:** Check troubleshooting section above
- **Questions:** See inline comments in config files
- **Contributions:** PRs welcome!

## License

MIT - Use freely, modify, share.

## Author

Created to optimize multi-model usage in Claude Code while reducing token costs and improving workflow.

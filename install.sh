#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
  echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
print_header "Checking Prerequisites"

if ! command -v python3 &> /dev/null; then
  print_error "Python 3 not found. Install with: apt-get install python3 (Linux) or brew install python3 (macOS)"
  exit 1
fi
print_success "Python 3 found"

if ! command -v pip3 &> /dev/null; then
  print_error "pip3 not found. Install with: apt-get install python3-pip (Linux) or brew install python3 (macOS)"
  exit 1
fi
print_success "pip3 found"

if ! command -v git &> /dev/null; then
  print_error "Git not found. Install with: apt-get install git (Linux) or brew install git (macOS)"
  exit 1
fi
print_success "Git found"

# Get the directory where install.sh is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directory structure
print_header "Creating Directory Structure"

mkdir -p ~/.claude/agents
print_success "Created ~/.claude/agents"

mkdir -p ~/.config/systemd/user
print_success "Created ~/.config/systemd/user"

mkdir -p ~/litellm/logs
print_success "Created ~/litellm"

mkdir -p ~/orchestrator
print_success "Created ~/orchestrator"

mkdir -p ~/.monitor
print_success "Created ~/.monitor"

# Copy configuration files
print_header "Installing Configuration Files"

# Copy agents
cp "$SCRIPT_DIR"/agents/*.md ~/.claude/agents/ 2>/dev/null || true
print_success "Copied custom agents to ~/.claude/agents"

# Copy orchestrator scripts
cp "$SCRIPT_DIR"/scripts/prompt_engineer.py ~/orchestrator/
cp "$SCRIPT_DIR"/scripts/mcp_server.py ~/orchestrator/ 2>/dev/null || true
cp "$SCRIPT_DIR"/scripts/token_monitor.py ~/orchestrator/
cp "$SCRIPT_DIR"/scripts/statusline-command.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
print_success "Copied orchestrator scripts"

# Copy LiteLLM config
cp "$SCRIPT_DIR"/config/litellm_config.yaml ~/litellm/
print_success "Copied LiteLLM configuration"

# Copy systemd service
cp "$SCRIPT_DIR"/config/systemd/litellm.service ~/.config/systemd/user/
print_success "Copied systemd service file"

# Install Python dependencies
print_header "Installing Python Dependencies"

pip3 install --quiet litellm requests 2>/dev/null || {
  print_warning "Some pip packages failed to install. Try manual install:"
  echo "  pip3 install litellm requests"
}
print_success "Installed litellm and requests"

# Setup Claude Code settings
print_header "Configuring Claude Code"

SETTINGS_FILE=~/.claude/settings.json

# Check if settings.json exists
if [ -f "$SETTINGS_FILE" ]; then
  print_warning "settings.json already exists at $SETTINGS_FILE"
  echo "Backing up to settings.json.backup"
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
fi

# Create or merge settings.json
python3 << 'EOF'
import json
import os

settings_file = os.path.expanduser("~/.claude/settings.json")

# Default settings
default_settings = {
    "permissions": {
        "allow": [
            "Read",
            "Bash(ls:*)",
            "Bash(ls -la:*)",
            "Bash(find:*)",
            "Bash(grep:*)",
            "Bash(rg:*)",
            "Bash(cat:*)",
            "Bash(echo:*)",
            "Bash(pwd)",
            "Bash(whoami)",
            "Bash(hostname:*)",
            "Bash(date:*)",
            "Bash(env:*)",
            "Bash(printenv:*)",
            "Bash(which:*)",
            "Bash(type:*)",
            "Bash(wc:*)",
            "Bash(head:*)",
            "Bash(tail:*)",
            "Bash(sort:*)",
            "Bash(uniq:*)",
            "Bash(cut:*)",
            "Bash(awk:*)",
            "Bash(sed:*)",
            "Bash(tr:*)",
            "Bash(jq:*)",
            "Bash(diff:*)",
            "Bash(stat:*)",
            "Bash(file:*)",
            "Bash(du:*)",
            "Bash(df:*)",
            "Bash(ps:*)",
            "Bash(top:*)",
            "Bash(htop:*)",
            "Bash(uname:*)",
            "Bash(id:*)",
            "Bash(groups:*)",
            "Bash(git status:*)",
            "Bash(git log:*)",
            "Bash(git diff:*)",
            "Bash(git show:*)",
            "Bash(git branch:*)",
            "Bash(git remote:*)",
            "Bash(git stash list:*)",
            "Bash(git tag:*)",
            "Bash(git describe:*)",
            "Bash(git rev-parse:*)",
            "Bash(git ls-files:*)",
            "Bash(git blame:*)",
            "Bash(git shortlog:*)",
            "Bash(docker ps:*)",
            "Bash(docker images:*)",
            "Bash(docker inspect:*)",
            "Bash(docker logs:*)",
            "Bash(docker stats:*)",
            "Bash(docker-compose ps:*)",
            "Bash(docker-compose logs:*)",
            "Bash(docker compose ps:*)",
            "Bash(docker compose logs:*)",
            "Bash(cargo check *)",
            "Bash(cargo clippy *)",
            "Bash(cargo test *)",
            "Bash(cargo build *)",
            "Bash(cargo run --bin *)",
            "Bash(cargo fmt *)",
            "Bash(systemctl --user status *)",
            "Bash(systemctl --user restart *)",
            "Bash(systemctl --user start *)",
            "Bash(systemctl --user stop *)",
            "Bash(curl -s http://localhost:4000/*)",
            "Bash(curl -s http://127.0.0.1:4000/*)",
            "Bash(claude mcp *)",
            "Bash(netstat -tlnp)",
            "Bash(ss -tlnp)",
            "Bash(python3 /home/talasemico/orchestrator/*)",
            "Write",
            "Edit"
        ],
        "deny": [
            "Bash(rm:*)",
            "Bash(rmdir:*)",
            "Bash(git reset --hard:*)",
            "Bash(git clean:*)",
            "Bash(git push --force:*)",
            "Bash(git push -f:*)",
            "Bash(dd:*)",
            "Bash(mkfs:*)",
            "Bash(shred:*)",
            "Bash(truncate:*)",
            "Bash(> *)"
        ]
    },
    "model": "haiku",
    "statusLine": {
        "type": "command",
        "command": "bash ~/.claude/statusline-command.sh"
    },
    "hooks": {
        "UserPromptSubmit": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": "python3 ~/orchestrator/prompt_engineer.py",
                        "timeout": 8,
                        "statusMessage": "Improving prompt clarity..."
                    }
                ]
            }
        ]
    }
}

# Load existing settings if present
existing = {}
if os.path.exists(settings_file):
    try:
        with open(settings_file, 'r') as f:
            existing = json.load(f)
    except:
        pass

# Merge (prefer existing, add missing from default)
merged = {**default_settings}
if existing:
    if "permissions" in existing:
        # Merge permission lists
        merged["permissions"]["allow"] = list(set(
            merged["permissions"]["allow"] +
            existing["permissions"].get("allow", [])
        ))
        merged["permissions"]["deny"] = list(set(
            merged["permissions"]["deny"] +
            existing["permissions"].get("deny", [])
        ))
    merged.update({k: v for k, v in existing.items() if k != "permissions"})

# Write merged settings
with open(settings_file, 'w') as f:
    json.dump(merged, f, indent=2)

print(f"✓ Settings saved to {settings_file}")
EOF

print_success "Claude Code settings configured"

# Enable and start systemd service
print_header "Setting Up Auto-Start Service"

systemctl --user daemon-reload
print_success "Daemon reloaded"

systemctl --user enable litellm
print_success "LiteLLM service enabled for auto-start"

systemctl --user restart litellm
print_success "LiteLLM service started"

# Wait for service to start
sleep 2

# Verify setup
print_header "Verifying Installation"

if systemctl --user is-active --quiet litellm; then
  print_success "LiteLLM service is running"
else
  print_warning "LiteLLM service failed to start. Check logs with: journalctl --user -u litellm"
fi

# Test API connection
if curl -s http://localhost:4000/v1/models &>/dev/null; then
  MODEL_COUNT=$(curl -s http://localhost:4000/v1/models | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('data', [])))" 2>/dev/null || echo "?")
  print_success "LiteLLM API responding ($MODEL_COUNT models configured)"
else
  print_warning "Could not connect to LiteLLM. Service may still be starting..."
fi

# Check agents exist
AGENT_COUNT=$(ls -1 ~/.claude/agents/*.md 2>/dev/null | wc -l)
if [ "$AGENT_COUNT" -gt 0 ]; then
  print_success "Found $AGENT_COUNT custom agents"
else
  print_warning "No agents found in ~/.claude/agents"
fi

# Final instructions
print_header "Installation Complete!"

echo -e "\n${BLUE}Next Steps:${NC}\n"

echo "1. ${YELLOW}Add API Keys${NC} to ~/.bashrc:"
cat << 'KEYS'
   export GROQ_API_KEY="your-key-here"
   export CEREBRAS_API_KEY="your-key-here"
   export NVIDIA_API_KEY="your-key-here"
   # Optional: GEMINI_API_KEY, OPENROUTER_API_KEY, SAMBANOVA_API_KEY
KEYS

echo -e "\n2. ${YELLOW}Reload shell${NC}:"
echo "   source ~/.bashrc"

echo -e "\n3. ${YELLOW}Restart LiteLLM${NC} (to load new keys):"
echo "   systemctl --user restart litellm"

echo -e "\n4. ${YELLOW}Verify setup${NC}:"
echo "   curl -s http://localhost:4000/v1/models | jq '.data | length'"

echo -e "\n5. ${YELLOW}Test prompt engineer${NC}:"
echo "   echo '{\"prompt\":\"test\"}' | python3 ~/orchestrator/prompt_engineer.py"

echo -e "\n6. ${YELLOW}Restart Claude Code${NC} to see agents and status line"

echo -e "\n${GREEN}For detailed documentation, see README.md${NC}\n"

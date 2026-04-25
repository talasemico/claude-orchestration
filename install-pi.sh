#!/usr/bin/env bash

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

print_header "Pi.dev Installation & Setup"

# Check prerequisites
print_header "Checking Prerequisites"

if ! command -v node &> /dev/null; then
  print_error "Node.js not found. Pi.dev requires Node.js >=20.0.0"
  echo "Install from: https://nodejs.org/ (download LTS 20+)"
  exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
  print_error "Node.js version too old: $(node -v) (needs >=20.0.0)"
  echo "Upgrade at: https://nodejs.org/"
  exit 1
fi
print_success "Node.js $(node -v) found"

if ! command -v npm &> /dev/null; then
  print_error "npm not found"
  exit 1
fi
print_success "npm found"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header "Installing Pi.dev"

# Create local npm directory
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global

# Install pi
npm install -g @mariozechner/pi-coding-agent 2>&1 | grep -E "(added|up to date)" | head -1

# Create wrapper script
print_success "Pi.dev installed"

# Setup pi configuration
print_header "Configuring Pi.dev"

mkdir -p ~/.pi/skills
cp "$SCRIPT_DIR/pi-setup/config/config.yaml" ~/.pi/config.yaml
print_success "Created ~/.pi/config.yaml"

# Copy skills
for skill in "$SCRIPT_DIR/pi-setup/skills/"*.md; do
  cp "$skill" ~/.pi/skills/
  echo "✓ $(basename "$skill")"
done
print_success "Copied 5 skills to ~/.pi/skills/"

# Create wrapper script
mkdir -p ~/bin
cp "$SCRIPT_DIR/pi-setup/pi_wrapper.sh" ~/orchestrator/
chmod +x ~/orchestrator/pi_wrapper.sh

# Create pi binary wrapper
cat > ~/bin/pi << 'WRAPPER_EOF'
#!/usr/bin/env bash
node ~/.npm-global/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js "$@"
WRAPPER_EOF
chmod +x ~/bin/pi
print_success "Created ~/bin/pi wrapper"

# Update bashrc
if ! grep -q "alias pi=" ~/.bashrc; then
  cat >> ~/.bashrc << 'EOF'

# Pi.dev orchestration wrapper (prompt engineering + routing)
export PATH="$HOME/bin:$PATH"
alias pi='bash ~/orchestrator/pi_wrapper.sh'
EOF
  print_success "Added pi alias to ~/.bashrc"
fi

# Verify setup
print_header "Verifying Installation"

if ~/bin/pi --version &>/dev/null; then
  print_success "Pi.dev is working"
else
  print_warning "Could not verify pi (may need shell reload)"
fi

# Verify LiteLLM is running
if curl -s http://localhost:4000/v1/models &>/dev/null; then
  print_success "LiteLLM proxy is running (models will route through localhost:4000)"
else
  print_warning "LiteLLM proxy not running. Start with: systemctl --user start litellm"
fi

print_header "Setup Complete!"

echo -e "\n${BLUE}Next Steps:${NC}\n"
echo "1. Reload shell:"
echo "   source ~/.bashrc"

echo -e "\n2. Test pi.dev:"
echo "   pi --version"
echo "   pi 'show the project structure'"

echo -e "\n3. Available agents (skills):"
echo "   pi --skill scout 'analyze code'"
echo "   pi --skill builder 'run tests'"
echo "   pi --skill planner 'design architecture'"

echo -e "\n${GREEN}Pi.dev is now configured to use the same LiteLLM orchestration as Claude Code!${NC}\n"

echo "Documentation: See README.md for full setup details"

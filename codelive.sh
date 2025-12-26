#!/bin/bash

set -euo pipefail

# Check if running on Windows without proper shell support
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]] && ! command -v bash &>/dev/null; then
    echo "❌ This script requires Bash to run on Windows."
    echo "Please install one of the following:"
    echo "• Git Bash (included with Git for Windows): https://git-scm.com/download/win"
    echo "• WSL (Windows Subsystem for Linux): https://aka.ms/wsl"
    echo "• Cygwin: https://www.cygwin.com/"
    exit 1
fi

# ========================
#       Define Constants
# ========================
SCRIPT_NAME=$(basename "$0")
NODE_MIN_VERSION=18
NODE_INSTALL_VERSION=22
NVM_VERSION="v0.40.3"
CLAUDE_PACKAGE="@anthropic-ai/claude-code"
CONFIG_DIR="$HOME/.claude"
CONFIG_FILE="$CONFIG_DIR/settings.json"
API_BASE_URL="https://api.z.ai/api/anthropic"
API_KEY_URL="https://z.ai/manage-apikey/apikey-list"
API_TIMEOUT_MS=3000000

# ========================
#       Functions
# ========================

# Animation colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

show_welcome_animation() {
    clear
    echo -e "${RED}"

    # Frame 1
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║                                                               ║"
    echo "║                                                               ║"
    echo "║                                                               ║"
    echo "║                                                               ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    sleep 0.3

    # Frame 2
    clear
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║        ████████╗██╗  ██╗██╗████████╗███████╗██████╗         ║"
    echo "║        ╚══██╔══╝██║  ██║██║╚══██╔══╝██╔════╝██╔══██╗        ║"
    echo "║           ██║   ███████║██║   ██║   █████╗  ██████╔╝        ║"
    echo "║           ██║   ██╔══██║██║   ██║   ██╔══╝  ██╔══██╗        ║"
    echo "║           ██║   ██║  ██║██║   ██║   ███████╗██║  ██║        ║"
    echo "║           ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    sleep 0.3

    # Frame 3 - Full reveal with color
    clear
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                               ${RED}║${NC}"
    echo -e "${RED}║${NC}        ${RED}███████╗████████╗██╗███╗   ██╗██╗ ██████╗██╗  ██╗${NC} ${RED}║${NC}"
    echo -e "${RED}║${NC}        ${RED}██╔════╝╚══██╔══╝██║████╗  ██║██║██╔════╝██║ ██╔╝${NC} ${RED}║${NC}"
    echo -e "${RED}║${NC}        ${RED}███████╗   ██║   ██║██╔██╗ ██║██║██║     █████╔╝ ${NC} ${RED}║${NC}"
    echo -e "${RED}║${NC}        ${RED}╚════██║   ██║   ██║██║╚██╗██║██║██║     ██╔═██╗ ${NC} ${RED}║${NC}"
    echo -e "${RED}║${NC}        ${RED}███████║   ██║   ██║██║ ╚████║██║╚██████╗██║  ██╗${NC} ${RED}║${NC}"
    echo -e "${RED}║${NC}        ${RED}╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝╚═╝  ╚═╝${NC} ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                               ${RED}║${NC}"
    echo -e "${RED}║${NC}                     ${CYAN}★★★★★ ${WHITE}WELCOME TO${CYAN} ★★★★★${NC}           ${RED}║${NC}"
    echo -e "${RED}║${NC}                     ${YELLOW}🚀   C O D E L I V E   🚀${NC}           ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                               ${RED}║${NC}"
    echo -e "${RED}║${NC}                 ${GREEN}Code By Ed Duran @THEDURANCODE${NC}              ${RED}║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"

    sleep 0.5

    # Add blinking stars effect
    for i in {1..3}; do
        echo -e "\r${YELLOW}✨ Installing your AI-powered development environment... ✨${NC}"
        sleep 0.5
        echo -e "\r${YELLOW}⭐ Installing your AI-powered development environment... ⭐${NC}"
        sleep 0.5
    done

    echo ""
    echo ""
    sleep 1
}

log_info() {
    echo "🔹 $*"
}

log_success() {
    echo "✅ $*"
}

log_error() {
    echo "❌ $*" >&2
}

ensure_dir_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            exit 1
        }
    fi
}

# ========================
#     Node.js Installation
# ========================

install_nodejs() {
    local platform=$(uname -s 2>/dev/null || echo "Windows")

    case "$platform" in
        Linux|Darwin)
            log_info "Installing Node.js on $platform..."

            # Install nvm
            log_info "Installing nvm ($NVM_VERSION)..."
            curl -s https://raw.githubusercontent.com/nvm-sh/nvm/"$NVM_VERSION"/install.sh | bash

            # Load nvm
            log_info "Loading nvm environment..."
            \. "$HOME/.nvm/nvm.sh"

            # Install Node.js
            log_info "Installing Node.js $NODE_INSTALL_VERSION..."
            nvm install "$NODE_INSTALL_VERSION"

            # Verify installation
            node -v &>/dev/null || {
                log_error "Node.js installation failed"
                exit 1
            }
            log_success "Node.js installed: $(node -v)"
            log_success "npm version: $(npm -v)"
            ;;
        Windows|CYGWIN*|MINGW*|MSYS*)
            log_info "Installing Node.js on Windows..."

            # Check for Chocolatey
            if command -v choco &>/dev/null; then
                log_info "Installing Node.js via Chocolatey..."
                choco install nodejs --version="$NODE_INSTALL_VERSION" -y
            # Check for Scoop
            elif command -v scoop &>/dev/null; then
                log_info "Installing Node.js via Scoop..."
                scoop install nodejs
            # Check for winget
            elif command -v winget &>/dev/null; then
                log_info "Installing Node.js via winget..."
                winget install OpenJS.NodeJS --version "$NODE_INSTALL_VERSION"
            else
                log_info "No package manager found. Please install Node.js manually:"
                log_info "1. Download from: https://nodejs.org/"
                log_info "2. Or install Chocolatey: https://chocolatey.org/install"
                log_info "3. Or install Scoop: https://scoop.sh/"
                exit 1
            fi

            # Verify installation
            node -v &>/dev/null || {
                log_error "Node.js installation failed"
                exit 1
            }
            log_success "Node.js installed: $(node -v)"
            log_success "npm version: $(npm -v)"
            ;;
        *)
            log_error "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

# ========================
#       Git Installation
# ========================

install_git() {
    local platform=$(uname -s 2>/dev/null || echo "Windows")

    case "$platform" in
        Linux)
            log_info "Installing Git on Linux..."

            # Check for package managers
            if command -v apt-get &>/dev/null; then
                sudo apt-get update && sudo apt-get install -y git
            elif command -v yum &>/dev/null; then
                sudo yum install -y git
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y git
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm git
            else
                log_error "No supported package manager found for Git installation on Linux"
                log_info "Please install Git manually: https://git-scm.com/download/linux"
                exit 1
            fi
            ;;
        Darwin)
            log_info "Installing Git on macOS..."

            # Check if Homebrew is installed
            if command -v brew &>/dev/null; then
                brew install git
            elif command -v xcode-select &>/dev/null; then
                # Install Xcode command line tools (includes git)
                xcode-select --install
                log_info "Please complete the Xcode Command Line Tools installation and run the script again"
                exit 0
            else
                log_error "Please install Homebrew or Xcode Command Line Tools first"
                log_info "Homebrew: https://brew.sh/"
                log_info "Xcode CLI: xcode-select --install"
                exit 1
            fi
            ;;
        Windows|CYGWIN*|MINGW*|MSYS*)
            log_info "Installing Git on Windows..."

            # Check for Chocolatey
            if command -v choco &>/dev/null; then
                log_info "Installing Git via Chocolatey..."
                choco install git -y
            # Check for Scoop
            elif command -v scoop &>/dev/null; then
                log_info "Installing Git via Scoop..."
                scoop install git
            # Check for winget
            elif command -v winget &>/dev/null; then
                log_info "Installing Git via winget..."
                winget install Git.Git -e --source winget
            else
                log_info "No package manager found. Please install Git manually:"
                log_info "1. Download from: https://git-scm.com/download/win"
                log_info "2. Or install Chocolatey: https://chocolatey.org/install"
                log_info "3. Or install Scoop: https://scoop.sh/"
                exit 1
            fi
            ;;
        *)
            log_error "Unsupported platform for Git installation: $platform"
            log_info "Please install Git manually: https://git-scm.com/downloads"
            exit 1
            ;;
    esac

    # Verify installation
    git --version &>/dev/null || {
        log_error "Git installation failed"
        exit 1
    }
    log_success "Git installed: $(git --version)"
}

# ========================
#       Git Check
# ========================

check_git() {
    if command -v git &>/dev/null; then
        log_success "Git is already installed: $(git --version)"
        return 0
    else
        log_info "Git not found. Installing..."
        install_git
    fi
}

# ========================
#     Node.js Check
# ========================

check_nodejs() {
    if command -v node &>/dev/null; then
        current_version=$(node -v | sed 's/v//')
        major_version=$(echo "$current_version" | cut -d. -f1)

        if [ "$major_version" -ge "$NODE_MIN_VERSION" ]; then
            log_success "Node.js is already installed: v$current_version"
            return 0
        else
            log_info "Node.js v$current_version is installed but version < $NODE_MIN_VERSION. Upgrading..."
            install_nodejs
        fi
    else
        log_info "Node.js not found. Installing..."
        install_nodejs
    fi
}

# ========================
#     Claude Code Installation
# ========================

install_claude_code() {
    if command -v claude &>/dev/null; then
        log_success "Claude Code is already installed: $(claude --version)"
    else
        log_info "Installing Claude Code..."
        npm install -g "$CLAUDE_PACKAGE" || {
            log_error "Failed to install claude-code"
            exit 1
        }
        log_success "Claude Code installed successfully"
    fi
}

configure_claude_json(){
  node --eval '
      const os = require("os");
      const fs = require("fs");
      const path = require("path");

      const homeDir = os.homedir();
      const filePath = path.join(homeDir, ".claude.json");
      if (fs.existsSync(filePath)) {
          const content = JSON.parse(fs.readFileSync(filePath, "utf-8"));
          fs.writeFileSync(filePath, JSON.stringify({ ...content, hasCompletedOnboarding: true }, null, 2), "utf-8");
      } else {
          fs.writeFileSync(filePath, JSON.stringify({ hasCompletedOnboarding: true }, null, 2), "utf-8");
      }'
}

# ========================
#     API Key Configuration
# ========================

configure_claude() {
    echo -n "Please enter your Codelive API key: "
    read -s api_key
    echo

    if [ -z "$api_key" ]; then
        log_error "API key cannot be empty. Please run the script again."
        exit 1
    fi

    ensure_dir_exists "$CONFIG_DIR"

    # Write settings.json
    node --eval '
        const os = require("os");
        const fs = require("fs");
        const path = require("path");

        const homeDir = os.homedir();
        const filePath = path.join(homeDir, ".claude", "settings.json");
        const apiKey = "'"$api_key"'";

        const content = fs.existsSync(filePath)
            ? JSON.parse(fs.readFileSync(filePath, "utf-8"))
            : {};

        fs.writeFileSync(filePath, JSON.stringify({
            ...content,
            env: {
                ANTHROPIC_AUTH_TOKEN: apiKey,
                ANTHROPIC_BASE_URL: "'"$API_BASE_URL"'",
                API_TIMEOUT_MS: "'"$API_TIMEOUT_MS"'",
                CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: 1
            },
            mcpServers: {
                filesystem: {
                    command: "npx",
                    args: [
                        "-y",
                        "@modelcontextprotocol/server-filesystem",
                        "'"$HOME"'"
                    ]
                }
            }
        }, null, 2), "utf-8");
    ' || {
        log_error "Failed to write settings.json"
        exit 1
    }

    log_success "Claude Code configured successfully"
}

# ========================
#        Main
# ========================

main() {
    show_welcome_animation
    echo "🚀 Starting $SCRIPT_NAME"

    check_git
    check_nodejs
    install_claude_code
    configure_claude_json
    configure_claude

    echo ""
    log_success "🎉 CODELIVE installation completed successfully!"
    echo ""
    echo "🛠️  Installed tools: Git • Node.js • Claude Code"
    echo ""
    echo "📋 The script has automatically modified ~/.claude/settings.json to configure the following:"
    echo "   You don't need to edit manually:"
    echo ""
    echo "   {"
    echo "       \"env\": {"
    echo "           \"ANTHROPIC_AUTH_TOKEN\": \"[your-api-key]\","
    echo "           \"ANTHROPIC_BASE_URL\": \"https://api.z.ai/api/anthropic\","
    echo "           \"API_TIMEOUT_MS\": \"3000000\""
    echo "       },"
    echo "       \"mcpServers\": {"
    echo "           \"filesystem\": {"
    echo "               \"command\": \"npx\","
    echo "               \"args\": [\"-y\", \"@modelcontextprotocol/server-filesystem\", \"[your-home-dir]\"]"
    echo "           }"
    echo "       }"
    echo "   }"
    echo ""
    echo "🚀 You can now start using Claude Code with:"
    echo "   claude"
}

main "$@"

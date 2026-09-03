#!/usr/bin/env bash
# ==============================================================================
# init2k: Bootstrapper for 2K Ecosystem
# https://github.com/2kabhishek/init2k
# ==============================================================================

set -eo pipefail

# Reopen stdin from /dev/tty if running in a pipe (e.g. curl ... | bash)
if [[ ! -t 0 ]] && [[ -r /dev/tty ]]; then
    exec < /dev/tty
fi

export PATH="$HOME/.local/bin:$PATH"

current_dir="${BASH_SOURCE[0]%/*}"
[[ "$current_dir" == "${BASH_SOURCE[0]}" || "$current_dir" == "." ]] && current_dir="$PWD"
readonly current_dir

# Global OS detection (0 subshell forks via OSTYPE with uname fallback)
case "${OSTYPE:-$(uname -s)}" in
darwin* | Darwin* | *darwin*) HOST_OS="darwin" ;;
linux* | Linux* | *linux*) HOST_OS="linux" ;;
freebsd* | FreeBSD* | *freebsd*) HOST_OS="freebsd" ;;
*) HOST_OS="linux" ;;
esac
readonly HOST_OS

readonly VERSION="1.0.0"
readonly GH_BASE_URL="https://github.com/2kabhishek"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Projects/2KAbhishek}"
DRY_RUN=false
NON_INTERACTIVE=false
SELECTED_PROFILE=""
SELECTED_MODULES=()

# Colors and formatting (ANSI C-quoted for direct byte output)
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_GREEN=$'\033[32;1m'
C_BLUE=$'\033[34;1m'
C_CYAN=$'\033[36;1m'
C_YELLOW=$'\033[33;1m'
C_RED=$'\033[31;1m'
C_MAGENTA=$'\033[35;1m'
C_REV=$'\033[7m'

# ------------------------------------------------------------------------------
# Module Registry
# Format: REPO | DESCRIPTION | SCRIPT (optional, defaults to setup.sh)
# ------------------------------------------------------------------------------
# To add a new repo/module, simply add an entry to this array!
MODULE_DEFS=(
    "dots2k|Core shell, terminal, tmux, base packages & dotfiles|setup.sh -a"
    "nvim2k|Personalized Neovim IDE configuration & LSPs"
    "sway2k|Sway Wayland desktop environment, waybar & utils"
    "i32k|i3 X11 window manager, picom & utils"
    "rofi2k|Universal application launcher & themes"
    "qute2k|Keyboard-navigable browser configuration"
    "tdo|Note-taking and todo CLI management"
    "mkrepo|CLI GitHub repository generator"
    "repowatch|Interactive multi-repo monitor"
    "BWnB|Black, White & Blue themes (Kvantum, GTK)"
    "refind2k|rEFInd UEFI bootloader theme"
)

# Parse Module Registry into indexed arrays
TOTAL_MODULES=${#MODULE_DEFS[@]}
MOD_REPOS=()
MOD_SCRIPTS=()
MOD_DESCS=()

for ((i = 0; i < TOTAL_MODULES; i++)); do
    IFS='|' read -r mrepo mdesc mscript <<<"${MODULE_DEFS[i]}"
    mscript="${mscript:-setup.sh}"
    MOD_REPOS+=("$mrepo")
    MOD_DESCS+=("$mdesc")
    MOD_SCRIPTS+=("$mscript")
done

# ------------------------------------------------------------------------------
# Profile Registry
# Format: NAME | DESCRIPTION | MODULES
# ------------------------------------------------------------------------------
PROFILE_DEFS=(
    "minimal|Core shell, Neovim, dotfiles & CLI tools|dots2k nvim2k tdo mkrepo repowatch"
    "sway|Recommended: Sway, Waybar, apps & themes|dots2k nvim2k sway2k rofi2k qute2k tdo mkrepo repowatch BWnB"
    "i3|i3 window manager, Picom, apps & themes|dots2k nvim2k i32k rofi2k qute2k tdo mkrepo repowatch BWnB"
    "full|Everything part of other profiles|dots2k nvim2k sway2k i32k rofi2k qute2k tdo mkrepo repowatch BWnB"
)

TOTAL_PROFILES=${#PROFILE_DEFS[@]}
PROF_NAMES=()
PROF_DESCS=()
PROF_MODULES=()

for ((i = 0; i < TOTAL_PROFILES; i++)); do
    IFS='|' read -r pname pdesc pmods <<<"${PROFILE_DEFS[i]}"
    PROF_NAMES+=("$pname")
    PROF_DESCS+=("$pdesc")
    PROF_MODULES+=("$pmods")
done

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

log_info() { echo -e "${C_BLUE}==>${C_RESET} ${C_BOLD}$1${C_RESET}"; }
log_success() { echo -e "${C_GREEN}[✓]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[!]${C_RESET} $1"; }
log_err() { echo -e "${C_RED}[✗]${C_RESET} $1" >&2; }
log_step() { echo -e "\n${C_CYAN}:: ${C_BOLD}$1${C_RESET}"; }

cmd_sudo() {
    if [[ "$EUID" -ne 0 ]] && command -v sudo &>/dev/null; then
        sudo "$@"
    else
        "$@"
    fi
}

get_system_info() {
    case "$HOST_OS" in
    darwin) echo "mac" && return ;;
    freebsd) echo "freebsd" && return ;;
    esac

    if [[ -r /etc/os-release ]]; then
        local ID=""
        while IFS='=' read -r key val; do
            if [[ "$key" == "ID" ]]; then
                val="${val%\"}"
                val="${val#\"}"
                echo "$val"
                return
            fi
        done </etc/os-release
    fi

    if [[ -r /etc/lsb-release ]]; then
        local DISTRIB_ID=""
        while IFS='=' read -r key val; do
            if [[ "$key" == "DISTRIB_ID" ]]; then
                val="${val%\"}"
                val="${val#\"}"
                echo "$val"
                return
            fi
        done </etc/lsb-release
    fi

    echo "unknown"
}

banner() {
    cat <<"EOF"
  _       _ _     ____  _
 (_)     (_) |   |___ \| | __
  _ _ __  _| |_    __) | |/ /
 | | '_ \| | __|  / __/| ' <
 | | | | | | |_  |_____|_|\_\
 |_|_| |_|_|\__|  2kabhishek

EOF
    echo -e "${C_DIM}Bootstrapper for 2K Ecosystem v${VERSION}${C_RESET}\n"
}

ensure_bootstrap_prereqs() {
    local sys_kind
    sys_kind=$(get_system_info)

    if ! command -v git &>/dev/null || ! command -v curl &>/dev/null; then
        log_step "Installing bootstrap prerequisites (git, curl)..."
        case "$sys_kind" in
        arch | cachyos | archarm | manjaro | steamos | holo)
            if command -v pacman &>/dev/null; then
                cmd_sudo pacman -S --needed --noconfirm git curl base-devel
            fi
            ;;
        debian | ubuntu | pop | kali)
            if command -v apt-get &>/dev/null; then
                cmd_sudo apt-get update && cmd_sudo apt-get install -y git curl build-essential
            fi
            ;;
        fedora | fedora-asahi-remix)
            if command -v dnf &>/dev/null; then
                cmd_sudo dnf install -y git curl @development-tools
            fi
            ;;
        mac)
            if ! command -v brew &>/dev/null; then
                log_warn "Homebrew not found. Please install Xcode command line tools or Homebrew."
            fi
            ;;
        esac
    fi

    mkdir -p "$WORKSPACE_DIR"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
}

# ------------------------------------------------------------------------------
# Checkbox TUI (Pure Bash Multi-Select)
# ------------------------------------------------------------------------------

run_checkbox_ui() {
    local checked=()
    local cursor=0
    local i

    # Default: select all modules from sway profile
    local default_modules=()
    for ((i = 0; i < TOTAL_PROFILES; i++)); do
        if [[ "${PROF_NAMES[i]}" == "sway" ]]; then
            read -r -a default_modules <<<"${PROF_MODULES[i]}"
            break
        fi
    done

    for ((i = 0; i < TOTAL_MODULES; i++)); do
        if [[ " ${default_modules[*]} " =~ " ${MOD_REPOS[i]} " ]]; then
            checked+=(1)
        else
            checked+=(0)
        fi
    done

    # Terminal configuration & cleanup traps
    cleanup_tui() {
        tput cnorm 2>/dev/null || true
        stty echo 2>/dev/null || true
    }
    trap 'cleanup_tui; echo -e "\n${C_RED}Setup cancelled.${C_RESET}"; exit 1' INT TERM
    trap 'cleanup_tui' EXIT

    stty -echo -icanon 2>/dev/null || true
    tput civis 2>/dev/null || true

    clear_checkbox_view() {
        local lines_to_clear=$((TOTAL_MODULES + 3))
        for ((i = 0; i < lines_to_clear; i++)); do
            echo -en "\033[1A\033[2K"
        done
    }

    render_checkbox_view() {
        echo -e "${C_BOLD}Toggle modules to setup:${C_RESET}"
        for ((i = 0; i < TOTAL_MODULES; i++)); do
            local mark=" "
            if [[ ${checked[i]} -eq 1 ]]; then
                mark="${C_GREEN}✓${C_RESET}"
            fi

            local pointer="  "
            local line_style="${C_RESET}"
            if [[ $i -eq $cursor ]]; then
                pointer="${C_CYAN}➜ ${C_RESET}"
                line_style="${C_CYAN}${C_BOLD}"
            fi

            printf "%s[%s] %s%-10s%s %s\n" \
                "$pointer" "$mark" "$line_style" "${MOD_REPOS[i]}" "${C_RESET}${C_DIM}" "- ${MOD_DESCS[i]}${C_RESET}"
        done
        echo ""
        echo -e "${C_DIM}Controls: [↑/k] Up  [↓/j] Down  [Space] Toggle  [a] Toggle All  [Enter] Confirm  [q] Cancel${C_RESET}"
    }

    # Initial render
    render_checkbox_view

    while true; do
        local key=""
        IFS= read -rsn1 key 2>/dev/null || true

        if [[ "$key" == $'\x1b' ]]; then
            local rest=""
            read -rsn2 -t 0.05 rest 2>/dev/null || true
            key+="$rest"
        fi

        case "$key" in
        $'\x1b[A' | $'\x1bOA' | 'k' | 'K') # Up
            if [[ $cursor -gt 0 ]]; then
                cursor=$((cursor - 1))
            else
                cursor=$((TOTAL_MODULES - 1))
            fi
            ;;
        $'\x1b[B' | $'\x1bOB' | 'j' | 'J') # Down
            if [[ $cursor -lt $((TOTAL_MODULES - 1)) ]]; then
                cursor=$((cursor + 1))
            else
                cursor=0
            fi
            ;;
        ' ') # Space to toggle
            if [[ ${checked[cursor]} -eq 1 ]]; then
                checked[cursor]=0
            else
                checked[cursor]=1
            fi
            ;;
        'a' | 'A') # Toggle all
            local any_unchecked=0
            for ((i = 0; i < TOTAL_MODULES; i++)); do
                if [[ ${checked[i]} -eq 0 ]]; then
                    any_unchecked=1
                    break
                fi
            done
            for ((i = 0; i < TOTAL_MODULES; i++)); do
                checked[i]=$any_unchecked
            done
            ;;
        "" | $'\n' | $'\r') # Enter to submit
            break
            ;;
        $'\x1b' | 'q' | 'Q') # Escape or 'q' to Quit
            cleanup_tui
            echo -e "\n${C_RED}Setup cancelled.${C_RESET}"
            exit 0
            ;;
        *)
            continue
            ;;
        esac

        clear_checkbox_view
        render_checkbox_view
    done

    cleanup_tui
    trap - EXIT INT TERM
    echo ""

    SELECTED_MODULES=()
    for ((i = 0; i < TOTAL_MODULES; i++)); do
        if [[ ${checked[i]} -eq 1 ]]; then
            SELECTED_MODULES+=("${MOD_REPOS[i]}")
        fi
    done
}

# ------------------------------------------------------------------------------
# Interactive Profile Menu
# ------------------------------------------------------------------------------

show_profile_menu() {
    echo -e "${C_BOLD}Choose a setup profile or custom selection:${C_RESET}\n"
    for ((i = 0; i < TOTAL_PROFILES; i++)); do
        printf "  ${C_CYAN}(%d)${C_RESET} ${C_BOLD}%-10s${C_RESET} ${C_DIM}- %s${C_RESET}\n" \
            "$((i + 1))" "${PROF_NAMES[i]}" "${PROF_DESCS[i]}"
    done
    printf "  ${C_CYAN}(%d)${C_RESET} ${C_BOLD}%-10s${C_RESET} ${C_DIM}- %s${C_RESET}\n" \
        "$((TOTAL_PROFILES + 1))" "custom" "Interactive picker"
    echo -e "  ${C_RED}(q)${C_RESET} ${C_DIM}Exit${C_RESET}\n"

    local choice=""
    while [[ -z "$choice" ]]; do
        echo -en "${C_GREEN}Select an option [1-$((TOTAL_PROFILES + 1)), q]: ${C_RESET}"
        read -r choice
    done

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le "$TOTAL_PROFILES" ]]; then
        select_profile "${PROF_NAMES[$((choice - 1))]}"
    elif [[ "$choice" -eq $((TOTAL_PROFILES + 1)) ]]; then
        run_checkbox_ui
    elif [[ "$choice" =~ ^[qQ]$ ]]; then
        echo -e "${C_RED}Exiting.${C_RESET}"
        exit 0
    else
        log_err "Invalid selection!"
        exit 1
    fi
}

select_profile() {
    local profile="$1"
    SELECTED_MODULES=()
    for ((i = 0; i < TOTAL_PROFILES; i++)); do
        if [[ "${PROF_NAMES[i]}" == "$profile" ]]; then
            read -r -a SELECTED_MODULES <<<"${PROF_MODULES[i]}"
            return 0
        fi
    done

    log_err "Unknown profile: '$profile'. Available: ${PROF_NAMES[*]}"
    exit 1
}

# ------------------------------------------------------------------------------
# Git Sync and Execution Engine
# ------------------------------------------------------------------------------

sync_repo() {
    local repo="$1"
    local dest="$WORKSPACE_DIR/$repo"
    local url="$GH_BASE_URL/$repo.git"

    if [[ ! -d "$dest" ]]; then
        log_info "Cloning $repo into $dest..."
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] git clone $url $dest"
        else
            git clone "$url" "$dest"
        fi
    else
        log_info "Updating $repo in $dest..."
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] git -C $dest pull --ff-only"
        else
            if git -C "$dest" rev-parse --is-inside-work-tree &>/dev/null; then
                if git -C "$dest" diff-index --quiet HEAD -- 2>/dev/null; then
                    git -C "$dest" pull --ff-only 2>/dev/null || log_warn "$repo has local/diverged branch; skipping pull"
                else
                    log_warn "$repo has local modifications; skipping pull to preserve changes."
                fi
            fi
        fi
    fi
}

run_module_setup() {
    local repo="$1"
    local idx=-1

    for ((i = 0; i < TOTAL_MODULES; i++)); do
        if [[ "${MOD_REPOS[i],,}" == "${repo,,}" ]]; then
            idx=$i
            break
        fi
    done

    if [[ $idx -eq -1 ]]; then
        log_err "Unknown module: '$repo'"
        return 1
    fi

    local repo="${MOD_REPOS[idx]}"
    local script_cmd="${MOD_SCRIPTS[idx]}"
    local script_file="${script_cmd%% *}"
    local dest="$WORKSPACE_DIR/$repo"

    log_step "Running setup for $repo..."

    sync_repo "$repo"

    if [[ "$DRY_RUN" == true ]]; then
        if [[ -n "$script_file" && (-f "$dest/$script_file" || ! -d "$dest") ]]; then
            echo "[DRY-RUN] cd $dest && ./$script_cmd"
        else
            echo "[DRY-RUN] $repo repository synchronized."
        fi
        return 0
    fi

    if [[ -n "$script_file" && -f "$dest/$script_file" ]]; then
        chmod +x "$dest/$script_file" 2>/dev/null || true
        (cd "$dest" && ./$script_cmd)
        log_success "$repo setup completed!"
    else
        log_success "$repo repository synchronized!"
    fi
}

execute_pipeline() {
    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        log_warn "No modules selected. Exiting."
        exit 0
    fi

    echo -e "\n${C_BOLD}Selected Modules (${#SELECTED_MODULES[@]}):${C_RESET}"
    for m in "${SELECTED_MODULES[@]}"; do
        echo -e "  ${C_CYAN}•${C_RESET} $m"
    done
    echo ""

    if [[ "$NON_INTERACTIVE" == false ]]; then
        echo -en "${C_GREEN}Proceed with setup? [Y/n]: ${C_RESET}"
        read -r confirm
        if [[ "$confirm" =~ ^[nN] ]]; then
            echo -e "${C_RED}Aborted by user.${C_RESET}"
            exit 0
        fi
    fi

    ensure_bootstrap_prereqs

    # Ensure dots2k is executed first if selected
    if [[ " ${SELECTED_MODULES[*]} " =~ " dots2k " ]]; then
        run_module_setup "dots2k"
    fi

    # Execute remaining modules
    for m in "${SELECTED_MODULES[@]}"; do
        if [[ "$m" != "dots2k" ]]; then
            run_module_setup "$m"
        fi
    done

    # Ensure init2k itself is cloned in workspace and linked to PATH
    sync_repo "init2k"
    local self_path="$WORKSPACE_DIR/init2k/init2k.sh"
    if [[ ! -f "$self_path" && -f "$current_dir/init2k.sh" ]]; then
        self_path="$current_dir/init2k.sh"
    fi

    if [[ -f "$self_path" ]]; then
        chmod +x "$self_path" 2>/dev/null || true
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] ln -sfnv $self_path $HOME/.local/bin/init2k"
        else
            mkdir -p "$HOME/.local/bin"
            ln -sfnv "$self_path" "$HOME/.local/bin/init2k"
        fi
    fi

    echo -e "\n${C_GREEN}${C_BOLD}======================================================${C_RESET}"
    echo -e "${C_GREEN}${C_BOLD}  🎉 init2k: System setup completed successfully!     ${C_RESET}"
    echo -e "${C_GREEN}${C_BOLD}======================================================${C_RESET}"
    echo -e "${C_DIM}Run 'init2k' anytime to re-sync or modify your setup.${C_RESET}\n"
}

# ------------------------------------------------------------------------------
# CLI Arguments & Entrypoint
# ------------------------------------------------------------------------------

usage() {
    cat <<EOF
init2k - Bootstrapper for 2K Ecosystem v${VERSION}

Usage:
  init2k [OPTIONS]

Options:
  -p, --profile <name>     Select a preset profile:
                           (minimal | sway | i3 | full)
  -m, --module <list>      Comma-separated list of modules to setup
                           e.g. -m dots2k,nvim2k,tdo
  -a, --all                Setup all modules (equivalent to --profile full)
  -d, --dry-run            Simulate operations without making changes
  -y, --yes                Non-interactive mode (auto-confirm)
  -w, --workspace <dir>    Custom workspace directory (default: ~/Projects/2KAbhishek)
  -l, --list               List available modules and profiles
  -h, --help               Show this help message

Interactive Mode:
  Run without options to launch the profile picker & checkbox UI.
EOF
}

list_available() {
    echo -e "${C_BOLD}Available Profiles:${C_RESET}"
    for ((i = 0; i < TOTAL_PROFILES; i++)); do
        printf "  ${C_CYAN}%-10s${C_RESET} : %s\n" "${PROF_NAMES[i]}" "${PROF_DESCS[i]}"
    done
    echo ""
    echo -e "${C_BOLD}Available Modules (${TOTAL_MODULES}):${C_RESET}"
    for ((i = 0; i < TOTAL_MODULES; i++)); do
        printf "  ${C_CYAN}%-12s${C_RESET} %s\n" \
            "${MOD_REPOS[i]}" "- ${MOD_DESCS[i]}"
    done
}

main() {
    banner

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -p | --profile)
            SELECTED_PROFILE="$2"
            shift 2
            ;;
        -m | --module | --modules)
            IFS=',' read -r -a raw_modules <<<"$2"
            SELECTED_MODULES=()
            for raw_m in "${raw_modules[@]}"; do
                # Trim whitespace
                raw_m="${raw_m// /}"
                [[ -z "$raw_m" ]] && continue
                local found=0
                for ((i = 0; i < TOTAL_MODULES; i++)); do
                    if [[ "${MOD_REPOS[i],,}" == "${raw_m,,}" ]]; then
                        SELECTED_MODULES+=("${MOD_REPOS[i]}")
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 0 ]]; then
                    log_err "Unknown module '$raw_m'. Run 'init2k --list' to see valid modules."
                    exit 1
                fi
            done
            shift 2
            ;;
        -a | --all)
            SELECTED_PROFILE="full"
            shift
            ;;
        -d | --dry-run)
            DRY_RUN=true
            shift
            ;;
        -y | --yes)
            NON_INTERACTIVE=true
            shift
            ;;
        -w | --workspace)
            WORKSPACE_DIR="${2/#\~/$HOME}"
            shift 2
            ;;
        -l | --list)
            list_available
            exit 0
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            log_err "Unknown option: $1"
            usage >&2
            exit 1
            ;;
        esac
    done

    if [[ -n "$SELECTED_PROFILE" ]]; then
        select_profile "$SELECTED_PROFILE"
    elif [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        show_profile_menu
    fi

    execute_pipeline
}

main "$@"

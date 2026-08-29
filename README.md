<div align = "center">

<h1><a href="https://github.com/2kabhishek/init2k">init2k</a></h1>

<a href="https://github.com/2KAbhishek/init2k/blob/main/LICENSE">
<img alt="License" src="https://img.shields.io/github/license/2kabhishek/init2k?style=flat&color=eee&label="> </a>

<a href="https://github.com/2KAbhishek/init2k/graphs/contributors">
<img alt="People" src="https://img.shields.io/github/contributors/2kabhishek/init2k?style=flat&color=ffaaf2&label=People"> </a>

<a href="https://github.com/2KAbhishek/init2k/stargazers">
<img alt="Stars" src="https://img.shields.io/github/stars/2kabhishek/init2k?style=flat&color=98c379&label=Stars"></a>

<a href="https://github.com/2KAbhishek/init2k/network/members">
<img alt="Forks" src="https://img.shields.io/github/forks/2kabhishek/init2k?style=flat&color=66a8e0&label=Forks"> </a>

<a href="https://github.com/2KAbhishek/init2k/watchers">
<img alt="Watches" src="https://img.shields.io/github/watchers/2kabhishek/init2k?style=flat&color=f5d08b&label=Watches"> </a>

<a href="https://github.com/2KAbhishek/init2k/pulse">
<img alt="Last Updated" src="https://img.shields.io/github/last-commit/2kabhishek/init2k?style=flat&color=e06c75&label="> </a>

<h3>Bootstrapper for 2K Ecosystem 🐚⚡</h3>

<figure>
  <img src="images/screenshot.png" alt="init2k in action">
  <br/>
  <figcaption>init2k in action</figcaption>
</figure>

</div>

`init2k` is an idempotent system installer and workspace orchestrator. It bootstraps a fresh Arch Linux (or multi-distro) system into a fully configured development and desktop environment, setting up all tools, dotfiles, window managers, editors, and CLI utilities.

---

## ✨ Features

- 🎯 **Idempotent & Safe**: Run it on a fresh machine or repeatedly on an existing setup — it updates and links without clobbering uncommitted work or breaking existing configs.
- 🔘 **Interactive Checkbox UI**: Pure bash multi-select TUI (arrow keys + spacebar) to pick exactly the modules you want.
- ⚡ **Preset Profiles**: Quick presets for **Minimal CLI**, **Sway Wayland Desktop**, **i3 X11 Desktop**, or **Full Suite**.
- 🧩 **Modular Architecture**: Delegates to standalone `setup.sh` scripts in each repository ([`dots2k`](https://github.com/2kabhishek/dots2k), [`nvim2k`](https://github.com/2kabhishek/nvim2k), [`sway2k`](https://github.com/2kabhishek/sway2k), [`tdo`](https://github.com/2kabhishek/tdo), etc.).
- 🌐 **Arch-First, Multi-Distro Ready**: Prioritizes Arch Linux (`pacman`, `yay`) while supporting hooks for Debian/Ubuntu, Fedora, and macOS.
- 🔌 **Extensible Registry**: Adding a new repository or tool takes just one line in the module table.

---

## ⚡ Quickstart

### 1. Direct One-Liner (Recommended)

Run directly on a fresh install without manually cloning:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/2kabhishek/init2k/main/init2k.sh)
```

*(Or via pipe: `curl -fsSL https://raw.githubusercontent.com/2kabhishek/init2k/main/init2k.sh | bash`)*

> [!NOTE]
> On a bare minimal Arch install, make sure `curl` and `git` are installed: `sudo pacman -S --needed curl git`

### 2. Manual Clone & Run

```bash
git clone https://github.com/2kabhishek/init2k ~/Projects/2KAbhishek/init2k
cd ~/Projects/2KAbhishek/init2k
./init2k.sh
```

### 3. Post-Install CLI

`init2k` automatically symlinks itself to `~/.local/bin/init2k`. Once your shell is reloaded, you can run `init2k` anytime from anywhere:

```bash
init2k
```

---

## 🚀 Usage & Options

```
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
```

### Examples

```bash
# Interactive menu (Profile selector + Checkbox TUI)
init2k

# Install Sway Wayland desktop profile non-interactively
init2k -p sway -y

# Install only Neovim and base dotfiles
init2k -m dots2k,nvim2k

# Dry-run to see what commands would be executed
init2k --all --dry-run
```

---

## 📦 Preset Profiles

| Profile                | Target Repositories                                                       | Included Tools                                                             |
| :--------------------- | :------------------------------------------------------------------------ | :------------------------------------------------------------------------- |
| **`minimal`**          | `dots2k`, `nvim2k`, `tdo`, `mkrepo`                                       | Base shell (zsh/bash/fish), tmux, Neovim, notes CLI, repo creator          |
| **`sway`** _(Default)_ | `dots2k`, `nvim2k`, `sway2k`, `rofi2k`, `qute2k`, `tdo`, `mkrepo`, `BWnB` | Wayland desktop with Sway, Waybar, Foot, Swappy, Rofi, Qutebrowser, themes |
| **`i3`**               | `dots2k`, `nvim2k`, `i32k`, `rofi2k`, `qute2k`, `tdo`, `mkrepo`, `BWnB`   | X11 desktop with i3-wm, Picom, Rofi, Qutebrowser, themes                   |
| **`full`**             | All registered repositories                                               | Everything above + `refind2k`                                              |

---

## 🛠️ Registered Modules

| Module ID  | Repository                                         | Purpose                                             | Setup Script    |
| :--------- | :------------------------------------------------- | :-------------------------------------------------- | :-------------- |
| `dots2k`   | [dots2k](https://github.com/2kabhishek/dots2k)     | Core shell, terminal, tmux, packages, yay, dotfiles | `./setup.sh -a` |
| `nvim2k`   | [nvim2k](https://github.com/2kabhishek/nvim2k)     | Neovim IDE configuration, LSPs, Treesitter          | `./setup.sh`    |
| `sway2k`   | [sway2k](https://github.com/2kabhishek/sway2k)     | Sway Wayland desktop, waybar, swaync, foot          | `./setup.sh`    |
| `i32k`     | [i32k](https://github.com/2kabhishek/i32k)         | i3 X11 window manager, picom, shortcuts             | `./setup.sh`    |
| `rofi2k`   | [rofi2k](https://github.com/2kabhishek/rofi2k)     | Universal application launcher & emoji picker       | `./setup.sh`    |
| `qute2k`   | [qute2k](https://github.com/2kabhishek/qute2k)     | Keyboard-navigable browser configs                  | `./setup.sh`    |
| `tdo`      | [tdo](https://github.com/2kabhishek/tdo)           | Note-taking and todo CLI management                 | `./setup.sh`    |
| `mkrepo`   | [mkrepo](https://github.com/2kabhishek/mkrepo)     | GitHub repository generator CLI                     | `./setup.sh`    |
| `bwnb`     | [BWnB](https://github.com/2kabhishek/BWnB)         | Black, White & Blue themes (Kvantum, GTK)           | `./setup.sh`    |
| `refind2k` | [refind2k](https://github.com/2kabhishek/refind2k) | rEFInd UEFI bootloader theme                        | `./setup.sh`    |

---

## ➕ Adding a New Module

Adding a new tool or repository to `init2k` is as simple as adding an entry to the `MODULE_DEFS` array inside `init2k.sh`:

```bash
# Format: "ID | REPO_NAME | SCRIPT | PROFILES | DESCRIPTION"
MODULE_DEFS+=(
    "mytool|mytool|setup.sh|minimal sway full|My awesome new CLI tool"
)
```

The script will automatically:

1. Add it to the interactive checkbox UI.
2. Include it in the designated profiles.
3. Clone or pull it into `~/Projects/2KAbhishek/<repo_name>`.
4. Execute its `./setup.sh` idempotently.

---

## 🧑‍💻 Ecosystem & Tooling

- [dots2k](https://github.com/2kabhishek/dots2k) — Base Environment & Dotfiles
- [nvim2k](https://github.com/2kabhishek/nvim2k) — Personalized Editor
- [sway2k](https://github.com/2kabhishek/sway2k) — Wayland Desktop Environment
- [i32k](https://github.com/2kabhishek/i32k) — X11 Desktop Environment
- [qute2k](https://github.com/2kabhishek/qute2k) — Vim-Style Browser
- [rofi2k](https://github.com/2kabhishek/rofi2k) — Universal App Launcher
- [tdo](https://github.com/2kabhishek/tdo) — Note Taking & Todo CLI
- [mkrepo](https://github.com/2kabhishek/mkrepo) — Repository Spin-up CLI
- [BWnB](https://github.com/2kabhishek/BWnB) — Theme Suite
- [refind2k](https://github.com/2kabhishek/refind2k) — Bootloader Theme

<hr>

<div align="center">

<strong>⭐ Star this repo if you found it useful ⭐</strong><br>

<a href="https://github.com/2KAbhishek/init2k">Source</a>
| <a href="https://2kabhishek.github.io/blog" target="_blank">Blog </a>
| <a href="https://twitter.com/2kabhishek" target="_blank">Twitter </a>
| <a href="https://linkedin.com/in/2kabhishek" target="_blank">LinkedIn </a>
| <a href="https://2kabhishek.github.io/links" target="_blank">More Links </a>
| <a href="https://2kabhishek.github.io/projects" target="_blank">Other Projects </a>

</div>

<div align="center">

<img src="assets/badasskali-banner.svg" alt="BadAssKali — terminal bootstrap for Kali, Debian, and Ubuntu" width="100%" />

[![Platform](https://img.shields.io/badge/platform-Kali%20%7C%20Debian%20%7C%20Ubuntu-8b5cf6?style=for-the-badge&logo=linux&logoColor=white)](#compatibility)
[![Shell](https://img.shields.io/badge/shell-Zsh-4e9a06?style=for-the-badge&logo=zsh&logoColor=white)](#whats-inside)

</div>

## ⚡ Why BadAssKali?

BadAssKali turns a fresh supported Linux installation into a polished terminal workspace for development, system administration, and authorized security testing. It handles the boring setup so you can get straight to work.

<table>
  <tr>
    <td width="50%">
      <h3>🖥️ A terminal that feels great</h3>
      Ghostty, Zsh, Powerlevel10k, JetBrains Mono Nerd Font, Atuin, tmux, and a Catppuccin-inspired visual setup.
    </td>
    <td width="50%">
      <h3>🚀 Tools that stay out of your way</h3>
      Yazi previews, zoxide jumping, fzf search, eza icons, bat output, direnv, HTTPie, tldr, and more.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🧱 Reliable installations</h3>
      Ghostty builds with its required Zig release, Yazi uses official packages, and TheFuck runs outside your system Python.
    </td>
    <td width="50%">
      <h3>🛡️ Ready for authorized work</h3>
      Includes common discovery, web, directory-service, and password-audit utilities. Only use tools where you have explicit permission.
    </td>
  </tr>
</table>

## ✨ What's Inside

| Area | Included |
| --- | --- |
| **Terminal** | Ghostty, Zsh, Oh My Zsh, Powerlevel10k, JetBrainsMono Nerd Font |
| **Shell power** | Atuin, TheFuck, zoxide, fzf, fzf-tab, autosuggestions, syntax highlighting |
| **File & system** | Yazi with media/document/archive previews, eza, bat, fastfetch, btop, ncdu, tmux |
| **Developer flow** | Rust, Cargo, git-delta, bottom, dust, hyperfine, procs, direnv, HTTPie, ShellCheck, shfmt |
| **Authorized security** | Nmap, NetExec, Impacket, FFUF, Feroxbuster, Gobuster, RustScan, Certipy, BloodHound helpers |

## 🧩 Compatibility

| Distribution | CPU architectures |
| --- | --- |
| Kali Linux Rolling | `x86_64`, `aarch64` |
| Debian 13+ | `x86_64`, `aarch64` |
| Ubuntu 24.04+ | `x86_64`, `aarch64` |

> [!IMPORTANT]
> Run the installer as your normal user—not as `root`. It will request `sudo` only for system packages and Ghostty installation.

## 🚀 Install

```bash
git clone https://github.com/Madhav-Sai/BadAssKali.git
cd BadAssKali
chmod +x install.sh
./install.sh
```

<details>
<summary><b>What the installer does</b></summary>
<br />

1. Checks your distribution and architecture.
2. Installs base packages and a polished Zsh environment.
3. Builds the latest stable Ghostty release with the matching Zig version.
4. Installs Atuin, TheFuck, Yazi, tmux, Rust utilities, and optional authorized-security tooling.
5. Writes Ghostty, Yazi, tmux, aliases, and shell configuration files.

</details>

## 🏁 After Installation

```bash
source ~/.zshrc
p10k configure
atuin import auto
./verify.sh
```

Choose **Lean**, **Unicode**, and **Two Line** in the Powerlevel10k wizard for the intended look.

## 🎮 Quick Commands

| Command | What it does |
| --- | --- |
| `y` | Open Yazi and move the current shell to its selected directory |
| `z <name>` | Jump to a frequently used directory with zoxide |
| `Ctrl + R` | Search shell history with Atuin |
| `fuck` | Correct the previous command with TheFuck |
| `ll` / `lt` | Icon-rich directory listing / tree |
| `web` | Start a Python web server on port 8000 |
| `serve` | Serve the current directory using HTTPie |
| `weather` | Fetch a compact terminal weather report |
| `tnew <name>` | Create a named tmux session |
| `htb` / `notes` | Jump to your workspace directories |

## 🛠️ Troubleshooting

<details>
<summary><b>Ghostty fails to build</b></summary>
<br />

Make sure you have an internet connection and re-run only the module:

```bash
bash modules/07-ghostty.sh
```

The installer selects the latest stable Ghostty tag and reads its required Zig version automatically.

</details>

<details>
<summary><b>Yazi is missing previews</b></summary>
<br />

Restart your terminal after installation. The installer adds helpers for images, PDFs, archives, media, and text previews. On Wayland, ensure your terminal supports image rendering for inline image previews.

</details>

<details>
<summary><b>TheFuck is not found after installation</b></summary>
<br />

Reload your shell so `~/.local/bin` is on your `PATH`:

```bash
source ~/.zshrc
```

TheFuck uses an isolated Python 3.11 managed by `uv`, avoiding conflicts with newer system Python releases.

</details>

## 🔍 Verify

```bash
./verify.sh
```

The verifier checks core terminal, productivity, and authorized-security commands and reports anything missing.

## 🧹 Uninstall

```bash
./uninstall.sh
```

> [!CAUTION]
> The uninstaller removes generated Zsh, Ghostty, tmux, Atuin, Rust, and related configuration directories. Review `uninstall.sh` before running it if you have customized your setup.

## 🤝 Contributing

Issues and focused pull requests are welcome. Keep additions modular, idempotent, and compatible with Kali, Debian, and Ubuntu.

<div align="center">
  <br />
  <sub>Build smart. Stay authorized.</sub>
</div>

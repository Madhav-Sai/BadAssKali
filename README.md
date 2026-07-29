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
      Ghostty uses a distro package when available or verifies and builds official source with the exact required Zig release.
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
| Arch and derivatives | `x86_64`, `aarch64` — extended support |
| Fedora and derivatives | `x86_64`, `aarch64` — extended support |
| openSUSE | `x86_64`, `aarch64` — extended support |

> [!IMPORTANT]
> Run the installer as your normal user—not as `root`. It will request `sudo` only for system packages and Ghostty installation.

## 🚀 Install

```bash
git clone https://github.com/Madhav-Sai/BadAssKali.git
cd BadAssKali
chmod +x install.sh
./install.sh
```

### Pick your setup

```bash
# Shell, prompt, fonts, aliases, and configuration
./install.sh --profile core

# Full terminal workflow without the larger security-tool module
./install.sh --profile terminal

# Every module (the default)
./install.sh --profile full

# Pentesting workflow, recon automation, and engagement workspace
./install.sh --profile pentest
```

### Mix and match modules

```bash
./install.sh --list-modules
./install.sh --only 07                         # Ghostty only
./install.sh --skip 09,15                     # Skip TheFuck and security tools
./install.sh --profile terminal --no-ghostty  # Use your existing terminal
./install.sh --profile core --dry-run          # Preview without changing anything
./install.sh --profile terminal --yes          # Unattended confirmation
./install.sh --interactive                     # Guided selector
./install.sh --addons developer,containers     # Optional bundles
```

Run `./install.sh --help` for all module, execution, and Ghostty controls.

### Download and offline package cache

```bash
# Populate the package cache without configuring the downloaded packages
./install.sh --profile terminal --addons developer --download-only

# Reuse package-manager caches without refreshing repositories
./install.sh --profile terminal --addons developer --offline

# Choose a portable cache directory
./install.sh --profile core --download-only --cache-dir /mnt/usb/badasskali-cache
```

Remote, source-built tools may still require their own cached artifacts. The
offline controls apply to distribution packages and add-on bundles and fail if
required cached packages are absent.

### Ghostty choices

```bash
# Automatically prefer an available distro package, then build official source
./install.sh --only 07 --ghostty-method auto

# Verified official source, installed for only your user in ~/.local
./install.sh --only 07 --ghostty-method source --ghostty-prefix user

# Pin a release or reinstall an existing Ghostty installation
./install.sh --only 07 --ghostty-version 1.3.1 --force-ghostty
```

Source installation verifies Ghostty's official Minisign signature when
`minisign` is available, checks Zig against its published SHA-256 value, and
uses the build flags required when a distribution lacks `gtk4-layer-shell`.

Additional Ghostty controls include stable/tip channels, build-job limits,
Snap, community AppImage installation with explicit trust acceptance, retained
build directories, reinstalling, and selective uninstalling:

```bash
./install.sh --only 07 --ghostty-channel tip --ghostty-build-jobs 4
./install.sh --only 07 --ghostty-method snap
./install.sh --only 07 --ghostty-method appimage --accept-community-ghostty
bash modules/07-ghostty.sh --uninstall
```

<details>
<summary><b>What the installer does</b></summary>
<br />

1. Checks your distribution and architecture.
2. Installs base packages and a polished Zsh environment.
3. Installs Ghostty from an available distro package or builds a verified stable source release with the matching Zig version.
4. Installs Atuin, TheFuck, Yazi, tmux, Rust utilities, and optional authorized-security tooling.
5. Adds ProjectDiscovery, AutoRecon, scope-aware workflows, and an engagement workspace in the pentest/full profiles.
6. Writes Ghostty, Yazi, tmux, aliases, and shell configuration files.

</details>

## 🏁 After Installation

```bash
source ~/.zshrc
p10k configure
atuin import auto
./verify.sh --profile terminal
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
| `serve [port]` | Serve the current directory on port 8000 or a chosen port |
| `weather` | Fetch a compact terminal weather report |
| `tnew <name>` | Create a named tmux session |
| `htb` / `notes` | Jump to your workspace directories |
| `mkcd <dir>` | Create a directory and enter it |
| `backup <path>` | Make a timestamped backup without replacing the source |
| `extract <archive>` | Extract tar, zip, 7z, rar, gzip, bzip2, or xz archives |
| `gs` / `gl` / `gds` | Git status, graph log, and staged diff |
| `aptu` / `aptup` | Refresh packages / refresh and upgrade |
| `ips` / `ports` / `myip` | Inspect local addresses, listeners, and public IP details |
| `nmap-fast <target>` | Fast common-port scan for an authorized target |

The managed alias pack includes more than 130 navigation, file, package,
network, development, Git, tmux, container, and authorized-security shortcuts.
It is installed at `~/.config/badasskali/aliases.zsh`; your existing
`~/.aliases` content is preserved.

## 🧠 Management CLI

The installer adds `~/.local/bin/badasskali`, a command center for ongoing
maintenance:

```bash
badasskali status
badasskali status --json
badasskali doctor
badasskali logs
badasskali repair ghostty --yes
badasskali backup
badasskali snapshots
badasskali rollback --yes
badasskali update
```

Configuration writes create restorable snapshots. Zsh, Ghostty and tmux use
managed blocks so existing user content survives installation and upgrades.
Use `--config-mode replace` only when you explicitly want a clean generated
configuration.

## 🧩 Optional Add-ons

More than 30 bundles extend BadAssKali without making the default installation
unreasonably large:

```bash
badasskali addons list
badasskali addons info mobile-lab
badasskali addons install terminal-plus,desktop,developer
badasskali addons install forensics,web-audit,defensive
badasskali addons download virtualization
badasskali addons offline-install virtualization
badasskali addons remove desktop
```

Major areas include productivity, development, containers, virtualization,
network laboratories, API and Android testing, documentation, defensive host
tooling, forensics, wireless, passwords, reverse engineering, OSINT, web,
databases, exploitation labs, fuzzing, radio, Bluetooth, RFID and VoIP. On Kali,
specialized bundles prefer the corresponding official Kali metapackage.
Parrot OS gets its own official `parrot-tools-*` bundles instead of attempting
to install Kali metapackages or adding Kali repositories.

## 🧭 Pentesting Workflow

The pentest/full profile adds ProjectDiscovery's maintained toolchain,
AutoRecon, and two local workflow commands:

```bash
./install.sh --profile pentest

# Create a structured workspace after confirming written authorization
bak-engage new acme-external --scope example.com --authorized
bak-engage status
bak-engage authorize --i-have-written-authorization
bak-engage note "Kickoff completed; testing window opened"
bak-engage finding new high "Administrative endpoint exposed"

# Scope-checked and conservatively rate-limited workflows
bak-recon discover example.com --i-have-authorization
bak-recon web https://example.com --i-have-authorization
bak-recon full example.com --i-have-authorization
```

Every engagement gets separate scope, notes, evidence, scans, findings,
report, and log directories. The report skeleton follows an executive summary,
scope and limitations, methodology, findings, remediation, and appendices
structure. Automated recon refuses to start without both a stored authorization
marker and an exact or subdomain scope match.

## 🎨 Themes and Alias Packs

```bash
badasskali theme list
badasskali theme apply tokyo-night
badasskali aliases list
badasskali aliases enable web osint android defensive
badasskali aliases disable web
badasskali aliases search kubectl
source ~/.aliases
```

Included coordinated themes are Catppuccin, Dracula, Tokyo Night, Gruvbox,
Nord, Kali Red and Minimal Monochrome. Optional alias packs cover Kubernetes,
cloud, forensics, wireless, Active Directory, web, productivity, Android, API,
defensive operations and OSINT.

## 🛠️ Troubleshooting

<details>
<summary><b>Installation fails on Parrot OS</b></summary>
<br />

Run the new platform diagnostics and inspect the exact module log:

```bash
badasskali doctor
badasskali logs
sudo parrot-upgrade
./install.sh --profile pentest --yes
```

BadAssKali now detects Parrot as a first-class security distribution, validates
that `parrot-core` is visible, never adds Kali repositories, and reports broken
APT/dpkg state. Base font dependencies and non-fatal login-shell changes were
also fixed for minimal Parrot installations.

</details>

<details>
<summary><b>Ghostty fails to build</b></summary>
<br />

Make sure you have an internet connection and re-run only the module:

```bash
bash modules/07-ghostty.sh --method source --prefix user
```

The installer selects a stable signed source archive and reads its required Zig
version automatically. Add `--keep-build` to preserve the temporary source tree
for diagnosing a compiler error.

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
./verify.sh --profile terminal
./verify.sh --profile pentest
./verify.sh --profile full --json
```

The verifier checks core terminal, productivity, and authorized-security commands and reports anything missing.

## 🧹 Uninstall

```bash
./uninstall.sh
```

Selective and recoverable removal is also supported:

```bash
./uninstall.sh --only ghostty
./uninstall.sh --profile core --dry-run
./uninstall.sh --only aliases,configs --restore-backups
```

> [!CAUTION]
> Destructive removal still requires confirmation. Use `--dry-run` first and
> `--restore-backups` when you want the most recent managed snapshot restored.

## ✅ Automated Tests

The `tests/` suite covers profiles, option validation, idempotent aliases,
configuration merging, themes, snapshots, rollback and uninstall dry-runs.
GitHub Actions runs Bash syntax, ShellCheck, shfmt, Zsh parsing and Bats tests in
Ubuntu and Debian containers.

## 🤝 Contributing

Issues and focused pull requests are welcome. Keep additions modular, idempotent, and compatible with Kali, Parrot, Debian, and Ubuntu.

<div align="center">
  <br />
  <sub>Build smart. Stay authorized.</sub>
</div>

# Kali Beast Bootstrap

A production-focused terminal and pentesting workstation bootstrap for:

* Kali Linux Rolling
* Debian 13+
* Ubuntu 24.04+

Supports:

* AMD64 (x86_64)
* ARM64 (aarch64)

---

## Features

### Terminal Stack

* Ghostty
* Zsh
* Oh My Zsh
* Powerlevel10k
* JetBrainsMono Nerd Font
* zsh-autosuggestions
* zsh-syntax-highlighting
* zsh-completions
* fzf-tab

### Productivity

* Atuin
* TheFuck
* zoxide
* fzf
* eza
* bat
* fastfetch
* tmux
* ranger
* nnn
* yazi

### Rust Ecosystem

* rustup
* cargo
* rustfmt
* clippy

Optional cargo tools:

* git-delta
* bottom
* dust
* hyperfine
* procs

### Security Tooling

* NetExec
* BloodHound
* Certipy
* RustScan
* Kerbrute
* Feroxbuster
* Gobuster
* FFUF
* Impacket
* Nmap helpers
* AD helpers

### Quality of Life

* Large shell history
* Smart completion
* Better defaults
* Pentest aliases
* Reverse shell generators
* HTB workflow helpers

---

## Repository Layout

```text
kali-beast/
├── install.sh
├── uninstall.sh
├── verify.sh
├── modules/
│   ├── 00-os-detect.sh
│   ├── 01-packages.sh
│   ├── 02-zsh.sh
│   ├── 03-ohmyzsh.sh
│   ├── 04-p10k.sh
│   ├── 05-fonts.sh
│   ├── 06-rust.sh
│   ├── 07-ghostty.sh
│   ├── 08-atuin.sh
│   ├── 09-thefuck.sh
│   ├── 10-yazi.sh
│   ├── 11-tmux.sh
│   ├── 12-pentest.sh
│   ├── 13-configs.sh
│   ├── 14-cargo-tools.sh
│   └── 15-security-tools.sh
├── configs/
│   ├── .zshrc
│   ├── .tmux.conf
│   ├── aliases.zsh
│   └── ghostty/
│       └── config
└── docs/
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/kali-beast.git

cd kali-beast
```

Make installer executable:

```bash
chmod +x install.sh
```

Run:

```bash
./install.sh
```

---

## Post Installation

Reload shell:

```bash
source ~/.zshrc
```

Configure Powerlevel10k:

```bash
p10k configure
```

Import history into Atuin:

```bash
atuin import auto
```

Verify installation:

```bash
./verify.sh
```

---

## Recommended Powerlevel10k Setup

Prompt Style:

```text
Lean
```

Character Set:

```text
Unicode
```

Prompt Layout:

```text
Two Line
```

Transient Prompt:

```text
Yes
```

---

## Verification

Check installed tools:

```bash
./verify.sh
```

Expected output:

```text
[OK] zsh
[OK] cargo
[OK] ghostty
[OK] atuin
[OK] thefuck
[OK] tmux
[OK] yazi
...
```

---

## Common Aliases

HTB:

```bash
htb
```

Listener:

```bash
listen 4444
```

Web Server:

```bash
web
```

IPs:

```bash
ips
```

Ports:

```bash
ports
```

Reverse Shell:

```bash
revbash 10.10.14.5 4444
```

---

## Supported Architectures

| Architecture | Supported |
| ------------ | --------- |
| AMD64        | Yes       |
| ARM64        | Yes       |

---

## Supported Distributions

| Distribution  | Supported |
| ------------- | --------- |
| Kali Rolling  | Yes       |
| Debian 13+    | Yes       |
| Ubuntu 24.04+ | Yes       |

---

## Disclaimer

This project modifies:

* Shell configuration
* Terminal configuration
* User PATH
* Rust environment
* Font installation

Always review scripts before running them.

Use at your own risk.

---

## License

MIT License

#!/usr/bin/env bash
# argus-bootstrap.sh — idempotent setup for Argus (Mac Studio: Hermes + second brain)
#
# Two phases, run as two different macOS users:
#   ./argus-bootstrap.sh admin   # as your admin account: system settings, Homebrew, Tailscale, global tools
#   ./argus-bootstrap.sh agent   # as the standard `hermes` user: Claude Code, Hermes runtime
#
# Safe to re-run. Preview without changing anything:  DRY_RUN=1 ./argus-bootstrap.sh admin
#
# Naming: host = Argus, agent = Gus.
#
# CHANGELOG (add a line whenever you change this file; git history is the rest)
#   2026-11-15  initial version

set -euo pipefail

HOSTNAME_FORMAL="Argus"
HOSTNAME_LOCAL="argus"

# Homebrew formulae installed by the admin phase. rsync is here because macOS's
# bundled openrsync choked on signed .app bundles when syncing ~/.hermes.
BREW_FORMULAE=(git gh node rsync tailscale)

# Global npm packages (Node 22+ required by obsidian-headless).
NPM_GLOBALS=(obsidian-headless)

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

ensure_brew_in_path() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! grep -qs 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
      run bash -c "echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> \"$HOME/.zprofile\""
    fi
  fi
}

# ---------------------------------------------------------------- admin phase
phase_admin() {
  if [ "$(id -u)" = "0" ]; then warn "Run as your admin user, not root."; exit 1; fi
  run sudo -v

  log "Hostname"
  run sudo scutil --set ComputerName "$HOSTNAME_FORMAL"
  run sudo scutil --set LocalHostName "$HOSTNAME_LOCAL"
  run sudo scutil --set HostName "$HOSTNAME_LOCAL"

  log "Always-on power settings"
  run sudo pmset -a sleep 0 disksleep 0 displaysleep 1
  run sudo pmset -a autorestart 1        # restart after power failure

  log "Remote Login (SSH)"
  # May need Full Disk Access for Terminal; if it fails, use System Settings -> General -> Sharing.
  run sudo systemsetup -setremotelogin on || warn "Enable Remote Login in System Settings -> General -> Sharing"

  log "Homebrew"
  if ! have brew && [ ! -x /opt/homebrew/bin/brew ]; then
    run env NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  ensure_brew_in_path

  log "Brew packages: ${BREW_FORMULAE[*]}"
  for f in "${BREW_FORMULAE[@]}"; do
    brew list --formula "$f" >/dev/null 2>&1 || run brew install "$f"
  done

  log "Tailscale (system daemon, so it runs without a logged-in session)"
  if [ ! -f /Library/LaunchDaemons/com.tailscale.tailscaled.plist ]; then
    run sudo tailscaled install-system-daemon || warn "tailscaled install-system-daemon failed"
  fi
  if ! tailscale status >/dev/null 2>&1; then
    run sudo tailscale up --ssh            # prints a login URL; open it on any device
  fi

  log "Global npm packages: ${NPM_GLOBALS[*]}"
  for p in "${NPM_GLOBALS[@]}"; do
    npm ls -g --depth=0 "$p" >/dev/null 2>&1 || run npm install -g "$p"
  done

  cat <<'EOF'

Admin phase done. Still manual (cannot or should not be scripted):
  - Tailscale admin console: disable key expiry for argus.
  - Create the standard user `hermes` (System Settings -> Users & Groups).
  - FileVault: if on, auto-login is unavailable. Decide, then set auto-login for `hermes`.
  - Apple Account for Argus: Find My Mac only. No iCloud Drive/Photos/Passwords/Messages.
  - From Monarch:  infocmp -x xterm-ghostty | ssh <admin-user>@argus -- tic -x -
  - GitHub SSH key for this machine (ssh-keygen -t ed25519), add it at github.com, clone dotfiles.
EOF
}

# ---------------------------------------------------------------- agent phase
phase_agent() {
  if [ "$(id -u)" = "0" ]; then warn "Run as the hermes user, not root."; exit 1; fi
  ensure_brew_in_path

  log "Claude Code"
  if ! have claude; then
    run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  fi

  log "Hermes runtime"
  if ! have hermes; then
    run bash -c 'curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash'
  fi

  cat <<'EOF'

Agent phase done. Next, as the hermes user:
  1. claude login                                   # then: hermes plugins install claude-subscription-directsdk
  2. ob login && ob sync-setup                      # connect ~/Obsidian/<vault> to your remote vault
       - do NOT also run the Obsidian desktop app on this machine
       - run `ob sync` continuously as a launchd service (check `ob sync --help` for the flag)
  3. Migrate Hermes data from Phenix (stop Phenix's gateway first: hermes gateway stop):
       rsync -avz --exclude hermes-agent/ --exclude tools/ --exclude installs/ --exclude venv/ \
         phenix:~/.hermes/ ~/.hermes/
  4. Fix paths: grep -rn 'phenix' ~/.hermes/.env ~/.hermes/config.yaml   (old /Users/phenix, vault path, writable_roots)
  5. hermes gateway install && hermes gateway start
  6. Monarch desktop app: Settings -> Gateways -> Connect via SSH -> argus
EOF
}

case "${1:-}" in
  admin) phase_admin ;;
  agent) phase_agent ;;
  *) echo "usage: $0 admin|agent   (DRY_RUN=1 to preview)"; exit 2 ;;
esac

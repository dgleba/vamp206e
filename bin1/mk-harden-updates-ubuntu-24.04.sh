#!/usr/bin/env bash

mkdir -p $HOME/bin
f=$HOME/bin/harden-updates-ubuntu-24.04.sh
tee $f <<- 'HEREDOC'
#!/usr/bin/env bash

# see REV log starting about line 19...

#
# harden-updates-ubuntu-24.04.sh
#
# Purpose:
#   Disable automatic OS and snap updates on Ubuntu 24.04
#   and enforce a manual, auditable update workflow.
#
# Usage:
#   sudo bash $HOME/bin/harden-updates-ubuntu-24.04.sh
#
# Notes:
#   - Idempotent: safe to re-run.
#   - Logs all changes to /var/log/harden-updates-ubuntu-24.04.log
# 
# VERSIONS...
# 2026-06-11 r10 change /var/lib folder from update-hardening.
# 2026-06-22 r11 mod two fuctions disable_unattended_upgrades_service() configure_apt_periodic() 
# 2026-06-22 r14 add thisversion.
# 2026-06-22 r15 add configure_apt_periodic10. comment_allowed_origins50. hold nvidia pkgs. 
# 2026-06-22 r16 add unhold comment. add hold pkgs to manual update.
# 2026-06-24 r17 add more listing at end.
# 2026-06-24 r18 fixing listing status exited early.
# 2026-06-24 r19 fixing listing status again.
# 2026-06-24 r20 fix a quote.
# 2026-06-25 r21 change backup location.
# 2026-06-29 r22 fix backup_file had 2 slashes.
# 2026-06-29 r23 fix backup and 50unat.... .



#todo  0 12 */7 * * /bin/bash /home/albe/.nvsdkm/.updater/updater.sh




thisscriptversion=r23-2026-07-16



# =================================================




# show commands using -vx..
#set -euovx pipefail
# or not..
set -euo pipefail

LOG_FILE="/var/log/harden-updates-ubuntu-24.04.log"

log() {
  local ts
  ts="$(date -Iseconds)"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
  fi
}

check_ubuntu_version() {
  local ver
  ver="$(. /etc/os-release && echo "${VERSION_ID:-}")"
  if [[ "$ver" != "24.04" ]]; then
    log "WARNING: Detected Ubuntu $ver, script designed for 24.04. Continuing anyway."
  else
    log "Detected Ubuntu 24.04."
  fi
}

backup_file() {
  set -vx
  local f="$1"
  if [[ -f "$f" ]]; then
    mkdir -p "$HOME/backup"
    local base="$(basename "$f")"
    local backup="$HOME/backup/${base}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$f" "$backup"
    log "Backup created: $backup"
  fi
  set +vx
}


disable_unattended_upgrades_service_old2026-06-21() {
  log "Disabling unattended-upgrades service and related timers..."

  # Stop and disable unattended-upgrades
  systemctl stop unattended-upgrades.service 2>/dev/null || true
  systemctl disable unattended-upgrades.service 2>/dev/null || true
  systemctl mask unattended-upgrades.service 2>/dev/null || true

  # Disable apt periodic timers
  systemctl disable --now apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true

  log "unattended-upgrades and apt-daily timers disabled/masked."
}


disable_unattended_upgrades_service() {
  # 2026-06-22 01:00:18 PM 
  log "Masking unattended-upgrades service and related timers..."

  systemctl stop unattended-upgrades.service 2>/dev/null || true
  systemctl disable unattended-upgrades.service 2>/dev/null || true
  systemctl mask unattended-upgrades.service 2>/dev/null || true

  # Forcefully mask the systemd timers
  systemctl stop apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
  systemctl mask apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true

  log "unattended-upgrades and apt-daily timers hard-masked."
}


configure_apt_periodic10() {
  log "Configuring APT periodic settings to disable automatic updates..."

  local conf="/etc/apt/apt.conf.d/10periodic"

  if [[ -f "$conf" ]]; then
    backup_file "$conf"
  fi

  cat > "$conf" <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

  chmod 644 "$conf"
  log "APT periodic configuration written to $conf"
}

configure_apt_periodic() {
# 2026-06-22 12:59:18 PM 
  log "Configuring APT periodic settings to disable automatic updates..."

  # Nuke the default file that overrides 10periodic
  if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]]; then
    rm -f /etc/apt/apt.conf.d/20auto-upgrades
  fi

  # Write to 99disable-updates to ensure it takes ultimate lexical precedence
  local conf="/etc/apt/apt.conf.d/99disable-updates"

  cat > "$conf" <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

  chmod 644 "$conf"
  log "APT periodic configuration forcefully written to $conf"
}


comment_allowed_origins50() {
    local file="${1:-/etc/apt/apt.conf.d/50unattended-upgrades}"

    if [[ ! -f "$file" ]]; then
        echo "NOTICE: File does not exist: $file"
        return 0
    fi

    sed -i \
      '/^Unattended-Upgrade::Allowed-Origins\s*{/,/^};/ {
         /^[[:space:]]*\/\//b
         s/^[[:space:]]*/\/\/ &/
      }' "$file"
}



document_manual_update_procedure() {
  log "Documenting manual update procedure in /usr/local/sbin/manual-update-ubuntu-24.04.sh"

  local script="/usr/local/sbin/manual-update-ubuntu-24.04.sh"

  cat > "$script" <<'EOF'
#!/usr/bin/env bash
#
# manual-update-ubuntu-24.04.sh
#
# Purpose:
#   Perform a controlled, manual update of APT packages and snaps.
#
# Usage:
#   sudo manual-update-ubuntu-24.04.sh
#
# Notes:
#   - Logs to /var/log/manual-update-ubuntu-24.04.log
#   - Intended to be run during a planned maintenance window.

set -euo pipefail

LOG_FILE="/var/log/manual-update-ubuntu-24.04.log"

log() {
  local ts
  ts="$(date -Iseconds)"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
  fi
}

require_root

log "===== Manual update run started ====="

# to unhold them..
sudo apt-mark unhold linux-image-generic linux-headers-generic "nvidia-*"

log "Running: apt update"
apt update | tee -a "$LOG_FILE"

log "Running: apt upgrade -y"
apt upgrade -y | tee -a "$LOG_FILE"

# Uncomment if you explicitly want full-upgrade (kernel, etc.)
# log "Running: apt full-upgrade -y"
# apt full-upgrade -y | tee -a "$LOG_FILE"

log "Running: apt autoremove -y"
apt autoremove -y | tee -a "$LOG_FILE"

if command -v snap >/dev/null 2>&1; then
  log "Running: snap refresh"
  snap refresh | tee -a "$LOG_FILE"
else
  log "snap command not found; skipping snap refresh."
fi

# hold packages..
sudo apt-mark hold linux-image-generic linux-headers-generic "nvidia-*"

log "===== Manual update run completed ====="
log "If kernel or critical libraries were updated, schedule or perform a reboot."
EOF

  chmod 750 "$script"
  log "Manual update helper script installed at $script"
}

configure_snap_refresh_hold() {
  if ! command -v snap >/dev/null 2>&1; then
    log "snap not installed; skipping snap refresh configuration."
    return
  fi

  log "Configuring snap to hold automatic refreshes until 2050-01-01..."

  local hold_date
  hold_date="$(date --date='2050-01-01' +%Y-%m-%dT%H:%M:%S%:z)"

  snap set system "refresh.hold=${hold_date}"

  log "snap refresh.hold set to $hold_date"
}

export_installed_package_baseline() {
  local baseline_dir="/var/lib/hardening-of-updates"
  local baseline_file="${baseline_dir}/apt-installed-baseline.txt"

  mkdir -p "$baseline_dir"

  log "Exporting installed package baseline to $baseline_file"
  apt list --installed > "$baseline_file" 2>/dev/null || dpkg -l > "${baseline_file}.dpkg"
  cp "${baseline_file}" "${baseline_file}.$(date +%Y%m%d-%H-%M-%S).txt"
  #chmod 755  "${baseline_file}.$(date +%Y%m%d-%H-%M-%S).txt"
  log "Baseline export complete. See "${baseline_file}.dpkg".$(date +%Y%m%d-%H-%M-%S).txt"
}

main() {
  require_root
  touch "$LOG_FILE"
  chmod 640 "$LOG_FILE"

  echo "===== Starting update hardening for Ubuntu 24.04  script-version:$thisscriptversion ====="
  log  "===== Starting update hardening for Ubuntu 24.04  script-version:$thisscriptversion ====="

  check_ubuntu_version
  #echo sleeping 10s... ; sleep 8;
  N=15; for ((i=N; i>=1; i--)); do printf "\rPress key or Wait %d...   " $i; read -rsn1 -t 1 && break; done; echo;


  disable_unattended_upgrades_service
  configure_apt_periodic10
  configure_apt_periodic
  comment_allowed_origins50
  configure_snap_refresh_hold
  export_installed_package_baseline
  document_manual_update_procedure

	# hold packages..
	sudo apt-mark hold linux-image-generic linux-headers-generic "nvidia-*"
	# to unhold them..
	#    sudo apt-mark unhold linux-image-generic linux-headers-generic "nvidia-*"

	# Disable the update-notifier autostart entry
	if [[ -f /etc/xdg/autostart/update-notifier.desktop ]]; then
	  mv /etc/xdg/autostart/update-notifier.desktop \
		 /etc/xdg/autostart/update-notifier.desktop.disabled
	fi

	# Optional: disable Ubuntu Advantage notification autostart too
	if [[ -f /etc/xdg/autostart/ubuntu-advantage-notification.desktop ]]; then
	  mv /etc/xdg/autostart/ubuntu-advantage-notification.desktop \
		 /etc/xdg/autostart/ubuntu-advantage-notification.desktop.disabled
	fi

  log "===== Update hardening completed. Automatic updates are disabled. ====="
  log "Use: sudo manual-update-ubuntu-24.04.sh during planned maintenance windows."
  
}



# ================================================= Main. start here..

main "$@"


echo
echo
echo  Listing status ================================================= 	..
echo
echo

set +e ; set +u ; set +o pipefail;
set -vx

apt-config dump APT::Periodic::Update-Package-Lists
apt-config dump APT::Periodic::Unattended-Upgrade
systemctl status unattended-upgrades
systemctl list-timers | grep -E 'apt-daily|apt-daily-upgrade'
systemctl status apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service
apt-config dump | grep -i Periodic
apt-mark showhold
snap get system refresh.hold
#
set +vx
echo 'run ` cat /var/log/apt/history.log|less  ` . Check timestamps since ran the script. Should see no entries for automated package installations.'

echo
echo
echo Reached end of script.
echo


HEREDOC

chmod +x $f
#
# sudo bash $HOME/bin/harden-updates-ubuntu-24.04.sh
#
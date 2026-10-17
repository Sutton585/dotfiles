#!/bin/bash
set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "Run with: sudo bash setup.sh"; exit 1; }
REPO="https://github.com/Sutton585/dotfiles.git"

systemctl enable --now tailscaled
CURRENT_IP=$(tailscale ip -4 2>/dev/null || true)

# -------------------------------------------------------------------------
# STAGE 1: Configure Hostname & Join Tailscale
# -------------------------------------------------------------------------
if [ -z "$CURRENT_IP" ]; then
  CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname)
  echo "Current hostname is: '$CURRENT_HOSTNAME'"
  read -rp "Enter desired hostname for this machine (press Enter to keep '$CURRENT_HOSTNAME'): " CHOSEN_NAME
  HOST_NAME="${CHOSEN_NAME:-$CURRENT_HOSTNAME}"

  echo "System Network:"
  echo "  └─ Applying hostname '$HOST_NAME'..."
  hostnamectl set-hostname "$HOST_NAME"

  # Verify hostname change
  ACTIVE_NAME=$(cat /proc/sys/kernel/hostname)
  if [ "$ACTIVE_NAME" != "$HOST_NAME" ]; then
    echo "  └─ ERROR: Failed to set hostname. Current is still '$ACTIVE_NAME'."
    exit 1
  fi
  echo "  └─ Hostname verified: $ACTIVE_NAME"

  # Ensure SSH host keys exist (in case stripped from golden image) and restart sshd
  echo "  └─ SSH: ensuring host keys exist..."
  ssh-keygen -A
  systemctl restart sshd

  echo "  └─ Requesting Tailscale login URL for '$HOST_NAME'..."
  tailscale up --reset --hostname="$HOST_NAME" 2>&1

  CURRENT_IP=$(tailscale ip -4 2>/dev/null || true)
  if [ -z "$CURRENT_IP" ]; then
    echo "Login incomplete or canceled. Please re-run: sudo bash setup.sh"
    exit 1
  fi

  cat <<BANNER
===================================================================
Tailscale login successful!
Assigned IP: $CURRENT_IP
Node Name:   $HOST_NAME

NEXT STEPS:
1. Disconnect this current SSH session.
2. Reconnect over Tailscale using:  ssh admin@$CURRENT_IP
3. Re-run:  sudo bash setup.sh
===================================================================
BANNER
  exit 0
fi

# -------------------------------------------------------------------------
# STAGE 2: Verify SSH Arrived via Tailscale
# -------------------------------------------------------------------------
TS_IPS=$(tailscale ip)
TS_IPV4=$(tailscale ip -4 2>/dev/null || true)
[ -n "$TS_IPV4" ] || { echo "ERROR: Tailscale IPv4 address not found."; exit 1; }

# Verify current SSH session connected directly to the host's Tailscale IP
if ! ss -Htn state established '( sport = :22 )' | awk -v ip="$TS_IPV4" '
   { split($3,l,":"); split($4,p,":"); if (l[1]==ip && p[1]!=ip) ok=1 }
   END { exit !ok }'; then
  echo "ERROR: Current SSH connection was NOT made over Tailscale ($TS_IPV4)."
  echo "Tailscale IPs for this machine:"
  echo "$TS_IPS"
  echo "Please connect via: ssh admin@$TS_IPV4, then re-run this script."
  exit 1
fi

echo "System Network:"
echo "  └─ Hostname: $(cat /proc/sys/kernel/hostname) (verified)"
echo "  └─ Tailscale: $TS_IPV4 (verified)"

# -------------------------------------------------------------------------
# 1. Install Core System Tools & Shell Enhancements
# -------------------------------------------------------------------------
echo ""
echo "System Packages:"
echo "  └─ Core utilities: installing bash-completion, pkgfile, conntrack-tools"
pacman -S --needed --noconfirm bash-completion pkgfile conntrack-tools >/dev/null 2>&1 || true

if command -v pkgfile &>/dev/null; then
  echo "  └─ pkgfile: update timer enabled (indexing in background)"
  systemctl enable --now pkgfile-update.timer >/dev/null 2>&1 || true
  (pkgfile -u >/dev/null 2>&1 &) || true
fi

# -------------------------------------------------------------------------
# 2. Enforce SSH Keys Only (Disable Passwords)
# -------------------------------------------------------------------------
echo ""
echo "System Security:"
echo "  └─ SSH: enforcing key-only authentication (passwords disabled)"
[ -s "/home/admin/.ssh/authorized_keys" ] || { echo "ERROR: no authorized_keys for admin; refusing to disable passwords."; exit 1; }
mkdir -p /etc/ssh/sshd_config.d
cat << 'SSHEOF' > /etc/ssh/sshd_config.d/99-hardened.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
SSHEOF
sshd -t
systemctl reload sshd

# -------------------------------------------------------------------------
# 3. Lock Down Firewall & Terminate Stale Conntrack Sessions
# -------------------------------------------------------------------------
echo "  └─ Firewall: installing tailscale-only ruleset"
[ -f "/etc/nftables.locked.conf" ] || { echo "ERROR: /etc/nftables.locked.conf not found."; exit 1; }

# Validate syntax before swapping
nft -c -f /etc/nftables.locked.conf

# Backup bootstrap ruleset, install locked ruleset, and remove staging file
[ -f /etc/nftables.bootstrap.conf ] || cp -a /etc/nftables.conf /etc/nftables.bootstrap.conf
install -m 600 /etc/nftables.locked.conf /etc/nftables.conf
rm -f /etc/nftables.locked.conf
nft -f /etc/nftables.conf
systemctl enable --now nftables

# Idempotently ensure the ext_secure network exists with the matching bridge name
systemctl is-active --quiet docker || systemctl start docker
docker network inspect ext_secure >/dev/null 2>&1 || \
  docker network create --opt com.docker.network.bridge.name=br-exts ext_secure

# Sever existing non-Tailscale SSH sessions
if command -v conntrack &>/dev/null; then
  echo "  └─ conntrack: severing non-Tailscale SSH sessions"
  for ip in $(ip -4 -o addr show scope global | awk '$2!="tailscale0"{split($4,a,"/");print a[1]}'); do
    conntrack -D -p tcp --dport 22 -d "$ip" >/dev/null 2>&1 || true
  done
else
  echo "  └─ WARNING: conntrack missing; existing LAN SSH sessions not severed"
fi

# -------------------------------------------------------------------------
# 4. In-Script Verification Tests
# -------------------------------------------------------------------------
echo ""
echo "Security Verification:"
if nft list chain inet filter input | grep -q 'iifname "tailscale0" accept' \
   && ! nft list chain inet filter input | grep -q 'dport 22'; then
  echo "  └─ nftables: tailscale-only input active [PASS]"
else
  echo "  └─ nftables: WARNING - ruleset not as expected!"
fi

if ! sshd -T | grep -iq "passwordauthentication no"; then
  echo "  └─ sshd: WARNING - password authentication is still enabled!"
else
  echo "  └─ sshd: password authentication disabled [PASS]"
fi

if ip link show br-exts >/dev/null 2>&1; then
  echo "  └─ docker: ext_secure bridge br-exts present [PASS]"
else
  echo "  └─ docker: WARNING - br-exts missing!"
fi

# -------------------------------------------------------------------------
# 5. Clone Dotfiles & Run User Setup Script
# -------------------------------------------------------------------------
echo ""
echo "Deploying Environments:"
for u in admin dev; do
  h="/home/$u"
  target="$h/.dotfiles"
  if [ -d "$h" ]; then
    echo "  └─ User: $u"
    if [ ! -d "$target/.git" ]; then
      sudo -H -u "$u" git clone --quiet --depth 1 --single-branch --no-tags "$REPO" "$target" >/dev/null 2>&1
    else
      sudo -H -u "$u" git -C "$target" pull --quiet --ff-only >/dev/null 2>&1 || true
    fi

    if [ -f "$target/setup.sh" ]; then
      chmod +x "$target/setup.sh"
      # Run in user's security context with HOME correctly set to /home/$u and pass LOG_PREFIX
      sudo -H -u "$u" env LOG_PREFIX="    " bash "$target/setup.sh" || echo "    └─ Warning: Dotfiles setup for $u returned non-zero exit."
    fi
  fi
done

# -------------------------------------------------------------------------
# 6. Archive Provisioning Script for Audit Reference
# -------------------------------------------------------------------------
ARCHIVE_DIR="/var/log/provisioning"
mkdir -p "$ARCHIVE_DIR"
ARCHIVE_FILE="$ARCHIVE_DIR/host-setup-$(date +%Y%m%d_%H%M%S).sh"
SCRIPT_PATH="$(readlink -f "$0")"

echo ""
echo "Provisioning Complete:"
if [ "$SCRIPT_PATH" != "$ARCHIVE_FILE" ]; then
  mv "$SCRIPT_PATH" "$ARCHIVE_FILE"
  chmod 600 "$ARCHIVE_FILE"
  echo "  └─ Archived provisioning script to $ARCHIVE_FILE"
fi
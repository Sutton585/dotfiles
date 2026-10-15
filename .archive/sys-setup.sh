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
# 1. Enforce SSH Keys Only (Disable Passwords)
# -------------------------------------------------------------------------
echo ""
echo "System Security:"
echo "  └─ SSH: enforcing key-only authentication (passwords disabled)"
mkdir -p /etc/ssh/sshd_config.d
cat << 'SSHEOF' > /etc/ssh/sshd_config.d/99-hardened.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
SSHEOF
systemctl reload sshd

# -------------------------------------------------------------------------
# 2. Lock Down Firewall & Terminate Stale Conntrack Sessions
# -------------------------------------------------------------------------
echo "  └─ Firewall: restricting incoming SSH strictly to tailscale0"
cat << 'NFTEOF' > /etc/nftables.conf
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;

        iif "lo" accept
        ct state established,related accept
        ct state invalid drop

        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept

        iifname "tailscale0" tcp dport 22 accept
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
    }
    chain output {
        type filter hook output priority filter; policy accept;
    }
}
NFTEOF
nft -c -f /etc/nftables.conf
nft -f /etc/nftables.conf
systemctl enable --now nftables

# -------------------------------------------------------------------------
# 3. Install Core System Tools & Shell Enhancements
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

if command -v conntrack &>/dev/null; then
  echo "  └─ conntrack: severing non-Tailscale SSH sessions"
  # Kill any established conntrack flows on port 22 not destined for a Tailscale IP
  for tip in $TS_IPS; do
    conntrack -D -p tcp --dport 22 --dst-nat ! "$tip" >/dev/null 2>&1 || true
  done
fi

# -------------------------------------------------------------------------
# 4. In-Script Verification Tests
# -------------------------------------------------------------------------
echo ""
echo "Security Verification:"
if ! nft list chain inet filter input | grep -q 'iifname "tailscale0" tcp dport 22 accept'; then
  echo "  └─ nftables: WARNING - rules do not appear to be loaded properly!"
else
  echo "  └─ nftables: port 22 restriction active [PASS]"
fi

if ! sshd -T | grep -iq "passwordauthentication no"; then
  echo "  └─ sshd: WARNING - password authentication is still enabled!"
else
  echo "  └─ sshd: password authentication disabled [PASS]"
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
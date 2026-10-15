#!/bin/bash
# Run: sudo bash setup.sh   (re-run after joining Tailscale)
set -e
[ "$EUID" -eq 0 ] || { echo "Run with: sudo bash setup.sh"; exit 1; }
REPO="https://github.com/Sutton585/dotfiles.git"   # edit: your skeleton repo

systemctl enable --now tailscaled
ip=$(tailscale ip -4 2>/dev/null || true)

# Stage 1: not on Tailscale yet
if [ -z "$ip" ]; then
  echo "Tailscale not logged in. Starting login..."
  tailscale up --hostname="$(hostname)"   # prints auth URL, waits
  ip=$(tailscale ip -4 2>/dev/null || true)
  [ -n "$ip" ] || { echo "Login incomplete. Re-run."; exit 1; }
  cat <<EOF

1. Open the URL above and approve this device in Tailscale.
2. SSH back in over Tailscale:  ssh admin@$(hostname)   (or admin@$ip)
3. Re-run:  sudo bash setup.sh
EOF
  exit 0
fi

# Stage 2: must be running inside an SSH session that arrived via Tailscale
if ! ss -Htn state established sport = :22 | awk -v ip="$ip" '
   { split($3,l,":"); split($4,p,":"); if (l[1]==ip && p[1]!=ip) ok=1 }
   END { exit !ok }'; then
  echo "Tailscale is up ($ip), but no SSH session via it. SSH to admin@$ip, then re-run."
  exit 1
fi

# 1. Profiles
for u in admin dev; do
  h=/home/$u
  if [ ! -d "$h/.git" ]; then
    sudo -u "$u" git -C "$h" init -q
    sudo -u "$u" git -C "$h" remote add origin "$REPO" 2>/dev/null || true
    sudo -u "$u" git -C "$h" fetch -q origin
    sudo -u "$u" git -C "$h" checkout -f -B main origin/main
  fi
done

# 2. Lock down firewall
cp /etc/nftables.conf /etc/nftables.conf.bak
sed -i '/tcp dport ssh accept/d' /etc/nftables.conf
nft -c -f /etc/nftables.conf
nft -f /etc/nftables.conf
echo "Done. Only tailscale0 can reach this VM."

# 3. Self-delete
rm -- "$(readlink -f "$0")"

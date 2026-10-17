In previous conversation, we made a nftables.new.conf file so we can safely swap to it instead of making individual changes in the file itselt during. `sys-setup.sh`

I still need to actually update the sys-setup.sh script. i need your help to understand and make these adjustemnts:

---

## Recommendation: swap the file, don't generate it in the script

Put the finished ruleset in the image and have the script just install it. One tested file is the single source of truth; the script's heredoc is a second copy that drifts.

| | Golden image | Setup script |
|---|---|---|
| `/etc/nftables.conf` | Bootstrap: allows LAN SSH (your current file) | Replaced by the locked file |
| `/etc/nftables.locked.conf` | Staged, validated ruleset (rename your `.new.conf`) | Installed over `nftables.conf` |
| Docker, nftables, tailscale installed and enabled | Yes | No |
| `ext_secure` network | Optional | Create idempotently (preferred) |
| Hostname, Tailscale login, SSH hardening | No (per-machine) | Yes |

Create the network in the script rather than the image. It's one line, safe to re-run, and doesn't depend on Docker state surviving into clones:

```
docker network inspect ext_secure >/dev/null 2>&1 || \
  docker network create --opt com.docker.network.bridge.name=br-exts ext_secure
```

current nftables.locked.conf:
```bash
[admin@archvm ~]$ cat /etc/nftables.locked.conf
#!/usr/bin/nft -f
# vim:set ts=2 sw=2 et:

destroy table inet filter
table inet filter {
  chain input {
    type filter hook input priority filter
    policy drop

    ct state invalid drop comment "early drop of invalid connections"
    ct state {established, related} accept comment "allow tracked connections"
    iif lo accept comment "allow from loopback"
    iifname "tailscale0" accept comment "allow all from tailscale"
    meta l4proto { icmp, icmpv6 } accept comment "allow icmp (icmpv6 required for IPv6 ND)"
    counter comment "dropped by policy"
  }

  chain forward {
    type filter hook forward priority filter
    policy drop

    ct state invalid drop
    ct state {established, related} accept comment "replies"
    iifname "tailscale0" oifname "br-exts" accept comment "tailnet -> ext_secure"
    iifname "br-exts" accept comment "ext_secure: intra-bridge + egress"
  }
}
```

## Problems in the current script

1. **`flush ruleset` is dangerous.** It wipes Docker's and Tailscale's rules (they use `iptables-nft`). It also races with them at boot. The new file uses `destroy table inet filter`, which touches only your table.
2. **The forward chain is empty.** Containers would have no traffic at all. The new file fixes this.
3. **Input allows only tailscale port 22.** It should allow all of `tailscale0`.
4. **The conntrack kill probably does nothing.** `--dst-nat ! ip` is not a destination filter. This step matters because `ct state established` accepts any LAN SSH session that was open before the swap. Replace it (below).
5. **Lockout risk.** Password auth is disabled with no check that a key exists. Add a guard.
6. **The verification grep** looks for the old rule and will fail after the swap.
7. **Redundant `output` chain.** Remove it.

## Patched script sections

**Section 1: SSH hardening.** Add before writing the sshd config:

```
[ -s "/home/admin/.ssh/authorized_keys" ] || { echo "ERROR: no authorized_keys for admin; refusing to disable passwords."; exit 1; }
```

(Adjust the user if your key lives elsewhere.)

**Section 2: Firewall.** Replace the heredoc block:

```
echo "  └─ Firewall: installing tailscale-only ruleset"
nft -c -f /etc/nftables.locked.conf
cp -a /etc/nftables.conf /etc/nftables.bootstrap.conf
install -m 600 /etc/nftables.locked.conf /etc/nftables.conf
nft -f /etc/nftables.conf
systemctl enable nftables

docker network inspect ext_secure >/dev/null 2>&1 || \
  docker network create --opt com.docker.network.bridge.name=br-exts ext_secure
```

**Section 3: Conntrack.** Replace the loop to kill existing non-Tailscale SSH flows:

```
for ip in $(ip -4 -o addr show scope global | awk '$2!="tailscale0"{split($4,a,"/");print a[1]}'); do
  conntrack -D -p tcp --dport 22 -d "$ip" >/dev/null 2>&1 || true
done
```

This matches the original destination, so it kills LAN sessions but not your current Tailscale one.

**Section 4: Verification:**

```
if nft list chain inet filter input | grep -q 'iifname "tailscale0" accept' \
   && ! nft list chain inet filter input | grep -q 'dport 22'; then
  echo "  └─ nftables: tailscale-only input active [PASS]"
else
  echo "  └─ nftables: WARNING - ruleset not as expected!"
fi
```

## Order of operations

1. **Golden image:** keep the current `/etc/nftables.conf` (LAN SSH works) and add `/etc/nftables.locked.conf`.
2. **First run:** hostname, Tailscale login, exit (as now).
3. **Second run over Tailscale:** SSH hardening, firewall swap, network creation, conntrack cleanup, dotfiles.

## Notes

- **Archiving:** your script moves itself to `/var/log/provisioning`. That's fine, but re-running it afterward requires copying it back.
- **Rollback:** `/etc/nftables.bootstrap.conf` is the way back to LAN SSH from the console if Tailscale breaks.
- **Test once before cloning:** run the script on one throwaway VM from the image, then run the verification table from my last message (tailnet works, LAN times out, container egress works).
#!/usr/bin/env bash
# One-time setup for a fresh Ubuntu 24.04 DigitalOcean droplet.
# Paste into the droplet's web console as root:
#   curl -fsSL https://proposals.localairegistry.com/setup/lair-seat.sh | GOOGLE_CLIENT_ID=xxx bash
# The code repo is private, so this makes a read-only deploy key and pauses while you add it on GitHub.
set -euo pipefail
exec < /dev/tty

echo "== LAIR Seat setup =="
DOMAIN=${DOMAIN:-daisychain.localairegistry.com}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
ALLOWED_EMAILS=${ALLOWED_EMAILS:-steve@localairegistry.com}
# API keys (L2, Postalytics, Lob) are added later on the app's Settings page, not here.

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl git build-essential debian-keyring debian-archive-keyring apt-transport-https gnupg
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y && apt-get install -y caddy

id seat >/dev/null 2>&1 || useradd --system --home /opt/lair-seat --shell /usr/sbin/nologin seat
mkdir -p /root/.ssh && chmod 700 /root/.ssh
[ -f /root/.ssh/lair_seat ] || ssh-keygen -t ed25519 -N "" -C "lair-seat-droplet" -f /root/.ssh/lair_seat >/dev/null
ssh-keyscan -t ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null
export GIT_SSH_COMMAND="ssh -i /root/.ssh/lair_seat -o IdentitiesOnly=yes"
if ! git ls-remote git@github.com:Local-AI-Registry/lair-seat.git >/dev/null 2>&1; then
  echo; echo "== Add this deploy key on GitHub (read-only) =="
  echo "github.com/Local-AI-Registry/lair-seat/settings/keys/new"; echo
  cat /root/.ssh/lair_seat.pub; echo
  read -rp "Press Enter once the key is added... " _
fi
if [ -d /opt/lair-seat/.git ]; then git -C /opt/lair-seat pull --ff-only; else git clone git@github.com:Local-AI-Registry/lair-seat.git /opt/lair-seat; fi
git -C /opt/lair-seat config core.sshCommand "ssh -i /root/.ssh/lair_seat -o IdentitiesOnly=yes"
cd /opt/lair-seat && npm ci --omit=dev
mkdir -p /opt/lair-seat/data

if [ ! -f /opt/lair-seat/.env ]; then
cat > /opt/lair-seat/.env <<EOF
PORT=3100
BASE_URL=https://${DOMAIN}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
ALLOWED_EMAILS=${ALLOWED_EMAILS}
SESSION_SECRET=$(openssl rand -hex 32)
MAIL_PROVIDER=postalytics
L2_APP=COM_US
CONTACT_EMAIL=steve@localairegistry.com
COST_PER_MAIL=1.30
CHAIN_BUDGET=500
CARD_WORD=Invited.
FROM_NAME=Local AI Registry
FROM_LINE1=9891 Irvine Center Dr
FROM_CITY=Irvine
FROM_STATE=CA
FROM_ZIP=92618
CALENDLY_URL=https://calendly.com/bridgette-localairegistry/30min
EOF
fi
chmod 600 /opt/lair-seat/.env
chown -R seat:seat /opt/lair-seat

cat > /etc/systemd/system/lair-seat.service <<EOF
[Unit]
Description=LAIR Seat invitations
After=network.target
[Service]
User=seat
WorkingDirectory=/opt/lair-seat
ExecStart=/usr/bin/node --env-file=/opt/lair-seat/.env server.js
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now lair-seat

cat > /etc/caddy/Caddyfile <<EOF
${DOMAIN} {
  reverse_proxy 127.0.0.1:3100
}
EOF
systemctl restart caddy

IP=$(curl -fsS https://api.ipify.org || hostname -I | awk '{print $1}')
echo
echo "Done. Last step: in Hostinger DNS add an A record:  ${DOMAIN%%.localairegistry.com}  ->  ${IP}"
echo "Then open https://${DOMAIN} and sign in with Google."
echo "To update later:  cd /opt/lair-seat && git pull && npm ci --omit=dev && systemctl restart lair-seat"

#!/usr/bin/env bash
# One-time setup for a fresh Ubuntu 24.04 DigitalOcean droplet.
# Paste into the droplet's web console as root:
#   curl -fsSL https://proposals.localairegistry.com/setup/lair-seat.sh | bash
# The code repo is private, so this makes a read-only deploy key and pauses while you add it on GitHub.
set -euo pipefail
exec < /dev/tty

echo "== LAIR Seat setup =="
read -rp "Domain for the app [daisychain.localairegistry.com]: " DOMAIN; DOMAIN=${DOMAIN:-daisychain.localairegistry.com}
read -rsp "Choose a dashboard password: " ADMIN; echo
read -rp "L2 customer id (Enter to skip for now): " L2C
L2K=""; [ -n "$L2C" ] && { read -rsp "L2 API key: " L2K; echo; }
read -rp "Mail service: postalytics or lob [postalytics]: " PROVIDER; PROVIDER=${PROVIDER:-postalytics}
LOB=""; PSEND=""; PKEY=""
if [ "$PROVIDER" = "lob" ]; then
  read -rsp "Lob secret key (starts with test_ or live_): " LOB; echo
else
  read -rp "Postalytics campaign request URL (from the drip campaign's Settings page): " PSEND
  read -rsp "Postalytics API key: " PKEY; echo
fi

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

cat > /opt/lair-seat/.env <<EOF
PORT=3100
BASE_URL=https://${DOMAIN}
ADMIN_PASSWORD=${ADMIN}
MAIL_PROVIDER=${PROVIDER}
LOB_API_KEY=${LOB}
POSTALYTICS_SEND_URL=${PSEND}
POSTALYTICS_API_KEY=${PKEY}
CALENDLY_URL=https://calendly.com/steve-localairegistry/board-of-advisors-30-min
FROM_NAME=Local AI Registry
FROM_LINE1=9891 Irvine Center Dr
FROM_CITY=Irvine
FROM_STATE=CA
FROM_ZIP=92618
CONTACT_EMAIL=steve@localairegistry.com
COST_PER_MAIL=1.30
CHAIN_BUDGET=500
CARD_WORD=Invited.
DATA_DIR=/opt/lair-seat/data
L2_CUSTOMER=${L2C}
L2_KEY=${L2K}
L2_APP=COM_US
EOF
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
echo "Then open https://${DOMAIN}/seat-admin/map (any username, your dashboard password)."
echo "To update later:  cd /opt/lair-seat && git pull && npm ci --omit=dev && systemctl restart lair-seat"

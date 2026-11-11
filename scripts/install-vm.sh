#!/usr/bin/env bash
# Installs the portal on one Debian or Ubuntu machine, without containers:
# Node.js, the documentation toolchain and PostgreSQL, the built backend under
# /opt/portal, and a systemd service that runs it.
#
#   sudo scripts/install-vm.sh --base-url https://portal.example.org
#
# Run it from a checkout of this repository. Run it again after `git pull` to
# upgrade: it rebuilds and restarts, and keeps /etc/portal/portal.env and the
# database.
#
#   --base-url <url>   the address people will open (required the first time)
#   --dir <path>       where to install (default /opt/portal)
#   --no-service       build and configure only: for containers and images,
#                      where there is no systemd to start anything
#
# Afterwards put a reverse proxy with TLS in front of port 7007, and fill in
# the GitHub settings in /etc/portal/portal.env (see SETUP.md).
set -euo pipefail

DIR=/opt/portal
BASE_URL=
SERVICE=true
while [ $# -gt 0 ]; do
  case "$1" in
    --base-url) BASE_URL="$2"; shift 2 ;;
    --dir) DIR="$2"; shift 2 ;;
    --no-service) SERVICE=false; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE=/etc/portal/portal.env
say() { printf '\n==> %s\n' "$*"; }

[ "$(id -u)" = 0 ] || { echo "Run this as root (sudo)." >&2; exit 1; }
command -v apt-get >/dev/null || { echo "This installer supports Debian and Ubuntu." >&2; exit 1; }
if [ ! -f "$ENV_FILE" ] && [ -z "$BASE_URL" ]; then
  echo "--base-url is required the first time, for example --base-url https://portal.example.org" >&2
  exit 2
fi

say "Installing system packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  ca-certificates curl xz-utils git openssl rsync \
  python3 python3-venv g++ make libsqlite3-dev \
  postgresql >/dev/null

id portal >/dev/null 2>&1 || useradd --system --home-dir "$DIR" --shell /usr/sbin/nologin portal
mkdir -p "$DIR/data" /etc/portal

case "$(uname -m)" in
  x86_64) NODE_ARCH=x64; D2_ARCH=amd64 ;;
  aarch64 | arm64) NODE_ARCH=arm64; D2_ARCH=arm64 ;;
  *) echo "Unsupported machine: $(uname -m)" >&2; exit 1 ;;
esac

say "Installing Node.js 24"
# The newest 24.x from nodejs.org, checked against its published checksum.
sums="$(curl -fsSL https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt)"
tarball="$(printf '%s\n' "$sums" | awk -v a="linux-$NODE_ARCH.tar.xz" '$2 ~ a"$" {print $2}')"
if [ ! -x "$DIR/node/bin/node" ] || [ "v$("$DIR/node/bin/node" -p process.versions.node)" != "$(printf '%s' "$tarball" | cut -d- -f2)" ]; then
  work="$(mktemp -d)"
  curl -fsSL -o "$work/$tarball" "https://nodejs.org/dist/latest-v24.x/$tarball"
  (cd "$work" && printf '%s\n' "$sums" | grep " $tarball\$" | sha256sum --check --quiet)
  rm -rf "$DIR/node" && mkdir -p "$DIR/node"
  tar -xJf "$work/$tarball" -C "$DIR/node" --strip-components=1
  rm -rf "$work"
fi
export PATH="$DIR/node/bin:$PATH"
node --version

say "Installing the documentation toolchain"
# The versions are the Dockerfile's, so every way of hosting builds the same pages.
python3 -m venv "$DIR/techdocs"
# shellcheck disable=SC2046
"$DIR/techdocs/bin/pip" install --quiet $(grep -oE 'mkdocs-[a-z0-9-]+==[0-9.]+' "$REPO/Dockerfile" | sort -u)
D2_VERSION="$(grep -oE 'terrastruct/d2:v[0-9.]+' "$REPO/Dockerfile" | cut -d: -f2)"
if [ "$(/usr/local/bin/d2 --version 2>/dev/null || true)" != "$D2_VERSION" ]; then
  work="$(mktemp -d)"
  curl -fsSL "https://github.com/terrastruct/d2/releases/download/$D2_VERSION/d2-$D2_VERSION-linux-$D2_ARCH.tar.gz" | tar -xz -C "$work"
  install "$work/d2-$D2_VERSION/bin/d2" /usr/local/bin/d2
  rm -rf "$work"
fi

say "Building the portal (several minutes)"
BUILD="$DIR/build"
mkdir -p "$BUILD"
rsync -a --delete \
  --exclude .git --exclude node_modules --exclude dist --exclude dist-types \
  --exclude '.env*' --exclude 'edge/.*.vars' --exclude cmux-assets \
  "$REPO/" "$BUILD/"
chown -R portal:portal "$DIR"
as_portal() { runuser -u portal -- env HOME="$DIR" PATH="$PATH" COREPACK_ENABLE_DOWNLOAD_PROMPT=0 "$@"; }
(
  cd "$BUILD"
  as_portal node .yarn/releases/yarn-*.cjs install --immutable
  as_portal node .yarn/releases/yarn-*.cjs tsc
  as_portal node .yarn/releases/yarn-*.cjs workspace backend build
)

say "Assembling $DIR/app"
NEXT="$DIR/app.next"
rm -rf "$NEXT" && mkdir -p "$NEXT"
tar -xzf "$BUILD/packages/backend/dist/skeleton.tar.gz" -C "$NEXT"
cp -R "$BUILD/.yarn" "$BUILD/.yarnrc.yml" "$BUILD/backstage.json" "$BUILD/yarn.lock" "$BUILD/package.json" "$NEXT/"
chown -R portal:portal "$NEXT"
(cd "$NEXT" && as_portal node .yarn/releases/yarn-*.cjs workspaces focus --all --production)
tar -xzf "$BUILD/packages/backend/dist/bundle.tar.gz" -C "$NEXT"
cp "$BUILD/app-config.yaml" "$BUILD/app-config.production.yaml" "$BUILD/app-config.vm.yaml" "$NEXT/"
cp -R "$BUILD/examples" "$BUILD/catalog" "$BUILD/templates" "$NEXT/"
chown -R portal:portal "$NEXT"

say "Preparing PostgreSQL"
if [ "$SERVICE" = true ]; then
  systemctl enable --now postgresql >/dev/null
else
  # No systemd here: start the cluster the packages created.
  pg_ctlcluster "$(pg_lsclusters -h | awk 'NR==1 {print $1}')" main start 2>/dev/null || true
fi
if [ ! -f "$ENV_FILE" ]; then
  password="$(openssl rand -hex 24)"
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 --quiet <<SQL
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'portal') THEN
    CREATE ROLE portal LOGIN CREATEDB PASSWORD '$password';
  ELSE
    ALTER ROLE portal PASSWORD '$password';
  END IF;
END \$\$;
SQL
  runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'backstage'" | grep -q 1 ||
    runuser -u postgres -- createdb --owner portal backstage
  umask 077
  cat >"$ENV_FILE" <<ENV
# Settings of the portal service. Read by systemd; restart after a change:
#   systemctl restart portal

# The address people open. Put a reverse proxy with TLS in front of port 7007.
APP_BASE_URL=$BASE_URL
CORS_ORIGIN=$BASE_URL

# Written by the installer.
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=portal
POSTGRES_PASSWORD=$password
AUTH_SESSION_SECRET=$(openssl rand -hex 32)
PORTAL_DATA_DIR=$DIR/data

# GitHub. Remove the # from a line to set it: a name left empty stops the
# service starting. The token reads repositories and creates them from
# templates; the client secret belongs to the OAuth app described in
# /etc/portal/app-config.yaml.
#GITHUB_TOKEN=
#GITHUB_CLIENT_SECRET=

# Who may change the branding and ownership: user names, comma-separated.
# Left empty, the first person to sign in becomes the administrator.
PORTAL_ADMINS=
ENV
  chown root:portal "$ENV_FILE"
  chmod 640 "$ENV_FILE"
  cat >/etc/portal/app-config.yaml <<CONFIG
# Your own settings for the portal, loaded after the ones it ships with.
# Restart after a change: systemctl restart portal
#
# Until sign-in is set up, anyone who can reach the portal is let in as a
# guest. To sign people in with GitHub, create an OAuth app whose callback is
#   $BASE_URL/api/auth/github/handler/frame
# put its secret in /etc/portal/portal.env as GITHUB_CLIENT_SECRET, and
# replace the last line of this file with:
#
# auth:
#   providers:
#     guest: null
#     github:
#       production:
#         clientId: <the OAuth app's client id>
#         clientSecret: \${GITHUB_CLIENT_SECRET}
#         callbackUrl: $BASE_URL/api/auth/github/handler/frame
#
# To bring an organisation's teams and people into the catalog (needs
# GITHUB_TOKEN in portal.env), add:
#
# catalog:
#   providers:
#     githubOrg:
#       - id: production
#         githubUrl: https://github.com
#         orgs: [<organisation>]
#         schedule:
#           initialDelay: { seconds: 10 }
#           frequency: { minutes: 5 }
#           timeout: { minutes: 3 }

{}
CONFIG
  chown root:portal /etc/portal/app-config.yaml
  chmod 640 /etc/portal/app-config.yaml
fi

say "Switching to the new build"
rm -rf "$DIR/app.previous"
[ -d "$DIR/app" ] && mv "$DIR/app" "$DIR/app.previous"
mv "$NEXT" "$DIR/app"

if [ "$SERVICE" = true ]; then
  sed "s#@DIR@#$DIR#g" "$REPO/scripts/portal.service" >/etc/systemd/system/portal.service
  systemctl daemon-reload
  systemctl enable portal >/dev/null
  systemctl restart portal
  say "Waiting for the portal to answer"
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null http://127.0.0.1:7007/.backstage/health/v1/readiness; then
      echo "The portal is running on port 7007. Settings: $ENV_FILE"
      exit 0
    fi
    sleep 5
  done
  echo "The portal did not answer within five minutes. See: journalctl -u portal" >&2
  exit 1
fi
echo "Built and configured in $DIR. Start it with the command in scripts/portal.service."

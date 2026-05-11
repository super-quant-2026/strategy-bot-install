#!/bin/bash
# Super Quant Bot — One-line installer for Ubuntu / Debian, x86_64.
# Pulls the public PyArmor-obfuscated image from GHCR; no source code
# is downloaded to the host.
#
# Usage:
#   bash <(curl -sSL https://raw.githubusercontent.com/super-quant-2026/strategy-bot-install/main/install.sh)
#
# Override the image tag (e.g. to install a specific release):
#   IMAGE_TAG=v0.1.0-beta bash <(curl -sSL .../install.sh)
#
# Override the install directory (default /opt/super-quant-bot):
#   INSTALL_DIR=/srv/sqb bash <(curl -sSL .../install.sh)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INSTALL]${NC} $1"; }
warn() { echo -e "${YELLOW}[INSTALL]${NC} $1"; }
err()  { echo -e "${RED}[INSTALL]${NC} $1"; exit 1; }

# IMAGE_REPO: GHCR coordinates of the encrypted runtime image.
# DEPLOY_REPO: public GitHub repo holding install.sh + docker-compose
# + .env.example. Source code lives in a separate private repo
# (super-quant-2026/strategy-bot) — end users never see it.
IMAGE_REPO="super-quant-2026/strategy-bot"
DEPLOY_REPO="super-quant-2026/strategy-bot-install"
RAW_BASE="https://raw.githubusercontent.com/${DEPLOY_REPO}/main"
INSTALL_DIR="${INSTALL_DIR:-/opt/strategy-bot}"
IMAGE_TAG="${IMAGE_TAG:-v0.1.0-beta}"
COMPOSE_FILE="docker-compose.encrypted.yml"

# ── 0. Pre-flight ──────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && err "Please run with sudo (need to install Docker + write to ${INSTALL_DIR})"

# Architecture: amd64 only for v0.1
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    err "Unsupported architecture: ${ARCH}. v0.1 only supports x86_64 (amd64)."
fi

# OS: Ubuntu / Debian only for v0.1
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID,,}" in
        ubuntu|debian) ;;
        *)
            warn "OS '${PRETTY_NAME:-$ID}' is not officially tested. v0.1 supports Ubuntu / Debian. Continuing anyway."
            ;;
    esac
fi

log "═══════════════════════════════════════════"
log "  Super Quant Bot — installer"
log "  image:   ghcr.io/${IMAGE_REPO}:${IMAGE_TAG}"
log "  target:  ${INSTALL_DIR}"
log "═══════════════════════════════════════════"
echo ""

# ── 1. Install Docker (Engine + Compose plugin) ────────────────────
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    log "Docker installed ✓"
else
    log "Docker already present ✓"
fi

# Compose plugin (`docker compose ...`). The convenience get-docker.com
# already installs it on modern Ubuntu/Debian, but cover the gap.
if ! docker compose version &> /dev/null; then
    log "Installing docker-compose-plugin..."
    apt-get update -qq
    apt-get install -y docker-compose-plugin
fi
log "docker compose: $(docker compose version --short 2>/dev/null || echo unknown) ✓"

# ── 2. Prepare install directory ───────────────────────────────────
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# ── 3. Pull compose + .env.example from the repo (NO source) ───────
log "Fetching compose file + env template..."
curl -fsSL "${RAW_BASE}/${COMPOSE_FILE}" -o "${COMPOSE_FILE}"
if [ ! -f .env ]; then
    curl -fsSL "${RAW_BASE}/.env.example" -o .env.example
    cp .env.example .env

    # Auto-generate sane initial values so the bot can boot to the
    # login page without manual edits. User still has to set their
    # ADMIN_PASSWORD before exposing the dashboard publicly.
    RANDOM_PREFIX=$(head -c 8 /dev/urandom | xxd -p | head -c 10)
    RANDOM_DBPW=$(head -c 12 /dev/urandom | base64 | tr -d '+/=' | head -c 16)
    RANDOM_ROOTPW=$(head -c 12 /dev/urandom | base64 | tr -d '+/=' | head -c 16)
    # WATCHTOWER_TOKEN — shared bearer between bot and watchtower
    # sidecar. Auto-rotated here so every install gets a fresh value;
    # leakage only impacts that one user (worst case: someone with
    # the token can force the bot to pull GHCR and restart — same
    # surface as the in-app upgrade button itself).
    RANDOM_WT_TOKEN=$(head -c 24 /dev/urandom | base64 | tr -d '+/=' | head -c 32)
    sed -i "s|^ADMIN_PREFIX=.*|ADMIN_PREFIX=${RANDOM_PREFIX}|" .env
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${RANDOM_DBPW}|" .env
    sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=${RANDOM_ROOTPW}|" .env
    sed -i "s|^WATCHTOWER_TOKEN=.*|WATCHTOWER_TOKEN=${RANDOM_WT_TOKEN}|" .env

    SERVER_IP=$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || echo "<your-server-ip>")

    echo ""
    warn "═══════════════════════════════════════════"
    warn "  Edit ${INSTALL_DIR}/.env BEFORE going live:"
    warn "═══════════════════════════════════════════"
    echo "  - ADMIN_PASSWORD: change from 'changeme'"
    echo "  - DEBUG_MODE: 1 = paper trading, 0 = real orders"
    echo ""
    echo -e "  Dashboard URL after start:"
    echo -e "    ${BLUE}http://${SERVER_IP}:3030/${RANDOM_PREFIX}/${NC}"
    echo ""
    echo -e "  ${YELLOW}Security:${NC}"
    echo "    - API keys: TRADE permission only, NO withdrawal"
    echo "    - API keys: whitelist this server's IP if the venue supports it"
    echo "    - Firewall: only expose port 3030 to addresses you trust"
    echo ""
    read -rp "Press ENTER to continue once you've reviewed .env (or Ctrl-C to edit first)..." _
fi

# ── 4. Pull image + start ──────────────────────────────────────────
export IMAGE_TAG
log "Pulling image ghcr.io/${IMAGE_REPO}:${IMAGE_TAG} ..."
docker compose -f "${COMPOSE_FILE}" pull
log "Starting services..."
docker compose -f "${COMPOSE_FILE}" up -d

# ── 5. Wait for health ─────────────────────────────────────────────
log "Waiting for bot to come up..."
for i in $(seq 1 30); do
    if curl -fs http://localhost:3030/health &>/dev/null; then
        break
    fi
    sleep 2
done

if curl -fs http://localhost:3030/health &>/dev/null; then
    SERVER_IP=$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
    PREFIX=$(grep -E '^ADMIN_PREFIX=' .env | cut -d= -f2)
    echo ""
    log "═══════════════════════════════════════════"
    log "  Install complete ✓"
    log "═══════════════════════════════════════════"
    echo -e "  Dashboard: ${BLUE}http://${SERVER_IP}:3030/${PREFIX}/${NC}"
    echo -e "  Logs:      ${BLUE}docker logs -f super-quant-bot${NC}"
    echo -e "  Manage:    ${BLUE}cd ${INSTALL_DIR} && docker compose -f ${COMPOSE_FILE} <pull|up -d|down|restart>${NC}"
    echo ""
else
    err "Bot did not become healthy within 60s. Check: docker logs super-quant-bot"
fi

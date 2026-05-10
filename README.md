# Strategy Bot — Installer

One-line installer for the encrypted runtime image. Source code is
in a separate private repository; this repo only ships the
`install.sh` + docker-compose + env template.

## Install (Ubuntu / Debian, x86_64)

```bash
sudo bash <(curl -sSL https://raw.githubusercontent.com/super-quant-2026/strategy-bot-install/main/install.sh)
```

The installer:

1. Installs Docker + Docker Compose plugin (skips if already present).
2. Creates `/opt/strategy-bot/` and downloads `docker-compose.encrypted.yml` + `.env.example` here.
3. Generates a random `ADMIN_PREFIX`, `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`.
4. Pauses for you to review `.env` (edit `ADMIN_PASSWORD` etc. if needed).
5. Pulls `ghcr.io/super-quant-2026/strategy-bot:v0.1.0-beta` from GHCR.
6. Starts the stack and waits for `/health` to come up.

After install, the dashboard is at `http://<server-ip>:3030/<random-prefix>/`.

## Pin a specific version

```bash
IMAGE_TAG=v0.2.0 sudo bash <(curl -sSL https://raw.githubusercontent.com/super-quant-2026/strategy-bot-install/main/install.sh)
```

## Manual deploy (no installer)

```bash
mkdir -p /opt/strategy-bot && cd /opt/strategy-bot
curl -O https://raw.githubusercontent.com/super-quant-2026/strategy-bot-install/main/docker-compose.encrypted.yml
curl -O https://raw.githubusercontent.com/super-quant-2026/strategy-bot-install/main/.env.example
cp .env.example .env && nano .env       # set ADMIN_PASSWORD etc.
docker compose -f docker-compose.encrypted.yml pull
docker compose -f docker-compose.encrypted.yml up -d
```

## Update

```bash
cd /opt/strategy-bot
docker compose -f docker-compose.encrypted.yml pull
docker compose -f docker-compose.encrypted.yml up -d
```

To switch to a different version, edit `IMAGE_TAG` at the top of
`docker-compose.encrypted.yml` (or override on the command line:
`IMAGE_TAG=v0.2.0 docker compose -f docker-compose.encrypted.yml up -d`).

## Uninstall

```bash
cd /opt/strategy-bot
docker compose -f docker-compose.encrypted.yml down -v   # `-v` deletes the database volume too
rm -rf /opt/strategy-bot
```

## Security checklist

- Set a strong `ADMIN_PASSWORD` in `.env` before exposing port 3030 publicly.
- Exchange API keys: enable trading only, **never enable withdrawal**.
- Whitelist this server's IP on every exchange API key console where supported.
- Firewall: only expose port 3030 to addresses you trust.

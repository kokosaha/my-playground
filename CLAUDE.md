# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Local Docker infrastructure playground for IoT/charging-pile scenarios. Deployments are organized under `deploy/` as numbered service directories, each with its own `docker-compose.yml`, configs, certs, and data.

## Service Architecture

```
deploy/
├── 01-gitlab/       # GitLab CE 17.9.5 on :8080/:2222, named volumes (not bind mounts)
├── 02-emqx/         # EMQX 5.7.1 MQTT broker on :1883/:18083, emqx-net network
├── 03-mqtts/        # Standalone MQTT TLS certs (CA, server) for direct EMQX SSL testing
├── 04-nginx-lb/     # Nginx 1.24 TLS-termination proxy → EMQX (stream module, mTLS, :8443)
├── 05-iotda/        # Huawei Cloud IoTDA device certificates
└── 06-mysql/        # MySQL 5.7 on :3306, preloaded with usergf_uapdb_dev + usergf_hmsvcdb_dev
```

**Key inter-service dependency**: 04-nginx-lb joins 02-emqx's `emqx-net` (external network). Start 02-emqx first, then 04-nginx-lb.

**Certificate hierarchy**: `ca/` at project root contains the CA key/cert used to issue all service certificates. Individual services (02-emqx, 03-mqtts, 04-nginx-lb) hold their own server/client certs signed by this CA.

## Common Commands

```bash
# Start any service
cd deploy/<NN-service> && docker compose up -d

# Stop a service
docker compose down

# View logs
docker compose logs -f

# Recreate after config changes
docker compose up -d --force-recreate

# MySQL: import the dev databases (container must be running)
cd deploy/06-mysql && bash import.sh
```

## Shell Script Conventions

- `#!/bin/bash` with `set -e`
- Check prerequisites with `command -v <tool> &>/dev/null` before use
- Use `${VAR:-default}` for overridable defaults

## Docker Compose Conventions

- Compose v2.x syntax (no top-level `version` key needed)
- `restart: always` on all services
- Named volumes for persistent data; bind mounts (`./path:...:ro`) for configs/certs
- Secrets (passwords, admin keys) go in `.env` files, never committed

## Important Notes

- This is a Chinese-language project; documentation and commit messages are in Chinese
- `06-mysql/init/` contains large SQL dumps (~220MB, ~255MB) from Navicat — these are committed as-is and imported via `docker exec -i` (not volume-mounted init scripts)
- `04-nginx-lb/nginx.conf` has a hardcoded upstream IP (`192.168.97.2:1883`) — if the EMQX container IP changes, this must be updated
- `02-emqx/data/` is bind-mounted and contains live Mnesia database state
- Data directories (`data/`, `log/`) are gitignored

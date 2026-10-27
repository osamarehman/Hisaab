# Deploy handoff: Sure household edition

For the agent (or person) launching this on the server. Read fully before
running anything.

## What this is

A fork of [we-promise/sure](https://github.com/we-promise/sure) adapted for one
Pakistani household: PKR default, manual expenses with receipt photos,
bank-statement import (PDF via AI, CSV) with labelling, no bank sync, an AI
assistant via OpenRouter, and a redesigned Flutter app (`mobile/`).

- Repo: `github.com/osamarehman/sure-redesign` (private), branch
  `redesign/household-pkr`. `upstream` remote = we-promise/sure.
- API contract the app uses: `docs/redesign/household-api.md`.
- AI setup and model choice: `docs/redesign/openrouter.md`.
- Server stack: `compose.household.yml` (builds this repo's `Dockerfile`;
  web + sidekiq worker + Postgres 16 + Redis 7). Env template:
  `.env.household.example`.

## Target

- VPS `109.123.247.217` (root). It already runs **SureCaller** under
  `/root/surecaller` — do not touch its containers, volumes, ports or proxy
  config beyond adding a new site.
- Hostname: `sure.shipdeck.dev` (the APK defaults to it; DNS
  A record → 109.123.247.217 must exist before TLS can issue).

## Steps

1. **Recon (read-only):** `docker ps`, `ss -ltnp`, `free -h`, `df -h /`.
   Find how SureCaller is exposed (Caddy / nginx / Traefik / other) and which
   host ports are taken. Pick a free port for `PORT` (default 3010). Sure
   needs about 1.5 GB RAM for web + worker; stop and report if the box is
   short.
2. **Code:** `git clone -b redesign/household-pkr git@github.com:osamarehman/sure-redesign.git /root/sure-household`
   (private repo: use a deploy key or `gh auth`; ask the owner if neither works).
3. **Env:** `cp .env.household.example .env`, set `APP_DOMAIN`, generate
   `SECRET_KEY_BASE` (`openssl rand -hex 64`) and `POSTGRES_PASSWORD`
   (`openssl rand -hex 24`), set `OPENAI_ACCESS_TOKEN` to the owner's
   OpenRouter key (ask; never commit or echo it). `chmod 600 .env`.
4. **Build & start:** `docker compose -f compose.household.yml up -d --build`.
   The first build takes a while. The web entrypoint runs `db:prepare`
   (creates and migrates the DB) on boot.
   Check: `curl -sI http://127.0.0.1:$PORT/up` → 200, and
   `docker compose -f compose.household.yml logs --tail=50 web worker`.
5. **Reverse proxy + TLS:** add a site for `APP_DOMAIN` → `127.0.0.1:$PORT`
   in whatever proxy SureCaller uses (same style as its existing site). Must
   pass `Host` and `X-Forwarded-Proto: https`. Allow uploads ≥ 30 MB
   (statement PDFs up to 25 MB; nginx: `client_max_body_size 30m`). Reload the
   proxy, then confirm `https://$APP_DOMAIN/up` → 200.
6. **First account:** open `https://$APP_DOMAIN`, sign up (the first user
   becomes admin). In onboarding, keep currency **PKR** / country **Pakistan**.
   Then in Settings: enable **preview features** for the user (unlocks the
   Insights notes on Home and extra assistant tools) and enable **AI** for the
   assistant. Optionally create a "Cash in hand" account and the bank
   accounts (manual) whose statements will be imported.
7. **AI check:** Settings → System health → AI status → Run checks. If the
   model fails tool calls, switch `OPENAI_MODEL` (see openrouter.md) and
   `docker compose -f compose.household.yml up -d`.
8. **Report back** to the owner: URL, port used, proxy file changed, anything
   skipped. Do not paste secrets.

## Updating later

```bash
cd /root/sure-household && git pull && docker compose -f compose.household.yml -f compose.server.yml up -d --build
```

`compose.server.yml` exists only on the server (git-ignored). The web container
joins Caddy's shared network, where the name `db` resolves to another app's
Postgres, so the override points Sure at its own database and Redis. Keep it in
every compose command.

Live deployment (2026-10-27): `https://sure.shipdeck.dev`, `/root/sure-household`,
port 3010, Caddy site `/root/core-stack/caddy.d/sure.caddy`, backups via
`/root/scripts/sure-backup.sh` → `/root/backups/sure` (14 days).

## Mobile app

- APK is built locally from `mobile/` (`flutter build apk --release`); it is
  signed with the build machine's debug key, so later updates must be built on
  the same machine (or set up a release keystore via `mobile/android/key.properties`).
- The app defaults to `https://sure.shipdeck.dev`. For another host, use the server
  settings on the sign-in screen. To ship a build
  that already points at the server, change `_defaultBaseUrl` in
  `mobile/lib/services/api_config.dart` before building.

## Backups

The upstream compose has a `backup` sidecar (`compose.example.yml`); it is not
included here. At minimum schedule
`docker compose -f compose.household.yml exec -T db pg_dump -U sure_user sure_production | gzip > /root/backups/sure-$(date +%F).sql.gz`
and keep the `app-storage` volume (receipts, statements) in the backup set.

## Known gaps

- Web UI has the new colours/fonts but not the redesigned layouts (mobile has
  them).
- Excel statements are not supported (PDF/CSV only).
- Real PDF extraction with the chosen free model has not been tested end to end.
- The full Rails suite had 9 failures + 2 errors on a Windows CRLF checkout
  (PDF fixtures and generator tests); run `bin/rails test` on Linux to confirm
  they pass there.

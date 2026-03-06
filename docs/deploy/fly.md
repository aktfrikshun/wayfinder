# Fly.io Deployment

This guide deploys Wayfinder to Fly with:

- Dockerfile-based Rails deploy
- Two Fly processes: `web` (Puma) and `worker` (Solid Queue)
- `release_command` for DB migrations
- Unmanaged Postgres app (`wayfinder-frikshun-db`) on private Fly network
- No Redis dependency (jobs and cache are database-backed)

## 1) Prerequisites

- Install `flyctl`: https://fly.io/docs/flyctl/install/
- Login (repo-local Fly config):

```bash
export FLY_CONFIG_DIR="$(pwd)/.fly"
fly auth login
```

- Ensure this repo has `fly.toml` at project root.

## 2) Create the Rails app

```bash
fly apps create wayfinder-frikshun
```

## 3) Create unmanaged Postgres app (`wayfinder-frikshun-db`)

Run helper script:

```bash
DB_PASSWORD="$(openssl rand -hex 24)" bin/fly/setup_db
```

What this does:

- Creates Fly app `wayfinder-frikshun-db`
- Creates volume `pg_data` mounted to `/var/lib/postgresql/data`
- Runs `postgres:16` machine
- Leaves DB private-only on Fly 6PN (no public service)

Rails should connect using:

```text
postgres://wayfinder:<password>@wayfinder-frikshun-db.internal:5432/wayfinder_production
```

## 4) Set required app secrets

Set application secrets (never commit these):

```bash
fly secrets set -a wayfinder-frikshun \
  DATABASE_URL='postgres://wayfinder:<password>@wayfinder-frikshun-db.internal:5432/wayfinder_production' \
  POSTMARK_WEBHOOK_SECRET='<postmark-secret>' \
  OPENAI_API_KEY='<openai-key>' \
  OPENAI_MODEL='gpt-4.1-mini'
```

You can also set `RAILS_MASTER_KEY` if your app requires encrypted credentials at runtime.

## 5) Deploy

Use helper script:

```bash
bin/fly/deploy
```

The deploy uses:

- Docker build from `Dockerfile`
- `release_command = bundle exec rails db:migrate`
- Process groups from `fly.toml`:
  - `web`: `bundle exec puma -C config/puma.rb`
  - `worker`: `bundle exec rake solid_queue:start`

## 6) Verify

```bash
fly status -a wayfinder-frikshun
fly logs -a wayfinder-frikshun
fly machine list -a wayfinder-frikshun
```

Check health endpoint:

```bash
curl -i https://wayfinder-frikshun.fly.dev/up
```

## 7) Git workflow

Typical local workflow:

1. Push code to GitHub.
2. Pull latest main locally.
3. Run `bin/fly/deploy`.
4. Monitor `fly logs -a wayfinder-frikshun`.

GitHub Actions deploy is optional. Local deploy is fully supported by this setup.

## Notes

- `config/database.yml` production uses `DATABASE_URL`.
- Active Job uses `solid_queue` (database-backed) from `config/application.rb`.
- Rails cache uses `solid_cache_store` in development and production.

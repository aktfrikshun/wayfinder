# Fly.io Deployment

This guide deploys Wayfinder to Fly with:

- Dockerfile-based Rails deploy
- Two Fly processes: `web` (Puma) and `worker` (Sidekiq)
- `release_command` for DB migrations
- Unmanaged Postgres app (`wayfinder-frikshun-db`) on private Fly network
- Upstash Redis for Sidekiq and ActiveJob

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

## 4) Provision Redis (Upstash)

Create and attach Upstash Redis to `wayfinder-frikshun`:

```bash
fly redis create
fly redis attach <redis-app-name> --app wayfinder-frikshun
```

After attach, Fly sets `REDIS_URL` secret on `wayfinder-frikshun`.

## 5) Set required app secrets

Set application secrets (never commit these):

```bash
fly secrets set -a wayfinder-frikshun \
  DATABASE_URL='postgres://wayfinder:<password>@wayfinder-frikshun-db.internal:5432/wayfinder_production' \
  POSTMARK_WEBHOOK_SECRET='<postmark-secret>' \
  OPENAI_API_KEY='<openai-key>' \
  OPENAI_MODEL='gpt-4.1-mini'
```

You can also set `RAILS_MASTER_KEY` if your app requires encrypted credentials at runtime.

## 6) Deploy

Use helper script:

```bash
bin/fly/deploy
```

The deploy uses:

- Docker build from `Dockerfile`
- `release_command = bundle exec rails db:migrate`
- Process groups from `fly.toml`:
  - `web`: `bundle exec puma -C config/puma.rb`
  - `worker`: `bundle exec sidekiq -C config/sidekiq.yml`

## 7) Verify

```bash
fly status -a wayfinder-frikshun
fly logs -a wayfinder-frikshun
fly machine list -a wayfinder-frikshun
```

Check health endpoint:

```bash
curl -i https://wayfinder-frikshun.fly.dev/up
```

## 8) Git workflow

Typical local workflow:

1. Push code to GitHub.
2. Pull latest main locally.
3. Run `bin/fly/deploy`.
4. Monitor `fly logs -a wayfinder-frikshun`.

GitHub Actions deploy is optional. Local deploy is fully supported by this setup.

## Notes

- `config/database.yml` production uses `DATABASE_URL`.
- Sidekiq uses `REDIS_URL` via `config/initializers/sidekiq.rb`.

### Redis fallback (self-hosted on Fly)

Use this only if Upstash is not available:

```bash
fly apps create wayfinder-frikshun-redis
fly machine run redis:7 \
  -a wayfinder-frikshun-redis \
  --name wayfinder-frikshun-redis-1 \
  --restart always \
  --vm-size shared-cpu-1x \
  --vm-memory 256

fly secrets set -a wayfinder-frikshun REDIS_URL='redis://wayfinder-frikshun-redis.internal:6379/0'
```

Upstash remains the default/recommended option.

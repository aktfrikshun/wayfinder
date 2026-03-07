# Wayfinder

Wayfinder is a Rails 8 application that ingests family/school artifacts, runs extraction + classification, and exposes a child artifact timeline for parent-facing experiences.

## Architecture

### High-level flow

1. Postmark sends inbound email payload to `POST /webhooks/postmark/inbound`.
2. The webhook validates `X-Postmark-Webhook-Token` against `POSTMARK_WEBHOOK_SECRET`.
3. Wayfinder resolves the child from the inbound alias (email local-part), stores an `Artifact`, and enqueues processing.
4. In production lean mode, Active Job runs asynchronously in-process (`:async`) without a dedicated worker machine.
5. `Artifacts::ProcessArtifactJob` orchestrates shape detection, extraction, OCR fallback, classification, and AI extraction.
6. Clients fetch timeline entries from `GET /children/:id/artifacts` (latest 50).

### Core components

- Webhook controller: `app/controllers/webhooks/postmark_inbound_controller.rb`
- Artifact timeline API: `app/controllers/api/children_artifacts_controller.rb`
- Background job: `app/jobs/artifacts/process_artifact_job.rb`
- Artifact pipeline services: `app/services/artifacts/*`
- AI extraction dispatcher: `app/services/ai/extract_artifact.rb`
- OpenAI wrapper: `app/services/open_ai_client.rb`
- Serializer: `app/serializers/artifact_serializer.rb`
- Parent invites: `app/controllers/parent_portal/invitations_controller.rb`
- Invitation mailer: `app/mailers/invitation_mailer.rb`
- Postmark events webhook: `app/controllers/webhooks/postmark_events_controller.rb`

### Data model

- `Parent` has many `children`
- `Child` belongs to `parent`, has many `artifacts` (legacy `communications` retained for migration compatibility)
- `Artifact` belongs to `child`
- `Artifact.processing_state` values: `pending`, `detecting`, `extracting_text`, `classifying`, `processed`, `failed`
- `Artifact.ai_status` values: `pending`, `processing`, `complete`, `failed`

## Tech stack

- Ruby 3.x managed with `rbenv`
- Rails 8.x
- PostgreSQL
- Active Job (`:async` in production lean mode)
- Solid Cache (database-backed Rails cache store)
- OpenAI API (via Faraday)
- RSpec + FactoryBot
- Active Storage (Disk for dev/test, S3-compatible for production)

## Prerequisites

- `rbenv` with Ruby from `.ruby-version`
- Docker with Docker Compose

Start Postgres via Docker:

```bash
docker compose up -d
docker compose ps
```

This exposes PostgreSQL on `localhost:5432`.

## Configuration

Copy and edit environment values:

```bash
cp .env.example .env
```

Important variables:

- `DATABASE_URL=postgres://postgres:postgres@localhost:5432/wayfinder_development`
- `OPENAI_API_KEY=...`
- `OPENAI_MODEL=gpt-4.1-mini`
- `POSTMARK_WEBHOOK_SECRET=...`
- `POSTMARK_EVENTS_WEBHOOK_SECRET=...`
- `POSTMARK_API_TOKEN=...`
- `POSTMARK_MESSAGE_STREAM=outbound`
- `MAIL_FROM=wayfinder@frikshun.com`
- `ACTIVE_STORAGE_SERVICE=local` (development default) or `amazon`
- `AWS_ACCESS_KEY_ID=...`
- `AWS_SECRET_ACCESS_KEY=...`
- `AWS_REGION=us-east-1`
- `AWS_BUCKET=wayfinder-artifacts`
- `AWS_ENDPOINT=https://s3.us-east-1.amazonaws.com` (optional for S3-compatible providers)
- `AWS_FORCE_PATH_STYLE=true` (optional; set for MinIO or some compat providers)

On Fly.io, set storage credentials as secrets (example):

```bash
fly secrets set AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_REGION=us-east-1 AWS_BUCKET=wayfinder-artifacts --app wayfinder-frikshun
```

## Setup

Always run bundle commands through `rbenv`:

```bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"
bundle install
DATABASE_URL=postgres://postgres:postgres@localhost:5432/wayfinder_development bin/setup --skip-server
```

If you use Docker services from `docker-compose.yml`, the default `.env.example` values already point to the mapped localhost ports.

## Run locally

Start web + worker together:

```bash
bin/dev
```

This launches:

- Rails server on `http://localhost:3000`
- Solid Queue worker (`bundle exec rake solid_queue:start`)

Stop data services when done:

```bash
docker compose down
```

## Usage notes

### Seed baseline records

```bash
bundle exec rails db:seed
```

Creates:

- Parent: `allen@example.com`
- Child: `Zammy` (`inbound_alias: zammy`)

### Test inbound webhook quickly

```bash
POSTMARK_WEBHOOK_SECRET=changeme ./scripts/test_webhook.sh
```

### Query child artifacts timeline

```bash
curl -s http://localhost:3000/children/1/artifacts | jq .
```

Response fields:

- `id`
- `source_type`
- `content_type`
- `title`
- `subject`
- `occurred_at`
- `captured_at`
- `processing_state`
- `ai_status`
- `effective_category`
- `tags`
- `summary`

## Testing

Prepare test DB and run specs:

```bash
RAILS_ENV=test DATABASE_URL=postgres://postgres:postgres@localhost:5432/wayfinder_test bundle exec rails db:prepare
RAILS_ENV=test DATABASE_URL=postgres://postgres:postgres@localhost:5432/wayfinder_test bundle exec rspec
```

## CI

GitHub Actions workflow: `.github/workflows/ci.yml`

Pipeline runs:

1. Ruby setup from `.ruby-version`
2. PostgreSQL service
3. `bundle exec rails db:prepare`
4. `bundle exec rspec`

Pushes to `main` also trigger automatic Fly deploy via GitHub Actions.
Required repository secret: `FLY_API_TOKEN`.

## Fly Deployment

Fly deployment assets are included:

- `fly.toml` (web process, release migration command)
- `bin/fly/setup_db` (unmanaged Postgres app setup)
- `bin/fly/deploy` (deploy helper with Depot layer cache, scales to web=1/worker=0)
- `docs/deploy/fly.md` (full runbook)
- `docs/deploy/postmark.md` (Postmark send + webhook setup)

## Security notes

- Webhook token is validated before ingestion.
- Raw payload is stored for auditing in `artifacts.raw_payload`.
- Sensitive email body and payload fields are filtered from logs via `config/initializers/filter_parameter_logging.rb`.

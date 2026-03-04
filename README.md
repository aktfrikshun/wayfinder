# Wayfinder

Wayfinder is a Rails 8 application that ingests school communications, extracts structured signals with AI, and exposes a child communication timeline for parent-facing experiences.

## Architecture

### High-level flow

1. Postmark sends inbound email payload to `POST /webhooks/postmark/inbound`.
2. The webhook validates `X-Postmark-Webhook-Token` against `POSTMARK_WEBHOOK_SECRET`.
3. Wayfinder resolves the child from the inbound alias (email local-part), stores a `Communication`, and enqueues AI extraction.
4. Sidekiq runs `AI::ExtractCommunicationJob` from the `ai_extract` queue.
5. `AI::ExtractSchoolEmail` calls `OpenAIClient` and writes structured extraction to `communications.ai_extracted`.
6. Clients fetch timeline entries from `GET /children/:id/communications` (latest 50).

### Core components

- Webhook controller: `app/controllers/webhooks/postmark_inbound_controller.rb`
- Timeline API: `app/controllers/communications_controller.rb`
- Background job: `app/jobs/ai/extract_communication_job.rb`
- AI extraction service: `app/services/ai/extract_school_email.rb`
- OpenAI wrapper: `app/services/open_ai_client.rb`
- Serializer: `app/serializers/communication_serializer.rb`

### Data model

- `Parent` has many `children`
- `Child` belongs to `parent`, has many `communications`
- `Communication` belongs to `child`
- `Communication.ai_status` values: `pending`, `processing`, `complete`, `failed`

## Tech stack

- Ruby 3.x managed with `rbenv`
- Rails 8.x
- PostgreSQL
- Sidekiq + Redis
- OpenAI API (via Faraday)
- RSpec + FactoryBot

## Prerequisites

- `rbenv` with Ruby from `.ruby-version`
- PostgreSQL running on `localhost:5432`
- Redis running on `localhost:6379`

Optional local Postgres via Docker:

```bash
docker run -d --name wayfinder-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=wayfinder_development \
  -p 5432:5432 postgres:16
```

## Configuration

Copy and edit environment values:

```bash
cp .env.example .env
```

Important variables:

- `DATABASE_URL=postgres://localhost:5432/wayfinder_development`
- `REDIS_URL=redis://localhost:6379/0`
- `OPENAI_API_KEY=...`
- `OPENAI_MODEL=gpt-4.1-mini`
- `POSTMARK_WEBHOOK_SECRET=...`

## Setup

Always run bundle commands through `rbenv`:

```bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"
bundle install
DATABASE_URL=postgres://postgres:postgres@localhost:5432/wayfinder_development bin/setup --skip-server
```

## Run locally

Start web + worker together:

```bash
bin/dev
```

This launches:

- Rails server on `http://localhost:3000`
- Sidekiq worker using `config/sidekiq.yml`

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

### Query child communications timeline

```bash
curl -s http://localhost:3000/children/1/communications | jq .
```

Response fields:

- `id`
- `subject`
- `received_at`
- `ai_status`
- `ai_extracted.summary`

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

## Security notes

- Webhook token is validated before ingestion.
- Raw payload is stored for auditing in `communications.raw_payload`.
- Sensitive email body and payload fields are filtered from logs via `config/initializers/filter_parameter_logging.rb`.

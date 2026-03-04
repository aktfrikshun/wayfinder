# Wayfinder – Rails Project Bootstrap Specification
Version: 0.1  
Purpose: Provide Codex with a clear specification to generate the initial Wayfinder Rails project scaffold.

---

# Project Overview

Wayfinder is an AI-powered platform that helps parents navigate their child’s developmental journey.

The system analyzes signals from:

- school communications
- assignments
- teacher feedback
- parent observations

and generates insights that help parents understand patterns in:

- learning
- social development
- emotional wellbeing
- behavioral trends

Wayfinder acts as a **guide through the uncertainty of childhood development**, helping parents recognize signals earlier and respond thoughtfully.

---

# Technology Stack

Backend Framework:
- Ruby on Rails (latest stable version 8 of Rails and version 3.x of Ruby)
- Use rbenv for ruby version management

Database:
- PostgreSQL (local instance during prototype phase)

Background Processing:
- Sidekiq

Queue Backend:
- Redis

AI Processing:
- OpenAI API

Inbound Email Processing:
- Postmark Webhook (initial)
- Future: Gmail ingestion / forward-to-email support

Storage:
- ActiveStorage (local disk during prototype)

Testing:
- RSpec
- FactoryBot

Local Development:
- Ruby via rbenv
- Redis via Docker
- Postgres local install

---

# Core MVP Capabilities

The MVP should support:

1. Parent account
2. Child profiles
3. Inbound email ingestion
4. AI extraction of signals from emails
5. Timeline of events for each child
6. Background AI processing via Sidekiq

---

# Rails Project Name

wayfinder


---

# Folder Structure

Create the following folders if they do not exist:


docs/
specs/

app/
services/
ai/
postmark/
extractors/
jobs/
ai/
serializers/
controllers/
webhooks/

scripts/

config/
initializers/


---

# Required Gems

Add the following gems.

Core:


sidekiq
redis
faraday
dotenv-rails


Testing:


rspec-rails
factory_bot_rails
faker
webmock


Development Tools:


rubocop
rubocop-rails
rubocop-rspec
foreman


---

# Environment Variables

Create `.env.example`


DATABASE_URL=postgres://localhost:5432/wayfinder_development

REDIS_URL=redis://localhost:6379/0

OPENAI_API_KEY=changeme
OPENAI_MODEL=gpt-4.1-mini

POSTMARK_WEBHOOK_SECRET=changeme


---

# Local Development Commands

Create `Procfile.dev`


web: bundle exec rails server -p 3000
worker: bundle exec sidekiq -C config/sidekiq.yml


Create `bin/dev` script:


#!/usr/bin/env bash
foreman start -f Procfile.dev


---

# Database Models

## Parent

Fields:


id
email
name
created_at
updated_at


Constraints:

- email unique
- email required

Relationships:


has_many :children


---

## Child

Fields:


id
parent_id
name
grade
school_name
inbound_alias
created_at
updated_at


Constraints:

- inbound_alias unique
- name required

Relationships:


belongs_to :parent
has_many :communications


---

## Communication

Represents an inbound email or message.

Fields:


id
child_id
source
from_email
from_name
subject
received_at
body_text
body_html
raw_payload (jsonb)

ai_status
ai_raw_response (jsonb)
ai_extracted (jsonb)
ai_error

created_at
updated_at


AI Status values:


pending
processing
complete
failed


---

# Webhook Endpoint

Create controller:


app/controllers/webhooks/postmark_inbound_controller.rb


Endpoint:


POST /webhooks/postmark/inbound


Security:

Validate header:


X-Postmark-Webhook-Token


against:


POSTMARK_WEBHOOK_SECRET


Processing Steps:

1. Parse JSON payload
2. Extract inbound email address
3. Determine child via inbound_alias
4. Create Communication record
5. Enqueue AI processing job

Return:


{ status: "ok" }


---

# Background Jobs

Create job:


app/jobs/ai/extract_communication_job.rb


Queue:


ai_extract


Processing Steps:

1. Mark communication.ai_status = processing
2. Send email content to AI extraction service
3. Save structured output to ai_extracted
4. Mark ai_status = complete

Error handling:


ai_status = failed
ai_error = error message


---

# AI Extraction Service

Create service:


app/services/ai/extract_school_email.rb


Input:


communication


Output JSON schema:


{
summary: string,
subject_area: string,
concerns: [string],
assignments: [
{
title: string,
due_date: date,
details: string
}
],
signals: [
{
type: string,
description: string,
confidence: float
}
],
sentiment: string,
priority: string
}


---

# OpenAI Client

Create wrapper:


app/services/openai_client.rb


Responsibilities:

- manage API key
- perform requests
- enforce JSON structured responses
- return:


raw_response
parsed_response


---

# API Endpoint (MVP)

Provide endpoint:


GET /children/:id/communications


Returns latest 50 communications.

Fields returned:


id
subject
received_at
ai_status
ai_extracted.summary


---

# Seed Data

Create sample data in `db/seeds.rb`


Parent:
email: allen@example.com

Child:
name: Zammy
inbound_alias: zammy
grade: 5


---

# Webhook Test Script

Create:


scripts/test_webhook.sh


Script should:

1. POST sample payload to


http://localhost:3000/webhooks/postmark/inbound


2. Include header:


X-Postmark-Webhook-Token


3. Print response.

---

# GitHub CI Workflow

Create:


.github/workflows/ci.yml


Pipeline Steps:

1. checkout repo
2. setup ruby using `.ruby-version`
3. install gems
4. setup postgres service
5. run:


rails db:prepare
bundle exec rspec


OpenAI calls must be mocked in tests.

---

# Security Requirements

Never log:

- email body
- raw payload contents

Always store payload for auditing in `raw_payload`.

---

# Acceptance Criteria

Project is considered complete when:

- `bin/setup` works
- `bin/dev` launches Rails and Sidekiq
- webhook endpoint creates Communication record
- background job processes AI extraction
- tests pass locally and in CI


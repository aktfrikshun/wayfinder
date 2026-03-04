
# WAYFINDER_ARCHITECTURE.md
Purpose: Describe the system architecture for the Wayfinder platform.

---

# System Overview

Wayfinder is a signal detection platform that helps parents navigate their child's development journey.

Core pipeline:

Email → Ingestion → AI Extraction → Timeline Events → Insights → Parent Dashboard

---

# Core Components

## 1. Ingestion Layer

Sources:

- Forwarded school emails
- Uploaded documents
- Parent notes

Services:

- Postmark inbound webhook
- Document upload endpoint
- Parent observation form

---

## 2. Processing Pipeline

1. Raw message stored in `communications`
2. Background job triggered
3. AI extraction service analyzes content
4. Structured signals saved to database

Stack:

- Rails ActiveJob
- Sidekiq
- Redis queue

---

## 3. Data Model

Parent
  └── Children
         └── Communications
                └── Extracted Signals

Additional entities (future):

- Observations
- Assignments
- Grades
- Insights

---

# Timeline Engine

The timeline engine aggregates events chronologically.

Example:

Sept 2025 — Science grade declines  
Oct 2025 — Teacher notes group collaboration issue  
Nov 2025 — Parent logs anxiety before science class

AI Insight:

Possible stress related to collaborative science projects.

---

# AI Layer

Services:

- Email extraction
- Pattern detection
- Weekly digest generation

Future enhancements:

- behavioral trend detection
- emotional signal correlation
- learning style inference

---

# Parent Experience

Parents see:

- Child timeline
- Weekly digest
- Key signals
- Suggested conversation prompts

Goal:

Provide **guidance, not diagnosis**.

---

# Deployment Plan

Prototype phase:

Local Rails server  
Local Postgres  
Redis container

Future cloud deployment:

Fly.io or AWS Fargate

---

# Scaling Plan

Phase 1
Single worker, basic AI extraction

Phase 2
Multiple workers, document parsing

Phase 3
Insight engine + trend detection

---

# Security

Child data must be treated as sensitive.

Practices:

- minimal logging
- encrypted storage for PII
- strict API authentication

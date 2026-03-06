# WAYFINDER_ARTIFACT_PIPELINE_SPEC.md
Version: 0.1  
Purpose: Refactor the Wayfinder backend from a narrow `Communication` model to a generalized `Artifact` pipeline that supports email, uploads, screenshots, PDFs, parent notes, OCR fallback, classification, and future event/insight generation.

---

# Executive Summary

Wayfinder is evolving from a single-ingestion-path MVP:

```text
email -> communication -> extraction -> insight
```

to a generalized ingestion architecture:

```text
artifact -> text extraction -> classification -> normalized event(s) -> insight(s)
```

This change is required because Wayfinder will support multiple artifact sources over time, including:

- forwarded school emails
- uploaded PDFs
- screenshots of grades or test results
- scanned documents
- parent notes
- future system-generated artifacts

The core design principle is:

> **Artifact is the raw source object.**
>  
> **Category is inferred metadata, not the identity of the model.**
>  
> **Events and Insights are downstream interpretations, not the artifact itself.**

---

# Design Goals

1. Replace `Communication` with a more general `Artifact` model.
2. Preserve current email ingestion behavior.
3. Support future uploads and free-form parent-provided documents.
4. Introduce a text extraction pipeline with OCR as a conditional fallback.
5. Keep timeline/event generation separate from raw artifact storage.
6. Make the architecture resilient to unknown artifact shapes without requiring new core tables for every format.

---

# Architectural Recommendation

## Use one core `Artifact` model

Do **not** create separate first-class models yet for:

- EmailArtifact
- PdfArtifact
- ImageArtifact
- ScreenshotArtifact
- DoctorVisitArtifact

Those distinctions should initially be expressed as metadata on the Artifact itself.

This avoids premature fragmentation and keeps the ingestion pipeline unified.

## Separate raw representation from inferred meaning

Artifact should store:

### Raw/source identity
- where the artifact came from
- what media it is
- what text was extracted from it
- original payload / attached file(s)

### Inferred meaning
- what category it appears to belong to
- what tags / signals were extracted
- what timeline events it may create later

This means:

- `source_type` describes origin
- `content_type` describes media/format
- `system_category` describes inferred meaning

---

# High-Level Pipeline

```text
Artifact arrives
→ detect artifact shape
→ choose text extraction strategy
→ attempt native text extraction
→ if insufficient and artifact is image/scanned, run OCR
→ normalize extracted text
→ classify artifact
→ extract structured payload
→ later generate Event(s) and Insight(s)
```

---

# Domain Modeling Guidance

## Artifact = raw source object

Examples:

- forwarded teacher email
- uploaded screenshot of grade portal
- uploaded PDF report card
- uploaded image of doctor visit summary
- parent note about observed anxiety

## Event = normalized timeline item
Examples:

- “Science group collaboration concern”
- “Math worksheet due”
- “Doctor visit summary uploaded”
- “Reading assessment score captured”

## Insight = interpretation across artifacts/events
Examples:

- “Participation concerns are increasingly concentrated in science.”
- “Test performance appears stable while parent-reported stress is increasing.”
- “Recent health-related artifacts may correlate with missed assignments.”

---

# Required Refactor

## Current State
There is a `Communication` model primarily representing inbound emails.

## New State
Replace or supersede `Communication` with a generalized `Artifact` model.

### Recommendation
Implement `Artifact` alongside `Communication`, migrate data, update code paths, and then remove `Communication` when safe.

---

# Artifact Model Specification

Create a new `Artifact` model.

## Table: `artifacts`

Required columns:

- `child_id` : references, required
- `source_type` : string, required
- `content_type` : string, required
- `title` : string, optional
- `source` : string, optional
- `from_email` : string, optional
- `from_name` : string, optional
- `subject` : string, optional

Timing:
- `occurred_at` : datetime, optional
- `captured_at` : datetime, required

Raw content:
- `body_text` : text, optional
- `body_html` : text, optional
- `raw_payload` : jsonb, default `{}`
- `metadata` : jsonb, default `{}`

Text extraction:
- `text_extraction_method` : string, optional
- `processing_state` : string, required, default `"pending"`
- `raw_extracted_text` : text, optional
- `ocr_text` : text, optional
- `normalized_text` : text, optional
- `text_quality_score` : float, optional

AI / classification:
- `system_category` : string, optional
- `user_category` : string, optional
- `category_confidence` : float, optional
- `tags` : jsonb, default `[]`
- `extracted_payload` : jsonb, default `{}`
- `ai_status` : string, required, default `"pending"`
- `ai_raw_response` : jsonb, default `{}`
- `ai_error` : string, optional

Timestamps:
- standard `created_at`, `updated_at`

---

# Enum / Controlled Value Guidance

## source_type
Initial allowed values:

- `email`
- `upload`
- `parent_note`
- `system`

## content_type
Initial allowed values:

- `message`
- `image`
- `pdf`
- `document`
- `mixed`
- `unknown`

## processing_state
Allowed values:

- `pending`
- `detecting`
- `extracting_text`
- `classifying`
- `processed`
- `failed`

## ai_status
Allowed values:

- `pending`
- `processing`
- `complete`
- `failed`

## text_extraction_method
Allowed values:

- `native`
- `ocr`
- `native_plus_ocr`
- `none`

## system_category
Initial suggested values:

- `school_communication`
- `assignment`
- `report_card`
- `assessment_result`
- `health_record`
- `health_observation`
- `parent_observation`
- `behavior_note`
- `social_emotional_signal`
- `administrative_document`
- `other`

Do **not** make category mandatory at creation time.  
Category is often assigned after extraction/classification.

---

# Index Recommendations

Add indexes on:

- `child_id`
- `source_type`
- `content_type`
- `processing_state`
- `ai_status`
- `system_category`
- `occurred_at`
- `captured_at`

Also add:
- GIN index on `tags`
- optional GIN index on `extracted_payload`
- optional GIN index on `metadata`

---

# ActiveStorage

Artifacts should support uploads.

Recommendation:

```ruby
has_many_attached :files
```

Reason:
- Some artifacts may include multiple related files.
- Parents may upload multiple screenshots or a PDF plus image.
- It is more future-friendly than `has_one_attached`.

No upload UI is required in this task, but the model should be ready.

---

# Child Association Changes

Update `Child` to:

```ruby
has_many :artifacts, dependent: :destroy
```

Keep temporary `communications` association only if needed during migration.

---

# Communication → Artifact Migration Strategy

## Goal
Preserve all existing inbound email data while moving the application to Artifact.

## Mapping
For each `Communication`, create one `Artifact`:

- `source_type = "email"`
- `content_type = "message"`
- `title = communication.subject.presence || "Inbound Email"`
- `source = communication.source`
- `from_email = communication.from_email`
- `from_name = communication.from_name`
- `subject = communication.subject`
- `occurred_at = communication.received_at`
- `captured_at = communication.created_at || communication.received_at || Time.current`
- `body_text = communication.body_text`
- `body_html = communication.body_html`
- `raw_payload = communication.raw_payload || {}`
- `extracted_payload = communication.ai_extracted || {}`
- `ai_status = map_old_status`
- `ai_raw_response = communication.ai_raw_response || {}`
- `ai_error = communication.ai_error`
- `system_category = "school_communication"` unless extraction gives something stronger

## Implementation recommendation
- Add `Artifact`
- Add data migration or rake task:
  - `rake wayfinder:migrate_communications_to_artifacts`
- Update reads/writes to use Artifact
- Remove `Communication` only after successful transition and test coverage

---

# Artifact Shape Detection

Before classification, detect the artifact’s basic shape.

Create a service:

```ruby
Artifacts::DetectShape.call(artifact)
```

This service should assign:
- `content_type`
- preliminary metadata
- an initial extraction strategy hint

## Detection rules

### Email-like
If created from webhook or parent note text:
- `content_type = "message"`

### Uploaded PDF
- if MIME type indicates PDF, set `content_type = "pdf"`

### Uploaded image
- if MIME type is image/*, set `content_type = "image"`

### Uploaded textual document
- for DOCX / TXT / etc., set `content_type = "document"`

### Mixed / unknown
- if uncertain, set `content_type = "unknown"` or `mixed`

This step uses:
- MIME type
- filename
- source_type
- presence/absence of text body
- attachment metadata

It should **not** perform deep semantic classification.

---

# Text Extraction Pipeline

## Core Principle

Do **not** OCR first by default.

Instead:

> Use native text extraction when available.  
> Use OCR only as a conditional fallback for image-like or scanned artifacts, or when native text extraction is insufficient.

This yields better quality and lower cost.

---

# Text Extraction Service

Create a dispatcher service:

```ruby
Artifacts::ExtractText.call(artifact)
```

This should route to one of:

- `Extractors::EmailTextExtractor`
- `Extractors::PdfTextExtractor`
- `Extractors::ImageOcrExtractor`
- `Extractors::DocxTextExtractor`
- `Extractors::FallbackExtractor`

---

# Extraction Rules by Artifact Type

## Email
- use `body_text`
- fallback to cleaned `body_html`
- do not OCR

## Parent note
- use provided note text
- do not OCR

## Digital PDF
- try native PDF text extraction first
- if extracted text is sparse or poor quality, run OCR fallback

## Screenshot / image
- OCR first
- then normalize text

## Scanned PDF
- if native extraction yields too little text, OCR fallback

## Unknown binary
- attempt metadata inspection
- if image-like or PDF-like, choose respective extractor
- else store as unsupported / needs review

---

# OCR Fallback Rules

OCR should run if **any** of the following is true:

1. Artifact is `content_type = image`
2. Artifact is `content_type = pdf` and native text extraction returns no meaningful text
3. Extracted text quality falls below threshold
4. Artifact is marked as scanned / screenshot / photo-like by metadata
5. Parent uploaded image-based document

---

# Text Quality Heuristics

Implement a lightweight heuristic service:

```ruby
Artifacts::EvaluateTextQuality.call(text)
```

This may score text based on:

- total text length
- percentage of printable / readable words
- ratio of noise symbols
- presence of dates / numbers / common terms
- number of lines
- whether extracted text looks like OCR garbage

Return:
- `text_quality_score` (0.0–1.0)
- optional flags:
  - `too_short`
  - `too_noisy`
  - `likely_needs_ocr`

Use this to decide whether OCR fallback is needed.

---

# Normalized Text

After extraction, store:

- `raw_extracted_text`
- `ocr_text` if OCR used
- `normalized_text`

## normalized_text
This is the cleaned text used for:
- classification
- AI extraction
- event generation
- insight prompts

Normalization may include:
- whitespace cleanup
- line ending normalization
- removal of repeated headers/footers
- HTML stripping
- basic OCR cleanup

Do **not** aggressively summarize at this stage.

---

# Classification Layer

Classification should happen **after** text extraction.

Create:

```ruby
Artifacts::Classify.call(artifact)
```

Inputs:
- `normalized_text`
- `source_type`
- `content_type`
- metadata
- subject/title if present

Outputs:
- `system_category`
- `category_confidence`
- `tags`
- optional classification metadata in `extracted_payload`

## Important Rule
Category is **inferred metadata**, not the primary type system.

Do not use category to determine low-level file handling.  
Use `content_type` and extraction method for that.

---

# AI Extraction Layer

Create a generic dispatcher:

```ruby
Ai::ExtractArtifact.call(artifact)
```

This service should:
1. inspect artifact source/content
2. route to specialized extractors if needed
3. persist structured output in `extracted_payload`

Recommended internal routes:

- `Ai::ExtractEmailArtifact`
- `Ai::ExtractDocumentArtifact`
- `Ai::ExtractImageArtifact`
- `Ai::ExtractParentNoteArtifact`

All results should still normalize into shared downstream structures.

---

# Suggested Structured Output

Artifact extraction output should be stored in `extracted_payload`.

It may include:

```json
{
  "summary": "string",
  "subject_area": "string|null",
  "signals": [],
  "metrics": [],
  "assignments": [],
  "recommended_next_steps": [],
  "category_rationale": "string|null"
}
```

This is not the same as a timeline Event.  
It is artifact-scoped extraction data.

---

# Event Compatibility

Artifact should **not** become the timeline object.

Artifacts may later generate one or more `WayfinderEvent.v1` records.

For now:
- keep Artifact as the source object
- keep Event generation downstream

Optional future association:

```ruby
has_many :events
```

Do not fully implement unless already needed.

---

# API Changes

Replace Communication-centric APIs with Artifact-centric APIs.

## Add endpoint

```text
GET /children/:id/artifacts
```

Return latest 50 artifacts ordered by:
1. `occurred_at DESC NULLS LAST`
2. `captured_at DESC`

Include:
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
- summary from `extracted_payload` if available

---

# Convenience Methods on Artifact

Implement helper methods:

- `effective_category`
- `email?`
- `upload?`
- `parent_note?`
- `message?`
- `image?`
- `pdf?`
- `document?`
- `categorized?`
- `needs_ocr?`
- `display_title`

## display_title rules
Use:
1. `title` if present
2. `subject` if present
3. humanized effective category if present
4. fallback `"Untitled Artifact"`

---

# Webhook Ingestion Changes

Update inbound email processing to create Artifact, not Communication.

When a Postmark webhook is received, create:

- `source_type = "email"`
- `content_type = "message"`
- `title = subject.presence || "School Email"`
- `source = "postmark"`
- `from_email`
- `from_name`
- `subject`
- `occurred_at = parsed received timestamp if available`
- `captured_at = Time.current`
- `body_text`
- `body_html`
- `raw_payload = full webhook payload`
- `processing_state = "pending"`
- `ai_status = "pending"`

Then enqueue artifact processing job(s).

---

# Background Jobs

Introduce generalized jobs:

## 1. `Artifacts::ProcessArtifactJob`
Responsibilities:
- detect shape
- extract text
- classify artifact
- trigger AI extraction

## 2. Optional split jobs
If preferred, split into:
- `Artifacts::ExtractTextJob`
- `Artifacts::ClassifyJob`
- `Ai::ExtractArtifactJob`

For MVP, one orchestrator job is acceptable if code stays clean.

---

# Processing Flow

Suggested processing sequence:

```text
Artifact created
→ processing_state = detecting
→ detect shape
→ processing_state = extracting_text
→ extract text
→ evaluate text quality
→ OCR fallback if needed
→ processing_state = classifying
→ classify
→ ai_status = processing
→ structured extraction
→ processing_state = processed
→ ai_status = complete
```

On error:
- `processing_state = failed`
- `ai_status = failed`
- `ai_error = message`

---

# Testing Requirements

Add tests for:

## Model
- validations
- enum helpers
- `effective_category`
- `display_title`
- `needs_ocr?`

## Migration
- existing Communication rows migrate into Artifact correctly

## Webhook
- inbound Postmark creates Artifact, not Communication

## Extraction pipeline
- email uses native text extraction
- image triggers OCR path
- PDF tries native text first
- OCR fallback occurs when text quality is too low

## API
- `GET /children/:id/artifacts` returns expected payload

## Background jobs
- processing job updates states correctly
- failure states are persisted

---

# Documentation Updates

Update project docs to reflect:

- `Communication` is deprecated in favor of `Artifact`
- Artifact is the raw source object
- Category is inferred metadata
- OCR is conditional fallback, not default
- Events and Insights remain downstream concepts

Suggested docs to update:
- bootstrap spec
- architecture doc
- event schema doc
- README

---

# Practical Recommendations

## Strong recommendation 1
Do **not** use STI yet.

Avoid:
- `EmailArtifact`
- `PdfArtifact`
- `ImageArtifact`

A single Artifact model is the right starting point.

## Strong recommendation 2
Do **not** use category as identity.

A PDF report card and a screenshot of a report card are different raw artifact types but the same semantic category.

That is exactly why category should be inferred metadata.

## Strong recommendation 3
Keep Event separate from Artifact.

This will save substantial refactoring when timeline generation, insights, and parent chat become richer.

---

# Cursor / Codex Task List

Implement the following:

1. Create `Artifact` model + migration with fields described above.
2. Add ActiveStorage attachments support with `has_many_attached :files`.
3. Update `Child` associations.
4. Add artifact enums/constants/validations/helpers.
5. Build migration path from `Communication` to `Artifact`.
6. Replace inbound email webhook creation logic to create Artifact.
7. Create `Artifacts::DetectShape`.
8. Create `Artifacts::ExtractText` dispatcher + extractor classes.
9. Implement text quality evaluation service.
10. Implement OCR fallback rules.
11. Create `Artifacts::Classify`.
12. Create `Ai::ExtractArtifact` dispatcher.
13. Update API endpoint to `GET /children/:id/artifacts`.
14. Add tests for migration, webhook, extractors, classification, and API.
15. Update docs and README to reflect the Artifact architecture.

---

# End of Spec

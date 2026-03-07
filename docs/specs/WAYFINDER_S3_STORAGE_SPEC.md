# WAYFINDER_S3_STORAGE_SPEC.md
Version: 0.1  
Purpose: Add Codex-ready instructions for storing raw artifact binaries in S3-compatible object storage while storing extracted metadata, processing state, and AI outputs in Postgres.

---

# Executive Summary

Wayfinder should store:

- **raw binaries** in **S3-compatible object storage**
- **queryable metadata** in **Postgres**

This split is recommended because:

- Rails Active Storage is designed to attach files to models and supports Amazon S3 and other cloud backends. citeturn0search0turn0search6
- Fly Volumes are local persistent storage attached to a specific Fly Machine, which makes them a poor default for shared application artifact storage. citeturn0search2turn0search5
- Fly volume pricing is materially higher than S3 storage pricing for the same GB stored. Fly lists volumes at **$0.15/GB-month**, while AWS S3 Standard storage is listed at **$0.023/GB-month** for the first 50 TB/month. citeturn0search11turn0search1

Recommendation:

> Use **Active Storage + S3** for artifact binaries.  
> Use **Postgres** for artifact metadata, extracted text, structured payloads, processing state, and reprocessing version info.

---

# Architectural Decision

## Store in S3 / object storage
Store the following outside Postgres:

- uploaded PDFs
- uploaded screenshots and images
- inbound email attachments
- optional raw inbound MIME email files
- any future parent-uploaded binary records

## Store in Postgres
Store the following in relational tables:

- Artifact row
- source metadata
- file metadata references
- extracted text
- OCR text
- normalized text
- category / tags
- extracted structured JSON
- processing state
- extraction / insight version numbers
- links to child, events, and future insights

---

# Why This Is the Right Choice

## 1. Active Storage already supports this pattern
Rails Active Storage is explicitly designed to attach files to Active Record models and store them in cloud services like Amazon S3. It also supports local disk for development. citeturn0search0turn0search6

## 2. Fly volumes are machine-local
Fly Volumes are attached to a specific Fly Machine and region. They are good for database files and app-local state, but are awkward as shared, durable artifact storage for a multi-process Rails app. citeturn0search2turn0search5

## 3. S3 is significantly cheaper for artifact storage
AWS S3 Standard storage is listed at **$0.023/GB-month** for the first 50 TB/month, while Fly Volumes are listed at **$0.15/GB-month**. citeturn0search1turn0search11

## 4. Reprocessing requires preserving originals
Wayfinder explicitly wants the ability to:
- rerun OCR
- rerun metadata extraction
- rerun insight generation
- reprocess old artifacts with newer prompt versions

That requires preserving the **original binary** artifact separately from any derived text or AI outputs.

---

# Core Design Principle

For every artifact, keep four conceptual layers:

1. **Original binary**
2. **Derived text**
3. **Derived structured metadata**
4. **Derived events / insights**

Do **not** overwrite the original binary when extraction improves.

---

# Codex Task List

Implement the following.

## 1. Configure Active Storage for S3
Set up Rails Active Storage as the file abstraction layer.

Requirements:
- Keep local disk for development/test if helpful
- Add an S3 service for deployed environments
- Artifact model should use:
  ```ruby
  has_many_attached :files
  ```

Update:
- `config/storage.yml`
- environment configs as needed
- any missing Active Storage install/migrations if not already present

## 2. Add S3 environment variable support
Add support for the following environment variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_BUCKET`
- `AWS_ENDPOINT` (optional for S3-compatible providers)
- `AWS_FORCE_PATH_STYLE` (optional for compatibility)
- `ACTIVE_STORAGE_SERVICE` or environment-specific selection

Document how these are set locally and on Fly secrets.

## 3. Keep Artifact metadata in Postgres
Ensure the `Artifact` model stores metadata in Postgres, not the file binary.

Artifact should store:
- `child_id`
- `source_type`
- `content_type`
- `title`
- `subject`
- `occurred_at`
- `captured_at`
- `raw_payload`
- `metadata`
- `body_text`
- `body_html`
- `raw_extracted_text`
- `ocr_text`
- `normalized_text`
- `text_extraction_method`
- `text_quality_score`
- `system_category`
- `user_category`
- `category_confidence`
- `tags`
- `extracted_payload`
- `processing_state`
- `ai_status`
- `ai_raw_response`
- `ai_error`

Do not store large binary files directly in Postgres.

## 4. Add binary/file metadata helpers
Add convenience methods on Artifact to expose file metadata in a stable way.

Examples:
- `primary_file`
- `file_count`
- `file_names`
- `mime_types`
- `total_byte_size`

If helpful, add a JSON serializer that exposes:
- filename
- content_type
- byte_size
- checksum / key if appropriate
- created_at

## 5. Preserve originals for reprocessing
Never overwrite or mutate the original uploaded binary.

All reprocessing should work from:
- attached original file(s)
- optional stored raw MIME email source
- current extraction prompt/version settings

## 6. Add reprocessing version fields
Add versioning fields to Artifact for future reruns:

- `extraction_version` : integer, default 1
- `classification_version` : integer, default 1
- `insight_version` : integer, default 1
- `last_processed_at` : datetime, optional

These fields allow jobs like:
- “Reprocess artifacts where extraction_version < CURRENT_EXTRACTION_VERSION”

## 7. Add optional raw email source preservation
For inbound email artifacts, consider preserving the raw MIME email as a file attachment or in object storage, separate from parsed payload.

Recommended approach:
- attach raw MIME email as a file when available
- keep parsed Postmark payload in `raw_payload`

This will help with:
- replaying parsers
- attachment re-extraction
- debugging email threading and body parsing

## 8. Update artifact pipeline to read binaries from Active Storage
All extraction services should read from Active Storage attachments, not from local filesystem assumptions.

Create or update service interfaces so extractors can operate on:
- attached PDFs
- attached images/screenshots
- optional raw email source files

Examples:
- `Extractors::PdfTextExtractor`
- `Extractors::ImageOcrExtractor`
- `Extractors::DocxTextExtractor`

Each extractor should obtain an IO/Tempfile from Active Storage in a Rails-safe way.

## 9. Add artifact storage key discipline
Use structured object keys or rely on Active Storage defaults, but ensure the system can always find the original binary.

If customizing keys, use a predictable pattern such as:

```text
wayfinder/{environment}/children/{child_id}/artifacts/{artifact_id}/{filename}
```

If not customizing keys, leave Active Storage defaults in place.

Do not block implementation on custom key naming.

## 10. Add cleanup policy safeguards
Do not automatically delete stored binaries when reprocessing or updating metadata.

Only delete files when:
- parent intentionally deletes artifact
- retention policy explicitly removes it
- cascading child deletion is intended

## 11. Add API support for artifact file metadata
Update artifact API responses to include file metadata references, but do not expose raw internal secrets.

For `GET /children/:id/artifacts`, include something like:
- filenames
- mime types
- byte sizes
- attachment count

Signed download URLs can be added later if needed.

## 12. Documentation
Update docs to reflect:
- binary files live in S3-compatible object storage
- extracted metadata lives in Postgres
- Active Storage is the abstraction layer
- Fly volumes are not the default file store for artifacts
- originals are preserved for reruns

---

# Recommended storage.yml shape

Codex should configure `config/storage.yml` with at least:

## development
Use local disk, unless environment explicitly chooses S3.

## test
Use local disk / test storage.

## production
Use S3-compatible service, for example:

```yml
amazon:
  service: S3
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  region: <%= ENV["AWS_REGION"] %>
  bucket: <%= ENV["AWS_BUCKET"] %>
```

Optional support:
- endpoint
- force_path_style

If needed, Codex can implement provider-neutral S3-compatible configuration.

---

# Fly.io Notes

## Do not use Fly volumes as the primary artifact store
Reason:
- machine-local storage
- awkward with multiple processes and scaling
- higher storage cost than S3
- not ideal for durable shared file storage citeturn0search2turn0search5turn0search11

## Use Fly secrets for S3 credentials
Example:
```bash
fly secrets set AWS_ACCESS_KEY_ID=...
fly secrets set AWS_SECRET_ACCESS_KEY=...
fly secrets set AWS_REGION=us-east-1
fly secrets set AWS_BUCKET=wayfinder-artifacts
```

Optional:
```bash
fly secrets set AWS_ENDPOINT=...
fly secrets set AWS_FORCE_PATH_STYLE=true
```

---

# Suggested Artifact Model Additions

If not already present, add:

- `extraction_version : integer, default: 1, null: false`
- `classification_version : integer, default: 1, null: false`
- `insight_version : integer, default: 1, null: false`
- `last_processed_at : datetime`

These complement Active Storage and help manage reruns.

---

# Reprocessing Workflow Recommendation

When artifact processing is improved:

1. fetch artifact row from Postgres
2. load original attached file(s) from Active Storage
3. rerun extraction / OCR / classification
4. update:
   - `raw_extracted_text`
   - `ocr_text`
   - `normalized_text`
   - `extracted_payload`
   - `system_category`
   - version fields
   - `last_processed_at`
5. preserve original file attachment unchanged

This workflow is a major reason to keep binaries outside Postgres and preserved in object storage.

---

# Testing Requirements

Add tests for:

## Active Storage
- Artifact can attach files
- Artifact persists and reloads attached files correctly

## Metadata separation
- large file content is not stored in custom Postgres columns
- extracted metadata is stored in Artifact fields/jsonb

## Reprocessing
- rerunning extraction updates metadata/version fields
- original file remains attached and unchanged

## API
- artifact listing returns expected file metadata
- API does not require local filesystem assumptions

---

# Codex Deliverables

Implement all of the following:

1. Configure Active Storage for S3-compatible storage.
2. Update environment configuration for local/test/prod storage selection.
3. Ensure Artifact uses `has_many_attached :files`.
4. Add versioning fields for extraction/classification/insight reruns.
5. Update extractors to read from Active Storage attachments.
6. Preserve original binaries for reruns.
7. Update serializers/API endpoints to expose artifact file metadata.
8. Document Fly secret setup and environment configuration.
9. Update docs to explain: binaries in S3, metadata in Postgres.
10. Add tests covering attachment persistence, reprocessing, and API behavior.

---

# Final Recommendation

Wayfinder should use:

- **S3-compatible object storage** for original binaries
- **Postgres** for metadata, extracted text, structured JSON, categories, and processing state
- **Active Storage** as the Rails abstraction layer

This is the cleanest, cheapest, and most future-proof buildout path for:
- uploads
- email attachments
- OCR reruns
- prompt evolution
- insight reprocessing

---

# End of Spec

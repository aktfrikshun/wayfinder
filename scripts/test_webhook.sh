#!/usr/bin/env bash
set -euo pipefail

curl -sS -X POST "http://localhost:3000/webhooks/postmark/inbound" \
  -H "Content-Type: application/json" \
  -H "X-Postmark-Webhook-Token: ${POSTMARK_WEBHOOK_SECRET:-changeme}" \
  -d '{
    "From": "teacher@example.org",
    "FromName": "Ms. Carter",
    "Subject": "Math homework this week",
    "Date": "2026-03-04T12:00:00Z",
    "ToFull": [{"Email": "zammy@inbound.wayfinder.local"}],
    "TextBody": "Zammy should complete fractions worksheet by Friday.",
    "HtmlBody": "<p>Zammy should complete fractions worksheet by Friday.</p>"
  }'

echo

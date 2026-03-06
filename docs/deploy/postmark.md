# Postmark Setup (Send + Webhooks)

This runbook configures Wayfinder to send invitation emails and receive Postmark webhook notifications.

## 1. Create Postmark Server + Streams

1. Sign in to Postmark and create/select a server.
2. Ensure you have an outbound message stream (default: `outbound`).
3. (Recommended) Create an inbound stream if you want inbound parsing in Postmark.

## 2. Domain + Sender

1. Verify your sending domain in Postmark.
2. Use a sender like `wayfinder@frikshun.com`.

## 3. Configure Fly secrets

Set application secrets for `wayfinder-frikshun`:

```bash
FLY_CONFIG_DIR=.fly fly secrets set -a wayfinder-frikshun \
  POSTMARK_API_TOKEN="<postmark-server-api-token>" \
  POSTMARK_MESSAGE_STREAM="outbound" \
  MAIL_FROM="wayfinder@frikshun.com" \
  POSTMARK_WEBHOOK_SECRET="<inbound-webhook-token>" \
  POSTMARK_EVENTS_WEBHOOK_SECRET="<events-webhook-token>"
```

## 4. Configure Postmark webhooks

### Inbound webhook

- URL: `https://wayfinder.frikshun.com/webhooks/postmark/inbound`
- Auth header token: `POSTMARK_WEBHOOK_SECRET`

### Event webhook (delivery/bounce/open/etc)

- URL: `https://wayfinder.frikshun.com/webhooks/postmark/events`
- Auth header token: `POSTMARK_EVENTS_WEBHOOK_SECRET`

Wayfinder stores event payloads in `postmark_events`.

## 5. Verify sending

Invite a family member from parent dashboard:

- Parent Dashboard -> `Family Invitations` -> `Send Invite`

This creates a user with temporary password and sends an email via Postmark.

## 6. Verify inbound + events

1. Send test email into your inbound route.
2. Confirm inbound processing by checking artifacts/communications.
3. Confirm event ingestion:

```bash
FLY_CONFIG_DIR=.fly fly ssh console -a wayfinder-frikshun -C "sh -lc 'cd /rails && bundle exec rails runner \"puts PostmarkEvent.order(created_at: :desc).limit(5).pluck(:event_type, :recipient).inspect\"'"
```

## Notes

- Invited users are created with `must_change_password=true`.
- First login is blocked until password is changed.
- Public self-signup remains parent-only by default role behavior.

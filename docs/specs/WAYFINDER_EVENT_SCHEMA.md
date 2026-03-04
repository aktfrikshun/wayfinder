
# WAYFINDER_EVENT_SCHEMA.md
Version: 0.1
Purpose: Define the canonical, stable event and signal schema used across Wayfinder for:
- timeline display
- pattern detection
- weekly digests
- future analytics and insights

This schema prevents “JSON soup” by enforcing consistent types, fields, and enums.

---

# Core Concepts

## Event
An **Event** is a time-stamped, parent-facing record derived from:
- a school email (Communication)
- a document (report card, evaluation, PDF)
- a parent observation note

Events are shown on the child’s **timeline**.

## Signal
A **Signal** is a structured finding inside an Event. One Event can contain multiple Signals.
Signals include confidence scores and optional “severity” to help prioritize follow-up.

Wayfinder provides **guidance, not diagnosis**.
Signals should never claim medical or psychological diagnoses.

---

# Canonical Event Schema

All event payloads stored in the DB (and returned by APIs) should conform to:

## `WayfinderEvent.v1`

```json
{
  "schema_version": "WayfinderEvent.v1",
  "event_id": "string",
  "child_id": "string",
  "source": {
    "source_type": "email|document|parent_note|system",
    "source_id": "string|null",
    "provider": "postmark|upload|manual|other|null"
  },
  "occurred_at": "YYYY-MM-DDTHH:MM:SSZ",
  "captured_at": "YYYY-MM-DDTHH:MM:SSZ",
  "title": "string",
  "summary": "string",
  "domain": "academic|social|emotional|behavioral|logistics|health_related|other",
  "subject_area": "string|null",
  "location_context": "classroom|home|school_event|online|unknown",
  "participants": [
    {
      "role": "child|teacher|parent|peer|counselor|administrator|unknown",
      "name": "string|null"
    }
  ],
  "signals": [
    {
      "signal_id": "string",
      "type": "string",
      "description": "string",
      "confidence": 0.0,
      "severity": "low|medium|high",
      "evidence": {
        "highlights": ["string"],
        "why": "string|null"
      },
      "recommended_next_steps": [
        {
          "audience": "parent|parent_and_child|parent_and_teacher|teacher|counselor",
          "text": "string"
        }
      ],
      "follow_up_questions": ["string"]
    }
  ],
  "actions": [
    {
      "action_type": "assignment|meeting|form|reminder|check_in|other",
      "title": "string",
      "due_date": "YYYY-MM-DD|null",
      "details": "string|null"
    }
  ],
  "tags": ["string"],
  "priority": "low|medium|high",
  "sentiment": "positive|neutral|negative",
  "needs_follow_up": "yes|no"
}
```

Notes:
- `occurred_at` is when the underlying event happened (often equals email received time for emails).
- `captured_at` is when Wayfinder ingested it.
- `domain` is the primary timeline category.
- `signals.type` uses a controlled vocabulary below.
- `evidence.highlights` should be short paraphrases, not long quotes.

---

# Controlled Vocabulary

## Domains
- `academic`: performance, achievement, mastery, study habits
- `social`: peers, group work, friendships, bullying/peer conflict signals (without labeling)
- `emotional`: stress signals, mood cues, anxiety-like cues (no diagnosis)
- `behavioral`: attention, disruptions, compliance, focus, participation behaviors
- `logistics`: schedule, forms, events, reminders, permission slips
- `health_related`: non-diagnostic references (e.g., “nurse visit”, “stomach ache reported”)
- `other`: anything else

## Location Context
- `classroom`
- `home`
- `school_event`
- `online`
- `unknown`

## Participants Roles
- `child`
- `teacher`
- `parent`
- `peer`
- `counselor`
- `administrator`
- `unknown`

## Priority
- `low`: informational, no immediate action
- `medium`: notable, worth check-in
- `high`: urgent action recommended (meeting, deadline, repeated serious concern)

## Severity (per signal)
- `low`: mild concern or positive development
- `medium`: repeated or impactful concern
- `high`: strongly concerning language, repeated patterns, or explicit requests to intervene

---

# Signal Types (Recommended Enum Set)

Signals should set `type` to one of these whenever possible:

## Academic
- `grade_change`
- `missing_work`
- `assignment_deadline`
- `quiz_test`
- `concept_struggle`
- `study_habit`
- `positive_progress`

## Participation / Behavior
- `participation_change`
- `focus_attention`
- `classroom_disruption`
- `organization_planning`
- `behavior_note`
- `positive_behavior`

## Social
- `group_collaboration`
- `peer_conflict_signal`
- `social_withdrawal_signal`
- `leadership_teamwork`
- `friendship_support`

## Emotional
- `stress_signal`
- `confidence_signal`
- `avoidance_signal`
- `mood_shift_signal`
- `self_advocacy_signal`

## Logistics / Requests
- `teacher_request`
- `meeting_request`
- `form_required`
- `schedule_change`
- `event_announcement`

## Health-related (non-diagnostic)
- `nurse_visit`
- `somatic_complaint_reported`

## Fallback
- `other`

---

# Normalization Rules

1) Prefer a single **primary domain** per Event.
   - If multiple domains exist, choose the most parent-relevant domain and add others as tags.

2) Use short, parent-friendly titles.
   - “Science: group collaboration concern”
   - “Math: worksheet due”
   - “Reading: focus challenge noted”

3) Actions vs Signals
   - Use **actions** for tasks with dates (assignments, forms, meetings).
   - Use **signals** for observations and concerns.

4) Evidence
   - Evidence highlights should be short, paraphrased cues.
   - Do not include full email text.

5) Confidence vs Severity
   - Confidence: how clearly the source supports the signal.
   - Severity: how important it seems for follow-up.

---

# Mapping from `SchoolEmailExtraction.v1`

If using the existing extraction schema from WAYFINDER_AI_PROMPTS.md:

- `summary` -> Event.summary
- `subject_area` -> Event.subject_area
- `assignments[]` -> Event.actions[] (action_type: assignment)
- `signals[]` -> Event.signals[]
- `priority` -> Event.priority
- `sentiment` -> Event.sentiment
- `needs_follow_up` -> Event.needs_follow_up

Recommended transformation:
- One `Communication` can produce **1 Event** with multiple signals/actions.
- Later, you can split into multiple Events if needed, but start simple.

---

# Example Events

## Example A: Logistics + Assignment

```json
{
  "schema_version": "WayfinderEvent.v1",
  "event_id": "evt_001",
  "child_id": "child_123",
  "source": { "source_type": "email", "source_id": "comm_456", "provider": "postmark" },
  "occurred_at": "2026-03-04T15:30:00Z",
  "captured_at": "2026-03-04T15:31:10Z",
  "title": "Math: worksheet due",
  "summary": "Reminder that a Chapter 6 math worksheet is due soon.",
  "domain": "academic",
  "subject_area": "Math",
  "location_context": "classroom",
  "participants": [{ "role": "teacher", "name": "Mrs. Carter" }],
  "signals": [],
  "actions": [
    { "action_type": "assignment", "title": "Chapter 6 Worksheet", "due_date": null, "details": "Complete problems 1–20." }
  ],
  "tags": ["homework"],
  "priority": "low",
  "sentiment": "neutral",
  "needs_follow_up": "no"
}
```

## Example B: Social signal

```json
{
  "schema_version": "WayfinderEvent.v1",
  "event_id": "evt_002",
  "child_id": "child_123",
  "source": { "source_type": "email", "source_id": "comm_789", "provider": "postmark" },
  "occurred_at": "2026-03-03T18:10:00Z",
  "captured_at": "2026-03-03T18:10:30Z",
  "title": "Science: group collaboration concern",
  "summary": "Teacher notes discomfort during group work in science.",
  "domain": "social",
  "subject_area": "Science",
  "location_context": "classroom",
  "participants": [{ "role": "teacher", "name": null }],
  "signals": [
    {
      "signal_id": "sig_001",
      "type": "group_collaboration",
      "description": "May be finding group collaboration or presenting ideas uncomfortable.",
      "confidence": 0.72,
      "severity": "medium",
      "evidence": { "highlights": ["Teacher noted discomfort during group project"], "why": "The email explicitly mentions discomfort in group work." },
      "recommended_next_steps": [
        { "audience": "parent_and_child", "text": "Ask which part of group work feels hardest: sharing ideas, roles, or presenting." },
        { "audience": "parent_and_teacher", "text": "Ask the teacher what situations seem to trigger discomfort and what support helps." }
      ],
      "follow_up_questions": ["Is this happening in other classes too?", "Is it tied to specific classmates or presenting in general?"]
    }
  ],
  "actions": [],
  "tags": ["collaboration"],
  "priority": "medium",
  "sentiment": "neutral",
  "needs_follow_up": "yes"
}
```

---

# Implementation Notes (Rails)

Recommended storage approach in the MVP:

- Keep canonical event JSON in `communications.ai_extracted` initially, OR
- Add a new `events` table later (preferred once UI starts depending on it)

If adding `events` table, suggested columns:
- child_id (fk)
- occurred_at (datetime)
- title (string)
- domain (string)
- subject_area (string)
- payload (jsonb)  # full WayfinderEvent.v1 JSON
- source_type, source_id (polymorphic-ish fields)
- priority (string)
- sentiment (string)

---

# End of Spec

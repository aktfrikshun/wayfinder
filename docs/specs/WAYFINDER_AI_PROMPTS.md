
# WAYFINDER_AI_PROMPTS.md
Version: 0.1
Purpose: Provide Codex (and the Rails app) with ready-to-use prompt templates, schemas, and examples to accelerate Wayfinder’s AI extraction and insight pipeline.

---

# Guiding Principles

## 1) Direction, not certainty
Wayfinder is a guide through the unknown. Outputs should:
- highlight signals and patterns
- provide gentle, actionable suggestions
- avoid overconfident diagnoses

## 2) Structured outputs first
All extraction tasks must return valid JSON matching the schemas below.

## 3) Privacy and safety
- Do NOT output full email bodies.
- Do NOT infer medical diagnoses or mental health conditions.
- Use cautious language: “may indicate”, “possible”, “worth checking”.

## 4) Auditability
Every AI call should be stored as:
- input summary (safe)
- raw model response
- parsed structured JSON
- parse errors (if any)

---

# Model and Request Settings

Recommended defaults (tune later):

Model: OPENAI_MODEL (default gpt-4.1-mini)  
Temperature: 0.2 for extraction tasks  
Max tokens: 800–1200  
Timeout: 30 seconds  
Retries: 2 on transient failures (429/5xx)

---

# Standard Output Conventions

## Confidence
Numeric value between 0.0 and 1.0 representing signal strength in the source material.

## Dates
Use ISO format: YYYY-MM-DD

If unknown, return null.

## Categories
Preferred signal types:

- academic_performance
- assignment_deadline
- participation
- behavior
- social_dynamic
- emotional_wellbeing
- attendance
- teacher_request
- logistics
- positive_feedback
- other

---

# Prompt Pack Index

1. Email-to-Event Extraction (MVP core)
2. Assignment/Deadline Extraction
3. Concern & Signal Extraction
4. Weekly Digest Generator
5. Timeline Synthesis Summary
6. Parent Conversation Starters
7. JSON Repair Strategy

MVP only requires #1 and #4.

---

# 1) Email-to-Event Extraction

Goal:
Convert a school email into structured timeline signals.

Input fields:

child_name  
grade  
school_name  
email_subject  
from_name  
from_email  
received_at  
body_text  

---

## Output Schema: SchoolEmailExtraction.v1

{
  "schema_version": "SchoolEmailExtraction.v1",
  "summary": "string",
  "subject_area": "string|null",
  "concerns": ["string"],
  "assignments": [
    {
      "title": "string",
      "due_date": "YYYY-MM-DD|null",
      "details": "string|null"
    }
  ],
  "signals": [
    {
      "type": "string",
      "description": "string",
      "confidence": 0.0
    }
  ],
  "sentiment": "positive|neutral|negative",
  "priority": "low|medium|high",
  "recommended_next_steps": [
    {
      "audience": "parent|parent_and_child|parent_and_teacher",
      "text": "string"
    }
  ],
  "needs_follow_up": "yes|no",
  "follow_up_questions": ["string"]
}

---

## System Prompt

You are Wayfinder, an assistant that extracts structured educational and developmental signals from school communications for parents.

Return ONLY valid JSON matching the provided schema.

Avoid diagnoses and avoid copying long passages of email text.

---

## User Prompt Template

Extract structured information for a parent dashboard.

Child context:
child_name: {{child_name}}
grade: {{grade}}
school_name: {{school_name}}

Email metadata:
received_at: {{received_at}}
from_name: {{from_name}}
from_email: {{from_email}}
subject: {{email_subject}}

Email body:
{{body_text}}

Output JSON matching SchoolEmailExtraction.v1.

---

# 2) Assignment Extraction

Schema:

{
  "schema_version": "AssignmentsOnly.v1",
  "assignments": [
    {
      "title": "string",
      "due_date": "YYYY-MM-DD|null",
      "details": "string|null"
    }
  ]
}

Prompt:

Extract assignments and deadlines from the following email.

Subject:
{{email_subject}}

Body:
{{body_text}}

Return JSON only.

---

# 3) Signal Extraction

Schema:

{
  "schema_version": "SignalsOnly.v1",
  "concerns": ["string"],
  "signals": [
    {
      "type": "string",
      "description": "string",
      "confidence": 0.0
    }
  ],
  "priority": "low|medium|high"
}

Prompt:

Extract concerns or developmental signals.

Child: {{child_name}}

Subject:
{{email_subject}}

Body:
{{body_text}}

Return JSON matching SignalsOnly.v1.

---

# 4) Weekly Digest Generator

Purpose:
Summarize weekly activity for parents.

Schema:

{
  "schema_version": "WeeklyDigest.v1",
  "headline": "string",
  "high_priority_items": ["string"],
  "upcoming_deadlines": [
    {
      "title": "string",
      "due_date": "YYYY-MM-DD|null",
      "details": "string|null"
    }
  ],
  "themes": ["string"],
  "suggested_actions": ["string"],
  "questions_to_ask": ["string"]
}

Prompt:

Create a weekly digest for a parent.

Child: {{child_name}}

Week: {{week_start}} to {{week_end}}

Items:
{{items_json}}

Highlight key events, deadlines, and provide 1-3 suggestions.

Return JSON only.

---

# 5) Timeline Summary

Schema:

{
  "schema_version": "TimelineSummary.v1",
  "notable_trends": ["string"],
  "recurring_signals": [
    {
      "type": "string",
      "description": "string",
      "count": 0
    }
  ],
  "areas_of_strength": ["string"],
  "areas_to_watch": ["string"],
  "recommended_check_ins": ["string"]
}

Prompt:

Analyze events across a time range and summarize patterns.

Return JSON only.

---

# 6) Parent Conversation Starters

Schema:

{
  "schema_version": "ConversationStarters.v1",
  "starters": [
    {
      "topic": "string",
      "starter": "string",
      "tone": "curious|supportive|problem_solving"
    }
  ]
}

Prompt:

Generate gentle conversation starters a parent can use with their child.

Return JSON only.

---

# 7) JSON Repair Strategy

If model output fails JSON parsing:

System Prompt:
You are a JSON repair tool. Return ONLY valid JSON.

User Prompt:

The following text should be valid JSON but is not.

Fix it.

{{raw_text}}

---

# MVP Implementation Notes

Start with:

1) Email Extraction  
2) Weekly Digest

Everything else can be added later.


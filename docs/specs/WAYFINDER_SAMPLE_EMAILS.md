
# WAYFINDER_SAMPLE_EMAILS.md
Purpose: Provide realistic school communication examples and expected AI extraction outputs for development and testing.

---

## Example 1 — Assignment Reminder

Subject: Math Homework Due Tomorrow

Body:
Hello Parents,

Just a reminder that the Chapter 6 math worksheet is due tomorrow. Students should complete problems 1–20 and bring the worksheet to class.

Thanks,
Mrs. Carter

Expected Extraction (simplified):

{
  "summary": "Reminder that Chapter 6 math worksheet is due tomorrow.",
  "subject_area": "Math",
  "assignments": [
    {
      "title": "Chapter 6 Worksheet",
      "due_date": null,
      "details": "Complete problems 1–20."
    }
  ],
  "signals": [],
  "sentiment": "neutral",
  "priority": "low"
}

---

## Example 2 — Positive Feedback

Subject: Great participation today

Body:
Zammy did a wonderful job participating in today's science discussion and shared thoughtful ideas with the class.

Expected Extraction:

{
  "summary": "Teacher praised Zammy for strong participation in science discussion.",
  "subject_area": "Science",
  "concerns": [],
  "signals": [
    {
      "type": "positive_feedback",
      "description": "Strong participation and idea sharing during class discussion.",
      "confidence": 0.85
    }
  ],
  "sentiment": "positive",
  "priority": "low"
}

---

## Example 3 — Social Challenge

Subject: Group project update

Body:
Zammy seemed a little uncomfortable working with his group today during the history project. We will keep encouraging collaboration.

Expected Extraction:

{
  "summary": "Teacher noted discomfort during group collaboration.",
  "subject_area": "History",
  "concerns": ["Difficulty with group collaboration"],
  "signals": [
    {
      "type": "social_dynamic",
      "description": "Possible discomfort working in collaborative group settings.",
      "confidence": 0.7
    }
  ],
  "sentiment": "neutral",
  "priority": "medium"
}

---

## Example 4 — Behavior Note

Subject: Classroom focus

Body:
Zammy had some difficulty staying focused during independent reading today. We'll continue working on strategies to help him stay engaged.

Expected Extraction:

{
  "summary": "Teacher reports focus challenges during reading.",
  "subject_area": "Reading",
  "concerns": ["Difficulty maintaining focus"],
  "signals": [
    {
      "type": "behavior",
      "description": "Possible attention challenges during independent tasks.",
      "confidence": 0.65
    }
  ],
  "sentiment": "neutral",
  "priority": "medium"
}

---

## Example 5 — Schedule Change

Subject: Field trip permission slip

Body:
Please remember to sign and return the field trip permission slip for next week's museum visit.

Expected Extraction:

{
  "summary": "Reminder to return permission slip for upcoming field trip.",
  "assignments": [
    {
      "title": "Field Trip Permission Slip",
      "due_date": null,
      "details": "Return signed permission form."
    }
  ],
  "signals": [],
  "sentiment": "neutral",
  "priority": "low"
}

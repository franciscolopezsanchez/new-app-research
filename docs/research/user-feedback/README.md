# User Feedback — Parents & Families

This folder stores qualitative feedback from parents and family members who have used school-parent communication apps. Each file is one person's feedback.

**Purpose:** Feed into persona refinement. Agents working on personas should read all files in this folder before updating `/docs/product/user-personas.md`.

---

## Folder Structure

```
user-feedback/
├── README.md              ← this file
├── template.md            ← copy this for each new entry
├── synthesis.md           ← aggregated themes (update as entries accumulate)
└── entries/
    └── [initials]-[date].md   e.g. ml-2026-04-03.md
```

---

## How to Add a New Entry

1. Copy `template.md` into `entries/`
2. Name it `[initials]-[YYYY-MM-DD].md` (use initials only — no full names)
3. Fill in all fields you have. Leave unknown fields blank rather than guessing.
4. Update `synthesis.md` with any new themes or quotes worth surfacing.

---

## How Agents Should Use This Folder

When updating personas in `/docs/product/user-personas.md`, agents should:

1. Read all files in `entries/`
2. Look for patterns across: pain points, features used most, features ignored, emotional moments, and competitor apps mentioned
3. Update persona sections: **Goals**, **Frustrations**, **Behaviors**, and **Key Quotes**
4. Cross-reference with director call logs — parent pain ≠ director pain, but they are related

The persona file has three parent profiles (Sofia and Alejandro are the primary ones). Feedback here should sharpen those profiles with real behavioral data, not replace the structural framing.

---

## Signal Tags (use in entries to make synthesis easier)

| Tag | Meaning |
|-----|---------|
| `#pain` | A clear frustration or friction point |
| `#delight` | Something they genuinely loved |
| `#ignored` | A feature they never used |
| `#competitor` | Mentions a specific app by name |
| `#privacy` | Any mention of data, photos, or GDPR concern |
| `#adoption` | Difficulty getting started or convincing the school |
| `#habit` | Describes a recurring usage pattern |
| `#quote` | A verbatim quote worth keeping for personas or marketing |

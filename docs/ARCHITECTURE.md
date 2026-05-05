# Teaching Genome - Architecture & Design

## Core Principles
- **Lecturer owns their craft**: Each lecturer's course genome is private, never shared
- **Lecturer approves everything**: No auto-publish; all AI output requires review before use
- **Weekly reflection drives improvement**: Feedback → instant updates to remaining weeks
- **Persistent memory**: Course evolution is saved forever for next iteration

---

## 1. Data Model (Supabase)

### Tables

#### `lecturers`
```
id (UUID, PK)
name TEXT
email TEXT (unique)
institution TEXT
created_at TIMESTAMPTZ
```

#### `courses`
```
id (UUID, PK)
lecturer_id (UUID, FK)
module_code TEXT
module_name TEXT
module_descriptor_pdf_url TEXT (stored in bucket)
cohort_type TEXT (e.g., "first-year nursing", "final-year business")
preferences JSONB {
  teaching_style: "case_studies" | "lectures" | "simulations" | "mixed",
  pace: "fast" | "moderate" | "slow",
  assessment_type: "exams" | "projects" | "continuous" | "mixed"
}
academic_year TEXT (e.g., "2024-2025")
semester TEXT ("Spring" | "Fall" | "Summer")
status TEXT ("draft" | "ready" | "in_progress" | "completed")
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

#### `weeks`
```
id (UUID, PK)
course_id (UUID, FK)
week_number INT (1-14)
topic TEXT
learning_objectives JSONB (array of strings)
teaching_methods JSONB (array of objects)
  - method (lecture, workshop, simulation, debate, case_study)
  - duration_minutes INT
  - resources ARRAY[TEXT]
content_summary TEXT
powerpoint_url TEXT (stored in bucket)
status TEXT ("draft" | "pending_review" | "approved" | "taught")
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

#### `feedback_journals`
```
id (UUID, PK)
course_id (UUID, FK)
week_number INT
lecturer_reflection TEXT (raw, plain text)
sentiment_score FLOAT (-1 to 1)
key_issues JSONB (auto-extracted by AI)
  - concept_struggles (array)
  - timing_issues (array)
  - engagement_notes (array)
  - student_feedback (array)
status TEXT ("submitted" | "processed" | "applied")
created_at TIMESTAMPTZ
processed_at TIMESTAMPTZ
```

#### `week_adjustments`
```
id (UUID, PK)
course_id (UUID, FK)
feedback_journal_id (UUID, FK)
affected_weeks INT[] (which future weeks were changed)
adjustments_made JSONB {
  reordered_topics: [week_numbers],
  added_review_session: BOOLEAN,
  replaced_examples: [descriptions],
  changed_pace: old_value → new_value
}
applied_at TIMESTAMPTZ
```

#### `course_reflections`
```
id (UUID, PK)
course_id (UUID, FK)
reflection_text TEXT (end-of-semester summary)
created_at TIMESTAMPTZ
status TEXT ("submitted" | "processed")
```

#### `evolution_suggestions`
```
id (UUID, PK)
course_id (UUID, FK)
course_reflection_id (UUID, FK)
suggestion TEXT
category TEXT ("reorder", "remove", "swap_method", "add_activity", "timeline_adjustment")
affected_weeks INT[]
confidence_score FLOAT (0-1, how confident AI is in suggestion)
status TEXT ("pending" | "approved" | "rejected" | "applied")
lecturer_notes TEXT
approved_at TIMESTAMPTZ
```

---

## 2. N8N Workflows

### **Workflow 1: Initial Course Genome Generation**
**Trigger**: Lecturer uploads PDF descriptor

**Steps**:
1. Webhook receives PDF + lecturer context
2. Extract PDF content (text, structure, learning objectives)
3. Call Claude API to generate 14-week breakdown with pedagogical methods
4. For each week, call Claude + DALL-E to generate:
   - Teaching notes
   - Discussion prompts
   - Activity ideas
   - Suggested images/diagrams (DALL-E prompts)
5. Generate PowerPoint .pptx for each week (using library)
6. Store all outputs in Supabase
7. Set status to "pending_review" (lecturer approval gate)
8. Return to lecturer: "Your 14-week plan is ready for review"

---

### **Workflow 2: Weekly Feedback Processing**
**Trigger**: Lecturer submits weekly reflection

**Steps**:
1. Webhook receives raw reflection text
2. Parse reflection for key issues (use Claude to extract):
   - Concepts students struggled with
   - Timing/pacing problems
   - Engagement observations
   - Examples that didn't land
3. Store in `feedback_journals` table
4. Call Claude to generate **adjustments** for weeks 3-14:
   - Should we add a review session?
   - Which future topics need reordering?
   - What analogies/examples should change?
   - Reorder topics if needed
5. Regenerate affected weeks' PowerPoints
6. Store adjustments in `week_adjustments`
7. Return to lecturer: "Weeks 4-8 have been updated. Review changes?"

---

### **Workflow 3: End-of-Semester Evolution**
**Trigger**: Lecturer submits final semester reflection

**Steps**:
1. Receive full reflection text
2. Call Claude to extract themes:
   - What worked well?
   - What was too dense?
   - Topic ordering issues?
   - Method suggestions?
3. Generate **Evolution Suggestions** document with:
   - "Remove topic X from week 3" (with confidence %)
   - "Move chapter 7 before chapter 5"
   - "Replace method Y with Z for week 6"
4. Store suggestions in `evolution_suggestions` (status: pending)
5. Present to lecturer for approval
6. Once approved, mark as "to apply next time"

---

### **Workflow 4: Course Initialization (Next Iteration)**
**Trigger**: Lecturer starts new iteration of same course (next year/semester)

**Steps**:
1. Load previous course genome
2. Apply all "approved" evolution suggestions
3. Regenerate affected weeks
4. Present updated plan to lecturer
5. Lecturer reviews and unlocks for new semester

---

## 3. MCP Tool Interface

### Tools to expose:

1. **`upload_module_descriptor`**
   - Input: PDF file, lecturer_id, cohort_type, preferences
   - Output: course_id, workflow_start_confirmation
   - Action: Starts Workflow 1 (genome generation)

2. **`get_course_plan`**
   - Input: course_id
   - Output: Full 14-week plan with all week details
   - No side effects; read-only

3. **`get_week_details`**
   - Input: course_id, week_number
   - Output: Week plan, resources, PowerPoint URL, teaching notes
   - Read-only

4. **`submit_weekly_feedback`**
   - Input: course_id, week_number, reflection_text
   - Output: Feedback submission confirmation, list of weeks that will change
   - Action: Starts Workflow 2 (feedback processing)

5. **`review_and_approve_week_updates`**
   - Input: course_id, week_number, approved (true/false), lecturer_notes
   - Output: Update confirmation, affected weeks regenerated
   - Action: Marks feedback as "applied", regenerates PowerPoints

6. **`download_week_powerpoint`**
   - Input: course_id, week_number
   - Output: .pptx file (downloadable)
   - Read-only

7. **`submit_semester_reflection`**
   - Input: course_id, reflection_text
   - Output: Confirmation, list of evolution suggestions
   - Action: Starts Workflow 3 (evolution generation)

8. **`review_evolution_suggestions`**
   - Input: course_id, suggestions with accept/reject/modify for each
   - Output: Confirmation of approved suggestions
   - Action: Marks suggestions as approved, ready for next iteration

9. **`list_lecturers_courses`**
   - Input: lecturer_id
   - Output: Array of all courses (with status)
   - Read-only

10. **`start_new_iteration`**
    - Input: course_id (of previous iteration)
    - Output: new_course_id, plan with suggested improvements
    - Action: Starts Workflow 4, creates new course with evolution applied

---

## 4. API Endpoints (Next.js)

- `POST /api/courses` - Upload descriptor → trigger Workflow 1
- `GET /api/courses/:id` - Get full course plan
- `GET /api/courses/:id/weeks/:week` - Get specific week
- `POST /api/courses/:id/feedback` - Submit weekly feedback → Workflow 2
- `POST /api/courses/:id/reflection` - Submit semester reflection → Workflow 3
- `GET /api/courses/:id/weeks/:week/powerpoint` - Download PowerPoint
- `POST /api/courses/:id/approve-suggestions` - Approve evolution suggestions

---

## 5. AI Model Choice

**Recommendation**: Claude 3.5 Sonnet
- **Why**: Best for long-form generation, reasoning, and pedagogical understanding
- **Cost**: ~$0.003/1K tokens (cheaper than GPT-4)
- **Performance**: Superior at understanding nuance in teaching contexts
- **Alternative**: Mix Claude (reflection analysis) + DALL-E 3 (image generation)

---

## 6. Sequence: User Journey

```
1. Lecturer uploads PDF + preferences
   ↓
2. System generates 14-week genome
   ↓
3. Lecturer reviews; approves or requests changes
   ↓
4. Every week (after teaching):
   - Lecturer writes 2-3 sentence reflection
   - System updates remaining weeks
   - Lecturer reviews/approves changes
   ↓
5. End of semester:
   - Lecturer writes final reflection
   - System proposes evolution suggestions
   - Lecturer approves changes for next year
   ↓
6. Next year:
   - Lecturer loads course again
   - System applies evolution
   - Cycle repeats with improvements
```

---

## Next Steps
1. Create Supabase schema (SQL)
2. Build n8n workflows
3. Create MCP tool definitions
4. Build Next.js frontend
5. Deploy & test end-to-end

# Teaching Genome - n8n Workflows (via MCP)

## Overview
These workflows use n8n to orchestrate the Teaching Genome system. They integrate with:
- **Supabase** (data storage)
- **Claude API** (AI analysis & generation)
- **DALL-E** (image generation)
- **Python/Node.js** (PowerPoint generation)

---

## Workflow 1: Initial Course Genome Generation
**Trigger**: Webhook (from MCP: upload_module_descriptor)

### Flow:
```
1. Webhook Trigger
   Input: {lecturer_id, module_code, module_name, pdf_base64, cohort_type, preferences, academic_year, semester}

2. Extract PDF Content
   - Decode base64 PDF
   - Use pdf-lib to extract text
   - Save PDF to Supabase bucket

3. Call Claude API (Extract Learning Objectives)
   Prompt: "Extract learning objectives, topics, assessments from this module descriptor"
   Input: PDF text + cohort_type + preferences
   Output: Structured list of objectives

4. Call Claude API (Generate 14-Week Breakdown)
   For weeks 1-14:
   - Topic
   - 3-5 learning objectives
   - 2-3 teaching methods (lecture, workshop, simulation, etc.)
   - Resources needed
   - Suggested duration

5. For Each Week: Generate Teaching Content
   - Call Claude to write teaching notes, discussion prompts, activity ideas
   - Call DALL-E to generate 3-4 image prompts for week
   - Store in Supabase

6. Generate PowerPoint Files
   For each week:
   - Create PPTX with title slide, content slides, notes
   - Include speaker notes (teaching notes)
   - Placeholder for images
   - Download links for images
   - Save to Supabase bucket

7. Create Course Record in Supabase
   - INSERT into courses table (status: 'draft')
   - INSERT 14 rows into weeks table

8. Return Response
   Output: {course_id, status: 'draft', message: 'Your 14-week plan is ready for review', weeks_preview: [week summaries]}
```

### n8n Nodes:
- **Webhook** (trigger)
- **Move Binary** (decode base64)
- **Code** (extract PDF text)
- **Supabase** (save PDF, create course record)
- **HTTP Request** (Claude API for extraction)
- **HTTP Request** (Claude API for breakdown)
- **HTTP Request** (Claude API for content generation) - looped for each week
- **HTTP Request** (DALL-E API) - looped for image prompts
- **Code** (generate PPTX structure)
- **Python** or **Node** (create PPTX files using pptx library)
- **Supabase** (store weeks, teaching notes, image prompts)
- **HTTP Request** (return to client)

---

## Workflow 2: Weekly Feedback Processing
**Trigger**: Webhook (from MCP: submit_weekly_feedback)

### Flow:
```
1. Webhook Trigger
   Input: {course_id, week_number, reflection_text}

2. Store Feedback Journal
   - INSERT into feedback_journals table
   - Store raw reflection_text

3. Call Claude API (Extract Key Issues)
   Prompt: "Analyze this teaching reflection and extract:
   - Concepts students struggled with
   - Timing/pacing problems
   - Examples that didn't land
   - Engagement observations"
   Input: reflection_text
   Output: {concept_struggles, timing_issues, engagement_notes}

4. Store Extracted Issues
   - UPDATE feedback_journals with key_issues JSONB
   - Set status: 'processed'

5. Call Claude API (Generate Adjustments)
   Prompt: "Based on feedback from week {week_number}, suggest changes for weeks {week_number+1}-14:
   - Should we add review sessions?
   - Which topics need reordering?
   - What examples/analogies should change?
   - How should pacing adjust?"
   Input: reflection_text + course_id + affected_weeks_content
   Output: Adjustment recommendations

6. For Each Affected Week:
   - Get current week content from Supabase
   - Call Claude to regenerate:
     - Teaching notes (with adjustments)
     - Discussion prompts
     - Activity ideas
   - Call DALL-E for new image prompts
   - Generate updated PPTX
   - Save to Supabase

7. Store Adjustments Record
   - INSERT into week_adjustments table
   - Store what was changed and which weeks affected

8. Return Response
   Output: {feedback_id, status: 'processed', affected_weeks: [4,5,6,...], message: 'Weeks 4-14 have been updated. Review changes?'}
```

### n8n Nodes:
- **Webhook** (trigger)
- **Supabase** (insert feedback_journals)
- **HTTP Request** (Claude: extract key issues)
- **Supabase** (update feedback_journals with issues)
- **Code** (get affected weeks from course_id)
- **HTTP Request** (Claude: generate adjustments)
- **Loop** (for each affected week):
  - **Supabase** (get week content)
  - **HTTP Request** (Claude: regenerate content)
  - **HTTP Request** (DALL-E: new image prompts)
  - **Code** (generate PPTX)
  - **Python/Node** (create PPTX file)
  - **Supabase** (save updated week)
- **Supabase** (insert week_adjustments record)
- **HTTP Request** (return to client)

---

## Workflow 3: End-of-Semester Evolution
**Trigger**: Webhook (from MCP: submit_semester_reflection)

### Flow:
```
1. Webhook Trigger
   Input: {course_id, reflection_text}

2. Store Course Reflection
   - INSERT into course_reflections table

3. Get Full Course Data
   - Fetch all weeks for this course
   - Fetch all feedback_journals for this course
   - Fetch all week_adjustments

4. Call Claude API (Analyze Semester Holistically)
   Prompt: "A lecturer taught a 14-week course. They provided this end-of-semester reflection:
   
   [reflection_text]
   
   Earlier weekly feedback:
   [all feedback_journals]
   
   Current course structure:
   [all weeks with topics]
   
   Based on ALL this, suggest specific improvements for next time:
   - Topics to remove/add
   - Topics to reorder
   - Teaching methods to swap
   - Activities to introduce
   - Pace adjustments
   
   For each suggestion, provide:
   - What: specific suggestion
   - Why: rationale
   - Affected weeks: which weeks change
   - Confidence: 0-1 (how confident you are)"
   
   Output: Array of suggestions

5. For Each Suggestion: Generate Evolution Suggestion Record
   - INSERT into evolution_suggestions table
   - status: 'pending'
   - category: (reorder, remove, swap_method, etc.)

6. Return Response
   Output: {course_id, reflection_id, suggestions: [array], message: 'Review suggestions for next iteration'}
```

### n8n Nodes:
- **Webhook** (trigger)
- **Supabase** (insert course_reflections)
- **Supabase** (fetch all weeks, feedback, adjustments)
- **Code** (format data for Claude prompt)
- **HTTP Request** (Claude: analyze semester)
- **Code** (parse Claude response into suggestion objects)
- **Loop** (for each suggestion):
  - **Supabase** (insert into evolution_suggestions)
- **HTTP Request** (return to client)

---

## Workflow 4: Evolution Approval & Storage
**Trigger**: Webhook (from MCP: review_evolution_suggestions)

### Flow:
```
1. Webhook Trigger
   Input: {course_id, suggestions_response: [{suggestion_id, action: approve/reject/modify, notes}]}

2. For Each Suggestion:
   - UPDATE evolution_suggestions table
   - Set status: 'approved' | 'rejected' | 'approved' (if modified)
   - Store lecturer_notes

3. Mark Course Completed (if all suggestions processed)
   - UPDATE courses SET status = 'completed'

4. Return Response
   Output: {course_id, processed_suggestions: count, message: 'Changes saved for next iteration'}
```

### n8n Nodes:
- **Webhook** (trigger)
- **Loop** (for each suggestion):
  - **Supabase** (update evolution_suggestions)
- **Supabase** (update courses status)
- **HTTP Request** (return to client)

---

## Workflow 5: Initialize New Iteration
**Trigger**: Webhook (from MCP: start_new_iteration)

### Flow:
```
1. Webhook Trigger
   Input: {previous_course_id, academic_year, semester, cohort_type}

2. Create New Course Record
   - Create new course with same module_code, module_name
   - Different academic_year, semester
   - New cohort_type (may differ)
   - status: 'draft'

3. Clone Weeks with Evolution Applied
   For each approved evolution_suggestion:
   - Get suggested change (e.g., "remove week 5", "swap weeks 3 and 4", "change method to case_study")
   - Apply change to week structure
   
   For each week in new structure:
   - Get previous week's content
   - Apply approved suggestions if relevant
   - Call Claude to regenerate if suggestions affected this week
   - Create new PPTX for new course
   - INSERT into weeks table (for new_course_id)

4. Create History Link
   - Store reference to previous course iteration

5. Return Response
   Output: {new_course_id, status: 'draft', message: 'New iteration created with improvements applied'}
```

### n8n Nodes:
- **Webhook** (trigger)
- **Supabase** (create new course record)
- **Supabase** (fetch approved evolution_suggestions for previous course)
- **Code** (apply suggestions to week structure)
- **Loop** (for each new week):
  - **Supabase** (get previous week content + check for suggestions)
  - **Code** (determine if regeneration needed)
  - **Condition**: If suggestions affected this week:
    - **HTTP Request** (Claude: regenerate content with suggestions applied)
  - **Condition**: Else:
    - **Code** (copy previous content as-is)
  - **Python/Node** (generate PPTX)
  - **Supabase** (insert into weeks for new course)
- **HTTP Request** (return to client)

---

## Environment Variables Needed in n8n

```
OPENAI_API_KEY=sk-...
SUPABASE_URL=https://...supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
CLAUDE_API_KEY=sk-ant-...
```

---

## Testing Each Workflow

### Workflow 1: Upload Descriptor
```bash
POST /webhook/teaching-genome/upload
{
  "lecturer_id": "uuid",
  "module_code": "BIO-101",
  "module_name": "Human Anatomy",
  "pdf_base64": "JVBERi0xLjQK...",
  "cohort_type": "first-year pre-med students",
  "academic_year": "2024-2025",
  "semester": "Fall",
  "teaching_preferences": {
    "teaching_style": "case_studies",
    "pace": "moderate"
  }
}
```

### Workflow 2: Weekly Feedback
```bash
POST /webhook/teaching-genome/feedback
{
  "course_id": "uuid",
  "week_number": 3,
  "reflection_text": "Students struggled with the anatomy derivation. The pharmacy example fell flat; try sports context. Good engagement before lunch, then energy dropped. Need to slow down on topic X."
}
```

### Workflow 3: Semester Reflection
```bash
POST /webhook/teaching-genome/reflection
{
  "course_id": "uuid",
  "reflection_text": "Overall great semester. Case studies were excellent. Weeks 1-3 were too dense. Chapter 7 should precede chapter 5. Mid-term project was huge success."
}
```

---

## Next Steps
1. Create these workflows in n8n
2. Set up Claude & DALL-E API credentials
3. Deploy to Railway
4. Test end-to-end with sample lecturer data
5. Build frontend UI to interact with webhooks

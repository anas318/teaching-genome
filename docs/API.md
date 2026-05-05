# API Reference - Teaching Genome

Complete webhook and API endpoint documentation.

---

## Overview

Teaching Genome uses n8n webhooks for asynchronous processing. All communication is JSON-based with standard HTTP methods.

---

## Webhook: Generate Course Content

Triggers PDF generation for all 14 weeks after course upload.

### Endpoint
```
POST /webhook/teaching-genome/upload-generate
```

### Request

**Headers**:
```json
{
  "Content-Type": "application/json"
}
```

**Body**:
```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440000",
  "module_code": "CS101",
  "module_name": "Introduction to Computer Science",
  "pdf_url": "https://your-bucket.supabase.co/bucket/course_1.pdf",
  "preferences": {
    "teaching_style": "case_studies",
    "pace": "moderate",
    "assessment_type": "mixed"
  }
}
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `course_id` | UUID | Yes | Unique course identifier |
| `module_code` | String | Yes | Course code (e.g., "CS101") |
| `module_name` | String | Yes | Full course name |
| `pdf_url` | URL | Yes | Path to uploaded syllabus PDF |
| `preferences` | Object | No | Teaching preferences |
| `teaching_style` | String | No | "lectures", "case_studies", "simulations", "mixed" |
| `pace` | String | No | "fast", "moderate", "slow" |
| `assessment_type` | String | No | "exams", "projects", "continuous", "mixed" |

### Response

**Success (200)**:
```json
{
  "status": "success",
  "weeks_generated": 14,
  "total_pages": 182,
  "processing_time_ms": 8500
}
```

**Processing Async** (202):
If using async mode, returns immediately:
```json
{
  "status": "processing",
  "job_id": "job_12345",
  "check_status_url": "/webhook/teaching-genome/status/job_12345"
}
```

**Error (400)**:
```json
{
  "error": "invalid_course_id",
  "message": "Course ID must be a valid UUID",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Error (500)**:
```json
{
  "error": "pdf_generation_failed",
  "message": "Failed to generate PDF: exceeds max page limit",
  "job_id": "job_12345",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### cURL Example
```bash
curl -X POST https://your-n8n.com/webhook/teaching-genome/upload-generate \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": "550e8400-e29b-41d4-a716-446655440000",
    "module_code": "CS101",
    "module_name": "Introduction to Computer Science",
    "pdf_url": "https://your-bucket.supabase.co/bucket/course_1.pdf",
    "preferences": {
      "teaching_style": "case_studies",
      "pace": "moderate"
    }
  }'
```

### Process Flow
```
1. Webhook received → Validate JSON
2. Fetch course data from Supabase
3. Query module descriptor PDF
4. Call Gemini API with prompt
5. Parse response (split by SECTION:)
6. Create 14 week records in DB
7. Build PDF with raw operators
8. Store PDF in Supabase Storage
9. Update course status to "complete"
```

---

## Webhook: Weekly Feedback

Records lecturer feedback for a week and generates suggestions for that week.

### Endpoint
```
POST /webhook/teaching-genome/feedback
```

### Request

**Body**:
```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440000",
  "week_number": 5,
  "feedback_text": "Students struggled with recursion. Need more examples.",
  "difficulty_rating": 7,
  "student_engagement": 6,
  "teaching_notes": "Consider adding more visual diagrams"
}
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `course_id` | UUID | Yes | Which course |
| `week_number` | Integer | Yes | 1-14 |
| `feedback_text` | String | Yes | Lecturer's feedback |
| `difficulty_rating` | Integer (1-10) | No | How difficult week was |
| `student_engagement` | Integer (1-10) | No | Student engagement level |
| `teaching_notes` | String | No | Internal notes |

### Response

**Success (200)**:
```json
{
  "status": "success",
  "week": 5,
  "suggestions_generated": 3,
  "suggestion_ids": [
    "sugg_001_deeper_examples",
    "sugg_002_visual_aids",
    "sugg_003_pacing_slow"
  ],
  "processing_time_ms": 2800
}
```

**Error (404)**:
```json
{
  "error": "course_not_found",
  "message": "Course 550e8400-e29b-41d4-a716-446655440000 not found"
}
```

### cURL Example
```bash
curl -X POST https://your-n8n.com/webhook/teaching-genome/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": "550e8400-e29b-41d4-a716-446655440000",
    "week_number": 5,
    "feedback_text": "Students struggled with recursion",
    "difficulty_rating": 7
  }'
```

---

## Webhook: Approve Suggestion

When lecturer approves a suggestion, this creates a new course iteration.

### Endpoint
```
POST /webhook/teaching-geometry/approve-suggestion
```

### Request

**Body**:
```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440000",
  "suggestion_id": "sugg_001_deeper_examples",
  "week_number": 5,
  "apply_to_all_weeks": false
}
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `course_id` | UUID | Yes | Which course |
| `suggestion_id` | String | Yes | The suggestion ID |
| `week_number` | Integer | No | Specific week (if not all) |
| `apply_to_all_weeks` | Boolean | No | Apply to all remaining weeks? |

### Response

**Success (200)**:
```json
{
  "status": "success",
  "iteration_id": "iter_002",
  "weeks_updated": 10,
  "changes_applied": [
    "week_5_recursion_updated",
    "week_6_backtracking_updated",
    "week_7_dynamic_programming_updated"
  ],
  "processing_time_ms": 4200
}
```

### cURL Example
```bash
curl -X POST https://your-n8n.com/webhook/teaching-genome/approve-suggestion \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": "550e8400-e29b-41d4-a716-446655440000",
    "suggestion_id": "sugg_001_deeper_examples",
    "apply_to_all_weeks": true
  }'
```

---

## REST API: Get Course

Fetch course details from Supabase directly (if using anon key).

### Endpoint
```
GET https://your-project.supabase.co/rest/v1/courses?id=eq.{course_id}
```

### Headers
```json
{
  "apikey": "YOUR_SUPABASE_ANON_KEY",
  "Content-Type": "application/json"
}
```

### Response
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "lecturer_id": "660e8400-e29b-41d4-a716-446655440000",
  "module_code": "CS101",
  "module_name": "Introduction to Computer Science",
  "cohort_type": "Computer Science, Year 1",
  "academic_year": "2024-2025",
  "semester": "Fall",
  "module_descriptor_pdf_url": "https://...",
  "preferences": {
    "teaching_style": "case_studies",
    "pace": "moderate",
    "assessment_type": "mixed"
  },
  "status": "complete",
  "created_at": "2024-01-10T08:30:00Z",
  "updated_at": "2024-01-15T14:20:00Z"
}
```

### cURL Example
```bash
curl -X GET \
  "https://your-project.supabase.co/rest/v1/courses?id=eq.550e8400-e29b-41d4-a716-446655440000" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json"
```

---

## REST API: Get Weeks

Fetch all weeks for a course.

### Endpoint
```
GET https://your-project.supabase.co/rest/v1/weeks?course_id=eq.{course_id}&order=week_number.asc
```

### Response
```json
[
  {
    "id": "850e8400-e29b-41d4-a716-446655440000",
    "course_id": "550e8400-e29b-41d4-a716-446655440000",
    "week_number": 1,
    "topic": "Fundamentals of Computer Science",
    "learning_objectives": [
      "Understand what computer science is",
      "Learn about computational thinking",
      "Explore different domains of CS"
    ],
    "discussion_prompts": [
      "What problems can computers solve?",
      "How has CS impacted your life?"
    ],
    "content": "SECTION: Fundamentals...",
    "status": "complete",
    "created_at": "2024-01-10T09:00:00Z"
  }
]
```

---

## Error Handling

### Error Codes

| Code | Message | Solution |
|------|---------|----------|
| 400 | Invalid request body | Check JSON syntax and parameter types |
| 401 | Unauthorized | Verify API key/webhook credentials |
| 404 | Resource not found | Check course_id or week_number |
| 429 | Too many requests | Rate limit exceeded, wait 60 seconds |
| 500 | Server error | Try again, check n8n logs |
| 503 | Service unavailable | Gemini API down, try again later |

### Retry Strategy

```javascript
async function webhookWithRetry(
  url: string,
  payload: object,
  maxRetries: number = 3
) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.ok) return response.json();
      if (response.status >= 500) throw new Error('Server error');
      
      return null;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
}
```

---

## Rate Limits

| Endpoint | Limit | Period |
|----------|-------|--------|
| /upload-generate | 100 | 1 hour |
| /feedback | 500 | 1 hour |
| /approve-suggestion | 200 | 1 hour |

---

## Authentication

Teaching Genome uses two authentication layers:

1. **Frontend**: Supabase Auth (email/password)
2. **Webhooks**: URL-based (webhook URLs are secret)

Webhook URLs should **never be exposed** in client code.

---

## Versioning

Current API version: **v1** (2024-01-15)

Future versions will be at:
- `/webhook/teaching-genome/v2/upload-generate`
- `/webhook/teaching-genome/v2/feedback`

Backward compatibility maintained for 12 months.

---

<div align="center">

**API questions? Check n8n logs or open a GitHub issue!** 🚀

</div>

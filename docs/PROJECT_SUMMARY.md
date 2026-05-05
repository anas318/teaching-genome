# 🎓 Teaching Genome - Hackathon Project Summary

## The Idea in 60 Seconds

A lecturer receives a module descriptor from their university — a document that lists topics, learning objectives, and assessments for a 14-week course. But turning that document into an engaging semester is hard. 

**Teaching Genome** is an AI co-pilot that:
1. **Transforms** the module descriptor into a complete 14-week pedagogical plan with slides, discussion prompts, and activity ideas
2. **Adapts** weekly based on the lecturer's honest reflection ("Students were confused about X, try Y next time")
3. **Remembers** improvements forever so next time they teach the same course, it's better than before

---

## The 6-Step Workflow

```
1. TASK RECEIVED (Lecturer uploads descriptor)
   ↓
2. AI ANALYSES (System generates 14-week plan)
   ↓
3. SMART PLAN (Lecturer reviews & approves)
   ↓
4. LIVE FEEDBACK (Weekly reflections → instant adjustments)
   ↓
5. EVOLUTION (End-of-semester suggestions for improvement)
   ↓
6. NEXT TIME (Improvements applied automatically next year)
```

---

## Tech Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| **Database** | Supabase (PostgreSQL) | Secure, scalable, built-in Auth |
| **Workflows** | n8n | AI orchestration, easy to build visually |
| **AI** | Claude 3.5 Sonnet | Best for pedagogical reasoning + cost-effective |
| **Images** | DALL-E 3 | Real diagrams for slides |
| **Frontend** | Next.js + React | Fast, responsive lecturer interface |
| **Hosting** | Railway (n8n), Vercel (frontend) | Easy deployment, good for hackathon |

---

## Core Components

### 1. Supabase Schema ✅ READY
**File**: `backend/supabase-schema.sql`

Tables:
- `lecturers` — Multiple lecturers, each owns their courses
- `courses` — Can teach same module differently in different years/semesters
- `weeks` — 14-week breakdown with topics, methods, resources
- `feedback_journals` — Weekly reflections stored as raw text
- `week_adjustments` — What changed based on feedback
- `course_reflections` — End-of-semester summary
- `evolution_suggestions` — Improvements for next time

Row-level security (RLS) ensures each lecturer only sees their own data.

### 2. n8n Workflows ✅ BLUEPRINT READY
**File**: `workflows/n8n-workflows.md`

**5 Workflows**:

1. **Upload & Generate** — PDF descriptor → 14-week plan with PowerPoints
2. **Weekly Feedback** — Reflection text → Update future weeks
3. **Semester Evolution** — End reflection → Generate improvement suggestions
4. **Approval** — Lecturer approves suggestions for next time
5. **New Iteration** — Start new course with previous improvements applied

Each workflow:
- Takes input from lecturer
- Calls Claude for AI analysis/generation
- Calls DALL-E for images/diagrams
- Generates PowerPoints
- Stores results in Supabase

### 3. Frontend (To Be Built)
**Framework**: Next.js + React

**Pages**:
- `/login` — Supabase Auth (email/password)
- `/dashboard` — List all courses
- `/courses/[id]` — View course overview
- `/courses/[id]/upload` — Upload PDF descriptor
- `/courses/[id]/week/[number]` — View week details, download PowerPoint
- `/courses/[id]/feedback` — Submit weekly reflection (form)
- `/courses/[id]/reflection` — Submit end-of-semester reflection
- `/courses/[id]/suggestions` — Review and approve evolution suggestions

---

## Why This Is Brilliant

### For Lecturers
- ✅ No more starting from blank PowerPoint each year
- ✅ All hard-won teaching wisdom captured forever
- ✅ AI helps with slide design, examples, activities
- ✅ Real improvement cycle: feedback → updates → evolution
- ✅ Teaching is personal craft; each lecturer owns their genome

### For Universities
- ✅ Improve course quality year-over-year
- ✅ Reduce faculty workload on design
- ✅ Capture best practices
- ✅ Every course has a permanent "record of wisdom"

### For Students (Indirectly)
- ✅ Better taught courses (improved each iteration)
- ✅ Lecturers have time for other things (research, mentoring)
- ✅ Consistent, thoughtful pedagogy

---

## Data Model Highlights

### Course Identity
Each course is identified by:
- `lecturer_id` — Who teaches it (unique person)
- `module_code` — What (BIO-101, NUR-301)
- `academic_year` — When (2024-2025)
- `semester` — Which semester (Spring/Fall/Summer)

This means:
- Dr. Sarah can teach BIO-101 in 2024-2025 Spring (biology majors)
- Same Dr. Sarah teaches BIO-101 in 2025-2026 Fall (nursing students)
- These are **different courses** (different cohorts, different iterations)
- But evolution suggestions carry over

### Feedback Loop
1. Lecturer teaches week N
2. Writes reflection ("Students confused about X")
3. System extracts key issues (using Claude)
4. Generates adjustments for weeks N+1 to 14
5. Regenerates PowerPoints for affected weeks
6. Lecturer approves or rejects changes

### Evolution
1. After all 14 weeks taught
2. Lecturer writes semester summary
3. System analyzes it + all weekly reflections
4. Suggests concrete improvements:
   - "Remove topics X and Y"
   - "Move chapter 5 before chapter 3"
   - "Replace method A with method B for week 7"
   - "Add group project"
5. Lecturer approves/rejects each
6. Next time they teach course → improvements applied automatically

---

## API Endpoints (To Build)

### MCP Tools (via Copilot CLI)
```
upload_module_descriptor(lecturer_id, module_code, pdf, cohort_type, preferences, year, semester)
get_course_plan(course_id)
get_week_details(course_id, week_number)
submit_weekly_feedback(course_id, week_number, reflection_text)
review_week_updates(course_id, feedback_id, approve/reject)
download_week_powerpoint(course_id, week_number)
submit_semester_reflection(course_id, reflection_text)
review_evolution_suggestions(course_id, responses[])
list_lecturer_courses(lecturer_id)
start_new_iteration(previous_course_id, year, semester)
```

### REST Endpoints (From Frontend)
```
POST /api/upload-descriptor
GET /api/courses/:id
GET /api/courses/:id/weeks/:week
POST /api/courses/:id/feedback
POST /api/courses/:id/reflection
GET /api/courses/:id/download/:week
POST /api/courses/:id/approve-suggestions
```

---

## Deployment Plan

### Phase 1 (MVP - Hackathon)
- [ ] Deploy Supabase schema
- [ ] Build 5 n8n workflows on Railway
- [ ] Build Next.js frontend
- [ ] End-to-end test with sample course
- [ ] Demo to potential users

### Phase 2 (Post-Hackathon)
- [ ] User testing with real lecturers
- [ ] Refine AI prompts based on feedback
- [ ] Add analytics (which methods work best?)
- [ ] Create lecturer community/sharing features
- [ ] Mobile app for feedback journaling

---

## Success Criteria

**MVP Success**:
1. ✅ Lecturer uploads PDF → System generates 14-week plan with PowerPoints
2. ✅ Lecturer can download each week's PowerPoint
3. ✅ Lecturer submits weekly feedback → System updates remaining weeks
4. ✅ Lecturer submits semester reflection → System suggests improvements
5. ✅ Lecturer approves suggestions → Saved for next iteration
6. ✅ Next iteration starts with improvements applied

**Stretch Goals**:
- [ ] Image generation in slides (DALL-E)
- [ ] Teaching analytics (which methods were most engaging?)
- [ ] Multi-lecturer course templates
- [ ] Student download access (read-only)
- [ ] Integration with university LMS

---

## Competitive Advantage

**vs. Generic AI Writing Tools**:
- Not just slide generation; full pedagogical strategy
- Learns and improves over time
- Respects lecturer's craft (doesn't override their choices)

**vs. Learning Management Systems (Canvas, Blackboard)**:
- Focused on course **design**, not administration
- Adaptive based on real teaching experience
- AI-powered, not just organizational

**vs. Existing Education AI**:
- Lecturers own their genome (no data sharing)
- Weekly feedback loop (not just one-time plan)
- PowerPoint output (actually usable by educators)

---

## Team Roles (If Multiple People)

- **AI/n8n Engineer**: Build 5 workflows, tune Claude prompts
- **Frontend Dev**: Build Next.js pages, Supabase integration
- **Database**: Optimize schema, RLS policies, indexing
- **Testing**: End-to-end testing with real module descriptors
- **Product**: Demo, gather feedback from lecturers

---

## Estimated Effort (Hackathon Timeline)

- **Supabase Schema**: 0.5 hours (already done ✅)
- **n8n Workflows**: 8-10 hours (complex AI orchestration)
- **Frontend**: 6-8 hours (5-6 pages with forms)
- **Integration & Testing**: 3-4 hours
- **Demo Prep**: 1-2 hours

**Total**: ~20 hours of focused work

---

## Questions During Build

1. Should we pre-populate example modules for testing?
2. Should lecturers see their previous edits/justifications when reviewing suggestions?
3. How do we handle course deletion? Archive instead of delete?
4. Should we track time spent by lecturer on each step?
5. Should we send email notifications on week updates?

---

## Files Ready to Deploy

✅ **Database Schema**: `backend/supabase-schema.sql` (ready now)
✅ **Workflow Blueprints**: `workflows/n8n-workflows.md` (ready now)
✅ **Architecture Doc**: `docs/ARCHITECTURE.md` (reference)
✅ **Quick Start**: `docs/QUICKSTART.md` (reference)

🚀 **To Build**:
- [ ] n8n Workflows (5 workflows)
- [ ] Next.js Frontend
- [ ] Integration testing

---

## Contact & Questions
All files are in `/Users/anasaleryani/hackthon/`

Let's build something amazing! 🚀

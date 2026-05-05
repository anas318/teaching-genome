# Teaching Genome - Quick Start for Hackathon

## 🎯 Project Summary
**Teaching Genome** is an AI-powered system that transforms a dry university module descriptor into a vibrant, adaptive 14-week teaching strategy. The lecturer's feedback shapes the course week-by-week, and improvements are captured forever.

**Tech Stack**:
- **Backend**: Supabase (PostgreSQL + Auth)
- **Workflows**: n8n (orchestration & AI integration)
- **AI**: Claude API (analysis & generation), DALL-E (images)
- **Frontend**: Next.js or React (lecturer interface)
- **Hosting**: Railway (n8n), Vercel (frontend)

---

## 📁 Project Structure
```
/Users/anasaleryani/hackthon/
├── docs/
│   └── ARCHITECTURE.md          ← Full system design
├── backend/
│   └── supabase-schema.sql      ← Database schema (ready to deploy)
├── frontend/
│   └── (to be built)
├── mcp/
│   └── (integration with Copilot CLI)
└── workflows/
    └── n8n-workflows.md         ← 5 workflows (ready to build in n8n)
```

---

## 🚀 Quick Start Steps

### Step 1: Set Up Supabase
1. Create a new Supabase project at supabase.com
2. Go to **SQL Editor**
3. Paste the contents of `backend/supabase-schema.sql`
4. Run it
5. ✅ Database is ready

### Step 2: Get API Keys
You'll need:
- **Claude API Key** from [console.anthropic.com](https://console.anthropic.com)
- **OpenAI API Key** (for DALL-E) from [platform.openai.com](https://platform.openai.com)
- **Supabase URL & Keys** (already have from step 1)

### Step 3: Build n8n Workflows
Use the blueprint in `workflows/n8n-workflows.md`:

**Workflow 1**: `POST /webhook/teaching-genome/upload`
- Uploads PDF descriptor → Generates 14-week plan

**Workflow 2**: `POST /webhook/teaching-genome/feedback`
- Weekly reflection → Updates future weeks

**Workflow 3**: `POST /webhook/teaching-genome/reflection`
- End-of-semester review → Generates evolution suggestions

**Workflow 4**: `POST /webhook/teaching-genome/approve-suggestions`
- Lecturer approves suggestions → Saved for next iteration

**Workflow 5**: `POST /webhook/teaching-genome/new-iteration`
- Start new course iteration → Applies previous improvements

### Step 4: Build Frontend (Next.js)
```bash
cd /Users/anasaleryani/hackthon/frontend
npx create-next-app@latest --typescript

# Create pages:
# - /login (Supabase Auth)
# - /dashboard (list courses)
# - /courses/[id] (view course)
# - /courses/[id]/upload (upload descriptor)
# - /courses/[id]/week/[week] (view week details)
# - /courses/[id]/feedback (submit weekly feedback)
# - /courses/[id]/reflection (submit semester reflection)
# - /courses/[id]/suggestions (review evolution suggestions)
```

### Step 5: Create MCP Tools (for Copilot CLI)
```bash
cd /Users/anasaleryani/hackthon/mcp

# Define tools in npx package that exposes:
# - upload_module_descriptor
# - get_course_plan
# - submit_weekly_feedback
# - submit_semester_reflection
# - review_evolution_suggestions
# - start_new_iteration

# Register with Copilot CLI:
# copilot /mcp add teaching-genome <URL>
```

---

## 📊 Core Workflows at a Glance

| # | Name | Trigger | Key Steps | Output |
|---|------|---------|-----------|--------|
| 1 | **Genome Gen** | Upload PDF | Extract → Claude breakdown → PowerPoint | 14-week plan (draft) |
| 2 | **Feedback** | Weekly reflection | Parse feedback → Claude adjustments → Regen weeks | Updated weeks (pending approval) |
| 3 | **Evolution** | Semester reflection | Analyze semester → Claude suggestions → List changes | Evolution suggestions |
| 4 | **Approval** | Lecturer reviews | Update suggestion statuses | Saved for next time |
| 5 | **New Iter** | New semester | Clone + apply suggestions → Regen if needed | New improved course |

---

## 🎓 User Journey Example

### Lecturer: Dr. Sarah (Nursing Module)

**Week 0** (Before Semester):
1. Uploads PDF module descriptor
2. Says: "First-year students, weak bio background, prefer case studies"
3. System generates 14-week plan with real-world nursing examples
4. Sarah reviews, approves, makes minor tweaks
5. Ready to teach

**Week 3** (After Teaching):
1. Sarah writes: "Students lost on pharmacology calculation. The hospital example was great but ended too fast. Timing perfect."
2. System updates weeks 4-14:
   - Adds review session for calculation
   - Keeps hospital examples, extends them
   - No timing changes needed
3. Sarah reviews, approves, new slides are ready

**Week 12** (End of Semester):
1. Sarah reflects: "Overall great! Case studies were gold. Weeks 1-2 too dense. Should do pharma before anatomy. The group project was huge success."
2. System suggests:
   - ✅ "Slow down weeks 1-2" (approved)
   - ✅ "Move pharmacology before anatomy" (approved)
   - ✅ "Add group project to next year" (approved)
3. Sarah approves; changes saved

**Next Year** (New Iteration):
1. Sarah starts new iteration of same module
2. System loads improved version with all changes applied
3. Sarah can customize further or use as-is
4. Cycle repeats

---

## 🔑 Key Files to Deploy

| File | Purpose |
|------|---------|
| `backend/supabase-schema.sql` | Database (deploy to Supabase) |
| `workflows/n8n-workflows.md` | Workflow blueprints (build in n8n) |
| `frontend/*` | Next.js app (deploy to Vercel) |
| `mcp/*` | MCP tools (register with Copilot CLI) |

---

## 🧪 Testing Checklist

- [ ] Supabase schema applied
- [ ] n8n workflow 1 working (upload PDF → generates weeks)
- [ ] PowerPoint generation working
- [ ] Claude API calls successful
- [ ] Frontend upload page working
- [ ] Can submit weekly feedback
- [ ] Feedback updates weeks
- [ ] Semester reflection generates suggestions
- [ ] Evolution suggestions saveable
- [ ] New iteration flow working

---

## 💡 Advanced Features (Post-MVP)

- Real-time collaboration between lecturer & teaching assistants
- Student view (read-only access to approved slides)
- Analytics: Which teaching methods work best?
- Template library: Lecturers can share anonymized course structures
- Mobile app for feedback journaling
- Integration with Slack/Teams for instant notifications

---

## 📞 Questions to Ask Later

1. Should students ever see feedback? (Currently no)
2. Can TAs co-author feedback?
3. Should we track which students attend which weeks?
4. Export to LMS (Canvas, Blackboard)?
5. Video integration (lectures uploaded + transcribed)?

---

## 🎬 Next Immediate Steps

1. **Anas**: Build n8n workflows (5 workflows from blueprint)
2. **Frontend dev**: Set up Next.js with Supabase Auth
3. **Testing**: End-to-end test with real module descriptor
4. **Demo**: Show to potential lecturers for feedback
5. **Launch**: Deploy to Railway + Vercel

---

## 📚 Reference

- **Architecture**: See `docs/ARCHITECTURE.md`
- **Workflows**: See `workflows/n8n-workflows.md`
- **Database**: See `backend/supabase-schema.sql`
- **API**: Will be documented in frontend code

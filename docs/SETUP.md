# Setup Guide - Teaching Genome

Complete installation and configuration guide to get Teaching Genome running locally.

---

## Prerequisites

Before you start, make sure you have:

- **Node.js** 18+ ([Download](https://nodejs.org/))
- **npm** 9+ (comes with Node.js)
- **Git** ([Download](https://git-scm.com/))
- A **Supabase** account (free at [supabase.com](https://supabase.com))
- **Google Gemini API** key (free at [ai.google.dev](https://ai.google.dev/))
- **n8n** instance (cloud free tier or self-hosted)

---

## Step 1: Clone Repository

```bash
git clone https://github.com/anasaleryani/teaching-genome.git
cd teaching-genome
```

---

## Step 2: Frontend Setup

### Install Dependencies
```bash
npm install
```

### Create Environment File
```bash
cp .env.example .env.local
```

### Get Supabase Credentials
1. Go to [supabase.com](https://supabase.com) → Sign up/login
2. Create new project
3. Go to Settings → API
4. Copy:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **Anon Key** → `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### Get Gemini API Key
1. Go to [ai.google.dev](https://ai.google.dev)
2. Click "Get API Key"
3. Create new API key
4. Copy key (you'll use this in n8n setup)

### Get n8n Webhook URLs
1. Deploy n8n (see below)
2. Create webhook nodes in n8n
3. Copy webhook URLs to `.env.local`:
   - `NEXT_PUBLIC_N8N_BASE_URL`
   - `NEXT_PUBLIC_N8N_WEBHOOK_URL`

### Update .env.local
```
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...

# n8n
NEXT_PUBLIC_N8N_BASE_URL=https://your-n8n.com
NEXT_PUBLIC_N8N_WEBHOOK_URL=https://your-n8n.com/webhook/teaching-genome/upload-generate
NEXT_PUBLIC_N8N_FEEDBACK_WEBHOOK_URL=https://your-n8n.com/webhook/teaching-genome/feedback
```

### Start Development Server
```bash
npm run dev
```

**Open**: http://localhost:3000

---

## Step 3: Database Setup (Supabase)

### Create Tables
In Supabase SQL Editor, run:

```sql
-- Lecturers table
CREATE TABLE lecturers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

-- Courses table
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lecturer_id UUID REFERENCES lecturers(id),
  module_code TEXT NOT NULL,
  module_name TEXT NOT NULL,
  cohort_type TEXT,
  academic_year TEXT,
  semester TEXT,
  module_descriptor_pdf_url TEXT,
  preferences JSONB,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT now()
);

-- Weeks table
CREATE TABLE weeks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES courses(id),
  week_number INTEGER NOT NULL,
  topic TEXT NOT NULL,
  learning_objectives JSONB,
  discussion_prompts JSONB,
  activity_ideas JSONB,
  teaching_notes TEXT,
  content TEXT,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT now()
);

-- Evolution Suggestions
CREATE TABLE evolution_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES courses(id),
  suggestion TEXT NOT NULL,
  category TEXT,
  confidence_score FLOAT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT now()
);
```

### Enable RLS (Optional but Recommended)
```sql
ALTER TABLE lecturers ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE weeks ENABLE ROW LEVEL SECURITY;
```

### Create Storage Bucket
In Supabase Storage:
1. Create bucket: `module-descriptors`
2. Set to "Public" for PDF downloads

---

## Step 4: n8n Workflow Setup

### Deploy n8n

**Option A: Cloud (Easiest)**
1. Go to [n8n.cloud](https://n8n.cloud)
2. Sign up → Create new instance
3. Use free tier (1 execution/day is enough for testing)

**Option B: Self-Hosted**
```bash
docker run -it --rm \
  -p 5678:5678 \
  -e DB_TYPE=sqlite \
  -e N8N_USER_MANAGEMENT_DISABLED=true \
  n8nio/n8n
```

### Create Workflow
1. In n8n, create new workflow
2. Add nodes in sequence:
   - **Webhook** (POST /webhook/teaching-genome/upload-generate)
   - **Supabase** (fetch week data)
   - **Gemini** (generate content with prompt from summary)
   - **Code node** (build PDF)
   - **Code node** (return binary)
   - **Webhook Response**

### Get Webhook URLs
In n8n workflow:
1. Click Webhook node
2. Copy URL from "Webhook URL" field
3. Use for `NEXT_PUBLIC_N8N_WEBHOOK_URL` in `.env.local`

### Connect Credentials
In n8n Credentials:

**Supabase API:**
- Host: `your-project.supabase.co`
- API Key: From Supabase Settings

**Google Gemini API:**
- API Key: From [ai.google.dev](https://ai.google.dev)

---

## Step 5: Authentication Setup (Optional)

Teaching Genome uses Supabase Auth. To enable:

1. Go to Supabase → Authentication → Providers
2. Enable "Email" provider
3. Configure redirect URL: `http://localhost:3000/login`

For production:
- Update redirect to: `https://yourdomain.com/login`

---

## Verify Installation

### Test Frontend
1. Open http://localhost:3000
2. You should see landing page
3. Click "Get Started" → Upload course page

### Test Database
```bash
# In Supabase SQL Editor:
SELECT * FROM lecturers;
```

### Test Gemini API
```bash
# In n8n, add test Gemini node and run it
```

---

## Common Issues

### "Cannot find module 'supabase'"
```bash
npm install @supabase/supabase-js
```

### "NEXT_PUBLIC_SUPABASE_URL is undefined"
- Check `.env.local` has correct variables
- Restart dev server: `Ctrl+C` then `npm run dev`

### "Webhook not triggering"
- Verify webhook URL in n8n is correct
- Check n8n instance is running
- Review n8n logs for errors

### "Gemini returns 403 error"
- Verify API key is correct
- Check API key has Gemini permissions in Google Cloud
- Regenerate key if needed

---

## Next Steps

- Read [Architecture Guide](./ARCHITECTURE.md)
- Explore [Deployment Options](./DEPLOYMENT.md)
- Check [Contributing Guide](../CONTRIBUTING.md)
- Join [Community Discussions](https://github.com/anasaleryani/teaching-genome/discussions)

---

## Need Help?

- **Supabase Docs**: https://supabase.com/docs
- **n8n Docs**: https://docs.n8n.io
- **Gemini API**: https://ai.google.dev/tutorials
- **Next.js**: https://nextjs.org/docs
- **Discord**: Join our community (link in README)

---

<div align="center">

**You're all set! Start by uploading a test course. 🚀**

</div>

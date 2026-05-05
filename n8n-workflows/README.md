# n8n Workflows

Complete n8n automation workflows for Teaching Genome.

## Overview

These workflows automate the core functionality of Teaching Genome:
1. **Generate Week PDF** - Creates formatted PDF slides from Gemini output
2. Course content generation
3. Feedback processing

---

## Workflows

### 1. Upload & Generate Plan (`upload-and-generate-plan.json`)

**Purpose**: Upload course PDF, analyze with Gemini, create 14-week teaching plan

**Flow**:
```
Webhook (POST with PDF)
  → Create course record in Supabase
  → Send PDF to Gemini for analysis
  → Parse JSON response (14 weeks)
  → Loop: Create week record for each week (1-14)
  → Return success
```

**Endpoint**: `POST /webhook/teaching-genome/upload-generate`

**Request Body**:
```json
{
  "lecturer_id": "uuid",
  "course_id": "uuid",
  "module_code": "CS101",
  "module_name": "Introduction to Computer Science",
  "cohort_type": "Computer Science, Year 1",
  "academic_year": "2024-2025",
  "semester": "Fall",
  "teaching_style": "case_studies | lectures | simulations | mixed",
  "pace": "fast | moderate | slow",
  "pdf_url": "https://bucket.supabase.co/module-descriptors/course_1.pdf"
}
```

**Response**:
```json
{
  "ok": true,
  "weeks_generated": 14,
  "message": "14-week plan generated and saved"
}
```

**Features**:
- ✅ Analyzes PDF course descriptors with Gemini
- ✅ Generates complete 14-week teaching plan
- ✅ Creates course record in `courses` table
- ✅ Creates 14 week records in `weeks` table (one per week)
- ✅ Supports teaching style customization (lectures, case studies, simulations, mixed)
- ✅ Supports pace customization (fast, moderate, slow)
- ✅ Loops through all 14 weeks and creates records
- ✅ Follows Bloom's Taxonomy for learning objectives
- ✅ Provides detailed teaching notes and activity ideas

**Data Generated per Week**:
- Week number (1-14)
- Topic (descriptive title)
- Learning objectives (3-5 per week)
- Discussion prompts (3-6 per week)
- Teaching methods (lecture, workshop, simulation, etc.)
- Teaching notes (detailed strategy for lecturer)
- Activity ideas (2-4 specific hands-on activities)

**Nodes**:
1. **Webhook - Upload** - Receives POST with course details
2. **Create a row1** - Creates course record in Supabase
3. **Analyze document** - Sends PDF to Gemini for analysis
4. **Code in JavaScript** - Parses JSON response into 14 week objects
5. **Loop - Create Weeks1** - Iterates through 14 weeks (batch size 1)
6. **Create a row** - Creates week record in Supabase (runs 14 times)
7. **Return Success** - Returns success confirmation

---

### 2. Feedback & Iterate (`feedback-and-iterate.json`)

**Purpose**: Process weekly lecturer feedback and auto-update affected weeks

**Flow**:
```
Webhook (POST with feedback)
  → Store feedback in feedback_journals table
  → Analyze feedback with Gemini
  → Identify affected weeks (weeks that need adjustment)
  → For each affected week:
     ├→ Regenerate week content via Gemini
     └→ Update weeks table with new content
  → Return success
```

**Endpoint**: `POST /webhook/teaching-genome/feedback`

**Request Body**:
```json
{
  "course_id": "uuid",
  "week_number": 5,
  "reflection_text": "Students struggled with the recursion concept. Need more examples and visual explanations. The discussion prompts were too complex for this group."
}
```

**Response**:
```json
{
  "ok": true,
  "message": "Feedback processed. Weeks updated and ready for review."
}
```

**Features**:
- ✅ Stores lecturer reflection in `feedback_journals` table
- ✅ Analyzes feedback with Gemini to identify key issues
- ✅ Determines which future weeks are affected
- ✅ Regenerates teaching notes, discussion prompts, activities for affected weeks
- ✅ Updates week records automatically
- ✅ Loops through multiple affected weeks efficiently
- ✅ Returns confirmation when all updates complete

**Data Extracted from Feedback**:
- Concept struggles (what students found difficult)
- Timing issues (pacing problems)
- Engagement notes (what worked/didn't work)
- Suggestions (lecturer recommendations)
- Affected weeks (week numbers to update)

**Data Generated per Affected Week**:
- Updated teaching notes (addressing feedback issues)
- Updated discussion prompts (3-5 per week)
- Updated activity ideas (2-4 per week)

**Nodes**:
1. **Webhook - Weekly Feedback** - Receives POST with reflection text
2. **Store Feedback** - Saves reflection in `feedback_journals` table
3. **Extract Issues** - Calls Gemini to analyze feedback
4. **Generate Adjustment** - Calls Gemini to regenerate affected weeks
5. **Code in JavaScript** - Parses JSON response into week objects
6. **Loop - Affected Weeks** - Iterates through each affected week
7. **Regenerate Week Content** - Calls Gemini to improve week content
8. **Store Updated Week** - Updates `weeks` table (runs once per affected week)
9. **Return Processed** - Returns success confirmation

---

### 3. Generate Week PDF (`generate-week-pdf.json`)

**Purpose**: Generate beautiful PDF slides for a specific course week

**Flow**:
```
Webhook (POST) 
  → Fetch Week Data from Supabase 
  → Call Gemini API 
  → Build PDF with raw operators 
  → Return binary PDF
```

**Endpoint**: `POST /webhook/teaching-genome/generate-pdf`

**Request Body**:
```json
{
  "course_id": "uuid",
  "week_number": 5
}
```

**Response**: Binary PDF file

**Features**:
- ✅ Parses Gemini output with "SECTION:" format
- ✅ Builds PDF with raw operators (no dependencies)
- ✅ Colored section headers (Blue, Green, Purple, Orange)
- ✅ Automatic page breaks
- ✅ Footer with week number and page count
- ✅ Support for learning objectives, activities, discussion topics
- ✅ Teaching notes on final page

**Nodes**:
1. **Webhook - Generate PDF** - Listens for POST requests
2. **Fetch Week Data** - Queries Supabase for week details
3. **Generate PDF** - Calls Google Gemini with prompt
4. **Build PDF** - Creates PDF with raw operators
5. **Return PDF** - Encodes to binary
6. **Respond to Webhook** - Returns file to client

---

## Setup Instructions

### Prerequisites: Supabase Tables & Storage Bucket

**IMPORTANT**: All workflows require specific Supabase tables and a Storage bucket.

#### Create Required Tables

In Supabase SQL Editor, run:

```sql
-- Feedback Journals (for feedback processing workflow)
CREATE TABLE IF NOT EXISTS feedback_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL,
  week_number INTEGER NOT NULL,
  lecturer_reflection TEXT,
  status TEXT DEFAULT 'submitted',
  created_at TIMESTAMP DEFAULT now()
);

-- Courses Table (for upload/generate workflow)
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lecturer_id UUID,
  module_code TEXT NOT NULL,
  module_name TEXT NOT NULL,
  cohort_type TEXT,
  module_descriptor_pdf_url TEXT,
  preferences JSONB,
  academic_year TEXT,
  semester TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Weeks Table (for all workflows)
CREATE TABLE IF NOT EXISTS weeks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES courses(id),
  week_number INTEGER NOT NULL,
  topic TEXT,
  learning_objectives JSONB,
  teaching_methods TEXT,
  content_summary TEXT,
  discussion_prompts JSONB,
  teaching_notes TEXT,
  activity_ideas JSONB,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT now()
);
```

#### Create Storage Bucket

1. Go to **Supabase Dashboard** → **Storage**
2. Click **"Create a new bucket"**
3. Configure:
   - **Name**: `module-descriptors`
   - **Public bucket**: Toggle ON (allows PDF downloads)
   - **File size limit**: 50 MB
4. Click **Create bucket**

#### Set Bucket Policies

In **Storage** → **module-descriptors** → **Policies**:

Add policy to allow authenticated users to upload:
```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'module-descriptors' AND
  (auth.role() = 'authenticated')
);
```

Add policy to allow public access (for downloads):
```sql
CREATE POLICY "Allow public downloads"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'module-descriptors');
```

#### Upload Test File

1. In Supabase Storage → **module-descriptors**
2. Click **Upload file**
3. Select a PDF file
4. Copy the **Public URL**
5. Use this URL in webhook requests

**Example URL**:
```
https://your-project.supabase.co/storage/v1/object/public/module-descriptors/course_1.pdf
```

---

### 1. Import Workflows

In n8n:
1. Click "Workflows" → "+ New"
2. Click "Import from file"
3. Select `generate-week-pdf.json`
4. Click "Import"

### 2. Configure Credentials

**Supabase**:
1. Click "Fetch Week Data" node
2. Set credentials to your Supabase account
3. Configure table: `weeks`

**Google Gemini**:
1. Click "Generate PDF" node
2. Set credentials to your Gemini API key
3. Model: `gemini-2.5-flash`

### 3. Get Webhook URL

1. Click "Webhook - Generate PDF" node
2. Copy "Webhook URL"
3. Add to `.env.local`:
   ```
   NEXT_PUBLIC_N8N_WEBHOOK_URL=https://your-n8n.com/webhook/teaching-genome/generate-pdf
   ```

### 4. Test

```bash
curl -X POST https://your-n8n.com/webhook/teaching-genome/generate-pdf \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": "550e8400-e29b-41d4-a716-446655440000",
    "week_number": 5
  }'
```

---

## Customization

### Change Colors

In **Build PDF** node, modify color values (RGB):

```javascript
var BLUE   = '0.0 0.4 0.8';      // Section headers
var GREEN  = '0.15 0.68 0.38';   // Learning objectives
var PURPLE = '0.56 0.27 0.68';   // Teaching notes
var ORANGE = '0.9 0.5 0.13';     // Activities
```

### Change Font Sizes

```javascript
// Title page
'BT /F2 28 Tf ...' // 28pt
'BT /F2 20 Tf ...' // 20pt

// Section headers
'BT /F2 18 Tf ...' // 18pt

// Body text
'BT /F1 10 Tf ...' // 10pt
```

### Change Page Layout

```javascript
// Page dimensions (A4: 595.28 x 841.89 points)
/MediaBox [0 0 595.28 841.89]

// Margins
var indent = 50;  // Left margin
var y = 790;      // Top margin

// Footer position
p.y < 60  // Page break threshold
```

---

## Troubleshooting

### "Week not found"
- Verify course_id and week_number exist in Supabase
- Check Supabase credentials are correct

### "Gemini API error"
- Verify API key is valid
- Check API quota not exceeded
- Ensure model `gemini-2.5-flash` is available

### "PDF appears blank"
- Check Gemini output contains "SECTION:" headers
- Verify text encoding (should be latin1)
- Check PDF viewer supports uncompressed streams

### "Webhook not triggering"
- Verify n8n instance is running
- Check webhook URL is correct
- Review n8n logs for errors

---

## Deployment

### Cloud (n8n.cloud)
1. Sign up at https://n8n.cloud
2. Import workflow via UI
3. Configure credentials
4. Activate workflow

### Self-Hosted (Docker)
```bash
docker run -d \
  -p 5678:5678 \
  -e DB_TYPE=sqlite \
  -e N8N_USER_MANAGEMENT_DISABLED=true \
  n8nio/n8n
```

Then import workflow via http://localhost:5678

---

## Performance

- **Average execution time**: 8-12 seconds
- **PDF size**: 50-300 KB (depending on content)
- **Rate limit**: 100 requests/hour (free Gemini tier)

---

## Next Workflows

Coming soon:
- Course creation automation
- Feedback processing with Gemini
- Suggestion generation
- Email notifications

---

**Need help?** Check [n8n Docs](https://docs.n8n.io) or open a GitHub issue!

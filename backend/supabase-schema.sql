-- Teaching Genome Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================
-- LECTURERS
-- ========================
CREATE TABLE IF NOT EXISTS lecturers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  institution TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========================
-- COURSES (Multiple Courses per Lecturer)
-- ========================
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lecturer_id UUID NOT NULL REFERENCES lecturers(id) ON DELETE CASCADE,
  module_code TEXT NOT NULL,
  module_name TEXT NOT NULL,
  module_descriptor_pdf_url TEXT,
  cohort_type TEXT NOT NULL, -- e.g., "first-year nursing", "final-year business"
  preferences JSONB NOT NULL DEFAULT '{}'::jsonb, -- teaching_style, pace, assessment_type
  academic_year TEXT NOT NULL, -- e.g., "2024-2025"
  semester TEXT NOT NULL, -- "Spring", "Fall", "Summer"
  status TEXT NOT NULL DEFAULT 'draft', -- draft, ready, in_progress, completed
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(lecturer_id, module_code, academic_year, semester)
);

-- ========================
-- WEEKS (14-week breakdown)
-- ========================
CREATE TABLE IF NOT EXISTS weeks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  week_number INT NOT NULL CHECK (week_number >= 1 AND week_number <= 14),
  topic TEXT NOT NULL,
  learning_objectives JSONB NOT NULL DEFAULT '[]'::jsonb, -- array of strings
  teaching_methods JSONB NOT NULL DEFAULT '[]'::jsonb, -- array with method, duration, resources
  content_summary TEXT,
  powerpoint_url TEXT,
  teaching_notes TEXT,
  discussion_prompts JSONB DEFAULT '[]'::jsonb, -- array of prompts
  activity_ideas JSONB DEFAULT '[]'::jsonb, -- array of activities
  suggested_images JSONB DEFAULT '[]'::jsonb, -- DALL-E prompts for images
  status TEXT NOT NULL DEFAULT 'draft', -- draft, pending_review, approved, taught
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(course_id, week_number)
);

-- ========================
-- FEEDBACK JOURNALS (Weekly Reflections)
-- ========================
CREATE TABLE IF NOT EXISTS feedback_journals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  week_number INT NOT NULL CHECK (week_number >= 1 AND week_number <= 14),
  lecturer_reflection TEXT NOT NULL, -- raw text from lecturer
  sentiment_score FLOAT CHECK (sentiment_score >= -1 AND sentiment_score <= 1),
  key_issues JSONB NOT NULL DEFAULT '{}'::jsonb, -- extracted: concept_struggles, timing_issues, engagement_notes
  status TEXT NOT NULL DEFAULT 'submitted', -- submitted, processed, applied
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  FOREIGN KEY (course_id, week_number) REFERENCES weeks(course_id, week_number)
);

-- ========================
-- WEEK ADJUSTMENTS (Changes Applied)
-- ========================
CREATE TABLE IF NOT EXISTS week_adjustments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  feedback_journal_id UUID NOT NULL REFERENCES feedback_journals(id) ON DELETE CASCADE,
  affected_weeks INT[] NOT NULL, -- which future weeks were changed
  adjustments_made JSONB NOT NULL DEFAULT '{}'::jsonb, -- reordered_topics, added_review, replaced_examples, changed_pace
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========================
-- COURSE REFLECTIONS (End-of-Semester)
-- ========================
CREATE TABLE IF NOT EXISTS course_reflections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  reflection_text TEXT NOT NULL, -- full semester summary
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'submitted', -- submitted, processed
  processed_at TIMESTAMPTZ
);

-- ========================
-- EVOLUTION SUGGESTIONS (Improvements for Next Time)
-- ========================
CREATE TABLE IF NOT EXISTS evolution_suggestions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  course_reflection_id UUID NOT NULL REFERENCES course_reflections(id) ON DELETE CASCADE,
  suggestion TEXT NOT NULL, -- specific suggestion
  category TEXT NOT NULL, -- reorder, remove, swap_method, add_activity, timeline_adjustment
  affected_weeks INT[] NOT NULL, -- which weeks affected
  confidence_score FLOAT NOT NULL DEFAULT 0.5 CHECK (confidence_score >= 0 AND confidence_score <= 1),
  status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected, applied
  lecturer_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_at TIMESTAMPTZ,
  applied_at TIMESTAMPTZ
);

-- ========================
-- ROW LEVEL SECURITY (RLS)
-- ========================

-- Enable RLS on all tables
ALTER TABLE lecturers ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE week_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE evolution_suggestions ENABLE ROW LEVEL SECURITY;

-- Lecturers can only see their own data
CREATE POLICY lecturer_select ON lecturers
  FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY lecturer_update ON lecturers
  FOR UPDATE USING (auth.uid()::text = id::text);

-- Courses: lecturers can only see/edit their own courses
CREATE POLICY course_select ON courses
  FOR SELECT USING (lecturer_id::text = auth.uid()::text);

CREATE POLICY course_insert ON courses
  FOR INSERT WITH CHECK (lecturer_id::text = auth.uid()::text);

CREATE POLICY course_update ON courses
  FOR UPDATE USING (lecturer_id::text = auth.uid()::text);

-- Weeks: only accessible through their course
CREATE POLICY week_select ON weeks
  FOR SELECT USING (
    course_id IN (
      SELECT id FROM courses WHERE lecturer_id::text = auth.uid()::text
    )
  );

CREATE POLICY week_insert ON weeks
  FOR INSERT WITH CHECK (
    course_id IN (
      SELECT id FROM courses WHERE lecturer_id::text = auth.uid()::text
    )
  );

CREATE POLICY week_update ON weeks
  FOR UPDATE USING (
    course_id IN (
      SELECT id FROM courses WHERE lecturer_id::text = auth.uid()::text
    )
  );

-- Similar policies for feedback_journals, week_adjustments, course_reflections, evolution_suggestions
CREATE POLICY feedback_select ON feedback_journals
  FOR SELECT USING (
    course_id IN (
      SELECT id FROM courses WHERE lecturer_id::text = auth.uid()::text
    )
  );

CREATE POLICY feedback_insert ON feedback_journals
  FOR INSERT WITH CHECK (
    course_id IN (
      SELECT id FROM courses WHERE lecturer_id::text = auth.uid()::text
    )
  );

CREATE POLICY feedback_update ON feedback_journals
  FOR UPDATE USING (
    course_id IN (
      SELECT id FROM courses WHERE lecturer_id::text = auth.uid()::text
    )
  );

-- ========================
-- INDEXES (Performance)
-- ========================
CREATE INDEX idx_courses_lecturer_id ON courses(lecturer_id);
CREATE INDEX idx_weeks_course_id ON weeks(course_id);
CREATE INDEX idx_feedback_course_id ON feedback_journals(course_id);
CREATE INDEX idx_week_adjustments_course_id ON week_adjustments(course_id);
CREATE INDEX idx_course_reflections_course_id ON course_reflections(course_id);
CREATE INDEX idx_evolution_suggestions_course_id ON evolution_suggestions(course_id);
CREATE INDEX idx_evolution_suggestions_status ON evolution_suggestions(status);
CREATE INDEX idx_weeks_status ON weeks(status);

-- ========================
-- VIEWS (Useful Queries)
-- ========================

-- Lecturers with their course counts
CREATE VIEW lecturer_stats AS
SELECT 
  l.id,
  l.name,
  l.email,
  COUNT(c.id) as total_courses,
  COUNT(CASE WHEN c.status = 'in_progress' THEN 1 END) as active_courses,
  COUNT(CASE WHEN c.status = 'completed' THEN 1 END) as completed_courses
FROM lecturers l
LEFT JOIN courses c ON l.id = c.lecturer_id
GROUP BY l.id, l.name, l.email;

-- Course progress summary
CREATE VIEW course_progress AS
SELECT 
  c.id,
  c.module_name,
  c.academic_year,
  c.semester,
  c.status,
  COUNT(CASE WHEN w.status = 'approved' THEN 1 END) as approved_weeks,
  COUNT(w.id) as total_weeks,
  COUNT(fj.id) as feedback_submitted,
  COUNT(CASE WHEN es.status = 'approved' THEN 1 END) as approved_suggestions
FROM courses c
LEFT JOIN weeks w ON c.id = w.course_id
LEFT JOIN feedback_journals fj ON c.id = fj.course_id
LEFT JOIN evolution_suggestions es ON c.id = es.course_id
GROUP BY c.id, c.module_name, c.academic_year, c.semester, c.status;

-- migrate:up

-- ============================================================================
-- SEED DATA (realistic demo data)
-- ============================================================================

WITH upserted_users AS (
  INSERT INTO users (email, full_name, password_hash, is_active)
  VALUES
    ('john.doe@example.com',    'John Doe',    '$2b$12$seed_john',   TRUE),
    ('jane.singh@example.com',  'Jane Singh',  '$2b$12$seed_jane',   TRUE),
    ('morris.chen@example.com', 'Morris Chen', '$2b$12$seed_morris', TRUE),
    ('bob.khan@example.com',    'Bob Khan',    '$2b$12$seed_bob',    TRUE),
    ('nina.roy@example.com',    'Nina Roy',    '$2b$12$seed_nina',   TRUE)
  ON CONFLICT (email) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        password_hash = EXCLUDED.password_hash,
        is_active = EXCLUDED.is_active,
        updated_at = CURRENT_TIMESTAMP
  RETURNING id, email, full_name
),

upserted_profiles AS (
  INSERT INTO user_profiles (user_id, full_name, bio, avatar_url, timezone)
  SELECT
    u.id,
    u.full_name,
    CASE u.email
      WHEN 'john.doe@example.com'    THEN 'Product-minded PM focused on delivery and stakeholder alignment.'
      WHEN 'jane.singh@example.com'  THEN 'Backend engineer specializing in APIs, auth, and performance.'
      WHEN 'morris.chen@example.com' THEN 'UX designer bridging research, IA, and interaction design.'
      WHEN 'bob.khan@example.com'    THEN 'Frontend developer (React/TypeScript) with an eye for polish.'
      WHEN 'nina.roy@example.com'    THEN 'Data engineer supporting analytics pipelines and migrations.'
      ELSE 'Team member'
    END,
    'https://i.pravatar.cc/150?u=' || u.email,
    CASE u.email
      WHEN 'john.doe@example.com'    THEN 'Asia/Kolkata'
      WHEN 'jane.singh@example.com'  THEN 'Asia/Kolkata'
      WHEN 'morris.chen@example.com' THEN 'America/Los_Angeles'
      WHEN 'bob.khan@example.com'    THEN 'Europe/London'
      WHEN 'nina.roy@example.com'    THEN 'Asia/Singapore'
      ELSE 'UTC'
    END
  FROM upserted_users u
  ON CONFLICT (user_id) DO UPDATE
    SET full_name  = EXCLUDED.full_name,
        bio        = EXCLUDED.bio,
        avatar_url = EXCLUDED.avatar_url,
        timezone   = EXCLUDED.timezone,
        updated_at = CURRENT_TIMESTAMP
  RETURNING user_id
),

inserted_projects AS (
  INSERT INTO projects (name, description, status, owner_id)
  VALUES
    (
      'Website Redesign',
      'Modernize marketing site: new IA, refreshed visuals, improved performance and accessibility.',
      'active'::project_status,
      (SELECT id FROM upserted_users WHERE email = 'john.doe@example.com')
    ),
    (
      'Mobile App Development',
      'Customer app MVP: onboarding, profile, and core workflows with a stable API contract.',
      'active'::project_status,
      (SELECT id FROM upserted_users WHERE email = 'jane.singh@example.com')
    ),
    (
      'Database Migration',
      'Migrate legacy DB to Postgres: schema cleanup, data validation, and rollback-ready cutover.',
      'active'::project_status,
      (SELECT id FROM upserted_users WHERE email = 'nina.roy@example.com')
    )
  ON CONFLICT DO NOTHING
  RETURNING id, name
),

all_projects AS (
  SELECT id, name FROM inserted_projects
  UNION ALL
  SELECT p.id, p.name
  FROM projects p
  WHERE p.name IN ('Website Redesign', 'Mobile App Development', 'Database Migration')
),

seed_members AS (
  INSERT INTO project_members (project_id, user_id, role)
  SELECT p.id, u.id, m.role::member_role
  FROM (
    VALUES
      ('Website Redesign',        'john.doe@example.com',    'owner'),
      ('Website Redesign',        'bob.khan@example.com',    'admin'),
      ('Website Redesign',        'morris.chen@example.com', 'member'),
      ('Website Redesign',        'jane.singh@example.com',  'viewer'),

      ('Mobile App Development',  'jane.singh@example.com',  'owner'),
      ('Mobile App Development',  'john.doe@example.com',    'admin'),
      ('Mobile App Development',  'bob.khan@example.com',    'member'),

      ('Database Migration',      'nina.roy@example.com',    'owner'),
      ('Database Migration',      'jane.singh@example.com',  'admin'),
      ('Database Migration',      'john.doe@example.com',    'member')
  ) AS m(project_name, user_email, role)
  JOIN all_projects p ON p.name = m.project_name
  JOIN upserted_users u ON u.email = m.user_email
  ON CONFLICT (project_id, user_id) DO UPDATE
    SET role = EXCLUDED.role,
        updated_at = CURRENT_TIMESTAMP
  RETURNING project_id, user_id
),

inserted_tasks AS (
  INSERT INTO tasks (project_id, title, description, priority, status, due_date, assigned_to)
  SELECT
    p.id,
    t.title,
    t.description,
    t.priority::task_priority,
    t.status::task_status,
    t.due_date::date,
    u.id
  FROM (
    VALUES
      -- Website Redesign
      ('Website Redesign', 'Audit current pages',        'Inventory existing pages, track gaps, and capture key metrics.',          'medium', 'completed',   '2026-03-02', 'john.doe@example.com'),
      ('Website Redesign', 'Design new homepage',        'Homepage layout + hero, social proof section, and responsive variants.',  'high',   'review',      '2026-03-06', 'morris.chen@example.com'),
      ('Website Redesign', 'Implement landing pages',    'Build React + Tailwind pages, ensure Lighthouse score >= 90.',            'high',   'in_progress', '2026-03-12', 'bob.khan@example.com'),
      ('Website Redesign', 'Accessibility pass',         'Fix contrast, headings, keyboard nav; validate with WCAG checks.',        'medium', 'pending',     '2026-03-15', 'bob.khan@example.com'),

      -- Mobile App Development
      ('Mobile App Development', 'Define API contract',  'Finalize endpoints, auth strategy, and error format; share with mobile.',  'high',   'in_progress', '2026-03-07', 'jane.singh@example.com'),
      ('Mobile App Development', 'Prototype onboarding', 'Clickable onboarding flow prototype and usability feedback notes.',       'medium', 'pending',     '2026-03-10', 'morris.chen@example.com'),
      ('Mobile App Development', 'Push notification POC','Spike push provider setup and delivery testing for Android/iOS.',          'low',    'pending',     '2026-03-18', 'john.doe@example.com'),

      -- Database Migration
      ('Database Migration', 'Migration plan + rollback','Step-by-step cutover plan with rollback checklist and owner assignments.',  'high',   'in_progress', '2026-03-11', 'nina.roy@example.com'),
      ('Database Migration', 'Schema mapping',           'Map legacy tables -> new schema; document transformations & constraints.',  'high',   'pending',     '2026-03-14', 'nina.roy@example.com'),
      ('Database Migration', 'Data validation scripts',  'Write checksums and row-level validation queries for critical tables.',     'medium', 'pending',     '2026-03-20', 'jane.singh@example.com')
  ) AS t(project_name, title, description, priority, status, due_date, assignee_email)
  JOIN all_projects p ON p.name = t.project_name
  JOIN upserted_users u ON u.email = t.assignee_email
  RETURNING id, project_id, title, assigned_to
),

inserted_comments AS (
  INSERT INTO task_comments (task_id, user_id, content)
  SELECT
    it.id,
    cu.id,
    c.content
  FROM inserted_tasks it
  JOIN tasks tk ON tk.id = it.id
  JOIN upserted_users cu ON cu.email = c.commenter_email
  JOIN (
    VALUES
      ('Design new homepage',      'john.doe@example.com',   'Please include a variant optimized for faster LCP on mobile.'),
      ('Implement landing pages',  'jane.singh@example.com', 'Let’s standardize form error handling and tracking events.'),
      ('Define API contract',      'bob.khan@example.com',   'Can we lock response envelope shape this sprint to unblock FE?'),
      ('Migration plan + rollback','john.doe@example.com',   'Add a clear “no-go” checklist and a downtime estimate.')
  ) AS c(task_title, commenter_email, content)
    ON c.task_title = it.title
  RETURNING id, task_id
)

INSERT INTO activity_logs (project_id, task_id, user_id, action, metadata)
SELECT
  tk.project_id,
  tk.id,
  tk.assigned_to,
  'TASK_CREATED',
  jsonb_build_object(
    'title', tk.title,
    'priority', tk.priority,
    'status', tk.status,
    'due_date', tk.due_date
  )
FROM inserted_tasks it
JOIN tasks tk ON tk.id = it.id;

-- migrate:down

TRUNCATE TABLE activity_logs CASCADE;
TRUNCATE TABLE task_comments CASCADE;
TRUNCATE TABLE project_members CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE projects CASCADE;
TRUNCATE TABLE user_profiles CASCADE;
TRUNCATE TABLE users CASCADE;
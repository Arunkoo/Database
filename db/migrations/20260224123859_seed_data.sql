-- migrate:up

WITH inserted_users AS (
    INSERT INTO users (email, full_name, password_hash)
    VALUES
        ('john@example.com', 'John', 'hashed_pw_1'),
        ('jane@example.com', 'Jane', 'hashed_pw_2'),
        ('morris@example.com', 'Morris', 'hashed_pw_3'),
        ('bob@example.com', 'Bob', 'hashed_pw_4')
    RETURNING id, email, full_name
),

inserted_profiles AS (
    INSERT INTO user_profiles (user_id, avatar_url, bio, full_name, timezone)
    SELECT 
        id,
        'https://example.com/avatar' || row_number() OVER (ORDER BY email) || '.jpg',
        CASE 
            WHEN email LIKE 'john%'   THEN 'Project Manager with 5 yrs experience'
            WHEN email LIKE 'jane%'   THEN 'Senior Developer'
            WHEN email LIKE 'morris%' THEN 'UX Designer'
            WHEN email LIKE 'bob%'    THEN 'Frontend Developer'
            ELSE 'Business Analyst'
        END,
        full_name,
        'Asia/Kolkata'
    FROM inserted_users
    RETURNING user_id
),

inserted_projects AS (
    INSERT INTO projects (name, description, status, owner_id)
    SELECT
        unnest(ARRAY[
            'Website Redesign',
            'Mobile App Development',
            'Database Migration'
        ]),
        unnest(ARRAY[
            'Complete overhaul of company website',
            'New mobile app for customers',
            'Migration legacy database to new system'
        ]),
        unnest(ARRAY[
            'active'::project_status,
            'active'::project_status,
            'active'::project_status
        ]),
        (SELECT id FROM inserted_users WHERE email = 'john@example.com')
    RETURNING id, name
),

inserted_tasks AS (
  INSERT INTO tasks (project_id, title, description, priority, status, due_date, assigned_to)
  SELECT
    p.id,
    t.title,
    t.description,
    t.priority,
    t.status,
    t.due_date,
    u.id
  FROM (
    SELECT
      'Website Redesign' AS project_name,
      'Design Homepage' AS title,
      'Create new homepage design' AS description,
      'low'::task_priority AS priority,
      'pending'::task_status AS status,
      '2026-03-05'::date AS due_date,
      'bob@example.com' AS assignee_email

    UNION ALL

    SELECT
      'Website Redesign',
      'Implement Frontend',
      'Build responsive pages using React + Tailwind',
      'medium'::task_priority,
      'in_progress'::task_status,
      '2026-03-10'::date,
      'jane@example.com'

    UNION ALL

    SELECT
      'Mobile App Development',
      'Create API Contract',
      'Finalize endpoints & payload contracts for mobile app',
      'high'::task_priority,
      'review'::task_status,
      '2026-03-08'::date,
      'john@example.com'

    UNION ALL

    SELECT
      'Database Migration',
      'Plan Migration Steps',
      'Prepare migration plan, rollback strategy, and timeline',
      'high'::task_priority,
      'pending'::task_status,
      '2026-03-12'::date,
      'john@example.com'
  ) t
  JOIN inserted_projects p
    ON p.name = t.project_name
  JOIN inserted_users u
    ON u.email = t.assignee_email
  RETURNING id, project_id, title
)

INSERT INTO project_members (project_id, user_id, role)
SELECT 
    p.id,
    u.id,
    m.role::member_role
FROM (
    SELECT 'Website Redesign' AS project_name, 'john@example.com'   AS user_email, 'owner'  AS role
    UNION ALL SELECT 'Website Redesign',        'jane@example.com',   'admin'
    UNION ALL SELECT 'Website Redesign',        'morris@example.com', 'member'
    UNION ALL SELECT 'Website Redesign',        'bob@example.com',    'member'
    UNION ALL SELECT 'Mobile App Development',  'john@example.com',   'owner'
    UNION ALL SELECT 'Mobile App Development',  'jane@example.com',   'admin'
    UNION ALL SELECT 'Database Migration',      'john@example.com',   'owner'
) m
JOIN inserted_projects p
  ON p.name = m.project_name
JOIN inserted_users u
  ON u.email = m.user_email
RETURNING project_id, user_id;

-- migrate:down

TRUNCATE TABLE project_members CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE projects CASCADE;
TRUNCATE TABLE user_profiles CASCADE;
TRUNCATE TABLE users CASCADE;
-- migrate:up

-- Project status (overall project state)
CREATE TYPE project_status AS ENUM (
  'planned',
  'active',
  'on_hold',
  'completed',
  'archived'
);

-- Task status (individual task lifecycle)
CREATE TYPE task_status AS ENUM (
  'pending',
  'in_progress',
  'completed',
  'review',
  'cancelled'
);

CREATE TYPE task_priority AS ENUM(
  'low',
  'medium',
  'high'
);
-- Member role (role of a user in a project)
CREATE TYPE member_role AS ENUM (
  'owner',
  'admin',
  'member',
  'viewer'
);

-- users tabble
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT NOT NULL UNIQUE,
  full_name     TEXT NOT NULL,
  password_hash TEXT NOT NULL,             
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_profiles (
  user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  full_name    TEXT,
  bio          TEXT,
  avatar_url   TEXT,
  timezone     TEXT,                        -- e.g. 'Asia/Kolkata'
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  status project_status NOT NULL DEFAULT 'active',
  owner_id UUID NOT NULL REFERENCES users ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- one to many with projects..
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  project_id UUID NOT NULL
    REFERENCES projects
    ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT,

  status task_status NOT NULL DEFAULT 'in_progress',
  priority task_priority NOT NULL DEFAULT 'low',
  due_date DATE,
  assigned_to UUID REFERENCES users ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE project_members (

  project_id UUID NOT NULL
    REFERENCES projects
    ON DELETE CASCADE,

  user_id UUID NOT NULL
    REFERENCES users
    ON DELETE CASCADE,

  role member_role NOT NULL DEFAULT 'member',

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, user_id)
);
-- migrate:down

DROP TABLE IF EXISTS project_members
DROP TABLE IF EXISTS tasks
DROP TABLE IF EXISTS projects
DROP TABLE IF EXISTS user_profiles
DROP TABLE IF EXISTS users

DROP TYPE IF EXISTS project_status
DROP TYPE IF EXISTS task_status
DROP TYPE IF EXISTS task_priority
DROP TYPE IF EXISTS member_role


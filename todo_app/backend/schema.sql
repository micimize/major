create extension if not exists "uuid-ossp";

CREATE TYPE task_lifecycle AS ENUM (
  'TODO',
  'COMPLETED',
  'CANCELLED'
);


CREATE TABLE task (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  lifecycle       task_lifecycle default 'TODO',
  title           TEXT CHECK (char_length(title) < 280),
  description     TEXT
);

COMMENT ON COLUMN task.id IS 'Primary Key for Tasks';


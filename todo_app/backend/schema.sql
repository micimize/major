create extension if not exists "uuid-ossp";

create domain finite_datetime as timestamptz check (
   value != 'infinity'
);


CREATE TYPE task_lifecycle AS ENUM (
  'TODO',
  'COMPLETED',
  'CANCELLED'
);


CREATE TABLE task (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  lifecycle       task_lifecycle default 'TODO',
  title           TEXT CHECK (char_length(title) < 280),
  description     TEXT,
  updated         finite_datetime NOT NULL DEFAULT NOW(),
);

COMMENT ON COLUMN task.id IS 'Primary Key for Tasks';


CREATE OR REPLACE FUNCTION update_task_updated()   
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = now();
    RETURN NEW;   
END;
$$ language 'plpgsql';

CREATE TRIGGER update_task_updated
BEFORE UPDATE ON task
FOR EACH ROW
  EXECUTE PROCEDURE update_task_updated();

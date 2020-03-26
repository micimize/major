create extension if not exists "uuid-ossp";

CREATE FUNCTION uuid_timestamp(id uuid) RETURNS timestamptz AS $$
  select TIMESTAMP WITH TIME ZONE 'epoch' +
      (((('x' || lpad(split_part(id::text, '-', 1), 16, '0'))::bit(64)::bigint) +
      (('x' || lpad(split_part(id::text, '-', 2), 16, '0'))::bit(64)::bigint << 32) +
      ((('x' || lpad(split_part(id::text, '-', 3), 16, '0'))::bit(64)::bigint&4095) << 48) - 122192928000000000) / 10000000 ) * INTERVAL '1 second';
$$ LANGUAGE SQL
  IMMUTABLE
  RETURNS NULL ON NULL INPUT;

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

CREATE FUNCTION task_created(task task) RETURNS finite_datetime AS $$
  SELECT cast(uuid_timestamp(task.id) as finite_datetime)
$$ LANGUAGE sql STABLE;

COMMENT ON COLUMN task.id IS 'Primary Key for Tasks';


CREATE OR REPLACE FUNCTION update_task_updated()   
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated = now();
    RETURN NEW;   
END;
$$ language 'plpgsql';

CREATE TRIGGER update_task_updated
BEFORE UPDATE ON task
FOR EACH ROW
  EXECUTE PROCEDURE update_task_updated();


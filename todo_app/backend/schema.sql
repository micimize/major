create extension if not exists "uuid-ossp";

CREATE FUNCTION uuid_timestamp(id uuid) RETURNS timestamptz AS $$
  select TIMESTAMP WITH TIME ZONE 'epoch' +
      (
        (
          (('x' || lpad(split_part(id::text, '-', 1), 16, '0'))::bit(64)::bigint) +
          (('x' || lpad(split_part(id::text, '-', 2), 16, '0'))::bit(64)::bigint << 32) +
          ((('x' || lpad(split_part(id::text, '-', 3), 16, '0'))::bit(64)::bigint&4095) << 48) -
          122192928000000000
        ) / 10000000
      ) * INTERVAL '1 second';
$$ LANGUAGE SQL
  IMMUTABLE
  RETURNS NULL ON NULL INPUT;

create DOMAIN finite_datetime AS TIMESTAMPTZ CHECK (
   value != 'infinity'
);

CREATE TYPE task_lifecycle AS ENUM (
  'TODO',
  'COMPLETED',
  'CANCELLED'
);

CREATE TYPE datetime_interval AS (
  "start" finite_datetime,
  "end" finite_datetime
);

/*
CREATE DOMAIN stopwatch_interval AS datetime_interval[];
CHECK (
  SELECT * FROM UNNEST(VALUE)
  WHERE "end" is null
);
*/

CREATE TABLE task (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  updated            finite_datetime NOT NULL DEFAULT NOW(),

  lifecycle          task_lifecycle default 'TODO',
  closed             finite_datetime,

  title              TEXT CHECK (char_length(title) < 280),
  description        TEXT,
  stopwatch_value    datetime_interval[]
);
-- TODO check completed when lifecycle is completed

CREATE FUNCTION task_created(task task) RETURNS finite_datetime AS $$
  SELECT cast(uuid_timestamp(task.id) AS finite_datetime)
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION task_created(task) IS E'@sortable';

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



/*
CREATE DOMAIN timezone AS TEXT NOT NULL CHECK (
  now() AT TIME ZONE VALUE IS NOT NULL
);
 -- finite_datetime user_start_of_day)
*/

-- TODO should we surface a simple last "24 hours"
-- OR surface everything > user's "start of day"
CREATE OR REPLACE FUNCTION current_tasks(
  closed_buffer INTERVAL  DEFAULT '24 hours'
)
  RETURNS SETOF task AS $$
    SELECT * FROM task
    WHERE
      COALESCE(closed, now()) > (
        now() - $1
      )
    ORDER BY
      task_created(task)
    DESC
$$ LANGUAGE SQL STABLE;

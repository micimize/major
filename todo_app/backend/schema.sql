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

-- a bit of a stub for future configurations 
-- / an orchestration point for user facets
CREATE TABLE app_user (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v1mc()
);


CREATE TYPE google_sign_in AS (
  -- google id
  id             TEXT,
  email          TEXT,
  email_verified TEXT,
  name           TEXT,
  picture        TEXT,
  given_name     TEXT,
  family_name    TEXT,
  locale         TEXT
);

CREATE TABLE google_user (
  id                    TEXT PRIMARY KEY,
  data                  google_sign_in,
  app_user_id           uuid not null
    UNIQUE REFERENCES app_user (id)
    ON UPDATE CASCADE
);


create function current_sign_in()
  returns google_sign_in as $$
    select (
      nullif(current_setting('google_user.id', true), '')::text,
      nullif(current_setting('google_user.email', true), '')::text,
      nullif(current_setting('google_user.email_verified', true), '')::text,
      nullif(current_setting('google_user.name', true), '')::text,
      nullif(current_setting('google_user.picture', true), '')::text,
      nullif(current_setting('google_user.given_name', true), '')::text,
      nullif(current_setting('google_user.family_name', true), '')::text,
      nullif(current_setting('google_user.locale', true), '')::text
    )::google_sign_in;
$$ language sql stable;


CREATE FUNCTION current_app_user()
  RETURNS app_user AS $$
DECLARE
  signed_in google_sign_in;
  full_user app_user;
BEGIN
    signed_in := current_sign_in();

    IF signed_in.id IS NULL THEN
      RAISE EXCEPTION 'Authentication not provided';
    END IF;


    select * into full_user
    from app_user
    where id in (
      select app_user_id
      from google_user
      where id = signed_in.id limit 1
    ) limit 1;

    IF full_user.id IS NULL THEN
      insert into app_user default values
      returning * into full_user;

      insert into google_user (
        app_user_id,
        id,
        data
      ) values (
        full_user.id,
        signed_in.id,
        signed_in
      );
    END IF;

    RETURN full_user;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION current_user_id()
RETURNS uuid AS $$
  select (current_app_user()).id;
$$ language sql stable;




CREATE OR REPLACE DOMAIN app_public.finite_datetime AS TIMESTAMPTZ CHECK (
  isfinite(value)
);
COMMENT ON DOMAIN finite_datetime IS E'A timezone-enabled timestamp that is guaranteed to be finite';

CREATE OR REPLACE TYPE task_lifecycle AS ENUM (
  'TODO',
  'COMPLETED',
  'CANCELLED'
);

CREATE OR REPLACE TYPE datetime_interval AS (
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

DROP TABLE IF EXISTS task;
CREATE TABLE task (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  user_id            UUID NOT NULL,
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
$$ LANGUAGE 'plpgsql';

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

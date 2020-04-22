/*
    HELPERS AND AUTHENTICATION
    * craetes tg__add_job and finite_datetime, and tg__timestamps helpers
    * creates app_user table, current_app_user, and current_user_id function
*/

drop trigger if exists _100_timestamps on app_public.task;
drop function if exists current_tasks;
drop table if exists task;
drop type if exists task_lifecycle;
drop type if exists datetime_interval;


drop function if exists app_public.current_app_user;
drop table if exists app_public.app_user;
drop function if exists app_public.current_user_id;
drop function if exists app_private.tg__add_job;
drop function if exists app_private.tg__timestamps;

drop domain if exists app_public.finite_datetime;
drop domain if exists app_public.firebase_uid; 

create domain app_public.firebase_uid as varchar ;

create function app_private.tg__add_job() returns trigger as $$
begin
  perform graphile_worker.add_job(tg_argv[0], json_build_object('id', NEW.id), coalesce(tg_argv[1], public.gen_random_uuid()::text));
  return NEW;
end;
$$ language plpgsql volatile security definer set search_path to pg_catalog, public, pg_temp;
comment on function app_private.tg__add_job() is
  E'Useful shortcut to create a job on insert/update. Pass the task name as the first trigger argument, and optionally the queue name as the second argument. The record id will automatically be available on the JSON payload.';

/**********/

create domain app_public.finite_datetime as timestamptz check (
  isfinite(value)
);
comment on domain finite_datetime is E'A timezone-enabled timestamp that is guaranteed to be finite';

/**********/

create function app_private.tg__timestamps() returns trigger as $$
begin
  NEW.created = (case when TG_OP = 'INSERT' then NOW() else OLD.created end);
  NEW.updated = (case when TG_OP = 'UPDATE' and OLD.updated >= NOW() then OLD.updated + interval '1 millisecond' else NOW() end);
  return NEW;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;
comment on function app_private.tg__timestamps() is
  E'This trigger should be called on all tables with created, updated - it ensures that they cannot be manipulated and that updated will always be larger than the previous updated.';

/**********/

create table app_public.app_user (
  id app_public.firebase_uid primary key,
  created app_public.finite_datetime not null default now(),
  updated app_public.finite_datetime not null default now()
);
alter table app_public.app_user enable row level security;

comment on table app_public.app_user is
  E'A user who can log in to the application.';

comment on column app_public.app_user.id is
  E'Unique identifier for the user.';

create trigger _100_timestamps
  before insert or update on app_public.app_user
  for each row
  execute procedure app_private.tg__timestamps();

/**********/

CREATE FUNCTION app_public.current_app_user()
  RETURNS app_public.app_user AS $$
DECLARE
  sign_in_id app_public.firebase_uid;
  full_user app_public.app_user;
BEGIN
    sign_in_id := nullif(
      pg_catalog.current_setting('firebase.user.uid', true),
      ''
    )::app_public.firebase_uid;


    IF sign_in_id IS NULL THEN
      return null;
      --RAISE EXCEPTION 'Authentication not provided';
    END IF;

    SELECT * INTO full_user
    FROM app_public.app_user
    WHERE id = sign_in_id
    LIMIT 1;

    IF full_user.id IS NULL THEN
      INSERT INTO app_public.app_user (
        id
      ) VALUES (
        sign_in_id
      ) RETURNING * INTO full_user;
    END IF;

    RETURN full_user;
END;
$$ LANGUAGE plpgsql;

comment on function app_public.current_app_user() is
  E'The currently logged in user (or null if not logged in).';

/**********/

create function app_public.current_user_id() returns app_public.firebase_uid as $$
  select id from app_public.current_app_user()
$$ language sql stable security definer set search_path to pg_catalog, public, pg_temp;

comment on function app_public.current_user_id() is
  E'Handy method to get the current user ID, etc; in GraphQL, use `currentUser{id}` instead.';
-- We've put this in public, but omitted it, because it's often useful for debugging auth issues.

/**********/

create policy select_all on app_public.app_user for select using (true);
create policy update_self on app_public.app_user for update using (id = app_public.current_user_id());
grant select on app_public.app_user to :DATABASE_VISITOR;
-- NOTE: `insert` is not granted, because we'll handle that separately
-- grant update(username, name, avatar_url) on app_public.app_user to :DATABASE_VISITOR;
-- NOTE: `delete` is not granted, because we require confirmation via request_account_deletion/confirm_account_deletion

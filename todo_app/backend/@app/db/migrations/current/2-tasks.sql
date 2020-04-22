/*
  TASKS
    * Instantiates app_public, app_private, and app_hidden 
    * sets permissions
    * creates a few helper functions
    * creates app_user table and current_user_id auth function
*/

drop trigger if exists _100_timestamps on app_public.task;
drop function if exists current_tasks;
drop table if exists task;
drop type if exists task_lifecycle;
drop type if exists datetime_interval;

create type task_lifecycle as enum (
  'TODO',
  'COMPLETED',
  'CANCELLED'
);

create type datetime_interval as (
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

create table app_public.task (
  user_id            app_public.firebase_uid default app_public.current_user_id()
                        references app_public.app_user(id)
                        on delete set null,
  created            finite_datetime not null default now(),
  updated            finite_datetime not null default now(),

  id                 uuid primary key default uuid_generate_v1mc(),

  lifecycle          task_lifecycle default 'TODO',
  closed             finite_datetime,

  title              text check (char_length(title) < 280),
  description        text,
  stopwatch_value    datetime_interval[]
);
alter table app_public.task enable row level security;

create index task_created_index ON app_public.task (created);


grant
  select,
  insert (lifecycle, closed, title, description, stopwatch_value),
  update (lifecycle, closed, title, description, stopwatch_value),
  delete
on app_public.task to :DATABASE_VISITOR;

create policy manage_own on app_public.task for all using (
  user_id = app_public.current_user_id()
);


create trigger _100_timestamps before insert or update on app_public.task
  for each row execute procedure app_private.tg__timestamps();

/*
CREATE DOMAIN timezone AS TEXT NOT NULL CHECK (
  now() AT TIME ZONE VALUE IS NOT NULL
);
 -- finite_datetime user_start_of_day)
*/

-- TODO should we surface a simple last "24 hours"
-- OR surface everything > user's "start of day"
CREATE OR REPLACE FUNCTION app_public.current_tasks(
  closed_buffer INTERVAL DEFAULT '24 hours'
)
  RETURNS SETOF app_public.task AS $$
    SELECT * FROM app_public.task
    WHERE
      COALESCE(closed, now()) > (
        now() - $1
      )
    ORDER BY
      created
    DESC
$$ LANGUAGE SQL STABLE;

-- create policy select_all on app_public.posts for select using (true);
-- create policy manage_own on app_public.posts for all using (author_id = app_public.current_user_id());
-- create policy manage_as_admin on app_public.posts for all using (exists (select 1 from app_public.users where is_admin is true and id = app_public.current_user_id()));
-- create table app_public.user_feed_posts (
--   id               serial primary key,
--   user_id          int not null references app_public.users on delete cascade,
--   post_id          int not null references app_public.posts on delete cascade,
--   created_at       timestamptz not null default now()
-- );
-- alter table app_public.user_feed_posts enable row level security;

-- grant select on app_public.user_feed_posts to :DATABASE_VISITOR;

-- create policy select_own on app_public.user_feed_posts for select using (user_id = app_public.current_user_id());

-- comment on table app_public.user_feed_posts is 'A feed of `Post`s relevant to a particular `User`.';
-- comment on column app_public.user_feed_posts.id is 'An identifier for this entry in the feed.';
-- comment on column app_public.user_feed_posts.created_at is 'The time this feed item was added.';

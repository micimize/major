
drop type if exists task_lifecycle;
create type task_lifecycle as enum (
  'TODO',
  'COMPLETED',
  'CANCELLED'
);

drop type if exists datetime_interval;
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

drop table if exists task;
create table task (
  id                 uuid primary key default uuid_generate_v1mc(),
  user_id            uuid not null,
  created            finite_datetime not null default now(),
  updated            finite_datetime not null default now(),

  lifecycle          task_lifecycle default 'TODO',
  closed             finite_datetime,

  title              text check (char_length(title) < 280),
  description        text,
  stopwatch_value    datetime_interval[]
);
create trigger _100_timestamps before insert or update on app_public.task
  for each row execute procedure app_private.tg__timestamps();

-- grant
--   select,
--   insert (headline, body, topic),
--   update (headline, body, topic),
--   delete
-- on app_public.posts to :DATABASE_VISITOR;

-- create policy select_all on app_public.posts for select using (true);
-- create policy manage_own on app_public.posts for all using (author_id = app_public.current_user_id());
-- create policy manage_as_admin on app_public.posts for all using (exists (select 1 from app_public.users where is_admin is true and id = app_public.current_user_id()));

-- comment on table app_public.posts is 'A forum post written by a `User`.';
-- comment on column app_public.posts.id is 'The primary key for the `Post`.';
-- comment on column app_public.posts.headline is 'The title written by the `User`.';
-- comment on column app_public.posts.author_id is 'The id of the author `User`.';
-- comment on column app_public.posts.topic is 'The `Topic` this has been posted in.';
-- comment on column app_public.posts.body is 'The main body text of our `Post`.';
-- comment on column app_public.posts.created_at is 'The time this `Post` was created.';
-- comment on column app_public.posts.updated_at is 'The time this `Post` was last modified (or created).';

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

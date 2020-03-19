create schema if not exists internal;

-- the organizational focal point of the system,
--  used by event_recurrence to create schedules,
--  "emits" records
create table task (
  id              uuid default uuid_generate_v1mc(),
  title                 text check (char_length(title) < 280),
  description           text
);


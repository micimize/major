create extension if not exists "uuid-ossp";

create table task (
  id              uuid default uuid_generate_v1mc(),
  title           text check (char_length(title) < 280),
  description     text
);


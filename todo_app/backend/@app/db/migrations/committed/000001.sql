--! Previous: -
--! Hash: sha1:4c2f06ca2b815247c552eb7ea91772074a3b35f6

/*
    SCAFFOLDING
    * Instantiates app_public, app_private, and app_hidden 
    * sets permissions
*/

drop schema if exists app_public cascade;

alter default privileges revoke all on sequences from public;
alter default privileges revoke all on functions from public;

-- By default the public schema is owned by `postgres`; we need superuser privileges to change this :(
-- alter schema public owner to :DATABASE_OWNER;

revoke all on schema public from public;
grant all on schema public to :DATABASE_OWNER;

create schema app_public;
grant usage on schema public, app_public to :DATABASE_VISITOR;

/**********/

drop schema if exists app_hidden cascade;
create schema app_hidden;
grant usage on schema app_hidden to :DATABASE_VISITOR;
alter default privileges in schema app_hidden grant usage, select on sequences to :DATABASE_VISITOR;

/**********/

alter default privileges in schema public, app_public, app_hidden grant usage, select on sequences to :DATABASE_VISITOR;
alter default privileges in schema public, app_public, app_hidden grant execute on functions to :DATABASE_VISITOR;

/**********/

drop schema if exists app_private cascade;
create schema app_private;

/**********/

-- Setup
-- This script deletes everything in your database
\set QUIET true
SET client_min_messages TO WARNING; -- Less talk please.
-- Use this instead of drop schema if running on the Chalmers Postgres server
-- DROP OWNED BY TDA357_XXX CASCADE;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false
SET client_min_messages TO NOTICE; -- More talk please.


\ir tables.sql
\ir views.sql
\ir inserts.sql
\ir triggers.sql
\ir tests.sql
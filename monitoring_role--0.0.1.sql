/*
 * monitoring_role.sql
 *
 * Create a set of functions and views to give access to functions required for monitoring
 * to an unpriviliged role.
 *
 * After installation is done, please modify the configuration for the monitoring
 * user as :
 * ALTER ROLE monitoring SET search_path = monitoring, pg_catalog, public;
 *
 * Adapt this query to your context.
 */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION monitoring_role" to load this file. \quit


--CREATE SCHEMA IF NOT EXISTS @extschema@;

-- provide a complete pg_stat_activity view
CREATE FUNCTION @extschema@.pg_stat_activity ()
RETURNS SETOF pg_catalog.pg_stat_activity
LANGUAGE SQL
AS $func$
  SELECT * FROM pg_catalog.pg_stat_activity;
$func$
SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION @extschema@.pg_stat_activity() FROM PUBLIC;

CREATE OR REPLACE VIEW @extschema@.pg_stat_activity
AS SELECT * FROM @extschema@.pg_stat_activity();

-- pg_stat_bgwriter
-- pg_settings

-- provide pg_ls_dir function
CREATE OR REPLACE FUNCTION @extschema@.pg_ls_dir (text)
RETURNS SETOF text
LANGUAGE SQL
AS $func$
  SELECT * FROM pg_catalog.pg_ls_dir($1);
$func$
SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION @extschema@.pg_ls_dir(text) FROM PUBLIC;

-- pg_stat_file
CREATE OR REPLACE FUNCTION @extschema@.pg_stat_file (filename text,
       	OUT size bigint, OUT access timestamp with time zone,
        OUT modification timestamp with time zone, OUT change timestamp with time zone,
        OUT creation timestamp with time zone, OUT isdir boolean)
RETURNS SETOF RECORD
LANGUAGE SQL
AS $func$
  SELECT * FROM pg_catalog.pg_stat_file($1);
$func$
SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION @extschema@.pg_stat_file(text) FROM PUBLIC;

-- pg_read_file
CREATE FUNCTION @extschema@.pg_read_file(p_filename text)
RETURNS text
LANGUAGE plpgsql
AS $func$
BEGIN
  IF p_filename = 'PG_VERSION' THEN
    RETURN pg_catalog.pg_read_file('PG_VERSION');
  ELSE
    RAISE EXCEPTION 'Must be superuser to read files';
  END IF;
END;
$func$
SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION @extschema@.pg_read_file(text) FROM PUBLIC;

/* fonction complètement pourrie, à revoir */
CREATE OR REPLACE FUNCTION @extschema@.grant_monitor(p_username text)
RETURNS text
LANGUAGE plpgsql
AS $func$
DECLARE
  schema_name text := '@extschema@';
BEGIN
  EXECUTE 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || 
          ' TO ' || quote_ident(p_username);
  EXECUTE 'GRANT SELECT ON TABLE ' || quote_ident(schema_name) || 
          '.pg_stat_activity TO ' || quote_ident(p_username);
  EXECUTE 'GRANT EXECUTE ON FUNCTION ' || quote_ident(schema_name) || 
          '.pg_stat_activity() TO ' || quote_ident(p_username);
  EXECUTE 'GRANT EXECUTE ON FUNCTION ' || quote_ident(schema_name) || 
          '.pg_ls_dir(text) TO ' || quote_ident(p_username);
  EXECUTE 'GRANT EXECUTE ON FUNCTION ' || quote_ident(schema_name) ||
          '.pg_stat_file(text) TO ' || quote_ident(p_username);
  EXECUTE 'GRANT EXECUTE ON FUNCTION ' || quote_ident(schema_name) ||
          '.pg_read_file(text) TO ' || quote_ident(p_username);
  RETURN 'Done';
END;
$func$
SECURITY INVOKER;

REVOKE EXECUTE ON FUNCTION @extschema@.grant_monitor(text) FROM PUBLIC;

-- eof --

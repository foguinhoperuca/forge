\i :forgesys_path/forge/var.sql
\i :forgesys_path/forge/deashing_forge.sql

-- TODO implement it
CREATE OR REPLACE PROCEDURE forge_revoke_privileges(IN pvlg_schema VARCHAR, IN pvlg_role_user VARCHAR) LANGUAGE plpgsql AS
$BODY$
  DECLARE
    role_count INTEGER;
    forgesys_db TEXT;
    forgesys_dbas TEXT;
  BEGIN
    SELECT current_setting('session.forgesys_db') INTO forgesys_db;
    SELECT current_setting('session.forgesys_dbas') INTO forgesys_dbas;
    RAISE INFO 'pvlg_schema: % :: pvlg_role_user: % --> forgesys_db: % :: forgesys_dbas: %', pvlg_schema, pvlg_role_user, forgesys_db, forgesys_dbas;
    SELECT COUNT(*) INTO role_count FROM pg_roles WHERE rolname = pvlg_role_user;
    RAISE INFO '[ADMIN PROCEDURE] ROLE_COUNT: %', role_count;
    IF role_count > 0 THEN
      -- EXECUTE 'REVOKE ALL PRIVILEGES ON DATABASE db_name FROM user_fancy_name';
      RAISE INFO '[ADMIN PROCEDURE] Running REVOKE command...';
    END IF;

    -- Examples to remove privileges
    -- -- TYPES
    -- -- REVOKE ALL PRIVILEGES ON ALL TYPES IN SCHEMA :forgesys_schema FROM :forgesys_role; -- NOT WORK
    -- -- FIXME implement something to clean all privileges for types in db
    -- -- SELECT format('REVOKE ALL PRIVILEGES ON TYPE %I.%I FROM %s;', nspname, typname, :'forgesys_role')
    -- -- FROM pg_type t JOIN pg_namespace n ON t.typnamespace = n.oid
    -- -- WHERE nspname = :'forgesys_schema' AND t.typtype = 'b'; -- 'b' for base types, other types may need different filters
    -- -- \gexec

    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE USAGE ON TYPES FROM :forgesys_role;

    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE USAGE ON TYPES FROM :forgesys_user;

    -- -- SEQUENCES
    -- REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM :forgesys_role;
    -- REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA :forgesys_schema FROM :forgesys_role;
    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE ALL ON SEQUENCES FROM :forgesys_role;

    -- REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM :forgesys_user;
    -- REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA :forgesys_schema FROM :forgesys_user;
    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE ALL ON SEQUENCES FROM :forgesys_user;

    -- -- TABLES
    -- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM :forgesys_role;
    -- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA :forgesys_schema FROM :forgesys_role;
    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE ALL ON TABLES FROM :forgesys_role;

    -- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM :forgesys_user;
    -- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA :forgesys_schema FROM :forgesys_user;
    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE ALL ON TABLES FROM :forgesys_user;

    -- -- FUNCTIONS
    -- REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM :forgesys_role;
    -- REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA :forgesys_schema FROM :forgesys_role;
    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE ALL ON FUNCTIONS FROM :forgesys_role;

    -- REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM :forgesys_user;
    -- REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA :forgesys_schema FROM :forgesys_user;
    -- ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema REVOKE ALL ON FUNCTIONS FROM :forgesys_user;

    -- -- SCHEMA
    -- REVOKE ALL PRIVILEGES ON SCHEMA public FROM :forgesys_role;
    -- REVOKE ALL PRIVILEGES ON SCHEMA :forgesys_schema FROM :forgesys_role;
    -- REVOKE ALL PRIVILEGES ON SCHEMA :forgesys_schema FROM :forgesys_user;
    -- ALTER SCHEMA :forgesys_schema OWNER TO postgres;

    -- -- DATABASE
    -- REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db FROM :forgesys_user;
    -- REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db FROM :forgesys_role;


  END;
$BODY$;

\i :forgesys_path/forge/var.sql
\i :forgesys_path/forge/deashing_forge.sql

SET client_min_messages TO DEBUG1;

CREATE OR REPLACE PROCEDURE forge_revoke_privileges(IN pvlg_role_user VARCHAR) LANGUAGE plpgsql AS
$BODY$
  DECLARE
    role_count INTEGER;
    forgesys_db TEXT;
    forgesys_dbas TEXT;
    forgesys_schema TEXT;
    cmd TEXT;
  BEGIN
    SELECT current_setting('session.forgesys_db') INTO forgesys_db;
    SELECT current_setting('session.forgesys_dbas') INTO forgesys_dbas;
    SELECT current_setting('session.forgesys_schema') INTO forgesys_schema;
    SELECT COUNT(*) INTO role_count FROM pg_roles WHERE rolname = pvlg_role_user;
    RAISE INFO '[ADMIN PROCEDURE] ROLE_COUNT: % ::: pvlg_role_user: %', role_count, pvlg_role_user;

    IF role_count > 0 THEN
      -- TYPES
      -- FIXME implement something to clean all privileges for types in db --> REVOKE ALL PRIVILEGES ON ALL TYPES IN SCHEMA :forgesys_schema FROM :forgesys_role; -- DO NOT WORK
      -- SELECT format('REVOKE ALL PRIVILEGES ON TYPE %I.%I FROM %s;', nspname, typname, :'forgesys_role')
      -- FROM pg_type t JOIN pg_namespace n ON t.typnamespace = n.oid
      -- WHERE nspname = :'forgesys_schema' AND t.typtype = 'b'; -- 'b' for base types, other types may need different filters
      -- \gexec
      cmd := FORMAT('ALTER DEFAULT PRIVILEGES IN SCHEMA %1$s REVOKE USAGE ON TYPES FROM %2$s', forgesys_schema, pvlg_role_user);
      RAISE INFO '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      
      -- SEQUENCES
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %1$s FROM %2$s;', 'public', pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %1$s FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('ALTER DEFAULT PRIVILEGES IN SCHEMA %1$s REVOKE ALL ON SEQUENCES FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;

      -- TABLES
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA %1$s FROM %2$s;', 'public', pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA %1$s FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('ALTER DEFAULT PRIVILEGES IN SCHEMA %1$s REVOKE ALL ON TABLES FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;

      -- FUNCTIONS
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %1$s FROM %2$s;', 'public', pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %1$s FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('ALTER DEFAULT PRIVILEGES IN SCHEMA %1$s REVOKE ALL ON FUNCTIONS FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;

      -- SCHEMA
      cmd := FORMAT('ALTER SCHEMA  %1$s OWNER TO postgres;', forgesys_schema);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON SCHEMA %1$s FROM %2$s;', 'public', pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON SCHEMA %1$s FROM %2$s;', forgesys_schema, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;

      -- DATABASE
      cmd := FORMAT('REVOKE ALL PRIVILEGES ON DATABASE %1$s FROM %2$s;', forgesys_db, pvlg_role_user);
      RAISE DEBUG '[ADMIN PROCEDURE] %', cmd;
      EXECUTE cmd;
    END IF;
  END;
$BODY$;

-- FIXME those bellow already in session by var.sql file!?
SET session.forgesys_sys_grp = :'forgesys_sys_grp';
SET session.forgesys_view_report_pwd = :'forgesys_view_report_pwd';
SET session.forgesys_app_tester_pwd = :'forgesys_app_tester_pwd';
-- SET session.forgesys_db = :'forgesys_db';
CREATE OR REPLACE PROCEDURE forge_create_user(IN lgn VARCHAR, IN passwd VARCHAR, IN permissions VARCHAR) LANGUAGE plpgsql AS
$BODY$
  DECLARE
    pwd TEXT;
  BEGIN
    RAISE DEBUG '[ADMIN PROCEDURE] creating: % passwd % permissions: %', lgn, passwd, permissions;
    pwd := CASE WHEN passwd IS NULL THEN NULL ELSE FORMAT('"%1$s"', passwd) END;
    BEGIN
      -- TODO define some strategy to revoke all privileges from every object in host
      -- EXECUTE FORMAT('REVOKE ALL PRIVILEGES ON DATABASE %1$s FROM %$2s;', fhr[1], current_settings('session.forgesys_db'));
      EXECUTE FORMAT('DROP ROLE IF EXISTS %1$s;', lgn);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING '[ADMIN PROCEDURE] COULD NOT revoke OR drop role % :: will not be re-created!', lgn;
    END;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = lgn) THEN
      EXECUTE FORMAT('CREATE ROLE %1$I WITH %2$s %3$L;', lgn, permissions, pwd);
    END IF;
  END
$BODY$;

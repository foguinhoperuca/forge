/**
 * Before terraform, must have a "planet" with the follow:
 * - users: postgres, view_report, dba, <LOCAL_DBA_USER> (or any MS AD/LDAP user that will access by QGIS);
 * - database: any name but must be one in place;
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/var.sql

--
-- Droping/Revoking objects in correct order
--
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM :forgesys_role;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM :forgesys_role;

REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db FROM :forgesys_user;
REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db FROM :forgesys_role;

REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db_foreign FROM :forgesys_user;
REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db_foreign FROM :forgesys_role;

DROP SCHEMA IF EXISTS :forgesys_schema CASCADE;

DROP ROLE IF EXISTS :forgesys_user;
CREATE ROLE :forgesys_user WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  PASSWORD :'forgesys_pwd'
;
DROP ROLE IF EXISTS :forgesys_role;
CREATE ROLE :forgesys_role WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
;

SET session.dbas = :'forgesys_dbas';
SET session.forgesys_role = :forgesys_role;
DO $$
DECLARE
  dba TEXT;
  forgesys_role TEXT;
  dbas TEXT[];
BEGIN
  SELECT string_to_array(current_setting('session.dbas'), ',') INTO dbas;
  SELECT current_setting('session.forgesys_role') INTO forgesys_role;
  FOREACH dba IN ARRAY dbas LOOP
    RAISE INFO 'Current dba: % ::: Grant: %', dba, forgesys_role;
    EXECUTE format('GRANT %1$s TO "%2$s"', forgesys_role, dba);
  END LOOP;
END $$;
GRANT :forgesys_role, :forgesys_sys_grp TO :forgesys_user;

CREATE SCHEMA IF NOT EXISTS :forgesys_schema AUTHORIZATION :forgesys_role;
GRANT ALL ON SCHEMA :forgesys_schema TO postgres WITH GRANT OPTION;
GRANT ALL ON SCHEMA :forgesys_schema TO dba WITH GRANT OPTION;
GRANT ALL ON SCHEMA :forgesys_schema TO :forgesys_user;
GRANT USAGE ON SCHEMA :forgesys_schema TO :forgesys_role;
GRANT USAGE ON SCHEMA :forgesys_schema TO view_report;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT USAGE                                      ON TYPES     TO postgres WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT USAGE                                      ON TYPES     TO dba WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT USAGE                                      ON TYPES     TO :forgesys_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT USAGE                                      ON TYPES     TO :forgesys_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON SEQUENCES TO postgres WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON SEQUENCES TO dba WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON SEQUENCES TO :forgesys_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON SEQUENCES TO :forgesys_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT SELECT                                     ON SEQUENCES TO view_report;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON TABLES    TO postgres WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON TABLES    TO dba WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT ALL                                        ON TABLES    TO :forgesys_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT INSERT, SELECT, UPDATE, DELETE, REFERENCES ON TABLES    TO :forgesys_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT SELECT                                     ON TABLES    TO view_report;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT EXECUTE                                    ON FUNCTIONS TO postgres WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT EXECUTE                                    ON FUNCTIONS TO dba WITH GRANT OPTION;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT EXECUTE                                    ON FUNCTIONS TO :forgesys_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA :forgesys_schema GRANT EXECUTE                                    ON FUNCTIONS TO :forgesys_role;

GRANT CONNECT ON DATABASE :forgesys_db TO :forgesys_user;
GRANT CONNECT ON DATABASE :forgesys_db TO :forgesys_role;
GRANT USAGE ON SCHEMA public TO :forgesys_role;
GRANT SELECT, REFERENCES ON TABLE public.qgis_projects TO :forgesys_role;
GRANT SELECT, REFERENCES ON TABLE public.spatial_ref_sys TO :forgesys_role;

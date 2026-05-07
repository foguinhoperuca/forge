/**
 * Hypernova will create the basic for each system to live on:
 * - users: postgres, view_report, app_tester, sys_grp, dba_role, dba_person;
 * - database: any name but must be one in place. Default name will be alura (and variations: alura_prod, alura_stage, alura_homolog, alura_dev, alura_local) or gis (with same variations);
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/utils.sql
SET client_min_messages TO ERROR;

DROP DATABASE IF EXISTS :forgesys_db;
DROP DATABASE IF EXISTS :forgesys_db_foreign;

DO $$
DECLARE
  forgesys_hypernova_roles TEXT[][];
  fhr TEXT[];
BEGIN
  forgesys_hypernova_roles := ARRAY[
    ['dba', NULL, 'NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    ['gis_group', NULL, 'NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    [current_setting('session.forgesys_sys_grp'), NULL, 'NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    ['view_report', current_setting('session.forgesys_view_report_pwd'), 'LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    ['app_tester', current_setting('session.forgesys_app_tester_pwd'), 'LOGIN NOSUPERUSER INHERIT CREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD']
  ];
  FOREACH fhr SLICE 1 IN ARRAY forgesys_hypernova_roles LOOP
    RAISE INFO '[HYPERNOVA] creating: % passwd % permissions: %', fhr[1], fhr[2], fhr[3];
    -- TODO remove privileges for all users before re-create it using forge_revoke_privileges()!!
    CALL forge_create_user(fhr[1], fhr[2], fhr[3]);
  END LOOP;
END
$$;

CREATE DATABASE :forgesys_db;
ALTER DATABASE :forgesys_db OWNER TO postgres;
-- TODO create default permissions on database
GRANT ALL ON DATABASE :forgesys_db TO postgres WITH GRANT OPTION;
GRANT CREATE, CONNECT ON DATABASE :forgesys_db TO dba; -- FIXME options: CREATE, CONNECT, TEMPORARY (or ALL)
GRANT CONNECT ON DATABASE :forgesys_db TO gis_group;
GRANT CONNECT ON DATABASE :forgesys_db TO view_report;

-- TODO implement get all dbas in .pgpass credential file

CREATE DATABASE :forgesys_db_foreign;
ALTER DATABASE :forgesys_db_foreign OWNER TO postgres;
GRANT ALL ON DATABASE :forgesys_db_foreign TO postgres WITH GRANT OPTION;
GRANT CREATE, CONNECT ON DATABASE :forgesys_db_foreign TO dba; -- FIXME options: CREATE, CONNECT, TEMPORARY (or ALL)
GRANT CONNECT ON DATABASE :forgesys_db_foreign TO gis_group;
GRANT CONNECT ON DATABASE :forgesys_db_foreign TO view_report;

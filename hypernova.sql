/**
 * Hypernova will create the basic for each system to live on:
 * - database: any name but must be one in place. Default name will be alura (and variations: alura_prod, alura_stage, alura_homolog, alura_dev, alura_local) or gis (with same variations);
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/utils.sql
SET client_min_messages TO ERROR; -- TODO change back to NOTICE

DROP DATABASE IF EXISTS :forgesys_db;
DROP DATABASE IF EXISTS :forgesys_db_foreign;

DO $$
DECLARE
  forgesys_hypernova_roles TEXT[][];
  dbas TEXT[];
  dba TEXT;
  fhr TEXT[];
BEGIN
  forgesys_hypernova_roles := ARRAY[
    ['dba', NULL, 'NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    ['view_report', current_setting('session.forgesys_view_report_pwd'), 'LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD']
  ];

  -- TODO implement get all dbas in .pgpass credential file
  SELECT string_to_array(current_setting('session.forgesys_dbas'), ',') INTO dbas;
  FOREACH dba IN ARRAY dbas LOOP
    RAISE DEBUG 'Current dba: % :::', dba;
    forgesys_hypernova_roles := forgesys_hypernova_roles || ARRAY[dba, NULL, 'LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'];
  END LOOP;

  FOREACH fhr SLICE 1 IN ARRAY forgesys_hypernova_roles LOOP
    RAISE INFO '[HYPERNOVA] creating: % ', fhr[1];
    RAISE DEBUG '% passwd % permissions: %', fhr[1], fhr[2], fhr[3];
    -- TODO remove privileges for all users before re-create it using forge_revoke_privileges()!!
    CALL forge_create_user(fhr[1], fhr[2], fhr[3]);

    IF fhr[1] = ANY(dbas) THEN
      RAISE DEBUG 'grat dba: % into role dbas', fhr[1];
      EXECUTE format('GRANT dba TO "%1$s"', fhr[1]);
      EXECUTE format('GRANT gis_group TO "%1$s"', fhr[1]);
    END IF;
  END LOOP;
END
$$;

-- TODO create default permissions on databases

CREATE DATABASE :forgesys_db;
COMMENT ON DATABASE :forgesys_db IS 'Main database to hold data to all app. No directly access by end-user.';
ALTER DATABASE :forgesys_db OWNER TO postgres;
GRANT ALL ON DATABASE :forgesys_db TO postgres WITH GRANT OPTION; -- FIXME options: CREATE, CONNECT, TEMPORARY (or ALL)
GRANT ALL ON DATABASE :forgesys_db TO dba;
GRANT CONNECT ON DATABASE :forgesys_db TO view_report;

CREATE DATABASE :forgesys_db_foreign;
COMMENT ON DATABASE :forgesys_db_foreign IS 'Database to hold data to be accessed by end-user and/or gis app (qgis).';
ALTER DATABASE :forgesys_db_foreign OWNER TO postgres;
GRANT ALL ON DATABASE :forgesys_db_foreign TO postgres WITH GRANT OPTION;
GRANT CONNECT ON DATABASE :forgesys_db_foreign TO gis_group;
GRANT ALL ON DATABASE :forgesys_db_foreign TO dba;
GRANT CONNECT ON DATABASE :forgesys_db_foreign TO view_report;

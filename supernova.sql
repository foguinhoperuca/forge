/**
 * Supernova will create the basic for each system to live on:
 * - users: postgres, dba_role, dba_person, gis_group, view_report;
 * - database: any name but must be one in place. Default name will be alura (and variations: alura_prod, alura_stage, alura_homolog, alura_dev, alura_local) or gis (with same variations);
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/var.sql

DROP DATABASE IF EXISTS :forgesys_db;

SET session.forgesys_view_report_pwd = :'forgesys_view_report_pwd';
SET session.forgesys_sys_grp = :'forgesys_sys_grp';
-- SET session.forgesys_db = :'forgesys_db';
DO $$
DECLARE
  lgn TEXT;
  pwd TEXT;
  fhr TEXT[];
  forgesys_hypernova_roles TEXT[][];
BEGIN
  forgesys_hypernova_roles := ARRAY[
    ['dba', NULL],
    ['gis_group', NULL],
    [current_setting('session.forgesys_sys_grp'), NULL],
    ['view_report', current_setting('session.forgesys_view_report_pwd')]
  ];
  FOREACH fhr SLICE 1 IN ARRAY forgesys_hypernova_roles LOOP
    lgn := CASE WHEN fhr[2] IS NULL THEN 'NOLOGIN' ELSE 'LOGIN' END;
    pwd := CASE WHEN fhr[2] IS NULL THEN NULL ELSE FORMAT('"%1$s"', fhr[2]) END;
    RAISE INFO 'creating: % passwd % :: % ::: %', fhr[1], fhr[2], lgn, pwd;
    BEGIN
      -- TODO define some strategy to revoke all privileges from every object in host
      -- EXECUTE FORMAT('REVOKE ALL PRIVILEGES ON DATABASE %1$s FROM %$2s;', fhr[1], current_settings('session.forgesys_db'));
      EXECUTE FORMAT('DROP ROLE IF EXISTS %1$s;', fhr[1]);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'COULD NOT revoke OR drop role % :: will not be re-created!', fhr[1];
    END;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = fhr[1]) THEN
      EXECUTE FORMAT('CREATE ROLE %1$I WITH %2$s NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD %3$L;', fhr[1], lgn, pwd);
    END IF;
  END LOOP;
END
$$;

CREATE DATABASE :forgesys_db;
ALTER DATABASE :forgesys_db OWNER TO postgres;

-- -- TODO implement all CREATE extension need.
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- CREATE EXTENSION IF NOT EXISTS postgres_fdw;

GRANT ALL ON DATABASE :forgesys_db TO postgres WITH GRANT OPTION;
GRANT CREATE, CONNECT ON DATABASE :forgesys_db TO dba; -- FIXME options: CREATE, CONNECT, TEMPORARY (or ALL)
GRANT CONNECT ON DATABASE :forgesys_db TO gis_group;
GRANT CONNECT ON DATABASE :forgesys_db TO view_report;

-- TODO implement get all dbas in .pgpass credential file

-- -- TODO implement permissions and create table from public
-- GRANT USAGE ON SCHEMA public TO :alura_role;
-- GRANT SELECT, REFERENCES ON TABLE public.qgis_projects TO :alura_role;
-- GRANT SELECT, REFERENCES ON TABLE public.spatial_ref_sys TO :alura_role;

-- TODO create default permissions on database

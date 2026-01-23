/**
 * Hypernova will create the basic for each system to live on:
 * - users: postgres, view_report, dba role, dba_person;
 * - database: any name but must be one in place. Default name will be alura (and variations: alura_prod, alura_stage, alura_homolog, alura_dev, alura_local) or gis (with same variations);
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/var.sql

DROP DATABASE IF EXISTS :forgesys_db;

DROP ROLE IF EXISTS dba;
CREATE ROLE dba WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
;

DROP ROLE IF EXISTS gis_group;
CREATE ROLE dba WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
;

DROP ROLE IF EXISTS :forgesys_sys_grp;
CREATE ROLE dba WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
;

-- TODO get password for view_report (edit and join all TARGET_SERVER_DB)
-- REVOKE ALL PRIVILEGES ON DATABASE :forgesys_db FROM view_report;
DROP ROLE IF EXISTS view_report;
CREATE ROLE view_report WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  PASSWORD 'A12345678a'
--  PASSWORD :'view_report_pwd'
;

-- -- TODO implement here all CREATE extension need.
-- CREATE EXTENSION pg_stat_statements;
-- CREATE EXTENSION postgis;
-- CREATE EXTENSION postgres_fdw;

CREATE DATABASE :forgesys_db;
ALTER DATABASE :forgesys_db OWNER TO postgres;

GRANT ALL ON DATABASE :forgesys_db TO postgres WITH GRANT OPTION;
GRANT CREATE, CONNECT ON DATABASE :forgesys_db TO dba; -- FIXME options: CREATE, CONNECT, TEMPORARY (or ALL)
GRANT CONNECT ON DATABASE :forgesys_db TO view_report;

-- -- TODO implement permissions and create table from public
-- GRANT USAGE ON SCHEMA public TO :alura_role;
-- GRANT SELECT, REFERENCES ON TABLE public.qgis_projects TO :alura_role;
-- GRANT SELECT, REFERENCES ON TABLE public.spatial_ref_sys TO :alura_role;

-- TODO create default permissions on database

/**
 * Supernova will create the basic for each system to live on:
 * - users: postgres, dba_role, dba_person, gis_group, view_report;
 * - database: any name but must be one in place. Default name will be alura (and variations: alura_prod, alura_stage, alura_homolog, alura_dev, alura_local) or gis (with same variations);
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/var.sql

DO $$
BEGIN
  RAISE NOTICE 'TODO implement task above terraform';
END $$;

-- -- TODO implement all CREATE extension need.
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- -- TODO implement permissions and create table from public
-- GRANT USAGE ON SCHEMA public TO :alura_role;
-- GRANT SELECT, REFERENCES ON TABLE public.qgis_projects TO :alura_role;
-- GRANT SELECT, REFERENCES ON TABLE public.spatial_ref_sys TO :alura_role;

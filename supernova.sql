/**
 * Supernova will create the basic for each system to live on:
 * - users: postgres, view_report, dba role, dba_person;
 * - database: any name but must be one in place. Default name will be alura (and variations: alura_prod, alura_stage, alura_homolog, alura_dev, alura_local) or gis (with same variations);
 * - schema public is already created and must have this tables: qgis_projects and spatial_ref_sys;
 */

\i :forgesys_path/forge/var.sql

-- TODO implement task between hypernova (all database) and terraform - create all dba users

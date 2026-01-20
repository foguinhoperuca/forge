/**
 * ---
 * Template to be copied to your project's database folder.
 * You can use it as symlink or copy this template and customize it.
 * ---
 */

-- TODO (define as global var in forge) Default name will be <PROJECT_ACRONYM_DEPT> (and variations: <PROJECT_ACRONYM_DEPT>_prod, <PROJECT_ACRONYM_DEPT>_stage, <PROJECT_ACRONYM_DEPT>_homolog, <PROJECT_ACRONYM_DEPT>_dev, <PROJECT_ACRONYM_DEPT>_local) or gis (with same variations);

\echo '--------------------------- BEFORE terraform.sql :: Put all customization bellow ---------------------------'
\i :forgesys_path/forge/terraform.sql
\echo '--------------------------- AFTER terraform.sql :: Put all customization above   ---------------------------'

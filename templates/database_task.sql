/**
 * ---
 * Template to be copied to your project's database folder.
 * You can use it as symlink or copy this template and customize it.
 * ---
 */

-- TODO (define as global var in forge) Default name will be <PROJECT_ACRONYM_DEPT> (and variations: <PROJECT_ACRONYM_DEPT>_prod, <PROJECT_ACRONYM_DEPT>_stage, <PROJECT_ACRONYM_DEPT>_homolog, <PROJECT_ACRONYM_DEPT>_dev, <PROJECT_ACRONYM_DEPT>_local) or gis (with same variations);

\echo '--------------------------- BEFORE terraform.sql :: Put all customization bellow ---------------------------'

\i :forgesys_path/forge/var.sql

\if :{?forgesys_script}
  \echo 'Already setted forgesys_script -->' :forgesys_script
\else
   -- \set forgesys_sys_grp `echo "$(:forgesys_path/mount_etna.sh show | grep TARGET_SERVER_DB_SYS_GRP | cut -d = -f2)"`
   \set forgesys_script `echo "${DB_SCRIPT}"` -- format (full path with extension): e.g.: terraform.sql
   -- TODO implement case to get DB_SCRIPT from file name instead of DB_SCRIPT --> something like: `export FORGE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
\endif

\i :forgesys_path/forge/:forgesys_script
\echo '--------------------------- AFTER terraform.sql :: Put all customization above   ---------------------------'

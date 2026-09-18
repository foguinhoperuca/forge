/**
 * ---
 * Template to be copied to your project's database folder.
 * You can use it as symlink or copy this template and customize it.
 * Pass variable FORGESYS_SCRIPT in format (full path with extension): e.g.: forge/resources/sql/database/terraform.sql
 * ---
 */

-- FIXME just making a ln -s database/<SCRIPT_SQL>.sql ../forge/resources/sql/database/<SCRIPT_SQL>.sql already works! THis isn't the prototype for a main.sql to call all scripts?!
-- TODO implement case to get FORGESYS_PATH from file name instead of FORGESYS_SCRIPT --> something like: `export FORGE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
-- TODO rename forgesys_script to something like forgesys_sql_script or else
\if :{?forgesys_script}
  \echo 'Already setted forgesys_script ->' :forgesys_script
\else
   \set forgesys_script `[ -z "${FORGESYS_SCRIPT}" ] && find forge/resources/sql/ -type f | grep $(echo "$DB_SCRIPT" | cut -d / -f2) || echo "${FORGESYS_SCRIPT}"`
   \echo 'MANUALLY setted the forgesys_script ->' :forgesys_script
\endif

-- TODO implement change the log output
-- ALTER SYSTEM SET log_line_prefix = '%m [%p]: [%l-1] db=%d,user=%u ';
-- SELECT pg_reload_conf();
-- \set CLIENT_MIN_MESSAGES TO 'NOTICE';
\echo '--------------------------- RESULT database_task.sql ::' :forgesys_path '::' :forgesys_script '---------------------------'

\i :forgesys_path/:forgesys_script

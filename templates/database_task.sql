/**
 * ---
 * Template to be copied to your project's database folder.
 * You can use it as symlink or copy this template and customize it.
 * Pass variable FORGESYS_SCRIPT in format (full path with extension): e.g.: terraform.sql
 * ---
 */

\if :{?forgesys_script}
  \echo 'Already setted forgesys_script -->' :forgesys_script
\else
   -- TODO implement case to get FORGESYS_SCRIPT from file name instead of FORGESYS_SCRIPT --> something like: `export FORGE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
   \set forgesys_script `echo "${FORGESYS_SCRIPT}"`
\endif

-- TODO implement change the log output
-- ALTER SYSTEM SET log_line_prefix = '%m [%p]: [%l-1] db=%d,user=%u ';
-- SELECT pg_reload_conf();
-- \set CLIENT_MIN_MESSAGES TO 'NOTICE';
\echo '--------------------------- RESULT database_task.sql ::' :forgesys_script '---------------------------'

\i :forgesys_path/forge/:forgesys_script

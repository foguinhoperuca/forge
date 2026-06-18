/**
 * Set reusable variables to all db scripts.
 */

-- TODO create a separated variable to show script variables (debug)
\if :{?forgesys_debug}
  \echo 'Already setted forgesys_debug -->' :forgesys_debug
\else
  \set forgesys_debug `echo "${DEBUG:-0}"`
  SET session.forgesys_debug = :'forgesys_debug';
\endif

\if :{?forgesys_sys_grp}
  \echo 'Already setted forgesys_sys_grp -->' :forgesys_sys_grp
\else
  \set forgesys_sys_grp `echo "$(:forgesys_path/mount_etna.sh show | grep TARGET_SERVER_DB_SYS_GRP | cut -d = -f2)"`
  SET session.forgesys_sys_grp = :'forgesys_sys_grp';
\endif

\if :{?forgesys_dbas}
-- FIXME not working with user with colon: `first_name._last_name`
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_dbas `echo "$(:forgesys_path/mount_etna.sh show | grep TARGET_SERVER_DBAS | cut -d = -f2)"`
  SET session.forgesys_dbas = :'forgesys_dbas';
\endif

\if :{?forgesys_role}
  \echo 'Already setted forgesys_role -->' :forgesys_role
\else
  \set forgesys_role `echo "$(:forgesys_path/mount_etna.sh show | grep FORGE_SYSTEM_NAME | cut -d = -f2)_app"`
  SET session.forgesys_role = :'forgesys_role';
\endif

\if :{?forgesys_db}
  \echo 'Already setted forgesys_db -->' :forgesys_db
\else
  \set forgesys_db `echo "$(:forgesys_path/mount_etna.sh show | grep DB_DATABASE | cut -d = -f2)"`
  SET session.forgesys_db = :'forgesys_db';
\endif

\if :{?forgesys_db_foreign}
  \echo 'Already setted forgesys_db_foreign -->' :forgesys_db_foreign
\else
  \set forgesys_db_foreign `echo "$(:forgesys_path/mount_etna.sh show | grep DB_FOREIGN_DATABASE | cut -d = -f2)"`
  SET session.forgesys_db_foreign = :'forgesys_db_foreign';
\endif

\if :{?forgesys_schema}
  \echo 'Already setted forgesys_schema -->' :forgesys_schema
\else
  \set forgesys_schema `echo "$(:forgesys_path/mount_etna.sh show | grep FORGE_SYSTEM_NAME | cut -d = -f2)"`
  SET session.forgesys_schema = :'forgesys_schema';
\endif

-- FIXME use ACRONYM instead full name FORGE_SYSTEM_NAME
\if :{?forgesys_user}
  \echo 'Already setted forgesys_user -->' :forgesys_user
\else
  \set forgesys_user `echo "$(:forgesys_path/mount_etna.sh show | grep DB_USER | cut -d = -f2)"`
  SET session.forgesys_user = :'forgesys_user';
\endif

-- FIXME password has = inside. Do not work anymore
\if :{?forgesys_pwd}
  \echo 'Already setted forgesys_pwd -->' :forgesys_pwd
\else
  \set forgesys_pwd `echo "$(:forgesys_path/mount_etna.sh show | grep DB_PASS | cut -d = -f2)"`
  SET session.forgesys_pwd = :'forgesys_pwd';
\endif

-- FIXME missing forgesys_ before!?
\if :{?forgesys_view_report_pwd}
  \echo 'Already setted forgesys_view_report_pwd -->' :forgesys_view_report_pwd
\else
  \set forgesys_view_report_pwd `echo "$(:forgesys_path/mount_etna.sh show | grep DB_POSTGRES_VIEW_REPORT_PASS | cut -d = -f2)"`
  SET session.forgesys_view_report_pwd = :'forgesys_view_report_pwd';
\endif

\if :{?forgesys_app_tester_pwd}
  \echo 'Already setted forgesys_app_tester_pwd -->' :forgesys_app_tester_pwd
\else
  \set forgesys_app_tester_pwd `echo "$(:forgesys_path/mount_etna.sh show | grep DB_POSTGRES_APP_TESTER_PASS | cut -d = -f2)"`
  SET session.forgesys_app_tester_pwd = :'forgesys_app_tester_pwd';
\endif

\if :forgesys_debug
  \echo '|-------------------------------------------------------------------|'
  \echo '| SHOW SCRIPT VARIABLES                                             |'
  \echo '|-------------------------------------------------------------------|'
  \echo '| forgesys_debug-->' :forgesys_debug
  \echo '| forgesys_script-->' :forgesys_script
  \echo '| forgesys_path-->' :forgesys_path
  \echo '| forgesys_dbas -->' :forgesys_dbas
  \echo '| forgesys_sys_grp -->' :forgesys_sys_grp
  \echo '| forgesys_role-->' :forgesys_role
  \echo '| forgesys_db-->' :forgesys_db
  \echo '| forgesys_db_foreign-->' :forgesys_db_foreign
  \echo '| forgesys_schema-->' :forgesys_schema
  \echo '| forgesys_user -->' :forgesys_user
  -- TODO implement a variable to toggle the show variables bellow
  \echo '| forgesys_pwd --> <DO_NOT_SHOW_HERE_ONLY_IF_REAL_NEED>              '
  \echo '| forgesys_view_report_pwd --> <DO_NOT_SHOW_HERE_ONLY_IF_REAL_NEED>  '
  \echo '| forgesys_app_tester_pwd --> <DO_NOT_SHOW_HERE_ONLY_IF_REAL_NEED>   '
  \echo '|-------------------------------------------------------------------|'
\endif

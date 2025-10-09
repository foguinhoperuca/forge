/**
 * Set reusable variables to all db scripts.
 */

\if :{?forgesys_sys_grp}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_sys_grp `echo "$(:forgesys_path/forge.sh show | grep TARGET_SERVER_DB_SYS_GRP | cut -d = -f2)"`
\endif      

\if :{?forgesys_dbas}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_dbas `echo "$(:forgesys_path/forge.sh show | grep TARGET_SERVER_DBAS | cut -d = -f2)"`
\endif      

\if :{?forgesys_role}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_role `echo "$(:forgesys_path/forge.sh show | grep PMS_SYSTEM_NAME | cut -d = -f2)_app"`
\endif      

\if :{?forgesys_db}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_db `echo "$(:forgesys_path/forge.sh show | grep DB_DATABASE | cut -d = -f2)"`
\endif      

\if :{?forgesys_schema}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_schema `echo "$(:forgesys_path/forge.sh show | grep PMS_SYSTEM_NAME | cut -d = -f2)"`
\endif      

-- FIXME use ACRONYM instead full name PMS_SYSTEM_NAME
\if :{?forgesys_user}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_user `echo "$(:forgesys_path/forge.sh show | grep DB_USER | cut -d = -f2)"`
\endif

-- FIXME password has = inside. Do not work anymore
\if :{?forgesys_pwd}
  \echo 'Already setted forgesys_dbas -->' :forgesys_dbas
\else
  \set forgesys_pwd `echo "$(:forgesys_path/forge.sh show | grep DB_PASS | cut -d = -f2)"`
\endif

\echo '|------------------------------------------------------|'
\echo '| SHOW SCRIPT VARIABLES                                |'
\echo '|------------------------------------------------------|'
\echo '| forgesys_path-->' :forgesys_path
\echo '| forgesys_dbas -->' :forgesys_dbas
\echo '| forgesys_sys_grp -->' :forgesys_sys_grp
\echo '| forgesys_role-->' :forgesys_role
\echo '| forgesys_db-->' :forgesys_db
\echo '| forgesys_schema-->' :forgesys_schema
\echo '| forgesys_user -->' :forgesys_user
\echo '| forgesys_pwd--> <DO_NOT_SHOW_HERE_ONLY_IF_REAL_NEED>  '
\echo '|------------------------------------------------------|'

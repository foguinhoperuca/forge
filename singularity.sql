/**
 * Big bang will do configuration for host it tself
 */

\i :forgesys_path/forge/utils.sql
SET client_min_messages TO ERROR; -- TODO change back to NOTICE

DO $$
DECLARE
  forgesys_singularity_roles TEXT[][];
  fsr TEXT[];
BEGIN
  forgesys_singularity_roles := ARRAY[
    [current_setting('session.forgesys_sys_grp'), NULL, 'NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    ['gis_group', NULL, 'NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD'],
    ['app_tester', current_setting('session.forgesys_app_tester_pwd'), 'LOGIN NOSUPERUSER INHERIT CREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD']
  ];

  FOREACH fsr SLICE 1 IN ARRAY forgesys_singularity_roles LOOP
    RAISE INFO '[SINGULARITY] creating: % ', fsr[1];
    RAISE DEBUG '% passwd % :: %', fsr[1], fsr[2], fsr[3];
    -- TODO remove privileges for all users before re-create it using forge_revoke_privileges()!!
    CALL forge_create_user(fsr[1], fsr[2], fsr[3]);
  END LOOP;
END $$;

GRANT :forgesys_sys_grp TO app_tester;
GRANT CONNECT ON DATABASE postgres TO app_tester;

/**
 * Set default permissions for objects in database.
 * | User/Group    | Descr                                     | Role                                                                                                    |
 * |---------------+-------------------------------------------+---------------------------------------------------------------------------------------------------------|
 * | postgres      | database super admin                      | God.                                                                                                    |
 * | dba           | database administrators - team of project | Database administrator. Full access.                                                                    |
 * | :forgesys     | system user (programmatic access)         | Software-mediated access. Owner of most objects. API and other software                                 |
 * | :forgesys_app | end user with database access             | Direct access to the database on an indivudual basis, but with more restricted access. Use of QGIS app. |
 * | view_report   | read-only user                            | For report purpose only. Should not interfere with the system only observe it.                          |
 */

-- TODO
-- 0. Set permission by level for each object: FUNCTION, INDEX, SCHEMA, DATABASE

\i :forgesys_path/forge/var.sql
SET session.forgesys_role = :forgesys_role;
SET session.forgesys_user = :forgesys_user;
SET session.forgesys_db = :forgesys_db;
SET session.forgesys_schema = :forgesys_schema;

DO $$
DECLARE
  linerecord RECORD;
  cmd TEXT;
BEGIN
  RAISE INFO 'USER: % ::: ROLE: % ::: DB % ::: SCHEMA %', current_setting('session.forgesys_user'), current_setting('session.forgesys_role'), current_setting('session.forgesys_db'), current_setting('session.forgesys_schema');
  FOR linerecord IN
    -- TYPE: only enum
      SELECT
        t.oid AS "oid",
        t.typname AS "object_name",
        r.rolname AS "owner_username",
        t.typacl  AS "acl",
        CASE t.typtype
          WHEN 'c' THEN 'COMPOSITE TYPE (Explicit)'
          WHEN 'e' THEN 'ENUM TYPE'
          WHEN 'd' THEN 'DOMAIN'
          WHEN 'b' THEN 'BASE TYPE'
          -- 'p' is pseudo-types, 'r' is range types, 'm' is multirange types
          ELSE t.typtype::text
        END AS object_type,
        n.nspname AS "schema_name"
      FROM pg_type AS t
      INNER JOIN pg_namespace AS n ON n.oid = t.typnamespace
      INNER JOIN pg_roles AS r ON r.oid = t.typowner
      WHERE
        n.nspname = current_setting('session.forgesys_schema')
        AND t.typname NOT LIKE '_\_%' -- Exclude array types (names start with an underscore) and implicit table types
        AND t.typrelid = 0
        AND t.typtype = 'e' -- only ENUM TYPE
    UNION ALL
    -- great mass of objects
      SELECT
        c.oid     AS "oid",
        c.relname AS "object_name",
        r.rolname AS "owner_username",
        c.relacl  AS "acl",
        CASE c.relkind
          WHEN 'S' THEN 'SEQUENCE'
          WHEN 'r' THEN 'TABLE'
          WHEN 'v' THEN 'VIEW'
          WHEN 'm' THEN 'MATERIALIZED VIEW'
          WHEN 'i' THEN 'INDEX'
          ELSE c.relkind::text
        END AS "object_type",
        n.nspname AS "schema_name"
      FROM pg_class AS c
      INNER JOIN pg_namespace AS n ON n.oid = c.relnamespace
      INNER JOIN pg_roles AS r ON r.oid = c.relowner
      WHERE
        n.nspname = current_setting('session.forgesys_schema')
        -- AND c.relkind IN ('S', 'r', 'v', 'm', 'i') -- Filter common object types
    UNION ALL
    -- Function/procedure objects
      SELECT
        p.oid     AS "oid",
        p.proname AS "object_name",
        r.rolname AS "owner_username",
        p.proacl  AS "acl",
        CASE p.prokind
          WHEN 'f' THEN 'FUNCTION'
          WHEN 'p' THEN 'PROCEDURE'
          ELSE p.prokind::text
        END AS "object_type",
        n.nspname AS "schema_name"
      FROM pg_proc AS p
      INNER JOIN pg_namespace AS n ON n.oid = p.pronamespace
      INNER JOIN pg_roles AS r ON r.oid = p.proowner
      WHERE
        n.nspname = current_setting('session.forgesys_schema')
        AND p.prokind IN ('f', 'p')
    ORDER BY
      object_type,
      owner_username,
      object_name,
      oid
    LOOP
      RAISE INFO 'Curr linerecord: %', linerecord;
      CASE
        -- pg_type
        WHEN linerecord.object_type = 'ENUM TYPE' THEN
          SELECT format('ALTER TYPE %1$s.%2$s.%3$s OWNER TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT USAGE ON TYPE %1$s.%2$s.%3$s TO postgres', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT USAGE ON TYPE %1$s.%2$s.%3$s TO dba', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT USAGE ON TYPE %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT USAGE ON TYPE %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_role')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT USAGE ON TYPE %1$s.%2$s.%3$s TO view_report', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

        -- pg_class
        WHEN linerecord.object_type = 'SEQUENCE' THEN
          SELECT format('ALTER SEQUENCE %1$s.%2$s.%3$s OWNER TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON SEQUENCE %1$s.%2$s.%3$s TO postgres WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON SEQUENCE %1$s.%2$s.%3$s TO dba WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON SEQUENCE %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON SEQUENCE %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_role')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT SELECT ON SEQUENCE %1$s.%2$s.%3$s TO view_report', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;
        WHEN linerecord.object_type = 'TABLE' THEN
          SELECT format('ALTER TABLE %1$s.%2$s.%3$s OWNER TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON TABLE %1$s.%2$s.%3$s TO postgres WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON TABLE %1$s.%2$s.%3$s TO dba WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON TABLE %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON TABLE %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_role')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT SELECT, REFERENCES ON TABLE %1$s.%2$s.%3$s TO view_report', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;
        WHEN linerecord.object_type = 'VIEW' THEN
          SELECT format('ALTER VIEW %1$s.%2$s.%3$s OWNER TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO postgres WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO dba WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_role')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT SELECT, REFERENCES ON %1$s.%2$s.%3$s TO view_report', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;
        WHEN linerecord.object_type = 'MATERIALIZED VIEW' THEN
          SELECT format('ALTER MATERIALIZED VIEW %1$s.%2$s.%3$s OWNER TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO postgres WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO dba WITH GRANT OPTION', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT ALL ON %1$s.%2$s.%3$s TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_role')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT SELECT, REFERENCES ON %1$s.%2$s.%3$s TO view_report', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;
        WHEN linerecord.object_type = 'INDEX' THEN
          RAISE INFO 'TODO INDEX ::: %', linerecord;

        -- pg_proc
        WHEN linerecord.object_type = 'FUNCTION' THEN
          RAISE INFO 'TODO FUNCTION ::: %', linerecord;
        WHEN linerecord.object_type = 'PROCEDURE' THEN
          RAISE INFO 'PROCEDURE ::: %', linerecord;
          SELECT format('ALTER PROCEDURE %1$s.%2$s.%3$s OWNER TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT EXECUTE ON PROCEDURE %1$s.%2$s.%3$s() TO postgres ', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT EXECUTE ON PROCEDURE %1$s.%2$s.%3$s() TO dba ', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT EXECUTE ON PROCEDURE %1$s.%2$s.%3$s() TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_user')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;

          SELECT format('GRANT EXECUTE ON PROCEDURE %1$s.%2$s.%3$s() TO %4$s', current_setting('session.forgesys_db'), current_setting('session.forgesys_schema'), linerecord.object_name, current_setting('session.forgesys_role')) INTO cmd;
          RAISE NOTICE 'cmd: %', cmd;
          EXECUTE cmd;
        ELSE
          RAISE NOTICE 'OTHER ::: %', linerecord;
      END CASE;
    END LOOP;
END $$;

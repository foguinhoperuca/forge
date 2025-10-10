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
-- 0. Implement function to retrive DB's objects
-- 1. Set permission by leve for each object

-- QUERY 1: Relations (Tables, Views, etc.) from pg_class
  SELECT
    c.oid     AS "oid",
    c.relname AS "object_name",
    r.rolname AS "owner_username",
    c.relacl  AS "acl",
    CASE c.relkind
      WHEN 'r' THEN 'TABLE'
      WHEN 'v' THEN 'VIEW'
      WHEN 'm' THEN 'MATERIALIZED VIEW'
      WHEN 'i' THEN 'INDEX'
      WHEN 'S' THEN 'SEQUENCE'
      WHEN 'f' THEN 'FOREIGN TABLE'
      WHEN 'c' THEN 'TYPE'
      ELSE c.relkind::text
    END AS "object_type",
    n.nspname AS "schema_name"
  FROM pg_class AS c
  INNER JOIN pg_namespace AS n ON n.oid = c.relnamespace
  INNER JOIN pg_roles AS r ON r.oid = c.relowner
  WHERE
    n.nspname = 'river'
    -- AND c.relkind IN ('r', 'v', 'm', 'S', 'f', 'c') -- Filter common object types
    -- AND c.relisind = FALSE                          -- Exclude implicit indexes (like those for PRIMARY KEY)

UNION ALL

-- QUERY 2: Routines (Functions and Procedures) from pg_proc
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
    n.nspname = 'river'
    AND p.prokind IN ('f', 'p')

ORDER BY
  object_type,
  owner_username,
  object_name,
  oid
;

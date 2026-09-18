\echo '--------------------------- BEFORE permissions.sql :: Put all customization bellow ---------------------------'
\i :forgesys_path/forge/permissions.sql
\echo '--------------------------- AFTER permissions.sql :: Put all customization above   ---------------------------'


-- FIXME it is comtempled in forge/permissions.sql
-- -- Per object
-- GRANT ALL ON SCHEMA <PROJECT_ACRONYM> TO dba WITH GRANT OPTION;
-- GRANT ALL ON SCHEMA <PROJECT_ACRONYM> TO <PROJECT_ACRONYM>;
-- GRANT USAGE ON SCHEMA <PROJECT_ACRONYM> TO <PROJECT_ACRONYM>_app;
-- GRANT USAGE ON SCHEMA <PROJECT_ACRONYM> TO view_report;

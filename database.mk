db-admin-script:
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -f $(DB_ADMIN_SCRIPT)

db-script:
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f $(DB_SCRIPT)

db-start: db-terraform db-ddl db-permission django-update-permissions django-users db-fixtures
	@date

db-dev: db-terraform db-refresh-migration db-ddl db-permission django-super-user db-fixtures
	@date

db-deploy: db-terraform db-ddl db-permission db-seeds
	@echo "|+-------------------------+|"
	@echo "| DEPLOY PROD FROM SCRATCH  |"
	@echo "|+-------------------------+|"
	@date

db-hypernova:
	@echo "|+-------------+|"
	@echo "|   HYPERNOVA   |"
	@echo "|+-------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_POSTGRES_HOST) -p $(DB_POSTGRES_PORT) -d $(DB_POSTGRES_DATAVASE) -U $(DB_POSTGRES_USER) -f database/hypernova.sql

db-terraform:
	@echo "|+-------------+|"
	@echo "| TERRAFORMING  |"
	@echo "|+-------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -f database/terraform.sql
	@echo "|+--------------------+|"
	@echo "| INITIALIZE           |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/initialize.sql
	@echo "|+--------------------+|"
	@echo "| MIGRATE DJANGO       |"
	@echo "|+--------------------+|"
	@python3 backoffice/manage.py migrate
	@date

db-ddl:
	@echo "|+--------------------+|"
	@echo "| INDEPENDENTS         |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/independent.sql
	@echo "|+--------------------+|"
	@echo "| DDL                  |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/ddl.sql

db-permission:
	@echo "|+--------------------+|"
	@echo "| PERMISSION           |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/permissions.sql

import-permission-superuser:
	@echo "|+--------------------+|"
	@echo "| PERMISSION SUPERUSER |"
	@echo "|+--------------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/permissions_superuser.sql

db-seeds:
	@echo "|+--------------------+|"
	@echo "| SEEDS                |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/seeds.sql

db-fixtures: db-seeds
	@echo "|+--------------------+|"
	@echo "| FIXTURES             |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/fixtures.sql

db-show:
	@echo "|+--------------------+|"
	@echo "| SHOW                 |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -c "SELECT table_name FROM information_schema.tables WHERE table_schema = '$(DB_ADMIN_DATABASE)' AND table_type = 'BASE TABLE';"

db-migrate:
	@echo "|+--------------------+|"
	@echo "| MIGRATE SQL          |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/migrate.sql

MIGRATION_ENTITY ?= "<SET_YOUR_VAR_MIGRATION_ENTITY_TO_RUN_MAKEFILE_REFRESH_MIGRATION>"
db-refresh-migration:
	@echo "|+--------------------+|"
	@echo "| REFRESH MIGRATE      |"
	@echo "|+--------------------+|"
	@python3 backoffice/manage.py migrate $(MIGRATION_ENTITY) zero
	@rm backoffice/$(MIGRATION_ENTITY)/migrations/0001_initial.py
	@python3 backoffice/manage.py makemigrations
	@python3 backoffice/manage.py migrate $(MIGRATION_ENTITY)

db-clean:
	@clear
	@date
	@echo "|+--------------------+|"
	@echo "| CLEAN DB SOFT        |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/delete.sql
	@date

db-drop:
	@echo "|+--------------------+|"
	@echo "| DROPPING             |"
	@echo "|+--------------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/drop.sql

# TODO review it
db-tables-locked:
	# @psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -c "SELECT pid FROM pg_locks AS l INNER JOIN pg_class AS t ON l.relation = t.oid AND t.relkind = 'r' WHERE t.relname = 'Bill';" | tail -n +3 | head -n -2 | xargs kill
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -c "SELECT pid FROM pg_locks AS l INNER JOIN pg_class AS t ON l.relation = t.oid AND t.relkind = 'r';" | tail -n +3 | head -n -2


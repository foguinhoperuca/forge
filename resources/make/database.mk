db-postgres-admin-script:
	@if [ -z "$(DB_SCRIPT)" ]; then \
		echo "Error: DB_SCRIPT is not set or is empty"; \
		exit 1; \
	fi
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_POSTGRES_ADM_HOST) -p $(FORGE_PGPASS_POSTGRES_ADM_PORT) -d $(FORGE_PGPASS_POSTGRES_ADM_DBNM) -U $(FORGE_PGPASS_POSTGRES_ADM_USER) -f $(DB_SCRIPT)

db-admin-script:
	@if [ -z "$(DB_SCRIPT)" ]; then \
		echo "Error: DB_SCRIPT is not set or is empty"; \
		exit 1; \
	fi
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_ADM_HOST) -p $(FORGE_PGPASS_PRIMARY_ADM_PORT) -d $(FORGE_PGPASS_PRIMARY_ADM_DBNM) -U $(FORGE_PGPASS_PRIMARY_ADM_USER) -f $(DB_SCRIPT)

db-script:
	@if [ -z "$(DB_SCRIPT)" ]; then \
		echo "Error: DB_SCRIPT is not set or is empty"; \
		exit 1; \
	fi
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f $(DB_SCRIPT)

# TODO implement DUMP
db-restore:
	@echo "|+--------------------+|"
	@echo "| RESTORING            |"
	@echo "|+--------------------+|"
	@if [ -z "$(DB_SCRIPT)" ]; then \
		echo "Error: DB_SCRIPT is not set or is empty"; \
		exit 1; \
	fi
	@pg_restore -h $(FORGE_PGPASS_PRIMARY_ADM_HOST) -p $(FORGE_PGPASS_PRIMARY_ADM_PORT) -d $(FORGE_PGPASS_PRIMARY_ADM_DBNM) -U $(FORGE_PGPASS_PRIMARY_ADM_USER) $(DB_SCRIPT)

# TODO tasks here should be in more high level. A task with only one command have a bad smell (could be replaced by db-script/db-admin-script)

db-start: db-terraform db-ddl db-permission django-update-permissions django-users db-fixtures
	@date

db-dev: db-terraform db-refresh-migration db-ddl db-permission django-super-user db-fixtures
	@date

db-deploy: db-terraform db-ddl db-permission db-seeds
	@echo "|+-------------------------+|"
	@echo "| DEPLOY PROD FROM SCRATCH  |"
	@echo "|+-------------------------+|"
	@date

# FIXME not working because supernova needs schema to create DBA. Also, the terraform needs have extension postgis (that is in supernova) and causes a circular dependency. Beside forcing create the schema in supernova, it justs works if call DB_SCRIPT=database/supernova.sql make db-admin-script before terraform
db-bigbang:
	@echo "|+-------------+|"
	@echo "|  SINGULARITY  |"
	@echo "|+-------------+|"
	psql -v forgesys_path="$(shell pwd)" -v forgesys_script="forge/resources/sql/bootstrap/singularity.sql" -h $(FORGE_PGPASS_POSTGRES_ADM_HOST) -p $(FORGE_PGPASS_POSTGRES_ADM_PORT) -d $(FORGE_PGPASS_POSTGRES_ADM_DBNM) -U $(FORGE_PGPASS_POSTGRES_ADM_USER) -f database/singularity.sql
	@echo "|+-------------+|"
	@echo "|   HYPERNOVA   |"
	@echo "|+-------------+|"
	psql -v forgesys_path="$(shell pwd)" -v forgesys_script="forge/resources/sql/bootstrap/hypernova.sql" -h $(FORGE_PGPASS_POSTGRES_ADM_HOST) -p $(FORGE_PGPASS_POSTGRES_ADM_PORT) -d $(FORGE_PGPASS_POSTGRES_ADM_DBNM) -U $(FORGE_PGPASS_POSTGRES_ADM_USER) -f database/hypernova.sql
	@echo "|+-------------+|"
	@echo "|   SUPERNOVA   |"
	@echo "|+-------------+|"
	psql -v forgesys_path="$(shell pwd)" -v forgesys_script="forge/resources/sql/bootstrap/supernova.sql" -h $(FORGE_PGPASS_POSTGRES_ADM_HOST) -p $(FORGE_PGPASS_POSTGRES_ADM_PORT) -d $(FORGE_PGPASS_POSTGRES_ADM_DBNM) -U $(FORGE_PGPASS_POSTGRES_ADM_USER) -f database/supernova.sql

db-terraform:
	@echo "|+-------------+|"
	@echo "| TERRAFORMING  |"
	@echo "|+-------------+|"
	psql -v forgesys_path="$(shell pwd)" -v forgesys_script="forge/resources/sql/database/terraform.sql" -h $(FORGE_PGPASS_PRIMARY_ADM_HOST) -p $(FORGE_PGPASS_PRIMARY_ADM_PORT) -d $(FORGE_PGPASS_PRIMARY_ADM_DBNM) -U $(FORGE_PGPASS_PRIMARY_ADM_USER) -f database/terraform.sql
	@echo "|+--------------------+|"
	@echo "| INITIALIZE           |"
	@echo "|+--------------------+|"
	psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/initialize.sql
	@echo "|+--------------------+|"
	@echo "| MIGRATE DJANGO       |"
	@echo "|+--------------------+|"
	@if [ -f "backoffice/manage.py" ]; then \
		echo "Found migrate file!!"; \
		python3 backoffice/manage.py migrate; \
	else \
		echo "NOT FOUND MIGRATE FILE!!"; \
	fi
	@date

db-ddl:
	@echo "|+--------------------+|"
	@echo "| INDEPENDENTS         |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/independent.sql
	@echo "|+--------------------+|"
	@echo "| DDL                  |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/ddl.sql

db-permission:
	@echo "|+--------------------+|"
	@echo "| PERMISSION           |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -v forgesys_script="forge/resources/sql/database/permissions.sql" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/permissions.sql

db-seeds:
	@echo "|+--------------------+|"
	@echo "| SEEDS                |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/seeds.sql

db-fixtures:
	@echo "|+--------------------+|"
	@echo "| CLEAN DB SOFT        |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/delete.sql
	@echo "|+--------------------+|"
	@echo "| SEEDS                |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/seeds.sql
	@echo "|+--------------------+|"
	@echo "| FIXTURES             |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/fixtures.sql

db-show:
	@echo "|+--------------------+|"
	@echo "| SHOW                 |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_ADM_HOST) -p $(FORGE_PGPASS_PRIMARY_ADM_PORT) -d $(FORGE_PGPASS_PRIMARY_ADM_DBNM) -U $(FORGE_PGPASS_PRIMARY_ADM_USER) -c "SELECT table_name FROM information_schema.tables WHERE table_schema = '$(FORGE_PGPASS_PRIMARY_ADM_DBNM)' AND table_type = 'BASE TABLE';"

db-migrate:
	@echo "|+--------------------+|"
	@echo "| MIGRATE SQL          |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/migrate.sql

MIGRATION_ENTITY ?= "<SET_YOUR_VAR_MIGRATION_ENTITY_TO_RUN_MAKEFILE_REFRESH_MIGRATION>"
db-refresh-migration:
	@echo "|+--------------------+|"
	@echo "| REFRESH MIGRATE      |"
	@echo "|+--------------------+|"
	@echo "$(MIGRATION_ENTITY)"
	@python3 backoffice/manage.py migrate $(MIGRATION_ENTITY) zero
	@rm backoffice/$(MIGRATION_ENTITY)/migrations/0001_initial.py
	@python3 backoffice/manage.py makemigrations
	@python3 backoffice/manage.py migrate $(MIGRATION_ENTITY)

db-drop:
	@echo "|+--------------------+|"
	@echo "| DROPPING             |"
	@echo "|+--------------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -f database/drop.sql

# TODO review it
db-tables-locked:
	# @psql -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -c "SELECT pid FROM pg_locks AS l INNER JOIN pg_class AS t ON l.relation = t.oid AND t.relkind = 'r' WHERE t.relname = 'Bill';" | tail -n +3 | head -n -2 | xargs kill
	@psql -h $(FORGE_PGPASS_PRIMARY_SYS_HOST) -p $(FORGE_PGPASS_PRIMARY_SYS_PORT) -d $(FORGE_PGPASS_PRIMARY_SYS_DBNM) -U $(FORGE_PGPASS_PRIMARY_SYS_USER) -c "SELECT pid FROM pg_locks AS l INNER JOIN pg_class AS t ON l.relation = t.oid AND t.relkind = 'r';" | tail -n +3 | head -n -2


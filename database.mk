db-admin-script:
	@psql -v pmsys_path="$(shell pwd)" -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -f $(DB_ADMIN_SCRIPT)

db-script:
	@psql -v pmsys_path="$(shell pwd)" -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -f $(DB_SCRIPT)

db-start: db-terraform db-ddl db-permission django-update-permissions django-users db-fixtures
	@date

db-deploy: db-terraform db-ddl db-permission django-update-permissions django-users db-seeds
	@echo "|+-------------------------+|"
	@echo "| DEPLOY PROD FROM SCRATCH  |"
	@echo "|+-------------------------+|"
	@date

db-terraform: 
	@echo "|+-------------+|"
	@echo "| TERRAFORMING  |"
	@echo "|+-------------+|"
# TODO pass variable in psql call here
	@psql -v pmsys_path="$(shell pwd)" -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -f forge/terraform.sql
	@echo "|+-------------+|"
	@echo "| INITIALIZE    |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/initialize.sql
	@echo "|+--------------+|"
	@echo "| MIGRATE DJANGO |"
	@echo "|+--------------+|"
	@python3 backoffice/manage.py migrate
	@date

db-ddl:
	@echo "|+-------------+|"
	@echo "| INDEPENDENTS  |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/independent.sql
	@echo "|+-------------+|"
	@echo "| DDL           |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/ddl.sql
	@echo "|+-------------+|"
	@echo "| DB SHAPE      |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/gcm_data/import_sp_sorocaba_sr_cprm.sql
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/joined/final_merged.sql

db-permission:
	@echo "|+-------------+|"
	@echo "| PERMISSION    |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/permissions.sql

db-seeds:
	@echo "|+-------------+|"
	@echo "| SEEDS         |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/seeds.sql

db-fixtures: db-seeds
	@echo "|+-------------+|"
	@echo "| FIXTURES      |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/fixtures.sql

db-shp:
	@echo "|+-------------+|"
	@echo "| DB SHP        |"
	@echo "|+-------------+|"
	@shp2pgsql -d -W ISO-8859-1 database/gcm_data/SP_SOROCABA_SR_CPRM.dbf alerta_defesa_civil.alert_spsorocabasrcprm | psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER)

db-show:
	@echo "|+-------------+|"
	@echo "| SHOW          |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/show_types.sql
	@psql -h $(DB_ADMIN_HOST) -p $(DB_ADMIN_PORT) -d $(DB_ADMIN_DATABASE) -U $(DB_ADMIN_USER) -c 'SELECT unnest(enum_range(NULL::alerta_defesa_civil.grau_risco)) AS "Grau de Risco", unnest(enum_range(NULL::alerta_defesa_civil.grau_risco_tipologia_estudo)) AS "Gr Risco Tip Est", unnest(enum_range(NULL::alerta_defesa_civil.grau_vulnerabilidade_topologia_estudo)) AS "Gr Vuln Top Est", unnest(enum_range(NULL::alerta_defesa_civil.intervencao)) AS "Intervenção", unnest(enum_range(NULL::alerta_defesa_civil.natureza)) AS "Natureza";'

db-migrate:
	@echo "|+-------------+|"
	@echo "| MIGRATE SQL   |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/migrate.sql

clean-db:
	@clear
	@date
	@echo "|+-------------+|"
	@echo "| CLEAN DB SOFT |"
	@echo "|+-------------+|"
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/delete.sql
	@date

# TODO make populate part of django commands
clean-db-dev: clean-db db-fixtures
	@date

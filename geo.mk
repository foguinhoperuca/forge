geo-ddl:
	@echo "|+-------------+|"
	@echo "| INDEPENDENTS  |"
	@echo "|+-------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/independent.sql
	@echo "|+-------------+|"
	@echo "| DDL           |"
	@echo "|+-------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/ddl.sql
	@echo "|+-------------+|"
	@echo "| DB SHAPE      |"
	@echo "|+-------------+|"
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/gcm_data/import_sp_sorocaba_sr_cprm.sql
	@psql -v forgesys_path="$(shell pwd)" -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -f database/joined/final_merged.sql

geo-shp:
	@echo "|+-------------+|"
	@echo "| DB SHP        |"
	@echo "|+-------------+|"
	@shp2pgsql -d -W ISO-8859-1 database/gcm_data/SP_SOROCABA_SR_CPRM.dbf alerta_defesa_civil.alert_spsorocabasrcprm | psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER)

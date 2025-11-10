django-super-user:
	@python3 backoffice/manage.py createsuperuser --noinput
	@psql -h $(DB_HOST) -p $(DB_PORT) -d $(DB_DATABASE) -U $(DB_USER) -c "UPDATE $(FORGE_SYSTEM_NAME).auth_user SET first_name = 'Administrator', last_name = 'IT Dept' WHERE id = 1;"

django-users:
	@echo "|+-------------+|"
	@echo "| DJANGO USERS  |"
	@echo "|+-------------+|"
	@python3 database/populate.py

django-update-permissions:
	@echo "|+--------------+|"
	@echo "| DJANGO UP PERM |"
	@echo "|+--------------+|"
	@python3 backoffice/manage.py update_permissions

django-collectstatic:
	@echo "|+---------------------+|"
	@echo "| DJANGO COLLECT STATIC |"
	@echo "|+---------------------+|"
	@python3 backoffice/manage.py collectstatic --noinput

init-backoffice: init
	pip install -r backoffice/requirements.txt

init-api: init
	pip install -r api/requirements.txt

run-local:
	@clear
	@date
	@time python3 manage.py runserver 0.0.0.0:8080
	@date

# TODO implement test
test-api:
	clear; date; time ./api/tests/test_endpoint.sh auth STAGE; date

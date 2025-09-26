# # Env stuffs
# patch:
# 	@clear
# 	@date
# 	@rm -rf $(GIT_BRANCH).patch
# 	@git diff HEAD . >> $(GIT_BRANCH).patch
# 	scp $(GIT_BRANCH).patch $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):$(PATCH_GIT_DIFF_FILE_LOCATION)

# patch-diffutils: patch
# 	ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "cd $(APP_PATH_DOCUMENT_ROOT)/; git --work-tree=$(APP_PATH_DOCUMENT_ROOT) --git-dir=$(APP_PATH_BARE) checkout -f $(GIT_BRANCH); patch --forward < $(APP_PATH_WORKTREE)/$(GIT_BRANCH).patch"
# 	@date

# patch-git: patch
# 	ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "cd $(PATCH_GIT_TARGET); git restore .; git pull origin $(GIT_BRANCH); git apply $(PATCH_GIT_DIFF_FILE_LOCATION)/$(GIT_BRANCH).patch"
# 	@date

# patch-git-edge: PATCH_GIT_TARGET=$(APP_PATH_ORIGIN_EDGE)
# patch-git-edge: PATCH_GIT_DIFF_FILE_LOCATION=$(APP_PATH_ORIGIN_EDGE)
# patch-git-edge: patch-git

# patch-git-upstream: PATCH_GIT_TARGET=$(APP_PATH_UPSTREAM)
# patch-git-upstream: PATCH_GIT_DIFF_FILE_LOCATION=$(APP_PATH_WORKTREE)
# patch-git-upstream: patch-git

# # TODO cp secrets to /etc/adc - move it to forge.sh
# # TODO set array var to credential's files.
# cp-secrets:
# 	@clear
# 	@echo "|+-------------+|"
# 	@echo "| COPY SECRETS  |"
# 	@echo "|+-------------+|"
# 	@date
# 	@rm -f .*~
# 	@rm -f *~
# 	@rm -f .credentials/.*~
# 	@rm -f .credentials/*~
# 	scp .credentials/.mise-en-place.conf .credentials/.env.* .credentials/.google-service-account* .credentials/.pgpass.* .credentials/.target-server.* $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):$(shell echo "${APP_PATH_ORIGIN_EDGE}" | sed -e "s/${USER}/${TARGET_SERVER_USER}/g")/.credentials/
# 	scp .credentials/.env.* .credentials/.google-service-account* .credentials/.pgpass.* .credentials/.target-server.* $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):$(APP_PATH_ETC)/
# # ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "cd $(APP_PATH_ETC); source ./forge.sh export $(TARGET_ENV); ./forge.sh set_symbolic_link"
# 	@date

# deploy-apache-conf:
# 	@echo "|+-------------+|"
# 	@echo "| DEPLOY APACHE |"
# 	@echo "|+-------------+|"
# 	@date
# 	@rm -f webserver/apache/$(TARGET_SERVER_TYPE)_server/*~*
# 	@ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "rm /home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/*; mkdir -p /home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/"
# ifeq ($(TARGET_ENV),prod)
# 	scp webserver/apache/$(TARGET_SERVER_TYPE)_server/$(APP_NAME).sorocaba.sp.gov.br.conf $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):/home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/$(APP_NAME).sorocaba.sp.gov.br.conf
# 	scp webserver/apache/$(TARGET_SERVER_TYPE)_server/$(APP_NAME)-api.sorocaba.sp.gov.br.conf $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):/home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/$(APP_NAME)-api.sorocaba.sp.gov.br.conf
# else
# 	scp webserver/apache/$(TARGET_SERVER_TYPE)_server/$(APP_NAME).sorocaba.sp.gov.br.conf $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):/home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/$(APP_NAME)-$(TARGET_ENV).sorocaba.sp.gov.br.conf
# 	scp webserver/apache/$(TARGET_SERVER_TYPE)_server/$(APP_NAME)-api.sorocaba.sp.gov.br.conf $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):/home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/$(APP_NAME)-api-$(TARGET_ENV).sorocaba.sp.gov.br.conf
# endif
# 	@ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "sudo cp /home/$(TARGET_SERVER_USER)/tmp/$(APP_NAME)/$(APP_NAME)* /etc/apache2/sites-available/; sudo apachectl configtest"
# 	@ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "sudo a2ensite $(APP_NAME)*"
# 	@echo "[MAKEFILE] Restarting apache server..."
# 	@ssh $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR) "sudo service apache2 restart"

# umount:
# 	@echo "|+--------------+|"
# 	@echo "| UMOUNT FILESYS |"
# 	@echo "|+--------------+|"
# 	@echo "using: TARGET_ENV=$(TARGET_ENV) APP_NAME=$(APP_NAME)"
# ifneq ($(TARGET_ENV),local)
# 	@echo "umounting TARGET_ENV=$(TARGET_ENV)"
# 	@-umount -q /mnt/storage_sistemas/$(APP_NAME)-$(TARGET_ENV)
# else
# 	@echo "--- IGNORING umount $(TARGET_ENV) --> /mnt/storage_sistemas/$(APP_NAME)-$(TARGET_ENV)"
# endif
# 	@rm -f /mnt/storage_sistemas/$(APP_NAME)
# 	@df -h
# 	@ls --color=auto -lah /mnt/storage_sistemas/

# mount: umount
# 	@echo "|+-------------+|"
# 	@echo "| MOUNT FILESYS |"
# 	@echo "|+-------------+|"
# 	@echo "using: TARGET_ENV=$(TARGET_ENV) APP_NAME=$(APP_NAME) APP_PATH=$(APP_PATH)"
# ifneq ($(TARGET_ENV),local)
# 	@mount /mnt/storage_sistemas/$(APP_NAME)-$(TARGET_ENV)/
# else
# 	@echo "--- IGNORING mount $(TARGET_ENV) --> /mnt/storage_sistemas/$(APP_NAME)-$(TARGET_ENV)"
# endif
# 	@ln -s  /mnt/storage_sistemas/$(APP_NAME)-$(TARGET_ENV) /mnt/storage_sistemas/$(APP_NAME)
# 	@sudo chown -R www-data:www-data /mnt/storage_sistemas/$(APP_NAME)
# 	@df -h
# 	@echo ""
# 	@echo "--- MOUNTED AT:"
# 	@ls --color=auto -lah /mnt/storage_sistemas/$(APP_NAME)
# 	@echo ""
# 	@echo "--- INSIDE /mnt/storage_sistemas/$(APP_NAME)/:"
# 	@ls --color=auto -lah /mnt/storage_sistemas/$(APP_NAME)/

# post-receive:
# 	clear
# 	date
# 	echo "abcdef123 fedcba987 refs/heads/master" | ./git-hooks/post-receive
# 	date

# build-ctags:
# 	@cd backoffice
# 	@ctags -e -R --exclude=.git --exclude=__pycache__ --exclude=tests --exclude=venv --exclude=static --exclude=media --exclude=.mypy_cache --exclude=*~ .
# 	@cd ../api
# 	@ctags -e -R --options=.ctags .
# 	@cd ../bot
# 	@ctags -e -R --options=.ctags .

SEARCH_SRC_STR ?= "PMS_SYSTEM_NAME"
SEARCH_TYPE ?= "SUMMARY"
search-in-source-code:
	@clear
	@date
	@echo "SEARCH_TYPE --> $(SEARCH_TYPE) ::: SEARCH SRC STR --> $(SEARCH_SRC_STR)"
ifeq ($(SEARCH_TYPE),SUMMARY)
	@grep -rn "$(SEARCH_SRC_STR)" * --exclude-dir={forge,tmp,venv,__pycache__,tests} --exclude={TAGS,dev.patch} | awk '{print $1}'
else ifeq ($(SEARCH_TYPE),FULL)
	@grep -rn "$(SEARCH_SRC_STR)" * --exclude-dir={forge,tmp,venv,__pycache__,tests} --exclude={TAGS,dev.patch} | awk '{print $1}' | grep -v "~" | grep -v ":from" | sort | uniq
endif
	@echo "-------"
	@grep -rn "$(SEARCH_SRC_STR)" * --exclude-dir={forge,tmp,venv,__pycache__,tests} --exclude={TAGS,dev.patch} | awk '{print $1}' | sort | uniq | wc -l
	@echo ""
	@date


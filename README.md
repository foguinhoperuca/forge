# Forge #

Set of tools and scripts to create, maintain and run a project. Very (my own) Opinionated. Tired of copy and paste code from one project to another.

# File Organization #

## Terraform ##

All project need have, at least, the forge.sh script and the configuration's files (you should have the encrypted file and private key to uncrypt it).
By default, the original project is cloned in _$USER/universal/projects/<OPTIONAL-GROUP>/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/_ and it is called as edge. It will have a symlink into deployment described bellow.

_<OPTIONAL-GROUP>_ is used to group projects form same organization.

## Configurations ##

All config files will live in _/etc/<FORGE-SYSTEM-ACRONYM>/<CONFIG-FILE-UNCRYPTED>_ as plain text, to be used by system. The encrypted version will live in a repository described as bellow.

The general description of _<CONFIG-FILE-UNCRYPTED>_ files is:
```
|-- .env.<PYTHON_PROJECT>.<TARG ::: configuration specific for <PYTHON_PROJECT>: [api | backoffice | bot];
|-- .mise-en-place.conf         ::: the master configuration for project itself. Do not repeat/do not have environment version;
|-- .pgpass.<TARGET-ENV>        ::: specific to access database (postgresql). Each file for each envirionment;
|-- .target-server.<TARGET-ENV> ::: general conf for each envirionments;
```

You can see all details of each file inside of _.credentials/samples/<CONFIG-FILE-TEMPLATE>_.

### Secrets ###

All secrets and sensitive information will be stored in _<ROOT-HOST-PROJECT>/.credentials_.

```
|-- upstream                     ::: use **git sparse-checkout** to get data from sensitive's repository;
|---- encrypted                  ::: all data encrypted ust live here;
|------ secure                   ::: symlink to your main project;
|------ <FORGE_SYSTEM_ACRONYM>   ::: various folders;
|-------- *.gpg                  ::: encrypted data per ser;
|-------- *.asc                  ::: symlkink to pyblic keys stored in ../../pubkeys (2 levels above);
|---- pubkeys                    ::: gpg public keys **only** (DO NOT STORE PRIVATE KEY OR SENSITIVE DATA HERE!!);
|------ computer                 ::: stored public keys from computers, server, etc, dev machine, etc.;
|------ dev                      ::: stored public keys from developers;
|------ env                      ::: stored public keys from environments (keys that can be in various environments - docker, local, dev, stage, prod, replica-server);
|-- encrypted                    ::: symlink for _upstream/encrypted_ or "physical" folder that will store all layout described here;
|-- pubkeys                      ::: symlink for _upstream/pubkeys_ or "physical" folder that will store all layout described here;
|-- samples                      ::: symlink for _root-host-project/forge/samples_ need by forge's scripts;
```

Eventually, you can use this layout directly in your project instead of use it as git submodule.

## Deployment ##

The project will be living under _/opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/_ where, by default, <GIT_REPOS_NAME> is "backend".

```
/opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/
-- bare.git
---- hooks
------ ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/edge/forge.sh forge.sh
------ ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/edge/.mise-en-place.conf .mise-en-place.conf
------ ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/edge/git-hooks/post-receive post-receive
-- worktree
---- <GIT_BRANCH>: [local | dev | stage | prod | proxystage | proxyprod]
---- git clone <GIT_URL> upstream
---- ln -s <PATH_DEV_REPOS> edge
---- ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/<GIT_BRANCH>/ document_root
```

## Storage ##

The default local to store blob and files from upload is in a folder _/mnt/<OPTIONAL-GROUP>/<FORGE_SYSTEM_ACRONYM>-<TARGET_ENV>_.
Each environment [local | dev | stage | prod | replica] will have an own folder and _/mnt/<OPTIONAL-GROUP>/<FORGE_SYSTEM_ACRONYM>_ (without -<TARGET_ENV> in the end) will be a symlink to <TARGET_ENV> in use.
The system and scripts will only use the path to _/mnt/<OPTIONAL-GROUP>/<FORGE_SYSTEM_ACRONYM>_.
Also, a special path _/mnt/<OPTIONAL-GROUP>/all_ wuill be used to see all projects files (if it is in same storage).

**TODO organize it and set an default layout.**
**TODO replace OPTIONAL-ORGANIZATION with FORGE_ORGANIZATION_ACRONYM**

### Mounted on Server ###
```
|-- mnt
|---- <OPTIONAL-GROUP>                      ::: storage_sistemas should be replaced by <OPTIONAL-GROUP>
|------ <FORGE_SYSTEM_ACRONYM>              ::: ln -s /mnt/<OPTIONAL-GROUP>/<FORGE_SYSTEM_ACRONYM>-<TARGET_ENV>
|------ <FORGE_SYSTEM_ACRONYM>-all          ::: ln -s <STORAGE_ROOT>/<FORGE_SYSTEM_ACRONYM>
|------ <FORGE_SYSTEM_ACRONYM>-<TARGET_ENV> ::: ln -s <STORAGE_ROOT>/<FORGE_SYSTEM_ACRONYM>/<TARGET_ENV>
```

### Expected Organization in Storage ###

```
|-- <STORAGE-ROOT>
|---- <FORGE_SYSTEM_ACRONYM>
|------ .credentials               ::: backup for sensitive information (if needed)
|------ <TARGET_ENV>               ::: by env [local | dev | stage | prod | replica]
|-------- ANOTHER-SERVICVE-BY-ENV  ::: something that make sense be by <TARGET_ENV>
|-------- backups                  ::: copy of backup
|-------- files                    ::: store generic files
|---------- shared_users           ::: optional folder to be shared with end-users in company's network
|---------- media                  ::: stored by django
```

## Web Server ##

**TODO describe it!**

ln -s $APP_PATH_WORKTREE/$TARGET_ENV/webserver/apache/app_server/<FORGE_SYSTEM_BASE_DNS>-<DJANGO-PROJECT>.conf /etc/apache2/sites-available/<FORGE_SYSTEM_BASE_DNS>-<TARGET_ENV>-<DJANGO-PROJECT>.<FORGE_SYSTEM_BASE_DNS>.conf

**TODO describe layout**
- app_path_var_www_app
- app_path_var_www_proxy

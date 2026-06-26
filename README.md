# Forge #

Set of tools and scripts to create, maintain and run a project. Very (my own) Opinionated. Tired of copy and paste code from one project to another.
[Code style reference](https://google.github.io/styleguide/shellguide.html "Implementation in forge is WIP")

# Initialize Host Project #

Is expected to do the follow tasks:
- `mkdir -p $HOME/universal/projects/<FORGE_ORGANIZATION_ACRONYM>/<FORGE_SYSTEM_ACRONYM>/`
- `git clone --recurse-submodules "${GIT_PROTOCOL}${GIT_USER}@${GIT_BASE_URL}/${FORGE_SYSTEM_BASE_DNS}.git" $HOME/universal/projects/<FORGE_ORGANIZATION_ACRONYM>/<FORGE_SYSTEM_ACRONYM>/backend && cd $_`
- `gpg --yes -o .credentials/.mise-en-place.conf -d .credentials/secure/.mise-en-place.conf.gpg`
- `./mount_etna.sh terraform <TARGET_ENV>`

Also you can run the follow script to install your project:

```
# MANDATORY because values must be defined
export FORGE_SYSTEM_ACRONYM="<PROJECT_NAME>"
export FORGE_ORGANIZATION_ACRONYM="<PROJECT_ORGANIZATION>"

# NOT Mandatory because it has default values
export GIT_BRANCH="<DEFAULT_VALUE_MASTER>"
export FORGE_ORGANIZATION_VAULT="<DEFAULT_VALUE_SECRETS>"

curl -fsSL https://raw.githubusercontent.com/foguinhoperuca/forge/refs/heads/master/install.sh | bash -s -- $FORGE_SYSTEM_ACRONYM $FORGE_ORGANIZATION_ACRONYM $GIT_BRANCH $FORGE_ORGANIZATION_VAULT
```

# Database Organization #

- ```:forgesys_db``` is main database to hold data to all app. No directly access by end-user.
- ```:forgesys_db_foreign``` is database to hold data to be accessed by end-user and/or gis app (qgis).

There are levels for task as in this order: Singularity > Hypernova > Supernova > Terraform

| Level       | Description                                                   |
|-------------|---------------------------------------------------------------|
| Singularity | for host/server-level tasks                                   |
| Hypernova   | above database level, inside host server                      |
| Supernova   | intra database level (for main app database and gis database) |
| Terraform   | schema level tasks                                            |

## Default User/Roles ##

| User/Group           | Level                     | Description                                                 | Role                                                                                                                            |
|----------------------|---------------------------|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| postgres             | Singularity               | database super admin                                        | God.                                                                                                                            |
| gis_group            | Singularity               | user integrated with external auth mechanism (LDAP)         | For authentication purpose only. Do not have any power over any data or special privileges.                                     |
| app_tester (sys_grp) | Singularity (Singularity) | test apps user (programmatic)                               | For test purpose only. Should can have power to create DB. **Do not have access to DB of with data (forgesys, gis, etc)**       |
| :dba_person (dba)    | Hypernova (Hypernova)     | database administrators (**has role to manage it**)         | Database administrator. Full access to manage databases but not the server (not superadmin). Has a role to aggregate all users. |
| view_report          | Hypernova                 | read-only user (shared)                                     | For report purpose only. Should not interfere with the system only observe it.                                                  |
| :forgesys (sys_grp)  | Terraform (Singularity)   | system user/programmatic access (**has role to manage it**) | Software-mediated access. Owner of most objects. API and other software                                                         |
| :forgesys_app        | Terraform                 | end user with database access                               | Direct access to the database on an indivudual basis, but with more restricted access. Use of QGIS app.                         |

# File Organization #

## Terraform ##

All project need have, at least, the mount_etna.sh script and the configuration's files (you should have the encrypted file and private key to uncrypt it).
By default, the original project is cloned in _$USER/universal/projects/<OPTIONAL-GROUP>/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/_ and it is called as edge. It will have a symlink into deployment described bellow.

_<OPTIONAL-GROUP>_ is used to group projects form same organization.

## Configurations ##

All config files will live in _/etc/<FORGE-SYSTEM-ACRONYM>/<CONFIG-FILE-UNCRYPTED>_ as plain text, to be used by system. The encrypted version will live in a repository described as bellow.

The general description of _<CONFIG-FILE-UNCRYPTED>_ files is:
```
|-- .env.<PYTHON_PROJECT>.<TARGET-ENV> ::: configuration specific for <PYTHON_PROJECT>: [api | backoffice | bot];
|-- .mise-en-place.conf                ::: the master configuration for project itself. Do not repeat/do not have environment version;
|-- .pgpass.<TARGET-ENV>               ::: specific to access database (postgresql). Each file for each envirionment;
|-- .target-server.<TARGET-ENV>        ::: general conf for each envirionments;
|-- .user_seeds.csv.<TARGET-ENV>       ::: contain the initial users in system;
```

You can see all details of each file inside of _.credentials/samples/<CONFIG-FILE-TEMPLATE>_.

### Secrets ###

All secrets and sensitive information will be stored in _<ROOT-HOST-PROJECT>/.credentials_.

```
|-- .mise-en-place               ::: official local for main initial conf file
|-- output_secrets               ::: transactional folder to hold uncrypted secrets before it be sended to a proper local [etc | edge | .mise-en-place]
|-- samples                      ::: symlink for _root-host-project/forge/samples_ need by forge's scripts;
|-- secure                       ::: symlink to your main credential's encrypted data;
|-- cp_tests                     ::: transactional folder to hold uncrypted secrets - test purpose only (also used in /etc/<FORGE_SYSTEM_ACRONYM> and .credentials/secure)
|-- upstream                     ::: use **git sparse-checkout** to get data from sensitive's repository;
|---- encrypted                  ::: all data encrypted must live here;
|------ <FORGE_SYSTEM_ACRONYM>   ::: various folders;
|-------- *.gpg                  ::: encrypted data per ser;
|-------- *.asc                  ::: symlkink to pyblic keys stored in ../../pubkeys (2 levels above);
|---- pubkeys                    ::: gpg public keys **only** (DO NOT STORE PRIVATE KEY OR SENSITIVE DATA HERE!!);
|------ computer                 ::: stored public keys from computers, server, etc, dev machine, etc.;
|------ dev                      ::: stored public keys from developers;
|------ env                      ::: stored public keys from environments (keys that can be in various environments - docker, local, dev, stage, prod, replica-server);
~|-- encrypted                    ::: symlink for _upstream/encrypted_ or "physical" folder that will store all layout described here;~
~|-- pubkeys                      ::: symlink for _upstream/pubkeys_ or "physical" folder that will store all layout described here;~
```

Eventually, you can use this layout directly in your project instead of use it as git submodule.

## Deployment ##

The project will be living under _/opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/_ where, by default, <GIT_REPOS_NAME> is "backend".

```
/opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/
-- bare.git
---- hooks
------ ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/edge/mount_etna.sh mount_etna.sh
------ ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/edge/.mise-en-place.conf .mise-en-place.conf
------ ln -s /opt/<FORGE_SYSTEM_ACRONYM>/<GIT_REPOS_NAME>/worktree/edge/git-hooks/post-receive post-receive
-- worktree
---- <GIT_BRANCH>: [local | dev | stage | prod | replica<99> | proxystage | proxyprod]
---- git clone --recurse-submodules <GIT_URL> upstream
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

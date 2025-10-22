#!/bin/bash

terraform_app_path_etc() {
    echo ""
    echo "|---------------------------|"
    echo "| Terraforming APP_PATH_ETC |"
    echo "|---------------------------|"
    echo "$APP_PATH_ETC"
    export TARGET_SERVER_USER=$(PROCPS_USERLEN=20 w -h | awk '{print $1}' | uniq) # FIXME should get the first only (something like) --> | cut -d " " -f 1
    sudo rm -rf $APP_PATH_ETC
    sudo mkdir $APP_PATH_ETC
    # TODO copy each file - this way gnu core utils 8.32 will complain
    sudo cp ${APP_PATH_ORIGIN_EDGE}/.credentials/.* $APP_PATH_ETC/
    sudo rm $APP_PATH_ETC/.*.sample
    sudo chown -R $TARGET_SERVER_USER:$TARGET_SERVER_USER $APP_PATH_ETC/
    sudo chmod 600 -R $APP_PATH_ETC/.pgpass.* $APP_PATH_ETC/.pgpass.*
    sudo chown $TARGET_SERVER_USER:www-data $APP_PATH_ETC/.env.*
    sudo chmod 640 -R $APP_PATH_ETC/.env.*
    echo "${NOW}" > $APP_PATH_ETC/deployment_datetime.txt
}

terraform_app_path_opt() {
    echo ""
    echo "|---------------------------|"
    echo "| Terraforming APP_PATH_OPT |"
    echo "|---------------------------|"
    echo "$APP_PATH_OPT"
    sudo rm -rf $APP_PATH_OPT
    sudo mkdir -p $APP_PATH_WORKTREE
    sudo chown -R $TARGET_SERVER_USER:$TARGET_SERVER_USER /opt/${FORGE_SYSTEM_ACRONYM}/

    ln -s $APP_PATH_ORIGIN_EDGE $APP_PATH_WORKTREE/edge

    git init --bare $APP_PATH_BARE
    rm $APP_PATH_BARE/hooks/*
    ln -s $APP_PATH_WORKTREE/edge/forge.sh $APP_PATH_BARE/hooks/forge.sh
    ln -s $APP_PATH_WORKTREE/edge/.credentials/.mise-en-place.conf $APP_PATH_BARE/hooks/.mise-en-place.conf

    for env_available in ${ENVS_AVAILABLE[@]};
    do
        if [[ "$env_available" != @(edge|upstream) ]]
        then
            mkdir $APP_PATH_WORKTREE/$env_available
        fi
    done
    # TODO on deploy set correct APP_PATH_WORKTREE/TARGET_ENV for $APP_PATH_DOCUMENT_ROOT
    ln -s $APP_PATH_UPSTREAM $APP_PATH_DOCUMENT_ROOT

    git -c credential.helper='!f() { sleep 1; echo "password=${GIT_PASSWORD}"; }; f' clone http://$GIT_USER@$GIT_BASE_URL/$FORGE_SYSTEM_BASE_DNS.git $APP_PATH_UPSTREAM
    cd $APP_PATH_UPSTREAM
    git config credential.helper store
    git fetch -a $APP_PATH_UPSTREAM
    git checkout -b $GIT_BRANCH origin/$GIT_BRANCH
    git remote add deployment file://$APP_PATH_BARE
    git push deployment $GIT_BRANCH
    ln -s $APP_PATH_WORKTREE/edge/git-hooks/post-receive $APP_PATH_BARE/hooks/post-receive

    git submodule update --init --recursive

    cd -
    echo "${NOW}" > $APP_PATH_UPSTREAM/deployment_datetime.txt
}

terraform_app_path_mnt() {
    echo ""
    echo "|-----------------------|"
    echo "| Creating APP_PATH_MNT |"
    echo "|-----------------------|"
    echo "$APP_PATH_MNT"
    # umount -q $APP_PATH_MNT*
    # rm -f $APP_PATH_MNT
    # for env_available in ${ENVS_AVAILABLE[@]};
    # do
    #     if [[ "$env_available" != @(edge|upstream) ]]
    #     then
    #         for media_file_available in ${DJANGO_MEDIA_FILE_AVAILABLE[@]};
    #         do
    #             sudo mkdir -p /mnt/storage_sistemas/"$FORGE_SYSTEM_BASE_DNS"-"$env_available"/media/"$media_file_available"/
    #         done
    #     fi
    # done
    # sudo chown -R $TARGET_SERVER_USER:www-data $APP_PATH_MNT*
    # sudo chmod 775 $APP_PATH_MNT*

    # if [ "$TARGET_ENV" != "local" ];
    # then
    #     mount /mnt/storage_sistemas/"$FORGE_SYSTEM_BASE_DNS"-"$TARGET_ENV"
    # fi
    # # TODO implement a function to manage /etc/fstab - maybe use 999_adc-<ENV>.fstab
    # # sudo mount -a -fstab deployment_conf/999_adc.fstab
    # ln -sf $APP_PATH_MNT-$TARGET_ENV $APP_PATH_MNT
}

terraform_app_path_var_www_app() {
    # TODO implement load balance apache
    echo ""
    echo "|---------------------------|"
    echo "| Creating APP_PATH_VAR_WWW |"
    echo "|---------------------------|"
    echo "$APP_PATH_VAR_WWW - app: local webserver"
    sudo a2dissite $FORGE_SYSTEM_BASE_DNS*
    echo "VARS ::: $FORGE_SYSTEM_BASE_DNS ::: $FORGE_SYSTEM_ACRONYM ::: $APP_PATH_VAR_WWW"
    if grep -q "^export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=" /etc/apache2/envvars; then
        sudo sed -i.bkp "s/^export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=.*/export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=\"-$TARGET_ENV\"/" /etc/apache2/envvars
    else
        echo "export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=\"-$TARGET_ENV\"" | sudo tee -a /etc/apache2/envvars > /dev/null
    fi
    # unset ITER
    # ITER=0
    # ITER=$(expr $ITER + 1)
    for django_project in ${DJANGO_PROJECTS_AVAILABLE[@]}
    do
        # if [ "${ITER}" == "0" ];
        if [ "${django_project}" == "backoffice" ];
        then
            sudo ln -sf $APP_PATH_DOCUMENT_ROOT/$django_project $APP_PATH_VAR_WWW
            sudo ln -sf $APP_PATH_DOCUMENT_ROOT/webserver/apache/app_server/$FORGE_SYSTEM_BASE_DNS.sorocaba.sp.gov.br.conf /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS.sorocaba.sp.gov.br.conf
        else
            sudo ln -sf $APP_PATH_DOCUMENT_ROOT/$django_project "$APP_PATH_VAR_WWW"-$django_project
            sudo ln -sf $APP_PATH_DOCUMENT_ROOT/webserver/apache/app_server/$FORGE_SYSTEM_BASE_DNS-$django_project.sorocaba.sp.gov.br.conf /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS-$django_project.sorocaba.sp.gov.br.conf
        fi
    done
    # TODO move www-data and other defaults from ubuntu to conf var
    sudo chown -R $TARGET_SERVER_USER:www-data $APP_PATH_VAR_WWW*
    sudo chown -R $TARGET_SERVER_USER:www-data /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS*
    sudo a2ensite $FORGE_SYSTEM_BASE_DNS*
    sudo apachectl configtest
    sudo service apache2 restart
}

terraform_app_path_var_www_proxy() {
    echo ""
    echo "|---------------------------|"
    echo "| Creating APP_PATH_VAR_WWW |"
    echo "|---------------------------|"
    echo "$APP_PATH_VAR_WWW - Setting the proxy server."
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo a2dissite $FORGE_SYSTEM_BASE_DNS*"
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo rm -f /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS*"
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "
    #     if grep -q '^export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=' /etc/apache2/envvars; then
    #         sudo sed -i.bkp 's/^export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=.*/export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=\"-$TARGET_ENV\"/' /etc/apache2/envvars
    #     else
    #         echo 'export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=\"-$TARGET_ENV\"' | sudo tee -a /etc/apache2/envvars > /dev/null
    #     fi
    # "
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo rm -rf $APP_PATH_OPT"
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo mkdir -p $APP_PATH_DOCUMENT_ROOT/webserver/apache/proxy_server/"
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo chown $TARGET_SERVER_PROXY_USER:$TARGET_SERVER_PROXY_USER -R /opt/$FORGE_SYSTEM_ACRONYM"
    # scp webserver/apache/proxy_server/$FORGE_SYSTEM_BASE_DNS* $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR:$APP_PATH_DOCUMENT_ROOT/webserver/apache/proxy_server/
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo chown $TARGET_SERVER_PROXY_USER:www-data -R $APP_PATH_DOCUMENT_ROOT"
    # unset ITER
    # ITER=0
    # for django_project in ${DJANGO_PROJECTS_AVAILABLE[@]}
    # do
    #     if [ "${ITER}" == "0" ];
    #     then
    #         ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo ln -sf $APP_PATH_DOCUMENT_ROOT/webserver/apache/proxy_server/$FORGE_SYSTEM_BASE_DNS.sorocaba.sp.gov.br.conf /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS.sorocaba.sp.gov.br.conf"
    #     else
    #         ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo ln -sf $APP_PATH_DOCUMENT_ROOT/webserver/apache/proxy_server/$FORGE_SYSTEM_BASE_DNS-$django_project.sorocaba.sp.gov.br.conf /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS-$django_project.sorocaba.sp.gov.br.conf"
    #     fi
    #     ITER=$(expr $ITER + 1)
    # done
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo a2ensite $FORGE_SYSTEM_BASE_DNS*"
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo apachectl configtest"
    # ssh $TARGET_SERVER_PROXY_USER@$TARGET_SERVER_PROXY_ADDR "sudo service apache2 restart"
}

app_path_base_backup_database() {
    TODO plan about: ln -s /var/backups/postgresql/$DB_DATABASE /mnt/storage_sistemas/$FRG_SYSTEM_ACRONYM/backups/db/
    echo "TODO implement create and mount an datbase backup folder"
}

# TODO transform terraform fn into case branch in main.sh
terraform() {
    # Assume there is no env yet! Just basic vars (without file's dependent values)
    # $1 :: set the target env

    # FIXME - ?: (staticfiles.W004) The directory '/opt/adc/backend/worktree/local/api/setup/static' in the STATICFILES_DIRS setting does not exist.

    # Tasks to deploy - perform more tasks like migrate and run test, the output of these commands will be shown on the push screen
    # * filesystem /mnt/storage_sistemas
    # ** se certificar que as pastas /mnt/storage_sistemas/alerta-defesa-civil-<ENV>/media/pedido_ajuda e /mnt/storage_sistemas/alerta-defesa-civil-<ENV>/media/photo_guia_atendimento/ existem!
    # * /etc/hosts

    echo "Terraforming for env $1"
    echo "======================="
    set_vars $1 "" ""

    terraform_app_path_etc

    set_vars_by_env

    terraform_app_path_opt

    set_symbolic_link

    # # TODO move it for deploy() fn and TEST IT
    # terraform_app_path_mnt

    # TODO move to a proper function
    terraform_app_path_var_www_app
    # terraform_app_path_var_www_proxy

    # echo ""
    # echo "|---------------------------|"
    # echo "| Creating APP_PATH_VAR_LOG |"
    # echo "|---------------------------|"
    # echo "$APP_PATH_VAR_LOG"
    # echo "TODO implement log file for app"
}

deploy_app_path_opt() {
    echo ""
    echo "|------------------------|"
    echo "| Deploying APP_PATH_OPT |"
    echo "|------------------------|"
    echo "$APP_PATH_OPT"

    rm -rf $APP_PATH_WORKTREE/$GIT_BRANCH
    mkdir $APP_PATH_WORKTREE/$GIT_BRANCH
    git --work-tree=$APP_PATH_WORKTREE/$GIT_BRANCH --git-dir=$APP_PATH_BARE checkout -f $GIT_BRANCH
    echo "${NOW}" > $APP_PATH_WORKTREE/$GIT_BRANCH/deployment_datetime.txt
    # FIXME maybe can be an error with master != prod for symlink
    rm -f $APP_PATH_DOCUMENT_ROOT
    ln -s $APP_PATH_WORKTREE/$GIT_BRANCH $APP_PATH_DOCUMENT_ROOT
    set_symbolic_link

}

deploy_venv() {
    for python_project in ${PYTHON_PROJECTS_AVAILABLE[@]};
    do
        echo ""
        echo "----------------------------------------------"
        echo "----- Install libs for ${python_project} -----"
        echo "----------------------------------------------"
        rm -rf $APP_PATH_DOCUMENT_ROOT/$python_project/venv
        python3 -m venv $APP_PATH_DOCUMENT_ROOT/$python_project/venv
        source $APP_PATH_DOCUMENT_ROOT/$python_project/venv/bin/activate
        pip install -r $APP_PATH_DOCUMENT_ROOT/$python_project/requirements.txt
        deactivate
    done
}

deploy_collectstatic() {
    for django_project in ${DJANGO_PROJECTS_AVAILABLE[@]};
    do
        echo ""
        echo "----------------------------------------------"
        echo "----- Install libs for ${django_project} -----"
        echo "----------------------------------------------"
        source $APP_PATH_DOCUMENT_ROOT/$django_project/venv/bin/activate
        python3 $APP_PATH_DOCUMENT_ROOT/$django_project/manage.py collectstatic -c --no-input
        deactivate
    done
}

deploy() {
    # Assume that set_vars was setted

    if [ "$GIT_BRANCH" == "edge" ] || [ "$GIT_BRANCH" == "upstream" ];
    then
        echo "CAN'T deploy on EDGE or UPSTREAM (do not deploy a remote worktree - only from bare.git) - stoping..."
        return 1
    fi

    echo "Deploying for env $TARGET_ENV branch $GIT_BRANCH"
    echo "================================================"
    
    deploy_app_path_opt

    deploy_venv
    deploy_collectstatic

    # TODO
    # - build env files
    # - run unittest/pytests
    # - migration

    # cd $APP_PATH_WORKTREE/$GIT_BRANCH # FIXME need it!?
    # if [ "$TARGET_ENV" == "prod" ];
    # then
    #     echo "Stop! You are in $TARGET_ENV . Beware with prod before run again"
    # else
    #     echo ""
    #     echo "------------------------------------------------"
    #     echo "----- Run migrations for env ${TARGET_ENV} -----"
    #     echo "------------------------------------------------"
    #     source $APP_PATH_DOCUMENT_ROOT/backoffice/venv/bin/activate
    #     make db-start
    #     deactivate
    # fi
    # cd -

    # echo ""
    # echo "|------------------------|"
    # echo "| Deploying APP_PATH_MNT |"
    # echo "|------------------------|"
    # echo "$APP_PATH_MNT"
    # echo "FIXME using a simple version. Move it to use a function app_path_mnt 'cause in terraform and deploy all tasks is the same"
    # echo "TODO setar $APP_PATH_MNT para o $GIT_BRANCH que será trabalhado"
    # # umount -q $APP_PATH_MNT*
    # # rm -f $APP_PATH_MNT
    # # if [ "$TARGET_ENV" != "local" ];
    # # then
    # #     mount /mnt/storage_sistemas/"$FORGE_SYSTEM_BASE_DNS"-"$TARGET_ENV"
    # # fi
    # # ln -s /mnt/storage_sistemas/"$FORGE_SYSTEM_BASE_DNS"-"$TARGET_ENV" $APP_PATH_MNT

    # echo ""
    # echo "|-----------------------------|"
    # echo "| Deploying APP_PATH_VAR_WWW  |"
    # echo "|-----------------------------|"
    # echo "$APP_PATH_VAR_WWW"
    # echo "TODO must implement something from terraform here?!"
    # # # FIXME will use filesystem path with -$TARGET_ENV?!
    # # # sudo ln -s $APP_PATH_WORKTREE/$TARGET_ENV/webserver/apache/app_server/alerta-defesa-civil.sorocaba.sp.gov.br.conf /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS-$TARGET_ENV.sorocaba.sp.gov.br.conf
    # # # sudo ln -s $APP_PATH_WORKTREE/$TARGET_ENV/webserver/apache/app_server/alerta-defesa-civil-api.sorocaba.sp.gov.br.conf /etc/apache2/sites-available/$FORGE_SYSTEM_BASE_DNS-$TARGET_ENV-api.sorocaba.sp.gov.br.conf

    # # if grep -q "^export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=" /etc/apache2/envvars; then
    # #     sudo sed -i.bkp "s/^export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=.*/export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=\"-$TARGET_ENV\"/" /etc/apache2/envvars
    # # else
    # #     echo "export ${FORGE_SYSTEM_ACRONYM^^}_ENV_APP=\"-$TARGET_ENV\"" | sudo tee -a /etc/apache2/envvars > /dev/null
    # # fi
    # # TODO configtest result in error should stop deploy
    # # TODO get the return of apachectl configtest
    # sudo apachectl configtest
    # sudo service apache2 restart
}

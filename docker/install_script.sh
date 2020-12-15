#!/bin/bash

# Dumping autoload using --optimize-autoloader to keep performenace on a usable level, not needed on linux host.
# Second chown line:  For dev and behat tests we give a bit extra rights, never do this for prod.

s=0
for i in $(seq 1 3); do
    composer install --no-progress --no-interaction --prefer-dist --optimize-autoloader --no-scripts
    yes | composer recipes:install --force

    s=$?
    if [ "$s" != "0" ]; then
        sleep 1
    fi
    break
done


if [ "$s" != "0" ]; then
    echo "ERROR : composer install failed, exit code : $s"
    exit $s
fi

if [ "${INSTALL_DATABASE}" == "1" ]; then 
    export DATABASE_URL=${DATABASE_PLATFORM}://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}?serverVersion=${DATABASE_VERSION}

    php /scripts/wait_for_db.php
    composer ezplatform-install
    if [ "$APP_CMD" != '' ]; then
        echo '> Executing' "$APP_CMD"
        php bin/console $APP_CMD
    fi
    echo 'Dumping database into doc/docker/entrypoint/mysql/2_dump.sql for use by mysql on startup.'
    mysqldump -u $DATABASE_USER --password=$DATABASE_PASSWORD -h $DATABASE_HOST --add-drop-table --extended-insert  --protocol=tcp $DATABASE_NAME > doc/docker/entrypoint/mysql/2_dump.sql
fi

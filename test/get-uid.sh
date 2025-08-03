#!/usr/bin/env bash

docker compose exec -it db sh -c "mysql -u bitwarden -psuper_strong_password bitwarden_vault -e 'Select Id from User \G;'"

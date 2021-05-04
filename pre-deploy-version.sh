#!/usr/bin/env bash
set -ex

if [ -z "$1" ]
	then
		echo "Use: $0 versionlabel"
		exit 1
	else
		VERSION="$1"
fi

CURRENT_ENV=${PWD##*/}
if [ "${CURRENT_ENV}" != "pre" ]
	then
		echo "This script can only run in pre environment"
		exit 2
fi


# Set environment variables
source setenv.sh

# Move to the selected version
# git tag -d ${VERSION} || :
git fetch --all
git merge origin/dev
git reset --hard ${VERSION}
git push -f 
git push -f --tags

# Update schema based in Liquibase controller
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp >pre-deploy-version.log <<-EOF
set echo on
cd database/liquibase
lb update -changelog controller.xml -log
update DATABASECHANGELOG SET TAG='${VERSION}' WHERE TAG IS NULL;
QUIT
EOF




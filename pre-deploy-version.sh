#!/usr/bin/env bash
set -e

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
git merge origin/dev
git reset --hard ${VERSION}

# Update schema based in Liquibase controller
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp >pre-deploy-version.log <<-EOF
SET ECHO ON
lb update -label ${VERSION} -log
QUIT
EOF




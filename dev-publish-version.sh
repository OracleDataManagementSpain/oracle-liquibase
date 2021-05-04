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
if [ "${CURRENT_ENV}" != "dev" ]
	then
		echo "This script can only run in dev environment"
		exit 2
fi


# Set environment variables
source setenv.sh

# Generate Liquibase controller and schema
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp<<-EOF
SET ECHO ON
CD database/liquibase
LB gencontrolfile
LB genschema -label ${VERSION}
quit
EOF

# Commit and tag version
# TODO: Remove add all
git add -A
# Add newly added liquibase
git add -A database/liquibase
git commit -m "Deploy version ${VERSION}"
git tag -f $VERSION
git push
git push -f --tags


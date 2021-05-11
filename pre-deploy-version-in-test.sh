#!/usr/bin/env bash
set -ex

# Set environment variables
source setenv.sh

# Check parameters
if [ -z "$1" ]
	then
		echo "Use: $0 versionlabel"
		exit 1
	else
		VERSION="$1"
		VERSION=${VERSION^^}
fi

CURRENT_ENV=${PWD##*/}
if [ "${CURRENT_ENV}" != "pre" ]
	then
		echo "This script can only run in pre environment"
		exit 2
fi

# Temp file
TEMPFILE=$(mktemp)

# Start
echo "==============================================" 
echo "Deploy version in test on $(date)"  

# Get last edition
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp >>pre-rollback-version.log <<-EOF
SET PAGES 0
SET FEEDBACK OFF
SET TERM OFF
SET TIMING OFF
SET PAUSE OFF
SET TRIMSPOOL ON
SET HEAD OFF
SET FEED OFF
SET ECHO OFF
SPOOL $TEMPFILE
SELECT LastEdition() FROM DUAL;
SPOOL OFF
QUIT
EOF

LAST_EDITION=$(cat $TEMPFILE && rm $TEMPFILE)
NEW_EDITION="EDITION_${VERSION}"

echo "The version will be deployed in edition ${NEW_EDITION} AS CHILD OF ${LAST_EDITION}"

# Move GIT repository to the selected version
git fetch --all
git merge origin/dev
git reset --hard ${VERSION}
git push -f 
git push -f --tags

# Create EDITION
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp  <<-EOF
SET ECHO ON
CREATE EDITION $NEW_EDITION AS CHILD OF $LAST_EDITION;
QUIT
EOF


# Update schema based in Liquibase controller
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp  <<-EOF
SET ECHO ON
CD database/liquibase
ALTER SESSION SET EDITION = $NEW_EDITION;
LB UPDATE -changelog controller.xml -log
UPDATE DATABASECHANGELOG SET TAG='${VERSION}' WHERE TAG IS NULL;
QUIT
EOF




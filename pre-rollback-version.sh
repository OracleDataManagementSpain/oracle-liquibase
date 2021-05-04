#!/usr/bin/env bash
set -ex

CURRENT_ENV=${PWD##*/}
if [ "${CURRENT_ENV}" != "pre" ]
	then
		echo "This script can only run in pre environment"
		exit 2
fi


# Temp file
TEMPFILE=$(mktemp)
echo "==============================================" >>pre-rollback-version.log
echo "Rolling back version on $(date)" >>pre-rollback-version.log

# Get last tag
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
SELECT MIN(TAG) FROM DATABASECHANGELOG WHERE ORDEREXECUTED=(SELECT MAX(ORDEREXECUTED) FROM DATABASECHANGELOG);
SPOOL OFF
QUIT
EOF

LASTTAG=$(cat $TEMPFILE && rm $TEMPFILE)

# Get last tag count
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
SELECT COUNT(*) FROM DATABASECHANGELOG WHERE TAG='${LASTTAG}';
SPOOL OFF
QUIT
EOF

COUNTLASTTAG=$(cat $TEMPFILE && rm $TEMPFILE)


# Rolling back schema based in Liquibase controller
echo "Rolling back $COUNTLASTTAG update from version $LASTTAG" >>pre-rollback-version.log
sql ${DB_USER}/${DB_PASSWORD}@lbtest_tp >>pre-rollback-version.log <<-EOF
set echo on
cd database/liquibase
lb rollback -changelog controller.xml -log -count $COUNTLASTTAG
QUIT
EOF


# Return to previous version the source code
##  Get last tag -> Now is the last available version
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
SELECT MIN(TAG) FROM DATABASECHANGELOG WHERE ORDEREXECUTED=(SELECT MAX(ORDEREXECUTED) FROM DATABASECHANGELOG);
SPOOL OFF
QUIT
EOF

VERSION=$(cat $TEMPFILE && rm $TEMPFILE)

git reset --hard ${VERSION}
git push -f 
git push -f --tags



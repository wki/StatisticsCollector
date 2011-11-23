#!/bin/bash
appdir=`dirname $0`/..

ssh myloc '/usr/bin/pg_dump -U postgres statistics' \
    > $appdir/dump/statistics_`date '+%Y-%m-%d_%H%M'`.sql

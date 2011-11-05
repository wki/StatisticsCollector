#!/bin/bash
appdir=`dirname $0`/..
dstdir=/var/www/StatisticsCollector
cd $appdir

set -x
rsync -vcr  --delete \
  --exclude blib --exclude inc --exclude '.git*' \
  --exclude 'META.*' --exclude 'MYMETA.*' \
  --exclude Makefile \
  --exclude script/dbicdh \
  --exclude Changes --exclude 'README.*' --exclude 'INFO.*' \
  . root@myloc:$dstdir/ $*

ssh root@myloc chown -R www-data:www-data $dstdir

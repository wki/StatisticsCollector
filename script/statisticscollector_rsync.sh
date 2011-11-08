#!/bin/bash
appdir=`dirname $0`/..
dstdir=/home/sites/StatisticsCollector
cd $appdir

rsync -vcr  --delete \
  --exclude perl5lib \
  --exclude blib --exclude inc --exclude '.git*' \
  --exclude 'META.*' --exclude 'MYMETA.*' \
  --exclude Makefile \
  --exclude script/dbicdh \
  --exclude Changes --exclude 'README.*' --exclude 'INFO.*' \
  . sites@myloc:$dstdir/ $*

# ssh root@myloc chown -R www-data:www-data $dstdir

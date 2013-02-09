#!/bin/bash
appdir=`dirname $0`/..
dstdir=/home/sites/StatisticsCollector
cd $appdir

# regenerate static css/js files for faster access
mkdir -p root/_static/css root/_static/js
easy test /css/site.css > root/_static/css/site.css
easy test /js/site.js   > root/_static/js/site.js

# transfer files to server
rsync -vcr  --delete \
  --exclude /perl5lib \
  --exclude /blib --exclude /inc --exclude '/.git*' \
  --exclude '/META.*' --exclude '/MYMETA.*' --exclude .DS_Store \
  --exclude /Makefile \
  --exclude /script/dbicdh \
  --exclude /dump \
  --exclude /run \
  --exclude /Changes --exclude '/README.*' --exclude '/INFO.*' \
  . sites@myloc:$dstdir/ $*


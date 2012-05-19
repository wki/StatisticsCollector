#!/bin/bash
#
# deploy everything to a virtual box
#
appdir=`dirname $0`/..
cd $appdir

# nginx config files
process_template -c $appdir/config/server -t nginx.tpl \
    | ssh root@box 'cat > /etc/init.dstatisticscollector_starman'
ssh root@box 'ln -sf /etc/nginx/sites-available/statisticscollector /etc/nginx/sites-enabled/statisticscollector'

# init.d for starman
process_template -c $appdir/config/server -t init.d_starman.tpl \
    | ssh root@box 'cat > /etc/init.d/statisticscollector_starman'
ssh root@box 'chmod a+x /etc/init.d/statisticscollector_starman'
ssh root@box 'update-rc.d -n statisticscollector_starman defaults 90'

# DB Deployment, migration, etc.

# create static files
mkdir -p root/_static/css root/_static/js
easy test /css/site.css > root/_static/css/site.css
easy test /js/site.js   > root/_static/js/site.js

# transfer files to server
ssh box 'mkdir StatisticsCollector'

rsync -vcr  --delete \
  --exclude perl5lib --exclude local \
  --exclude blib --exclude inc --exclude '.git*' \
  --exclude 'META.*' --exclude 'MYMETA.*' --exclude .DS_Store \
  --exclude Makefile \
  --exclude script/dbicdh \
  --exclude dump \
  --exclude Changes --exclude 'README.*' --exclude 'INFO.*' \
  . box:StatisticsCollector/ $*

# rsync

# restart server

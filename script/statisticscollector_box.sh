#!/bin/bash
appdir=`dirname $0`/..
dstdir=/web/data/statistics.kinkeldei-net.de/StatisticsCollector
cd $appdir

# regenerate static css/js files for faster access
mkdir -p root/_static/css root/_static/js
easy test /css/site.css > root/_static/css/site.css
easy test /js/site.js   > root/_static/js/site.js

# transfer files to server
rsync -vcr  --delete \
  --exclude perl5lib --exclude local --exclude .carton \
  --exclude blib --exclude inc --exclude '.git*' \
  --exclude 'META.*' --exclude 'MYMETA.*' --exclude .DS_Store \
  --exclude Makefile \
  --exclude script/dbicdh --exclude script/cpanm \
  --exclude dump \
  --exclude Changes --exclude 'README.*' --exclude 'INFO.*' \
  . vagrant@box:$dstdir/ $*

### following things must execute on the box. Put into a shell script

# initially we need cpanm and Carton
# wget http://cpanmin.us -O script/cpanm
# chmod a+x script/cpanm
# mkdir -p local
# script/cpanm -L local Carton
# -- can we rm script/cpanm ??? we have it also at local/bin/cpanm now.

# install all missing modules
# PATH=local/bin:$PATH PERL5LIB=local/lib/perl5 local/bin/carton install

# find a way to handle all needed daemons by either:
#   - remove old daemons
#   - copy scripts
#   - start daemons
#
# OR:
#   - install scripts if not available
#   - start or restart daemons

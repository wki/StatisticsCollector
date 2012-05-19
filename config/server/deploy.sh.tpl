#!/bin/bash
#
# deploy everything to a virtual box
# assume we are in application directory
#

# nginx config files
process_template -c config/server -t nginx.tpl \
    | ssh root@[% ssh_hostname %] 'cat > /etc/nginx/sites-available/[% name %]'
ssh root@[% ssh_hostname %] 'ln -sf /etc/nginx/sites-available/[% name %] /etc/nginx/sites-enabled/[% name %]'

# init.d for starman
process_template -c $appdir/config/server -t init.d_starman.tpl \
    | ssh root@[% ssh_hostname %] 'cat > /etc/init.d/[% init_d_name %]'
ssh root@[% ssh_hostname %] 'chmod a+x /etc/init.d/[% init_d_name %]'
ssh root@[% ssh_hostname %] 'update-rc.d -n [% init_d_name %] defaults 90'

# install binary packages if not available

# DB Deployment, migration, etc.

# create static files
mkdir -p root/_static/css root/_static/js
easy test /css/site.css > root/_static/css/site.css
easy test /js/site.js   > root/_static/js/site.js

# transfer files to server
ssh [% user %]@[% ssh_hostname %] 'mkdir -p [% install_dir %]'
ssh [% user %]@[% ssh_hostname %] 'mkdir -p [% cpanm_local %]'

rsync -vcr  --delete \
  --exclude perl5lib --exclude local \
  --exclude blib --exclude inc --exclude '.git*' \
  --exclude 'META.*' --exclude 'MYMETA.*' --exclude .DS_Store \
  --exclude Makefile \
  --exclude script/dbicdh \
  --exclude dump \
  --exclude Changes --exclude 'README.*' --exclude 'INFO.*' \
  . [% user %]@[% ssh_hostname %]:[% install_dir %]/ -n $*

# install perlbrew if not available
ssh [% user %]@[% ssh_hostname %] '[ -f [% perlbrew %] ] || (curl -kL http://install.perlbrew.pl | bash)'

# extract modules and order of installation from perllocal
# cat local/lib/perl5/darwin-2level/perllocal.pod |
#   egrep -e 's{^(?:=head2.*?L<.*?(\|)|C<VERSION:)(.*?)>.*}{$1$2}xms' |
#   tr "| " "\n~"

# install perl if not yet there
ssh [% user %]@[% ssh_hostname %] '[% perlbrew %] list | grep [% perl_version %] >/dev/null || [% perlbrew %] install perl-[% perl_version %]'
ssh [% user %]@[% ssh_hostname %] '[ -f [% cpanm %] ] || [% perlbrew %] install-cpanm'
ssh [% user %]@[% ssh_hostname %] '[% perl %] [% cpanm %] -L[% cpanm_local %] Carton'
ssh [% user %]@[% ssh_hostname %] 'PATH="[% cpanm_local %]/bin:$PATH" PERL5LIB=[% cpanm_local %]/lib/perl5 [% cpanm_local %]/bin/carton install'

# restart server

#!/usr/bin/env perl
use Provision::DSL;

# test with:
# PERL5LIB=/Users/wolfgang/proj/Provision-DSL/lib /Users/wolfgang/proj/Provision-DSL/bin/provision.pl -c config/deploy_live.pl -n -v
#
# when Provision::DSL is installed:
# provision.pl -c config/deploy_live.pl -n -v

my $APP_NAME        = 'StatiscticsCollector';
my $DOMAIN          = 'statistics.kinkeldei-net.de',
my $STATIC          = 'root/static';
my $SCRIPT          = 'script';
my $CONFIG          = 'config';

my $WEB_DIR         = '/web/data';
my $SITE_DIR        = "$WEB_DIR/$DOMAIN";
my $APP_DIR         = "$SITE_DIR/app";
my $STATIC_DIR      = "$APP_DIR/$STATIC";
my $SCRIPT_DIR      = "$APP_DIR/$SCRIPT";

my $CONFIG_DIR      = "$APP_DIR/$CONFIG";
my $MAIN_CONFIG     = "$CONFIG_DIR/\L$APP_NAME\E.pl";
my $CONFIG_SUFFIX   = 'live';

my $PERL_LIB        = 'local';
my $PERL5LIB_DIR    = "$APP_DIR/$PERL_LIB/lib/perl5";

my $EXT_PORT        = 81;
my $INT_PORT        = 5000;

Defaults {
    Dir  => { user => 'vagrant' },
    File => { user => 'vagrant' },
};

Package 'build-essential';
Package 'nginx';
Package 'postgresql-9.1';
Package 'postgresql-client-9.1';
Package 'postgresql-server-dev-9.1';

Perlbrew {
    wanted        => '5.16.0',
    install_cpanm => 1,
    ### FIXME: what happens if we change perl version.
    ### TODO: we must delete local-lib directory
};

Dir $WEB_DIR => {
    user       => 'root',
    permission => '0755',
};

Dir $SITE_DIR => {
    user  => 'vagrant',
    mkdir => ['logs', 'pid'],
};

Dir $APP_DIR => {
    content => Resource('app'),
    mkdir   => [
        $PERL_LIB,
        "root/cache",
        "root/files",
        "$STATIC/_css",
        "$STATIC/_js",
    ],
};

#### Idea:
# Perl_Modules '/path/to/local' => {
#     installdeps => '/path/to/app',
# };

### FIXME: what can we do to ensure all modules are there?
Execute install_cpan_modules => {
    default_state => 'outdated',     ### FIXME: need condition
    path   => Perlbrew->perl,
    cwd    => $APP_DIR,
    args   => [
        Perlbrew->cpanm,
        '-n', # for faster operation: no tests.
        '-L'            => "$APP_DIR/$PERL_LIB",
        '--installdeps' => $APP_DIR,
        '--mirror',     => 'http://10.0.2.2:8080', 
        '--mirror-only',
    ],
};

foreach my $cache_entry (qw(css/site.css js/site.js)) {
    Execute "cache_$cache_entry" => {
        path => Perlbrew->perl,
        args => [
            "$SCRIPT_DIR/\L$APP_NAME\E_test.pl",
            "/$cache_entry",
        ],
        env => {
            PERL5LIBS                           => $PERL5LIB_DIR,
            "\U$APP_NAME\E_CONFIG"              => $CONFIG_DIR,
            "\U$APP_NAME\E_CONFIG_LOCAL_SUFFIX" => $CONFIG_SUFFIX,
        },
    };
    
    File "$STATIC_DIR/_$cache_entry" => {
        ### FIXME: need condition (mtime static/css/* > this)
        # Idea:
        # when => FileNewer(<$STATIC_DIR/css/*.css>),
        content => Execute("cache_$cache_entry"),
    };
}

# TODO!
# Execute db_migration => {
#     path => '/path/to/website/MyApp/script/db_migration.pl',
# };

Service "\L$APP_NAME\E_plack" => {
    ### FIXME: need restart condition
    content => Template('service/starman', {
                vars => {
                    name     => "\L$APP_NAME\E_starman",
                    app_dir  => $APP_DIR,
                    starman  => Perlbrew->bin('starman'),
                    port     => $INT_PORT,
                    pid      => "$SITE_DIR/pid/\L$APP_NAME\E.pid",
                    psgi     => "$APP_DIR/\L$APP_NAME\E.psgi",
                    user     => 'vagrant',
                    group    => 'vagrant',
                },
            }),
};

File "/etc/nginx/sites-enabled/\L$APP_NAME\E" => {
    content    => Template('service/nginx_site', {
                    vars => {
                        name     => "\L$APP_NAME\E",
                        ext_port => $EXT_PORT,
                        int_port => $INT_PORT,
                        domain   => $DOMAIN,
                        app_dir  => $APP_DIR,
                    },
                }),
    user       => 'root',
    permission => '0777',
};

Service nginx => {
    ### FIXME: need restart condition
};

Done;

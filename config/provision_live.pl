#!/usr/bin/env perl
use Provision::DSL;

# test with:
# PERL5LIB=/Users/wolfgang/proj/Provision-DSL/lib /Users/wolfgang/proj/Provision-DSL/bin/provision.pl -c config/deploy_live.pl -n -v

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
my $MAIN_CONFIG     = "$CONFIG_DIR/\L$APP_NAME/Q.pl";
my $CONFIG_SUFFIX   = 'live';

my $PERL_LIB        = 'local';
my $PERL5LIB_DIR    = "$APP_DIR/$PERL_LIB/lib/perl5";

Package 'build-essential';
Package 'nginx';
Package 'postgresql-9.1';
Package 'postgresql-client-9.1';
Package 'postgresql-server-dev-9.1';

Perlbrew {
    install_cpanm => 1,
    # wanted  => '5.14.2',
    wanted  => '5.16.0',
};

Dir $WEB_DIR => {
    user => 'root',
    permission => '0755',
};

Dir $SITE_DIR => {
    mkdir   => [
        'logs', 
        'pid',
    ],
    tell   => 'source_changed',
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
    tell   => 'source_changed',
};

### FIXME: what can we do to ensure all modules are there?
Execute install_cpan_modules => {
    default_state => 'outdated',     ### bad fake.
    listen => 'source_changed',
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
            "$SCRIPT_DIR/\L$APP_NAME\Q_test.pl",
            "/$cache_entry",
        ],
        env => {
            PERL5LIBS                           => $PERL5LIB_DIR,
            "\U$APP_NAME\Q_CONFIG"              => $CONFIG_DIR,
            "\U$APP_NAME\Q_CONFIG_LOCAL_SUFFIX" => $CONFIG_SUFFIX,
        },
    };
    
    File "$STATIC_DIR/_$cache_entry" => {
        listen  => 'source_changed',
        content => Execute("cache_$cache_entry"),
    };
}

# TODO!
# Execute db_migration => {
#     path => '/path/to/website/MyApp/script/db_migration.pl',
# };

Service "\L$APP_NAME\Q_plack" => {
    listen  => 'source_changed',
    content => Resource('service/plack'),
};

File "/etc/nginx/sites-enabled/\L$APP_NAME\Q" => {
    content    => Resource('service/nginx_site'),
    user       => 'root',
    permission => '0777',
    tell       => 'nginx_config_changed',
};

Service nginx => {
    listen => 'nginx_config_changed',
};

Done;

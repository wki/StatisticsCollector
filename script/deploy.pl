#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';
use aliased 'DBIx::Class::DeploymentHandler' => 'DH';
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::Schema;

my $schema = StatisticsCollector::Schema->connect(
    'dbi:Pg:dbname=stat;host=127.0.0.1',
    'postgres', ''
);

my $dh = DH->new({
     schema              => $schema,
     script_directory    => "$FindBin::Bin/dbicdh",
     databases           => 'PostgreSQL',
     sql_translator_args => { add_drop_table => 0 },
     # force_overwrite     => 1
});


say 'INFO: version storage installed' if $dh->version_storage_is_installed;
say 'INFO: DB-Version: ', $dh->database_version if $dh->version_storage_is_installed;


if (!$dh->version_storage_is_installed) {
    say 'version not in storage, install DB';
    $dh->prepare_install;
    $dh->install;
} elsif ($StatisticsCollector::Schema::VERSION == $dh->database_version) {
    say 'DB Version is current. Nothing to do.';
} elsif ($StatisticsCollector::Schema::VERSION > $dh->database_version) {
    say 'DB Version older than current. Upgrading.';
    $dh->prepare_deploy;
    $dh->prepare_upgrade(
        { 
            from_version => $StatisticsCollector::Schema::VERSION - 1,
            to_version   => $StatisticsCollector::Schema::VERSION
        });
    $dh->upgrade;
} else {
    say 'DB Version newer than current. Downgrading.';
    die 'still TODO';
}

#!/usr/bin/env perl
use strict;
use warnings;
use aliased 'DBIx::Class::DeploymentHandler' => 'DH';
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::Schema;

my $schema = StatisticsCollector::Schema->connect(
    'dbi:Pg:dbname=statistics;host=127.0.0.1',
    'postgres', ''
);

my $dh = DH->new({
     schema              => $schema,
     script_directory    => "$FindBin::Bin/dbicdh",
     databases           => 'PostgreSQL',
     sql_translator_args => { add_drop_table => 0 },
     force_overwrite     => 1
});

if ($StatisticsCollector::Schema::VERSION == 1) {
    $dh->prepare_install;
    $dh->install;
} else {
    $dh->prepare_upgrade(
        { 
            from_version => $StatisticsCollector::Schema::VERSION - 1,
            to_version   => $StatisticsCollector::Schema::VERSION
        });
    $dh->upgrade;
}

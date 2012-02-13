#!/usr/bin/env perl
use Modern::Perl;
use Parallel::Scoreboard;
use FindBin;
use YAML;

my $base_dir = "$FindBin::Bin/../run";
die "base dir ($base_dir) does not exist"
    if !-d $base_dir;

my $status = Parallel::Scoreboard
    ->new(base_dir => $base_dir)
    ->read_all;

say Dump $status;


#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector;
use DBIx::Class::Migration::Script;

DBIx::Class::Migration::Script->run_with_options(
    schema => StatisticsCollector->model('DB')->schema,
);

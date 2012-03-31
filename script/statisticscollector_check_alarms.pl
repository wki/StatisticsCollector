#!/usr/bin/env perl
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::App::CheckAlarms;

StatisticsCollector::App::CheckAlarms->new_with_options->run();

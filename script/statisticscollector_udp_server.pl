#!/usr/bin/env perl
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::App::UdpServer;

StatisticsCollector::App::UdpServer->new_with_options->run();

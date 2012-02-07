#!/usr/bin/env perl
use strict;
use warnings;
use Plack::Builder;
use StatisticsCollector;
use FindBin;

my $app = StatisticsCollector
        ->apply_default_middlewares(StatisticsCollector->psgi_app);

sub is_development {
    $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development'
}

builder {    
    if (!is_development) {
        enable "Plack::Middleware::Static",
               path => qr{\A/(css|js)/}xms, root => "$FindBin::Bin/root/_static/";
    }
    enable 'Runtime';
    enable 'ServerStatus::Lite',
        path => '/server-status',
        allow => [ '127.0.0.1' ],
        scoreboard => "$FindBin::Bin/run";
    $app;
};

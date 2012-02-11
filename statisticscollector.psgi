#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Plack::Builder;
use StatisticsCollector;

#
# some helpers. All called with $env
#
sub is_development {
    $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development'
}

sub is_proxy_request {
    exists $_[0]->{HTTP_X_FORWARDED_FOR}
}

#
# our app decorated with middleware
#
builder {
    enable_if { !is_development($_[0]) } 'Plack::Middleware::Static',
        path => qr{\A/(css|js)/}xms,
        root => "$FindBin::Bin/root/_static/";

    enable 'Runtime';

    # WRONG: enable_if restricts from saving things!
    # enable_if { !is_proxy_request($_[0]) } 'ServerStatus::Lite',
    # must find a way to fail on /server-status if proxy request
    enable 'ServerStatus::Lite',
        path       => '/server-status',
        allow      => [ '127.0.0.1' ],
        scoreboard => "$FindBin::Bin/run";

    StatisticsCollector->apply_default_middlewares(
        StatisticsCollector->psgi_app
    );
};


__END__
ways to start as server (in real life use absolute paths!):

- Server::Starter and Starman:
  start_server --port 8080 -- starman --workers 5 statisticscollector.psgi

- Server::Starter and Twiggy (only 1 worker process)
  start_server --port 8080 -- twiggy statisticscollector.psgi


Use Apache as a reverse Proxy:

    RewriteEngine On
    ProxyPass / http://localhost:8080/ disablereuse=On
    ProxyPassReverse / http://localhost:8080/

using another URL than / confuses the base URL of catalyst.
--> see Catalyst::TraitFor::Request::ProxyBase


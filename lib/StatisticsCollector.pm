package StatisticsCollector;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90;

use Catalyst qw/
    Static::Simple
    ConfigLoader
/;

extends 'Catalyst';

our $VERSION = '0.03';

__PACKAGE__->setup();

1;

=head1 NAME

StatisticsCollector - Catalyst based application

=head1 SYNOPSIS

    script/statisticscollector_server.pl

=head1 DESCRIPTION

StatisticsCollector is a Catalyst Application that is like a marriage
of Nagios with collectd. Best of both worlds :-)

=head1 SEE ALSO

L<StatisticsCollector::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

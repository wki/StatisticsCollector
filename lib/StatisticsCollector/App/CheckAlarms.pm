package StatisticsCollector::App::CheckAlarms;

use Moose;
use IO::Socket::INET;
use Try::Tiny;
use StatisticsCollector::Schema;

extends 'StatisticsCollector::App';

=head1 NAME

StatisticsCollector::App::CheckAlarms - Check if sensor alarms are changing

=head1 SYNOPSIS

    StatisticsCollector::App::CheckAlarms->new_with_options->run();

=head1 DESCRIPTION

This is the class behind a shell-executable script to check alarms

=head1 ATTRIBUTES

=cut

=head2 to be defined...

=cut

has whatever => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Int',
    default => 8080,
    lazy => 1,
    cmd_aliases => ['w'],
    documentation => 'XXX-fill me',
);

=head1 METHODS

=cut

=head2 run

called from L<StatisticsCollector::App> in order to run the script

=cut

sub run {
    my $self = shift;
    
    ...
    
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

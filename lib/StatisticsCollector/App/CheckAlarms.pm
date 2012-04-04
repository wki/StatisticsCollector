package StatisticsCollector::App::CheckAlarms;
use Moose;
use IO::Socket::INET;
use Try::Tiny;

extends 'StatisticsCollector::App';
with 'StatisticsCollector::Role::Schema';

=head1 NAME

StatisticsCollector::App::CheckAlarms - Check if sensor alarms are changing

=head1 SYNOPSIS

    StatisticsCollector::App::CheckAlarms->new_with_options->run();

=head1 DESCRIPTION

This is the class behind a shell-executable script to check alarms

=head1 METHODS

=cut

=head2 run

called from L<StatisticsCollector::App> in order to run the script

=cut

sub run {
    my $self = shift;

    my $alarms_to_notify =
        $self->resultset('Alarm')
             ->check_and_update
             ->need_notification;

    while (my $alarm = $alarms_to_notify->next) {
        ### TODO: process.
    }
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

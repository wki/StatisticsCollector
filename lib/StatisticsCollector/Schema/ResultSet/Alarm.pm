package StatisticsCollector::Schema::ResultSet::Alarm;

use Modern::Perl;
use base 'DBIx::Class::ResultSet';
use DateTime;

=head1 NAME

StatisticsCollector::Schema::ResultSet::Alarm

=head1 SYNOPSIS

    $schema->resultset('Alarm')->check_and_update;

=head1 DESCRIPTION

a collection of methods around alarms

=head1 METHODS

=cut

=head2 check_and_update

does two things: check if a sensor runs into a condition that must trigger
an alarm and check if an open alarm is still in a bad condition.

=cut

sub check_and_update {
    my $self = shift;
    
    # get current and saved alarms
    my @alarming_sensors      = $self->_get_alarming_sensors;
    my @open_alarms           = $self->_get_open_alarms;
    
    my @alarming_sensor_ids   = map { $_->sensor_id } @alarming_sensors;
    my @open_alarm_sensor_ids = map { $_->sensor_id } @open_alarms;
    
    # get differences
    my %alarming_but_not_open = map { ($_->sensor_id => $_) } @alarming_sensors;
    delete $alarming_but_not_open{$_} for @open_alarm_sensor_ids;

    my %to_close = map { ($_->sensor_id => $_) } @open_alarms;
    delete $to_close{$_} for @alarming_sensor_ids;

    # update DB
    $self->result_source->resultset
         ->search( { alarm_id => { -in => [ keys %to_close ] } } )
         ->update( { ending_at => DateTime->now } );
    
    $self->create({
             alarm_condition_id => $_->get_column('alarm_condition_id'),
             sensor_id          => $_->sensor_id,
         })
        for values %alarming_but_not_open;
    
    return $self;
}

sub _get_alarming_sensors {
    my $self = shift;
    
    return
        $self->result_source->schema->resultset('Sensor')
             ->search(
                 {
                     -bool => 'me.active',
                     -or => [
                        -bool => 'latest_measure.measure_age_alarm',
                        -bool => 'latest_measure.latest_value_gt_alarm',
                        -bool => 'latest_measure.latest_value_lt_alarm',
                        -bool => 'latest_measure.min_value_gt_alarm',
                        -bool => 'latest_measure.max_value_lt_alarm',
                     ],
                 },
                 {
                     join      => 'latest_measure',
                     '+select' => [ qw(latest_measure.alarm_condition_id) ],
                     '+as'     => [ 'alarm_condition_id' ],
                 })
             ->all;
}

sub _get_open_alarms {
    my $self = shift;
    
    return
        $self->search(
                {
                    ending_at => undef,
                    -bool => 'sensor.active',
                },
                {
                    join => 'sensor',
                })
             ->all;
}

=head2 need_notification

Search for alarms that need notification. Alarms need a notification if

=over

=item

just activated and not yet notified ==> urgent

=item

just cancelled and not yet notified ==> urgent

=item

still active                        ==> not urgent

=back

Urgent messages must get notified immediately,
not urgend messages are notified every hour or in company with urgent

=cut

sub need_notification {
    my $self = shift;
    
    return $self->search(
        {
            -or => [
               'me.ending_at'        => undef,
               'me.last_notified_at' => undef,
               'me.last_notified_at' => { '<' => \'coalesce(me.ending_at, me.starting_at)' },
            ]
        },
        {
        });
}

1;

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package StatisticsCollector::Schema::Result::Alarm;
use feature ':5.10';
use DBIx::Class::Candy -components => [ qw(InflateColumn::DateTime TimeStamp) ];

=head1 NAME

StatisticsCollector::Schema::Result::Alarm - Table definition

=head1 SYNOPSIS

=head1 DESCRIPTION

By regular polling, alarm situations will get discovered. As soon as an alarm
for a sensor is discovered, a Alarm-record will be generated.

=head1 TABLE

alarm

=cut

table 'alarm';

=head1 COLUMNS

=cut

=head2 alarm_id

Primary Key

=cut

primary_column alarm_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

=head2 alarm_condition_id

indicates the L<AlarmCondition|StatisticsCollector::Schema::Result::AlarmCondition>
that fired this alarm

=cut

column alarm_condition_id => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 sensor_id

indicates the L<Sensor|StatisticsCollector::Schema::Result::Sensor> 
that fired this alarm

=cut

column sensor_id => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 starting_at

The first time this alarm occured

=cut

column starting_at => {
    data_type => 'datetime', timezone => 'local',
    is_nullable => 0,
    set_on_create => 1
};

=head2 last_notified_at

The time this alarm was last notified

=cut

column last_notified_at => {
    data_type => 'datetime', timezone => 'local',
    is_nullable => 1,
};

=head2 ending_at

The alarm was cleared at this time

=cut

column ending_at => {
    data_type => 'timestamp', timezone => 'local',
    is_nullable => 1,
};

=head1 RELATIONS

=cut

=head2 alarm_condition

=cut

belongs_to alarm_condition => 'StatisticsCollector::Schema::Result::AlarmCondition', 'alarm_condition_id';

=head2 sensor

=cut

belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';


=head1 METHODS

=cut

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

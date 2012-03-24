package StatisticsCollector::Schema::Result::AlarmCondition;
use feature ':5.10';
use DBIx::Class::Candy -components => [ qw(DynamicDefault) ];

=head1 NAME

StatisticsCollector::Schema::Result::AlarmCondition - Table definition

=head1 SYNOPSIS

=head1 DESCRIPTION

stores a series of conditions are tested against 
L<Measure|StatisticsCollector::Schema::Result::Measure> records
in order to find out if measures or their age still are sane.

=head1 TABLE

alarm_condition

=cut

table 'alarm_condition';

=head1 COLUMNS

=cut

=head2 alarm_condition_id

Primary Key

=cut

primary_column alarm_condition_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

=head2 name

a meaningful name for this condition. Should be human understandable

=cut

column name => {
    data_type => 'text',
    is_nullable => 1,
};

=head2 sensor_mask

a valid likehood mask '%/whatever/temperature' which is usually written in
small letters only and should only consist of letters, digits and underscore.

The 3 parts have the following meaning (from left to richt):

=over

=item 1

contains the domain, location or hostname of machine or service supervised

eg. erlangen, new_york, my_server.com, mywebsite.de

=item 2

is something the watched service can be divided into

eg. basement, room_2, cpu, hard_drive_1, orders

=item 3

some kind of unit or kind of measure

eg. temperature, fill, count, to_process

=back

This way meaningful paths of 3 parts get constructed:

    basement/room_2/temperature
    new_york/2000_5th/humidity
    my_server.com/cpu/load
    my_server.com/hard_drive_1/fill
    my_customer.com/orders/open

=cut

column sensor_mask => {
    data_type => 'text',
    is_nullable => 0,
};

=head2 max_measure_age_minutes

assert that measure age is not greater than this value

=cut

column max_measure_age_minutes => {
    data_type => 'int',
    is_nullable => 1,
};

=head2 latest_value_gt

assert that latest value is greater than this value

=cut

column latest_value_gt => {
    data_type => 'int',
    is_nullable => 1,
};

=head2 latest_value_lt

assert that latest value is less than this value

=cut

column latest_value_lt => {
    data_type => 'int',
    is_nullable => 1,
};

=head2 min_value_gt

assert that min value is greater than this value

=cut

column min_value_gt => {
    data_type => 'int',
    is_nullable => 1,
};

=head2 max_value_lt

assert that max value is less than this value

=cut

column max_value_lt => {
    data_type => 'int',
    is_nullable => 1,
};

=head2 severity_level

indicates the severity of an alarm condition. The higher severity level
will be the one firing an alarm.

=over

=item 1

info

=item 2

warn

=item 3

error

=item 4

fatal

=back

=cut

column severity_level => {
    data_type => 'int',
    is_nullable => 0,
    default_value => 2,
};

=head2 notify_email

holds the person to get notified by mail.

=cut

column notify_email => {
    data_type => 'text',
    is_nullable => 1,
};

=head2 specificity

a autogenerated value that allows sorting by specificity of sensor masks.
Masks might contain like-wildcarts B<%> to indicate a "don't care" condition.

If we are in situation that more than one mask matches a given sensor, a
higher value in this column has precedence over an alarm condition having
a lower value.

=cut

column specificity => {
    data_type => 'int',
    is_nullable => 0,
    default_value => 0,
    dynamic_default_on_create => \&calculate_specificity_from_mask,
    dynamic_default_on_update => \&calculate_specificity_from_mask,
};

=head1 METHODS

=cut

=head2 calculate_specificity_from_mask

typically auto called during manipulation of records. Calculates an integer
from a given sensor mask that can be put into the C<specificity> column.

=cut

sub calculate_specificity_from_mask {
    my $self = shift;
    
    my $specificity = 8;
    
    given ($self->sensor_mask) {
        $specificity = 7 when m{\A % / [^%]+ \z}xms;
        $specificity = 6 when m{\A [^%]+ / % / [^%]+ \z}xms;
        $specificity = 5 when m{\A [^%]+ / % \z}xms;
        $specificity = 4 when m{\A % / % / [^%]+ \z}xms;
        $specificity = 3 when m{\A % / [^%]+ / % \z}xms;
        $specificity = 2 when m{\A [^%]+ / % / % \z}xms;
        $specificity = 1 when m{\A % / % / % \z}xms;
    }
    
    return $specificity;
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__

order of alarm conditions
-------------------------

most important (most specific)
  8: erlangen/keller/temperatur

medium specific
  7: %/keller/temperatur
  6: erlangen/%/temperatur
  5: erlangen/keller/%

low specific
  4: %/%/temperatur
  3: %/keller/%
  2: erlangen/%/%

unspecific
  1: %/%/%

not defined
  0: ?


testing
-------

- search all alarm conditions with matching masks
- sort by severity (desc) and then by specificity (desc)
- for every severity only keep the first (highest specificity value)
- the highest severity giving an alarm wins

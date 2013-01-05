package StatisticsCollector::Schema::Result::AlarmKind;
use feature ':5.10';
use DBIx::Class::Candy -components => [ qw(DynamicDefault) ];

=head1 NAME

StatisticsCollector::Schema::Result::AlarmKind - Table definition

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 TABLE

alarm_condition

=cut

table 'alarm_kind';

=head1 COLUMNS

=cut

=head2 alarm_kind_id

Primary Key

=cut

primary_column alarm_kind_id => {
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

=head2 kind

specifies the kind of alarm like 'Mail' or 'SMS'

=cut

column kind => {
    data_type => 'text',
    is_nullable => 1,
};

=head2 destination

the destination argument for the kind of alarm like the mail address
or a phone number to direct a SMS to

=cut

column destination => {
    data_type => 'text',
    is_nullable => 1,
};

=head2 arg1

an optional additional argument for for the alarm_kind

=cut

column arg1 => {
    data_type => 'text',
    is_nullable => 1,
};

=head2 arg2

an optional additional argument for for the alarm_kind

=cut

column arg2 => {
    data_type => 'text',
    is_nullable => 1,
};

=head1 RELATIONS

=cut

=head2 alarm_conditions

=cut

has_many alarm_conditions => 'StatisticsCollector::Schema::Result::AlarmCondition', 'alarm_condition_id';

1;

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

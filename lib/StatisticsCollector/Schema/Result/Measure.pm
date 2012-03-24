package StatisticsCollector::Schema::Result::Measure;
use DBIx::Class::Candy -components => [qw(InflateColumn::DateTime TimeStamp)];
use DateTime;

=head1 NAME

StatisticsCollector::Schema::Result::Measure - Table definition

=head1 SYNOPSIS

    my $measure = $schema->resultset('Measure')-> ...

=head1 DESCRIPTION

Represents a row in the measure table. A measure record contains all measured
values for the interval of one hour. This is done to avoid having too many
records in the database for heavy-logging services.

=head1 TABLE

measure

Extended by L<LatestMeasure|StatisticsCollector::Schema::Result::LatestMeasure>

=cut

table 'measure';

=head1 COLUMNS

All columns following are inherited by
L<LatestMeasure|StatisticsCollector::Schema::Result::LatestMeasure>

=cut

=head2 measure_id

primary key

=cut

primary_column measure_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

=head2 sensor_id

foreign key, pointing to the sensor a measure belongs to

=cut

column sensor_id => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 latest_value

The latest value read is always put into this column

=cut

column latest_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 min_value

the aggregated minimum value

=cut

column min_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 max_value

the aggregated maximum value

=cut

column max_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 sum_value

the aggregated summary value

=cut

column sum_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 nr_values

The total number of values read within this record's period

=cut

column nr_values => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 starting_at

The starting timestamp for aggregated measures inside this record

=cut

column starting_at => {
    data_type => 'datetime', timezone => 'local',
    is_nullable => 0,
};

=head2 updated_at

The last measure's measure time

=cut

column updated_at => {
    data_type => 'datetime', timezone => 'local',
    is_nullable => 0,
    set_on_create => 1, set_on_update => 1,
};

=head2 ending_at

The ending timestamp for aggregated measures inside this record

=cut

column ending_at => {
    data_type => 'timestamp', timezone => 'local',
    is_nullable => 0,
};

=head1 RELATIONS

=cut

=head2 sensor

Every L<Measure|StatisticsCollector::Schema::Result::Measure> belongs to exactly one L<Sensor|StatisticsCollector::Schema::Result::Sensor>
and a L<Sensor|StatisticsCollector::Schema::Result::Sensor> might mave many L<Measures|StatisticsCollector::Schema::Result::Measure>

=cut

belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';

=head1 METHODS

=cut

=head2 new( $class, \%attrs )

overloaded in order to do aggregation properly

=cut

sub new {
    my ($class, $attrs) = @_;
    
    my $this_hour = DateTime->now( time_zone => 'local' )
                            ->truncate( to => 'hour' );
    my $next_hour = $this_hour->clone->add( hours => 1 );
    
    $attrs->{starting_at}  //= $this_hour;
    $attrs->{ending_at}    //= $next_hour;
    $attrs->{latest_value} //= 0;
    $attrs->{min_value}    //= $attrs->{latest_value};
    $attrs->{max_value}    //= $attrs->{latest_value};
    $attrs->{sum_value}    //= $attrs->{latest_value};
    $attrs->{nr_values}    //= 1;
    
    return $class->next::method($attrs);
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

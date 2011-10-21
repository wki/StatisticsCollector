package StatisticsCollector::Schema::Result::Measure;
use DBIx::Class::Candy -components => [qw(InflateColumn::DateTime TimeStamp)];
use DateTime;

table 'measure';

primary_column measure_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

column sensor_id => {
    data_type => 'int',
    is_nullable => 0,
};

column latest_value => {
    data_type => 'int',
    is_nullable => 0,
};

column min_value => {
    data_type => 'int',
    is_nullable => 0,
};

column max_value => {
    data_type => 'int',
    is_nullable => 0,
};

column sum_value => {
    data_type => 'int',
    is_nullable => 0,
};

column nr_values => {
    data_type => 'int',
    is_nullable => 0,
};

column starting_at => {
    data_type => 'datetime', timezone => 'local',
    is_nullable => 0,
};

column updated_at => {
    data_type => 'datetime', timezone => 'local',
    is_nullable => 0,
    set_on_create => 1, set_on_update => 1,
};

column ending_at => {
    data_type => 'timestamp', timezone => 'local',
    is_nullable => 0,
};

belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';

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

1;

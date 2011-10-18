use strict;
use warnings;
use DateTime;
use Test::More;
use Test::Exception;
use Test::DBIx::Class;


# ensure DB is empty
is Sensor->count, 0, 'no records in sensor table';

my $sensor;
my $sensor2;

# add some sensors
{
    # add a sensor for the first time
    ok $sensor = Sensor->find_or_create({name => 'erlangen/keller/temperatur'}),
        'find or create sensor';
    is_result $sensor;
    is_fields [qw(sensor_id name)], $sensor, [1, 'erlangen/keller/temperatur'],
        'sensor fields look good';
    is Sensor->count, 1, '1 record in sensor table';
    
    
    # add same sensor name
    undef $sensor;
    ok $sensor = Sensor->find_or_create({name => 'erlangen/keller/temperatur'}),
        'find or create sensor 2';
    is_result $sensor;
    is_fields [qw(sensor_id name)], $sensor, [1, 'erlangen/keller/temperatur'],
        'sensor 2 fields look good';
    is Sensor->count, 1, 'still 1 record in sensor table';
    
    
    # add another sensor name
    ok $sensor2 = Sensor->find_or_create({name => 'erlangen/garage/temperatur'}),
        'find or create sensor 3';
    is_result $sensor2;
    is_fields [qw(sensor_id name)], $sensor2, [2, 'erlangen/garage/temperatur'],
        'sensor 3 fields look good';
    is Sensor->count, 2, '2 records in sensor table';
    
    
    is Measure->count, 0, 'no records in measure table';
}

# add measures
{
    my $test_time = DateTime->new(
        year       => 2009, month      => 10, day        => 11,
        hour       => 12,   minute     => 13, second     => 14,
        nanosecond => 0,
        time_zone  => 'local',
    );

    no warnings 'redefine';
    local *DateTime::now = sub { return $test_time->clone };

    
    my $start_hour = DateTime->new(
        year => 2009, month => 10, day => 11,
        hour => 12,
        time_zone  => 'local',
    );
    
    my $end_hour = DateTime->new(
        year => 2009, month => 10, day => 11,
        hour => 13,
        time_zone  => 'local',
    );
    
    my $measure;
    lives_ok { $measure = $sensor->add_measure(42) } 'add measure lives';
    is_result $measure;
    is_fields $measure,
              {
                  sensor_id   => 1,
                  min_value   => 42,
                  max_value   => 42,
                  sum_value   => 42,
                  nr_values   => 1,
                  starting_at => $start_hour,
                  ending_at   => $end_hour,
              },
        'measure 1 fields look good';
    is Measure->count, 1, '1 record in measure table';
    
    undef $measure;
    $test_time->set(minute => 42);
    lives_ok { $measure = $sensor->add_measure(10) } 'add measure 2 lives';
    $measure->discard_changes;
    is_fields $measure,
              {
                  sensor_id   => 1,
                  min_value   => 10,
                  max_value   => 42,
                  sum_value   => 52,
                  nr_values   => 2,
                  starting_at => $start_hour,
                  ending_at   => $end_hour,
              },
        'measure 2 fields look good';
    is Measure->count, 1, '1 record in measure table (2)';

    undef $measure;
    $test_time->set(minute => 59);
    lives_ok { $measure = $sensor->add_measure(60) } 'add measure 3 lives';
    is_fields $measure,
              {
                  sensor_id   => 1,
                  min_value   => 10,
                  max_value   => 60,
                  sum_value   => 112,
                  nr_values   => 3,
                  starting_at => $start_hour,
                  ending_at   => $end_hour,
              },
        'measure 3 fields look good';
    is Measure->count, 1, '1 record in measure table (3)';
    
    undef $measure;
    $test_time->set(hour => 13, minute => 0);
    $start_hour->set(hour => 13);
    $end_hour->set(hour => 14);
    lives_ok { $measure = $sensor->add_measure(13) } 'add measure 4 lives';
    is_fields $measure,
              {
                  sensor_id   => 1,
                  min_value   => 13,
                  max_value   => 13,
                  sum_value   => 13,
                  nr_values   => 1,
                  starting_at => $start_hour,
                  ending_at   => $end_hour,
              },
        'measure 4 fields look good';
    is Measure->count, 2, '2 records in measure table';
    
    ### TODO: check latest measure
}

# add some alarms and see if latest measure reports them
{
    my $x;
}

done_testing;
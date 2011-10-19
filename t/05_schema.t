use strict;
use warnings;
use DateTime;
use Test::More;
use Test::Exception;
use Test::DBIx::Class;


# ensure DB is empty
is Sensor->count, 0, 'no records in sensor table';

my ($sensor1, $sensor2, $sensor3);

# add some sensors
{
    # add a sensor for the first time
    ok $sensor1 = Sensor->find_or_create({name => 'erlangen/keller/temperatur'}),
        'find or create sensor';
    is_result $sensor1;
    is_fields [qw(sensor_id name)], $sensor1, [1, 'erlangen/keller/temperatur'],
        'sensor fields look good';
    is Sensor->count, 1, '1 record in sensor table';
    
    # add same sensor name
    undef $sensor1;
    ok $sensor1 = Sensor->find_or_create({name => 'erlangen/keller/temperatur'}),
        'find or create sensor 2';
    is_result $sensor1;
    is_fields [qw(sensor_id name)], $sensor1, [1, 'erlangen/keller/temperatur'],
        'sensor 2 fields look good';
    is Sensor->count, 1, 'still 1 record in sensor table';
    
    # add another sensor name
    ok $sensor2 = Sensor->find_or_create({name => 'erlangen/garage/temperatur'}),
        'find or create sensor 3';
    is_result $sensor2;
    is_fields [qw(sensor_id name)], $sensor2, [2, 'erlangen/garage/temperatur'],
        'sensor 3 fields look good';
    is Sensor->count, 2, '2 records in sensor table';
    
    # add third sensor name
    ok $sensor3 = Sensor->find_or_create({name => 'dallas/pool/temperatur'}),
        'find or create sensor 4';
    is_result $sensor3;
    is_fields [qw(sensor_id name)], $sensor3, [3, 'dallas/pool/temperatur'],
        'sensor 4 fields look good';
    is Sensor->count, 3, '3 records in sensor table';
    
    # no measures so far
    is Measure->count, 0, 'no records in measure table';
}

# add measures
{
    my $test_date = DateTime->new( year => 2009, month => 10, day => 11, time_zone  => 'local' );
    my $time_12_00_00 = $test_date->clone->set( hour => 12 );
    my $time_13_00_00 = $test_date->clone->set( hour => 13 );
    my $time_14_00_00 = $test_date->clone->set( hour => 14 );
    
    # this time might get changed during tests!
    my $test_time = $test_date->clone->set( hour => 12, minute => 13, second => 14 );

    no warnings 'redefine';
    local *DateTime::now = sub { return $test_time->clone };

    # multiple measures within one hour reside in the same record
    {
        my $measure;
        lives_ok { $measure = $sensor1->add_measure(42) } 'add measure lives';
        is_result $measure;
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 42,
                      max_value   => 42,
                      sum_value   => 42,
                      nr_values   => 1,
                      starting_at => $time_12_00_00,
                      ending_at   => $time_13_00_00,
                  },
            'measure 1 fields look good';
        is Measure->count, 1, '1 record in measure table';
        
        undef $measure;
        $test_time->set(minute => 42);
        lives_ok { $measure = $sensor1->add_measure(10) } 'add measure 2 lives';
        $measure->discard_changes;
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 10,
                      max_value   => 42,
                      sum_value   => 52,
                      nr_values   => 2,
                      starting_at => $time_12_00_00,
                      ending_at   => $time_13_00_00,
                  },
            'measure 2 fields look good';
        is Measure->count, 1, '1 record in measure table (2)';
        
        undef $measure;
        $test_time->set(minute => 59);
        lives_ok { $measure = $sensor1->add_measure(60) } 'add measure 3 lives';
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 10,
                      max_value   => 60,
                      sum_value   => 112,
                      nr_values   => 3,
                      starting_at => $time_12_00_00,
                      ending_at   => $time_13_00_00,
                  },
            'measure 3 fields look good';
        is Measure->count, 1, '1 record in measure table (3)';
    }
    
    # adding a measure in another hour must add new record
    {
        my $measure;
        $test_time->set(hour => 13, minute => 0);
        lives_ok { $measure = $sensor1->add_measure(13) } 'add measure 4 lives';
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 13,
                      max_value   => 13,
                      sum_value   => 13,
                      nr_values   => 1,
                      starting_at => $time_13_00_00,
                      ending_at   => $time_14_00_00,
                  },
            'measure 4 fields look good';
        is Measure->count, 2, '2 records in measure table';
    }
    
    # adding a measure for another sensor does not influence the others
    {
        my $measure;
        $test_time->set(hour => 13, minute => 0);
        lives_ok { $measure = $sensor2->add_measure(26) } 'add measure 5 lives';
        is_fields $measure,
                  {
                      sensor_id   => 2,
                      min_value   => 26,
                      max_value   => 26,
                      sum_value   => 26,
                      nr_values   => 1,
                      starting_at => $time_13_00_00,
                      ending_at   => $time_14_00_00,
                  },
            'measure 5 fields look good';
        is Measure->count, 3, '3 records in measure table';
        
    }
    
    # check latest measure
    {
        my $measure;
        lives_ok { $measure = $sensor1->latest_measure } 'sensor 1 latest_measure lives';
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 13,
                      max_value   => 13,
                      sum_value   => 13,
                      nr_values   => 1,
                      starting_at => $time_13_00_00,
                      ending_at   => $time_14_00_00,
                      max_severity_level => undef,
                      max_value_lt_alarm => 0,
                      measure_age_alarm => 0,
                      min_value_gt_alarm => 0,
                      nr_matching_alarm_conditions => 0,
                  },
            'sensor 1 latest_measure fields look good';
    }
}

# add some alarms and see if latest measure reports them
{
    my $x;
}

done_testing;
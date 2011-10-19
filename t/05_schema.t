use strict;
use warnings;
use DateTime;
use Test::More;
use Test::Exception;
use Test::DBIx::Class;


# ensure DB is empty
is Sensor->count, 0, 'no records in sensor table';

my ($sensor1, $sensor2, $sensor3);

# add some sensors: 1=erlangen/keller/temperatur, 2=erlangen/garage/temperatur, 3=dallas/pool/temperatur
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

# add measures s1: 2 measures t2, t1 / s2: 1 measure: t1 / s3: 1 measure: t0
{
    # today's times are used. We simply assume that our DB is also operating in our local time zone
    # t2 = current hour - 2 hours, t1 = current hour - 1 hour, t0 = current hour
    my $now       = DateTime->now(time_zone => 'local');
    my $test_date = $now->clone->truncate(to => 'day');
    my $t2 = $now->clone->truncate(to => 'hour')->subtract(hours => 2);
    my $t1 = $now->clone->truncate(to => 'hour')->subtract(hours => 1);
    my $t0 = $now->clone->truncate(to => 'hour');
    my $ta = $now->clone->truncate(to => 'hour')->add(hours => 1);
    
    # this time might get changed during tests!
    my $test_time = $t2->clone->set(minute => 13, second => 14);

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
                      starting_at => $t2,
                      ending_at   => $t1,
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
                      starting_at => $t2,
                      ending_at   => $t1,
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
                      starting_at => $t2,
                      ending_at   => $t1,
                  },
            'measure 3 fields look good';
        is Measure->count, 1, '1 record in measure table (3)';
    }
    
    # adding a measure in another hour must add new record
    {
        my $measure;
        $test_time = $t1->clone->set(minute => 0);
        lives_ok { $measure = $sensor1->add_measure(13) } 'add measure 4 lives';
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 13,
                      max_value   => 13,
                      sum_value   => 13,
                      nr_values   => 1,
                      starting_at => $t1,
                      ending_at   => $t0,
                  },
            'measure 4 fields look good';
        is Measure->count, 2, '2 records in measure table';
    }
    
    # adding a measure for another sensor does not influence the others
    {
        my $measure;
        $test_time = $t1->clone->set(minute => 0);
        lives_ok { $measure = $sensor2->add_measure(26) } 'add measure 5 lives';
        is_fields $measure,
                  {
                      sensor_id   => 2,
                      min_value   => 26,
                      max_value   => 26,
                      sum_value   => 26,
                      nr_values   => 1,
                      starting_at => $t1,
                      ending_at   => $t0,
                  },
            'measure 5 fields look good';
        is Measure->count, 3, '3 records in measure table';
        
    }
    
    # check latest measure
    {
        # sensor 1 has 2 measures: 12:00 and 13:00
        my $measure;
        lives_ok { $measure = $sensor1->latest_measure } 'sensor 1 latest_measure lives';
        is_fields $measure,
                  {
                      sensor_id   => 1,
                      min_value   => 13,
                      max_value   => 13,
                      sum_value   => 13,
                      nr_values   => 1,
                      starting_at => $t1,
                      ending_at   => $t0,
                      max_severity_level => undef,
                      max_value_lt_alarm => 0,
                      measure_age_alarm => 0,
                      min_value_gt_alarm => 0,
                      nr_matching_alarm_conditions => 0,
                  },
            'sensor 1 latest_measure fields look good';

        # sensor 2 has 1 measure: 13:00
        undef $measure;
        lives_ok { $measure = $sensor2->latest_measure } 'sensor 2 latest_measure lives';
        is_fields $measure,
                  {
                      sensor_id                    => 2,
                      min_value                    => 26,
                      max_value                    => 26,
                      sum_value                    => 26,
                      nr_values                    => 1,
                      starting_at                  => $t1,
                      ending_at                    => $t0,
                      max_severity_level           => undef,
                      max_value_lt_alarm           => 0,
                      measure_age_alarm            => 0,
                      min_value_gt_alarm           => 0,
                      nr_matching_alarm_conditions => 0,
                  },
            'sensor 2 latest_measure fields look good';

        # sensor 3 has no measures so far
        undef $measure;
        lives_ok { $measure = $sensor3->latest_measure } 'sensor 3 latest_measure lives';
        ok !defined $measure, 'sensor 3 measure is undefined';
        
        # add a measure with negative value for sensor 3
        undef $measure;
        $test_time = $t0->clone->set(minute => 12);
        lives_ok { $measure = $sensor3->add_measure(-42) } 'add measure 6 lives';
        is Measure->count, 4, '4 records in measure table';

        undef $measure;
        lives_ok { $measure = $sensor3->latest_measure } 'sensor 3 latest_measure lives 2';
        is_fields $measure,
                  {
                      sensor_id                    => 3,
                      min_value                    =>-42,
                      max_value                    =>-42,
                      sum_value                    =>-42,
                      nr_values                    => 1,
                      starting_at                  => $t0,
                      ending_at                    => $ta,
                      max_severity_level           => undef,
                      max_value_lt_alarm           => 0,
                      measure_age_alarm            => 0,
                      min_value_gt_alarm           => 0,
                      nr_matching_alarm_conditions => 0,
                  },
            'sensor 3 latest_measure fields look good';
    }
}

# add some alarms and see if latest measure reports them
{
    # sensor 1: 2 measures, 1 and 2 hours age, latest: value = 13 .. 13
    # sensor 2: 1 measure,  1 hour age,        latest: value = 26 .. 26
    # sensor 3: 1 measure,  0 hour age,        latest: value = 42 .. 42
    my $alarm;
}

done_testing;

use strict;
use warnings;
use DateTime;
use List::MoreUtils 'zip';
use Test::More;
use Test::Exception;
use Test::DBIx::Class;

# ensure DB is empty
is Sensor->count, 0, 'no records in sensor table';

our ($sensor1, $sensor2, $sensor3);

# today's times are used. We simply assume that our DB is also operating in our local time zone
# t2 = current hour - 2, t1 = current hour - 1, t0 = current hour, ta = current hour + 1
my $now = DateTime->now( time_zone => 'local' );
my $test_date = $now->clone->truncate( to => 'day' );
my $t2        = $now->clone->truncate( to => 'hour' )->subtract( hours => 2 );
my $t1        = $now->clone->truncate( to => 'hour' )->subtract( hours => 1 );
my $t0        = $now->clone->truncate( to => 'hour' );
my $ta        = $now->clone->truncate( to => 'hour' )->add( hours => 1 );

# add some sensors: 1=erlangen/keller/temperatur, 2=erlangen/garage/temperatur, 3=dallas/pool/temperatur
{
    my @testcases = (
        { name => 'add e/k/t 1st time', sensor_name => 'erlangen/keller/temperatur', count => 1, id => 1 },
        { name => 'add e/k/t 2nd time', sensor_name => 'erlangen/keller/temperatur', count => 1, id => 1 },
        { name => 'add e/g/t 1st time', sensor_name => 'erlangen/garage/temperatur', count => 2, id => 2 },
        { name => 'add e/g/t end time', sensor_name => 'erlangen/garage/temperatur', count => 2, id => 2 },
        { name => 'add d/p/t 1st time', sensor_name => 'dallas/pool/temperatur',     count => 3, id => 3 },
        { name => 'add d/p/t end time', sensor_name => 'dallas/pool/temperatur',     count => 3, id => 3 },
    );

    foreach my $testcase (@testcases) {
        my $name = $testcase->{name};

        my $sensor;
        ok $sensor =
          Sensor->find_or_create( { name => $testcase->{sensor_name} } ),
          "$name: find or create sensor";
        is_fields [qw(sensor_id name)], $sensor,
          [ $testcase->{id}, $testcase->{sensor_name} ],
          "$name: sensor fields look good";
        is Sensor->count, $testcase->{count}, "$name: $testcase->{count} record(s) in sensor table";
    }

    # no measures so far
    is Measure->count, 0, 'no records in measure table';

    # put sensors into global variables
    ($sensor1, $sensor2, $sensor3) = Sensor->search(undef, {order_by => 'sensor_id'})->all;
}

# add measures s1: 2 measures t2, t1 / s2: 1 measure: t1 / s3: 1 measure: t0
{
    # this time will change during tests!
    my $test_time = $t2->clone->set( minute => 13, second => 14 );

    no warnings 'redefine';
    local *DateTime::now = sub { return $test_time->clone };
    local *DBIx::Class::TimeStamp::get_timestamp =
        sub { return $test_time->clone };

    my @testcases = (
        # sensor 1 hour t2
        {
            name => 's1 t2 value 1', sensor => $sensor1, time => $t2, minute => 13, second => 14, value => 42,
            min => 42, max => 42, sum => 42, nr => 1, count => 1,
        },
        {
            name => 's1 t2 value 2', sensor => $sensor1, time => $t2, minute => 42, second => 16, value => 10,
            min => 10, max => 42, sum => 52, nr => 2, count => 1,
        },
        {
            name => 's1 t2 value 3', sensor => $sensor1, time => $t2, minute => 59, second => 59, value => 60,
            min => 10, max => 60, sum => 112, nr => 3, count => 1,
        },

        # sensor 1 hour t1
        {
            name => 's1 t1 value 1', sensor => $sensor1, time => $t1, minute => 0, second => 0, value => 13,
            min => 13, max => 13, sum => 13, nr => 1, count => 2,
        },

        # sensor 2 hour t1
        {
            name => 's2 t1 value 1', sensor => $sensor2, time => $t1, minute => 0, second => 0, value => 26,
            min => 26, max => 26, sum => 26, nr => 1, count => 3,
        },
        {
            name => 's2 t1 value 2', sensor => $sensor2, time => $t1, minute => 13, second => 0, value => -42,
            min => -42, max => 26, sum => -16, nr => 2, count => 3,
        },

        # sensor 3 hour t0
        {
            name => 's3 t0 value 1', sensor => $sensor3, time => $t0, minute => 0, second => 0, value => 42,
            min => 42, max => 42, sum => 42, nr => 1, count => 4,
        },
    );

    foreach my $testcase (@testcases) {
        my $name = $testcase->{name};
        my $sensor = $testcase->{sensor};

        $test_time = $testcase->{time}->clone->set( minute => $testcase->{minute}, second => $testcase->{second} );

        my %measure_values = (
            sensor_id    => $sensor->id,
            latest_value => $testcase->{value},
            min_value    => $testcase->{min},
            max_value    => $testcase->{max},
            sum_value    => $testcase->{sum},
            nr_values    => $testcase->{nr},
            starting_at  => $testcase->{time},
            updated_at   => $test_time,
            ending_at    => $testcase->{time}->clone->add( hours => 1 ),
        );
        my %alarm_values = (
            alarm_condition_id    => undef,
            measure_age_alarm     => 0,
            latest_value_gt_alarm => 0,
            latest_value_lt_alarm => 0,
            min_value_gt_alarm    => 0,
            max_value_lt_alarm    => 0,
            max_severity_level    => undef,
        );

        my $measure;
        lives_ok { $measure = $sensor->add_measure($testcase->{value}) } "$name: add measure lives";

        is_fields $measure, \%measure_values,
                  "$name: measure look good";

        my $latest_measure;
        # using find() is necessary here because ->latest_measure gests cached otherwise!
        lives_ok { $latest_measure = Sensor->find($sensor->id)->latest_measure }
                 "$name: latest_measure lives";

        is_fields $latest_measure, { %measure_values, %alarm_values },
                  "$name: latest measure looks goog";
        is Measure->count, $testcase->{count}, "$name: $testcase->{count} record(s) in measure table";
    }
}

# check low-level calculation of specificity
{
    my $sensor_mask = 'abc';
    no warnings 'redefine';
    local *StatisticsCollector::Schema::Result::AlarmCondition::sensor_mask =
        sub { return $sensor_mask };

    my $ac = StatisticsCollector::Schema::Result::AlarmCondition->new();
    is $ac->sensor_mask, 'abc', 'mocking of mask works';
    is $ac->calculate_specificity_from_mask, 8, 'mask w/o % is 8';

    my @testcases = (
        { mask => 'abc/dev/ghi',   specificity => 8 },

        { mask => '%/keller/temp', specificity => 7 },
        { mask => 'bla/%/temp',    specificity => 6 },
        { mask => 'bla/foo/%',     specificity => 5 },

        { mask => '%/%/temp',      specificity => 4 },
        { mask => '%/keller/%',    specificity => 3 },
        { mask => 'foo/%/%',       specificity => 2 },

        { mask => '%/%/%',         specificity => 1 },
    );

    foreach my $testcase (@testcases) {
        $sensor_mask = $testcase->{mask};
        is $ac->calculate_specificity_from_mask, $testcase->{specificity},
           "$testcase->{mask} is $testcase->{specificity}";
    }
}

# add some alarms and see if latest measure reports them
{

# 1: erlangen/keller/temperatur 2 measures, 1 and 2 hours age, latest: value = 13 .. 13
# 2: erlangen/garage/temperatur 1 measure,  1 hour age,        latest: value = -42 .. 26
# 3: dallas/pool/temperatur     1 measure,  0 hour age,        latest: value = 42 .. 42

    is AlarmCondition->count, 0, 'no alarm conditions defined yet';
    
    my @testcases = (
        # not firing:
        {
            name => 'not-matching not-firing',
            alarm_conditions => [
                # id mask              age    lat-gt lat-lt min-gt max-lt severity
                [ 1, 'non/sense/mask', undef, undef, undef, undef, undef, 2 ],
            ],
            expect => {},
        },
        {
            name => 'fully-matching not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', undef, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },
        {
            name => '1-matching not-firing',
            alarm_conditions => [
                [ 1, '%/keller/temperatur', undef, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },
        {
            name => '2-matching not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/%/temperatur', undef, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },
        {
            name => '3-matching not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/%', undef, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },

        # min-value-gt
        {
            name => 'fully-matching min-value-gt firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, 20, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1, min_value_gt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching min-value-gt higher firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, 14, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1, min_value_gt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching min-value-gt equal firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, 13, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1, min_value_gt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching min-value-gt range not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, 12, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },

        # latest-value-gt
        {
            name => 'fully-matching latest-value-gt firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching latest-value-gt higher firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 14, undef, undef, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching latest-value-gt equal firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 13, undef, undef, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching latest-value-gt range not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 12, undef, undef, 1000, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },

        # max-value-lt
        {
            name => 'fully-matching max-value-lt firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, undef, 5, 2 ],
            ],
            expect => { alarm_condition_id => 1, max_value_lt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching max-value-lt lower firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, undef, 12, 2 ],
            ],
            expect => { alarm_condition_id => 1, max_value_lt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching max-value-lt equal firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, undef, 13, 2 ],
            ],
            expect => { alarm_condition_id => 1, max_value_lt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching max-value-lt range not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, undef, undef, 14, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },

        # latest-value-lt
        {
            name => 'fully-matching latest-value-lt firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, 5, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1, latest_value_lt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching latest-value-lt lower firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, 12, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1, latest_value_lt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching latest-value-lt equal firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, 13, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1, latest_value_lt_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching latest-value-lt range not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, undef, 14, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },

        # age
        {
            name => 'fully-matching age 1m firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 1, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1, measure_age_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching age 60-m-1 firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 60 + $now->minute - 1, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1, measure_age_alarm => 1, max_severity_level => 2 },
        },
        {
            name => 'fully-matching age 60-m+1 not-firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 60 + $now->minute + 1, undef, undef, undef, undef, 2 ],
            ],
            expect => { alarm_condition_id => 1 },
        },
        
        # multiple alarms
        {
            name => '2: one matching mask 1 firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 2 ], # should fire
                [ 2, 'foo/bar/mask',               121, 10, undef, undef, undef, 4 ], # does not fire
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        },
        # {
        # NO: currently higher severity wins but does not fire --  BUG or FEATURE?
        #     name => '2: both matching mask lower severity firing',
        #     alarm_conditions => [
        #         [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 2 ], # should fire
        #         [ 2, 'erlangen/keller/temperatur', 121, 10, undef, undef, undef, 4 ], # does not fire
        #     ],
        #     expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        # },
        {
            name => '2: both matching mask higher severity firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 4 ], # should fire
                [ 2, 'erlangen/keller/temperatur', 121, 10, undef, undef, undef, 2 ], # does not fire
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 4 },
        },
        {
            name => '2: both matching mask/partial higher severity firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 4 ], # should fire
                [ 2, '%/%/temperatur',               1, 10, undef, undef, undef, 2 ], # does not fire
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 4 },
        },
        # {
        #     ### NO: severity wins over specificity -- BUG or FEATURE?
        #     ###     name => '2: both matching mask/partial higher specificity firing',
        #     ###     alarm_conditions => [
        #     ###         [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 2 ], # should fire
        #     ###         [ 2, '%/%/temperatur',               1, 10, undef, undef, undef, 4 ], # does not fire
        #     ###     ],
        #     ###     expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        # },
        {
            name => '2: both matching mask/partial same severity, higher specificity firing',
            alarm_conditions => [
                [ 1, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 2 ], # should fire
                [ 2, '%/%/temperatur',               1, 10, undef, undef, undef, 2 ], # does not fire
            ],
            expect => { alarm_condition_id => 1, latest_value_gt_alarm => 1, max_severity_level => 2 },
        },
    );

    my $alarm1;
    my %sensor1_measure = (
        sensor_id                    => 1,
        latest_value                 => 13,
        min_value                    => 13,
        max_value                    => 13,
        sum_value                    => 13,
        nr_values                    => 1,
        starting_at                  => $t1,
        updated_at                   => $t1->clone->set( minute => 0 ),
        ending_at                    => $t0,
        alarm_condition_id           => undef,
        measure_age_alarm            => 0,
        latest_value_gt_alarm        => 0,
        latest_value_lt_alarm        => 0,
        min_value_gt_alarm           => 0,
        max_value_lt_alarm           => 0,
        max_severity_level           => undef,
    );

    foreach my $testcase (@testcases) {
        my $name = $testcase->{name};
        set_alarm_conditions($testcase->{alarm_conditions});
        is_fields $sensor1->discard_changes->latest_measure,
                  { %sensor1_measure, %{$testcase->{expect}} },
                  "$name: expected values";
    }
}

# alarm creation and clearing
{
    my $test_time = $t2->clone->set( minute => 13, second => 14 );

    no warnings 'redefine';
    local *DateTime::now = sub { return $test_time->clone };
    local *DBIx::Class::TimeStamp::get_timestamp =
        sub { return $test_time->clone };
    
    is Alarm->count, 0, 'no alarm defined';
    
    ### TODO: add latest measures that do not alarm
    
    my $t0_13_14 = $t0->clone->set(minute => 13, second => 14);
    
    my @testcases = (
        ### alarm conditions that do not alarm
        {
            name => 'first occurence creates alarm',
            time => $t0_13_14,
            alarm_conditions => [
                [ 11, 'erlangen/keller/temperatur', 121, 20, undef, undef, undef, 2 ], # should fire
                [ 12, '%/%/temperatur',               1, 10, undef, undef, undef, 2 ], # does not fire
            ],
            nr_alarms => 1,
            expect => { alarm_condition_id => 11, sensor_id => 1, 
                        starting_at => $t0_13_14, last_notified_at => undef, ending_at => undef },
        },
    );
    
    foreach my $testcase (@testcases) {
        my $name = $testcase->{name};
        set_alarm_conditions($testcase->{alarm_conditions});
        
        $test_time = $testcase->{time};
        Alarm->check_and_update;
        
        is Alarm->count, $testcase->{nr_alarms},
           "$name: nr alarms is $testcase->{nr_alarms}";
    }
}

done_testing;

sub set_alarm_conditions {
    my $alarm_conditions = shift;
    
    AlarmCondition->delete;

    foreach my $alarm_condition (@$alarm_conditions) {
        my @fields = qw(alarm_condition_id sensor_mask
                        max_measure_age_minutes
                        latest_value_gt latest_value_lt
                        min_value_gt max_value_lt
                        severity_level);
        my @values = @{$alarm_condition};
        AlarmCondition->create( { zip @fields, @values } );
    }
    
}
use strict;
use warnings;
use DateTime;
use Test::More;
use Test::Exception;
use Test::DBIx::Class;

# ensure DB is empty
is Sensor->count, 0, 'no records in sensor table';

my ( $sensor1, $sensor2, $sensor3 );

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

    # add a sensor for the first time
    ok $sensor1 =
      Sensor->find_or_create( { name => 'erlangen/keller/temperatur' } ),
      'find or create sensor';
    is_result $sensor1;
    is_fields [qw(sensor_id name)], $sensor1,
      [ 1, 'erlangen/keller/temperatur' ],
      'sensor fields look good';
    is Sensor->count, 1, '1 record in sensor table';

    # add same sensor name
    undef $sensor1;
    ok $sensor1 =
      Sensor->find_or_create( { name => 'erlangen/keller/temperatur' } ),
      'find or create sensor 2';
    is_result $sensor1;
    is_fields [qw(sensor_id name)], $sensor1,
      [ 1, 'erlangen/keller/temperatur' ],
      'sensor 2 fields look good';
    is Sensor->count, 1, 'still 1 record in sensor table';

    # add another sensor name
    ok $sensor2 =
      Sensor->find_or_create( { name => 'erlangen/garage/temperatur' } ),
      'find or create sensor 3';
    is_result $sensor2;
    is_fields [qw(sensor_id name)], $sensor2,
      [ 2, 'erlangen/garage/temperatur' ],
      'sensor 3 fields look good';
    is Sensor->count, 2, '2 records in sensor table';

    # add third sensor name
    ok $sensor3 =
      Sensor->find_or_create( { name => 'dallas/pool/temperatur' } ),
      'find or create sensor 4';
    is_result $sensor3;
    is_fields [qw(sensor_id name)], $sensor3, [ 3, 'dallas/pool/temperatur' ],
      'sensor 4 fields look good';
    is Sensor->count, 3, '3 records in sensor table';

    # no measures so far
    is Measure->count, 0, 'no records in measure table';
}

# add measures s1: 2 measures t2, t1 / s2: 1 measure: t1 / s3: 1 measure: t0
{

    # this time might get changed during tests!
    my $test_time = $t2->clone->set( minute => 13, second => 14 );

    no warnings 'redefine';
    local *DateTime::now = sub { return $test_time->clone };
    local *DBIx::Class::TimeStamp::get_timestamp =
      sub { return $test_time->clone };

    # multiple measures within one hour reside in the same record
    {
        my $measure;
        lives_ok { $measure = $sensor1->add_measure(42) } 'add measure lives';
        is_result $measure;
        is_fields $measure,
          {
            sensor_id    => 1,
            latest_value => 42,
            min_value    => 42,
            max_value    => 42,
            sum_value    => 42,
            nr_values    => 1,
            starting_at  => $t2,
            updated_at   => $test_time,
            ending_at    => $t1,
          },
          'measure 1 fields look good';
        is Measure->count, 1, '1 record in measure table';

        undef $measure;
        $test_time->set( minute => 42 );
        lives_ok { $measure = $sensor1->add_measure(10) } 'add measure 2 lives';
        $measure->discard_changes;
        is_fields $measure,
          {
            sensor_id    => 1,
            latest_value => 10,
            min_value    => 10,
            max_value    => 42,
            sum_value    => 52,
            nr_values    => 2,
            starting_at  => $t2,
            updated_at   => $test_time,
            ending_at    => $t1,
          },
          'measure 2 fields look good';
        is Measure->count, 1, '1 record in measure table (2)';

        undef $measure;
        $test_time->set( minute => 59 );
        lives_ok { $measure = $sensor1->add_measure(60) } 'add measure 3 lives';
        is_fields $measure,
          {
            sensor_id    => 1,
            latest_value => 60,
            min_value    => 10,
            max_value    => 60,
            sum_value    => 112,
            nr_values    => 3,
            starting_at  => $t2,
            updated_at   => $test_time,
            ending_at    => $t1,
          },
          'measure 3 fields look good';
        is Measure->count, 1, '1 record in measure table (3)';
    }

    # adding a measure in another hour must add new record
    {
        my $measure;
        $test_time = $t1->clone->set( minute => 0 );
        lives_ok { $measure = $sensor1->add_measure(13) } 'add measure 4 lives';
        is_fields $measure,
          {
            sensor_id    => 1,
            latest_value => 13,
            min_value    => 13,
            max_value    => 13,
            sum_value    => 13,
            nr_values    => 1,
            starting_at  => $t1,
            updated_at   => $test_time,
            ending_at    => $t0,
          },
          'measure 4 fields look good';
        is Measure->count, 2, '2 records in measure table';
    }

    # adding a measure for another sensor does not influence the others
    {
        my $measure;
        $test_time = $t1->clone->set( minute => 0 );
        lives_ok { $measure = $sensor2->add_measure(26) } 'add measure 5 lives';
        is_fields $measure,
          {
            sensor_id    => 2,
            latest_value => 26,
            min_value    => 26,
            max_value    => 26,
            sum_value    => 26,
            nr_values    => 1,
            starting_at  => $t1,
            updated_at   => $test_time,
            ending_at    => $t0,
          },
          'measure 5 fields look good';
        is Measure->count, 3, '3 records in measure table';

    }

    # check latest measure
    {

        # sensor 1 has 2 measures: 12:00 and 13:00
        my $measure;
        lives_ok { $measure = $sensor1->latest_measure }
        'sensor 1 latest_measure lives';
        is_fields $measure,
          {
            sensor_id                    => 1,
            latest_value                 => 13,
            min_value                    => 13,
            max_value                    => 13,
            sum_value                    => 13,
            nr_values                    => 1,
            starting_at                  => $t1,
            updated_at                   => $test_time,
            ending_at                    => $t0,
            measure_age_alarm            => 0,
            latest_value_gt_alarm        => 0,
            latest_value_lt_alarm        => 0,
            min_value_gt_alarm           => 0,
            max_value_lt_alarm           => 0,
            max_severity_level           => undef,
            nr_matching_alarm_conditions => 0,
          },
          'sensor 1 latest_measure fields look good';

        # sensor 2 has 1 measure: 13:00
        undef $measure;
        lives_ok { $measure = $sensor2->latest_measure }
        'sensor 2 latest_measure lives';
        is_fields $measure,
          {
            sensor_id                    => 2,
            latest_value                 => 26,
            min_value                    => 26,
            max_value                    => 26,
            sum_value                    => 26,
            nr_values                    => 1,
            starting_at                  => $t1,
            updated_at                   => $test_time,
            ending_at                    => $t0,
            measure_age_alarm            => 0,
            latest_value_gt_alarm        => 0,
            latest_value_lt_alarm        => 0,
            min_value_gt_alarm           => 0,
            max_value_lt_alarm           => 0,
            max_severity_level           => undef,
            nr_matching_alarm_conditions => 0,
          },
          'sensor 2 latest_measure fields look good';

        # sensor 3 has no measures so far
        undef $measure;
        lives_ok { $measure = $sensor3->latest_measure }
        'sensor 3 latest_measure lives';
        ok !defined $measure, 'sensor 3 measure is undefined';

        # add a measure with negative value for sensor 3
        undef $measure;
        $test_time = $t0->clone->set( minute => 12 );
        lives_ok { $measure = $sensor3->add_measure(-42) }
        'add measure 6 lives';
        is Measure->count, 4, '4 records in measure table';

        undef $measure;
        lives_ok { $measure = $sensor3->latest_measure }
        'sensor 3 latest_measure lives 2';
        is_fields $measure,
          {
            sensor_id                    => 3,
            latest_value                 => -42,
            min_value                    => -42,
            max_value                    => -42,
            sum_value                    => -42,
            nr_values                    => 1,
            starting_at                  => $t0,
            updated_at                   => $test_time,
            ending_at                    => $ta,
            measure_age_alarm            => 0,
            latest_value_gt_alarm        => 0,
            latest_value_lt_alarm        => 0,
            min_value_gt_alarm           => 0,
            max_value_lt_alarm           => 0,
            max_severity_level           => undef,
            nr_matching_alarm_conditions => 0,
          },
          'sensor 3 latest_measure fields look good';
    }
}

# check low-level calculation of specificity
{
    my $sensor_mask = 'abc';
    local *StatisticsCollector::Schema::Result::AlarmCondition::sensor_mask =
        sub { return $sensor_mask };
    
    my $ac = StatisticsCollector::Schema::Result::AlarmCondition->new();
    is $ac->sensor_mask, 'abc', 'mocking of mask works';
    
    is $ac->calculate_specificity_from_mask, 8, 'mask w/o % is 8';
    
    $sensor_mask = '%/keller/temp';
    is $ac->calculate_specificity_from_mask, 7, 'mask %/a/b is 7';
    $sensor_mask = 'bla/%/temp';
    is $ac->calculate_specificity_from_mask, 6, 'mask a/%/b is 6';
    $sensor_mask = 'bla/foo/%';
    is $ac->calculate_specificity_from_mask, 5, 'mask a/b/% is 5';
    
    $sensor_mask = '%/%/temp';
    is $ac->calculate_specificity_from_mask, 4, 'mask %/%/a is 4';
    $sensor_mask = '%/xxx/%';
    is $ac->calculate_specificity_from_mask, 3, 'mask %/b/$ is 3';
    $sensor_mask = 'bla/%/%';
    is $ac->calculate_specificity_from_mask, 2, 'mask c/%/% is 2';
    
    $sensor_mask = '%/%/%';
    is $ac->calculate_specificity_from_mask, 1, 'mask %/%/% is 1';
}

# add some alarms and see if latest measure reports them
{

# 1: erlangen/keller/temperatur 2 measures, 1 and 2 hours age, latest: value = 13 .. 13
# 2: erlangen/garage/temperatur 1 measure,  1 hour age,        latest: value = 26 .. 26
# 3: dallas/pool/temperatur     1 measure,  0 hour age,        latest: value = 42 .. 42

    is AlarmCondition->count, 0, 'no alarm conditions defined yet';

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
        measure_age_alarm            => 0,
        latest_value_gt_alarm        => 0,
        latest_value_lt_alarm        => 0,
        min_value_gt_alarm           => 0,
        max_value_lt_alarm           => 0,
        max_severity_level           => undef,
        nr_matching_alarm_conditions => 0,

    );

    # a mask-non-matching alarm does neither show up not warn
    $alarm1 = AlarmCondition->create(
        {
            sensor_mask    => 'non/sense/mask',    # should never match
            severity_level => 5,
        }
    );
    is AlarmCondition->count, 1, 'one alarm condition defined';
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, },
      'nonsense alarm is not seen';

    # a mask-matching but null-valued alarm shows but does not warn
    $alarm1->update( { sensor_mask => 'erlangen/keller/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'fully masked alarm is seen';

    $alarm1->update( { sensor_mask => '%/keller/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'begin-masked alarm is seen';

    $alarm1->update( { sensor_mask => 'erlangen/%/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'mid-masked alarm is seen';

    $alarm1->update( { sensor_mask => 'erlangen/keller/%' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'end-masked alarm is seen';

    # a mask-matching and out-of-range-valued alarm shows but does not warn
    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 121,
            min_value_gt            => -1000,
            max_value_lt            => 1000,
            latest_value_gt         => -1000,
            latest_value_lt         => 1000,
        }
    );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'in-range alarm is seen';

    # min-gt warning
    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 6_000,
            min_value_gt            => 20,
            max_value_lt            => 1_000,
        }
    );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'min-gt alarm is fired for values outside range';

    $alarm1->update( { min_value_gt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'min-gt alarm is fired for edge values outside range';

    $alarm1->update( { min_value_gt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'min-gt alarm is fired for equal values';

    $alarm1->update( { min_value_gt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'min-gt alarm is not fired for edge value inside range';

    # latest-gt warning
    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 6_000,
            min_value_gt            => undef,
            max_value_lt            => undef,
            latest_value_gt         => 20,
            latest_value_lt         => 1_000,
        }
    );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_gt_alarm        => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'min-gt alarm is fired for values outside range';

    $alarm1->update( { latest_value_gt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_gt_alarm        => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'min-gt alarm is fired for edge values outside range';

    $alarm1->update( { latest_value_gt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_gt_alarm        => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'min-gt alarm is fired for equal values';

    $alarm1->update( { latest_value_gt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'min-gt alarm is not fired for edge value inside range';

    # max-lt warning
    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 121,
            min_value_gt            => -1000,
            max_value_lt            => 5,
            latest_value_gt         => -1000,
            latest_value_lt         => 1000,
        }
    );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        max_value_lt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'max-lt alarm is fired for values outside range';

    $alarm1->update( { max_value_lt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        max_value_lt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'max-lt alarm is fired for edge values outside range';

    $alarm1->update( { max_value_lt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        max_value_lt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'max-lt alarm is fired for equal values';

    $alarm1->update( { max_value_lt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'max-lt alarm is not fired for edge value inside range';

    # latest-lt warning
    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 121,
            min_value_gt            => -1000,
            max_value_lt            => 1000,
            latest_value_gt         => -1000,
            latest_value_lt         => 5,
        }
    );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_lt_alarm        => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'max-lt alarm is fired for values outside range';

    $alarm1->update( { latest_value_lt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_lt_alarm        => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'max-lt alarm is fired for edge values outside range';

    $alarm1->update( { latest_value_lt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_lt_alarm        => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'max-lt alarm is fired for equal values';

    $alarm1->update( { latest_value_lt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'max-lt alarm is not fired for edge value inside range';

    # age warning
    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 120,
            min_value_gt            => -1000,
            max_value_lt            => 1000,
            latest_value_gt         => -1000,
            latest_value_lt         => 1000,
        }
    );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'age alarm is not fired for ages in range';

    $alarm1->update( { max_measure_age_minutes => 1 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'age alarm is fired for ages out of range';

    $alarm1->update( { max_measure_age_minutes => 60 + $now->minute - 1 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'age alarm is fired for ages just out of range';

    $alarm1->update( { max_measure_age_minutes => 60 + $now->minute + 1 } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure, nr_matching_alarm_conditions => 1, },
      'age alarm is not fired for ages just in range';

    $alarm1->update(
        {
            sensor_mask             => 'erlangen/keller/temperatur',
            max_measure_age_minutes => 1,
            min_value_gt            => -1000,
            max_value_lt            => 1000,
            latest_value_gt         => -1000,
            latest_value_lt         => 1000,
        }
    );

    # multiple alarms work, severity is max
    my $alarm2 = AlarmCondition->create(
        {
            sensor_mask    => 'foo/bar/mask',    # should never match
            severity_level => 3,
        }
    );
    is AlarmCondition->count, 2, 'two alarm conditions defined';

    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 1,
      },
      'age alarm is fired for ages out of range, nonsense alarm ignored';

    $alarm2->update( { sensor_mask => '%/%/temperatur', min_value_gt => 0 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 2,
      },
      'age alarm is still fired, other alarm not fired';

    $alarm2->update( { min_value_gt => 20 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        measure_age_alarm            => 1,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
        nr_matching_alarm_conditions => 2,
      },
      'age alarm and min_value_gt alarm is fired';

    $alarm2->update( { severity_level => 9 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        measure_age_alarm            => 1,
        min_value_gt_alarm           => 1,
        max_severity_level           => 9,
        nr_matching_alarm_conditions => 2,
      },
      'reported severity level is maximum';
}

done_testing;

use strict;
use warnings;
use DateTime;
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
        alarm_condition_id           => 1,
        measure_age_alarm            => 0,
        latest_value_gt_alarm        => 0,
        latest_value_lt_alarm        => 0,
        min_value_gt_alarm           => 0,
        max_value_lt_alarm           => 0,
        max_severity_level           => undef,
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
      { %sensor1_measure,
        alarm_condition_id => undef },
      'nonsense alarm is not seen';

    # a mask-matching but null-valued alarm shows but does not warn
    $alarm1->update( { sensor_mask => 'erlangen/keller/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
      'fully masked alarm is seen';

    $alarm1->update( { sensor_mask => '%/keller/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
      'begin-masked alarm is seen';

    $alarm1->update( { sensor_mask => 'erlangen/%/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
      'mid-masked alarm is seen';

    $alarm1->update( { sensor_mask => 'erlangen/keller/%' } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
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
      { %sensor1_measure },
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
      },
      'min-gt alarm is fired for values outside range';

    $alarm1->update( { min_value_gt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
      },
      'min-gt alarm is fired for edge values outside range';

    $alarm1->update( { min_value_gt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
      },
      'min-gt alarm is fired for equal values';

    $alarm1->update( { min_value_gt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
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
      },
      'min-gt alarm is fired for values outside range';

    $alarm1->update( { latest_value_gt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_gt_alarm        => 1,
        max_severity_level           => 5,
      },
      'min-gt alarm is fired for edge values outside range';

    $alarm1->update( { latest_value_gt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_gt_alarm        => 1,
        max_severity_level           => 5,
      },
      'min-gt alarm is fired for equal values';

    $alarm1->update( { latest_value_gt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
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
      },
      'max-lt alarm is fired for values outside range';

    $alarm1->update( { max_value_lt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        max_value_lt_alarm           => 1,
        max_severity_level           => 5,
      },
      'max-lt alarm is fired for edge values outside range';

    $alarm1->update( { max_value_lt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        max_value_lt_alarm           => 1,
        max_severity_level           => 5,
      },
      'max-lt alarm is fired for equal values';

    $alarm1->update( { max_value_lt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
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
      },
      'max-lt alarm is fired for values outside range';

    $alarm1->update( { latest_value_lt => 12, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_lt_alarm        => 1,
        max_severity_level           => 5,
      },
      'max-lt alarm is fired for edge values outside range';

    $alarm1->update( { latest_value_lt => 13, } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        latest_value_lt_alarm        => 1,
        max_severity_level           => 5,
      },
      'max-lt alarm is fired for equal values';

    $alarm1->update( { latest_value_lt => 14, } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
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
      { %sensor1_measure },
      'age alarm is not fired for ages in range';

    $alarm1->update( { max_measure_age_minutes => 1 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
      },
      'age alarm is fired for ages out of range';

    $alarm1->update( { max_measure_age_minutes => 60 + $now->minute - 1 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
      },
      'age alarm is fired for ages just out of range';

    $alarm1->update( { max_measure_age_minutes => 60 + $now->minute + 1 } );
    is_fields $sensor1->discard_changes->latest_measure,
      { %sensor1_measure },
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
        alarm_condition_id           => 1,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
      },
      'age alarm is fired for ages out of range, nonsense alarm ignored';

    $alarm2->update( { sensor_mask => '%/%/temperatur', min_value_gt => 0 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 1,
        max_severity_level           => 5,
      },
      'age alarm is still fired, other alarm not fired';

    $alarm2->update( { min_value_gt => 20 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 1,
        ### min_value_gt_alarm           => 1,
        max_severity_level           => 5,
      },
      'age alarm and min_value_gt alarm is fired';

    $alarm2->update( { severity_level => 9 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 2,
        ### measure_age_alarm            => 1,
        min_value_gt_alarm           => 1,
        max_severity_level           => 9,
      },
      'reported severity level is maximum';

    # multiple alarms let the most-specific fire
    $alarm2->update( { severity_level => 5 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 1,
        min_value_gt_alarm           => 0,
        max_severity_level           => 5,
      },
      'same severity level reports one';

    $alarm1->update( { max_measure_age_minutes => undef } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 0,
        min_value_gt_alarm           => 0,
        max_severity_level           => undef,
      },
      'most specific alarm keeps quiet if not firing';


    ### multiple alarms let the most-specific of highest severity level fire
    my $alarm3 = AlarmCondition->create(
          {
              sensor_mask    => '%/%/temperatur',
              min_value_gt   => 30,
              severity_level => 2,
          }
      );

    ### currently broken...
    ### is_fields $sensor1->discard_changes->latest_measure,
    ###   {
    ###     %sensor1_measure,
    ###     alarm_condition_id           => 1,
    ###     measure_age_alarm            => 0,
    ###     min_value_gt_alarm           => 1,
    ###     max_severity_level           => 2,
    ###   },
    ###   'lower severity level reports if higher keeps silent';

    $alarm1->update( { min_value_gt => 30 } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 0,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
      },
      'higher severity alarm overrides lower severity one if fired';

    $alarm3->update( { sensor_mask => 'erlangen/keller/temperatur' } );
    is_fields $sensor1->discard_changes->latest_measure,
      {
        %sensor1_measure,
        alarm_condition_id           => 1,
        measure_age_alarm            => 0,
        min_value_gt_alarm           => 1,
        max_severity_level           => 5,
      },
      'higher severity alarm overrides more specific lower severity one if fired';
}

done_testing;

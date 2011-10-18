package StatisticsCollector::Schema::Result::AlarmCondition;
use DBIx::Class::Candy;

table 'alarm_condition';

primary_column alarm_condition_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

#
# a valid likehood mask '%/whatever/temperature'
#
column sensor_mask => {
    data_type => 'text',
    is_nullable => 0,
};

#
# maximum age of measure in hours (2 or more make sense, because our interval is 1 hour)
#
column max_measure_age => {
    data_type => 'int',
    is_nullable => 1,
};

#
# assert that minimum value is greater than this
#
column min_value_gt => {
    data_type => 'int',
    is_nullable => 1,
};

#
# assert that maximum value is less than this
#
column max_value_lt => {
    data_type => 'int',
    is_nullable => 1,
};

#
# TODO: do we need a severity (0=INFO/100=WARNING/200=ERROR/300=FATAL) ???
#
column severity_level => {
    data_type => 'int',
    is_nullable => 0,
    # default_value => 200,
};

1;

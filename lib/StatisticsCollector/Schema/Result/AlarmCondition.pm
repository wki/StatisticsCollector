package StatisticsCollector::Schema::Result::AlarmCondition;
use DBIx::Class::Candy;

table 'alarm_condition';

primary_column alarm_condition_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

column sensor_mask => {
    data_type => 'text',
    is_nullable => 0,
};

column max_measure_age => {
    data_type => 'int',
};

column min_value_gt => {
    data_type => 'int',
};

column max_value_lt => {
    data_type => 'int',
};

1;

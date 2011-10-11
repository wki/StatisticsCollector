{
    connect_info     => ['dbi:Pg:dbname=statistics_test', 'postgres', ''],
    schema_class     => 'StatisticsCollector::Schema',
    resultsets       => [ qw(AlarmCondition Measure Sensor) ],
    force_drop_table => 1,
}

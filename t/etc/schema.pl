{
    # connect_info     => ['dbi:Pg:dbname=statistics_test', 'postgres', ''],
    connect_info => {
        dsn => 'dbi:Pg:dbname=statistics_test', 
        user => 'postgres', 
        pass => '',
        on_connect_do => 'SET client_min_messages=WARNING;',
        pg_enable_utf8 => 1,
    },
    
    schema_class     => 'StatisticsCollector::Schema',
    resultsets       => [ qw(AlarmCondition Measure Sensor) ],
    force_drop_table => 1,
}

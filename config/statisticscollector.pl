{
    name => 'StatisticsCollector',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    
    default_view => 'ByCode',
    
    # model config resides in additional config but looks like:
    'Model::DB' => {
        schema_class => 'StatisticsCollector::Schema',
    
        # connect_info => {
        #     dsn            => 'dbi:Pg:dbname=statistics',
        #     user           => 'postgres',
        #     password       => '',
        #     pg_enable_utf8 => 1,
        # },
    },
    
    'Controller::HTML::FormFu' => {
        model_stash => {
            schema => 'StatisticsCollector::Schema',
        },
    },
}

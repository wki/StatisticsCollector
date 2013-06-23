#
# main config file. additionally, we need a site-dependend suffix-config file.
#
{
    name => 'StatisticsCollector',

    # requires Catalyst 5.9004 and above or P::Unicode::Encoding
    encoding => 'UTF-8',

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
            schema => 'DB',
        },
        constructor => {
            # args => {
            #     # plugins => ['FixFields'],
            # },
        },
    },
}

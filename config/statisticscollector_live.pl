#
# config file for live deployment
#
{
    'Model::DB' => {
        connect_info => {
            dsn => 'dbi:Pg:dbname=statistics',
            user => 'postgres',
            password => '',
            pg_enable_utf8 => 1,
        },
    },
}

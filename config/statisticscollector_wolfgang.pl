#
# config file for Wolfgang
#
{
    'Model::DB' => {
        connect_info => {
            # dsn => 'dbi:Pg:dbname=statistics',
            dsn => 'dbi:Pg:dbname=stat',
            user => 'postgres',
            password => '',
            pg_enable_utf8 => 1,
        },
    },
}

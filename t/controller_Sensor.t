use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::DBIx::Class;
use HTTP::Request::Common;
use DateTime;
use JSON;
use YAML;

BEGIN { $ENV{DSN} = 'dbi:Pg:dbname=statistics_test' }
use Catalyst::Test 'StatisticsCollector';
use StatisticsCollector::Controller::Sensor;

# prepare DB
my $sensor;
is Sensor->count, 0, 'initially no sensors in DB';
lives_ok { $sensor = Sensor->create({name => 'abc/def/ghi'}) }
         'sensor created';
is Sensor->count, 1, 'sensor created';

my $dt = DateTime->new(
    year => 2010,
    month => 12,
    day => 11,
    hour => 14,
    time_zone => 'local',
);
is Measure->count, 0, 'no measures so far';

add_some_measures($sensor, $dt);

is Measure->count, 2, 'measures created';

################ GET Requests

# failing sensor requests
{
    is request(GET '/sensor')->code, 400,
       'query without sensor fails';
    is request(GET '/sensor/xx/yy/zz')->code, 404,
       'query with unknown sensor fails';
}

# default response format is JSON
{
    my $response = request(GET '/sensor/abc/def/ghi');
    is $response->code, 200,
       'query with known sensor works';
    is $response->header('Content_Type'), 'application/json',
       'response content type is JSON';
    is_deeply decode_json($response->content),
              { min_value => 13, max_value => 20, sum_value => 33, nr_values => 2 },
              'JSON Response looks good';
}

# specify response format via 'Accept'
{
    my $response = request(GET '/sensor/abc/def/ghi', 'Accept' => 'text/x-yaml');
    is $response->code, 200,
       'query with known sensor works 2';
    is $response->header('Content_Type'), 'text/x-yaml',
       'response content type is YAML';
    is_deeply Load($response->content),
              { min_value => 13, max_value => 20, sum_value => 33, nr_values => 2 },
              'YAML Response looks good';
}

# specify response format via 'Content-Type'
{
    my $response = request(GET '/sensor/abc/def/ghi', 'Content-Type' => 'text/x-yaml');
    is $response->code, 200,
       'query with known sensor works 3';
    is $response->header('Content_Type'), 'text/x-yaml',
       'response content type is YAML 2';
    is_deeply Load($response->content),
              { min_value => 13, max_value => 20, sum_value => 33, nr_values => 2 },
              'YAML Response looks good 2';
}

################ POST Requests

# failing sensor requests
{
    is request(POST '/sensor')->code, 400,
       'save withour sensor fails';
    is request(POST '/sensor/xx/yy')->code, 400,
        'save with too short sensor name fails';
}

# create new sensor
{
    my $dt = DateTime->new(
        year       => 2011, month      =>  1, day        => 28,
        hour       => 15,   minute     => 20, second     => 23,
        time_zone  => 'local',
    );
    
    no warnings 'redefine';
    local *DateTime::now = sub { $dt->clone };
    
    is Sensor->search({ name => 'my/sensor/name' })->count, 0,
       'sensor not known before POST';
    
    my $response = request(POST '/sensor/my/sensor/name', [value => 42]);
    is $response->code, 209,
       'response code is 209-accepted';
    
    my $sensor_rs = Sensor->search({ name => 'my/sensor/name' });
    is $sensor_rs->count, 1,
       'sensor is known after POST';
    my $sensor = $sensor_rs->first;
    
    # check measure
    my $measure_rs = $sensor->search_related('measure');
    is $measure_rs->count, 1, 'one measure so far';
    
    is_fields $measure_rs->first,
              {
                  sensor_id   => $sensor->id,
                  min_value   => 42,
                  max_value   => 42,
                  sum_value   => 42,
                  nr_values   => 1,
                  starting_at => $dt->clone->truncate( to => 'hour' ),
                  ending_at   => $dt->clone->truncate( to => 'hour' )->add( hours => 1 ),
              },
              'measure 1 fields look good';
}

# add measure same hour
{
    my $dt = DateTime->new(
        year       => 2011, month      =>  1, day        => 28,
        hour       => 15,   minute     => 25, second     => 21,
        time_zone  => 'local',
    );
    no warnings 'redefine';
    local *DateTime::now = sub { $dt->clone };

    my $response = request(POST '/sensor/my/sensor/name', [value => 20]);
    is $response->code, 209,
       'response code is 209-accepted';
    my $sensor_rs = Sensor->search({ name => 'my/sensor/name' });
    is $sensor_rs->count, 1,
       'sensor is only one after POST 2';
    my $sensor = $sensor_rs->first;
    
    # check measure
    my $measure_rs = $sensor->search_related('measure');
    is $measure_rs->count, 1, 'one measure so far';
    
    is_fields $measure_rs->first,
              {
                  sensor_id   => $sensor->id,
                  min_value   => 20,
                  max_value   => 42,
                  sum_value   => 62,
                  nr_values   => 2,
                  starting_at => $dt->clone->truncate( to => 'hour' ),
                  ending_at   => $dt->clone->truncate( to => 'hour' )->add( hours => 1 ),
              },
              'measure 2 fields look good';
}

# add measure other hour
{
    my $dt = DateTime->new(
        year       => 2011, month      =>  1, day        => 28,
        hour       => 16,   minute     =>  5, second     => 56,
        time_zone  => 'local',
    );
    no warnings 'redefine';
    local *DateTime::now = sub { $dt->clone };

    my $response = request(POST '/sensor/my/sensor/name', [value => 2]);
    is $response->code, 209,
       'response code is 209-accepted';
    is Sensor->search({ name => 'my/sensor/name' })->count, 1,
       'sensor is only one after POST 2';

    # check measure
}



done_testing();

sub add_some_measures {
    my $sensor = shift;
    my $dt     = shift;
    
    $sensor->create_related(
        measures => {
            min_value   => 13,
            max_value   => 20,
            sum_value   => 33,
            nr_values   => 2,
            starting_at => $dt->clone,
            ending_at   => $dt->clone->add( hours => 1 ),
        });
    $sensor->create_related(
        measures => {
            min_value   => 14,
            max_value   => 21,
            sum_value   => 35,
            nr_values   => 2,
            starting_at => $dt->clone->subtract( hours => 1 ),
            ending_at   => $dt->clone,
        });
}
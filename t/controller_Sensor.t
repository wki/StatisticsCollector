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
is Measure->count, 2, 'measures created';

# check sensor queries
is request(GET '/sensor')->code, 400,
   'query without sensor fails';
is request(GET '/sensor/xx/yy/zz')->code, 404,
   'query with unknown sensor fails';

my $response = request(GET '/sensor/abc/def/ghi');
is $response->code, 200,
   'query with known sensor works';
is $response->header('Content_Type'), 'application/json',
   'response content type is JSON';
is_deeply decode_json($response->content),
          { min_value => 13, max_value => 20, sum_value => 33, nr_values => 2 },
          'JSON Response looks good';

undef $response;
$response = request(GET '/sensor/abc/def/ghi', 'Accept' => 'text/x-yaml');
is $response->code, 200,
   'query with known sensor works 2';
is $response->header('Content_Type'), 'text/x-yaml',
   'response content type is YAML';
is_deeply Load($response->content),
          { min_value => 13, max_value => 20, sum_value => 33, nr_values => 2 },
          'YAML Response looks good';

undef $response;
$response = request(GET '/sensor/abc/def/ghi', 'Content-Type' => 'text/x-yaml');
is $response->code, 200,
   'query with known sensor works 3';
is $response->header('Content_Type'), 'text/x-yaml',
   'response content type is YAML 2';
is_deeply Load($response->content),
          { min_value => 13, max_value => 20, sum_value => 33, nr_values => 2 },
          'YAML Response looks good 2';




done_testing();

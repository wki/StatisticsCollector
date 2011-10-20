use strict;
use warnings;
use Test::More;


use Catalyst::Test 'StatisticsCollector';
use StatisticsCollector::Controller::Css;

ok( request('/css')->is_success, 'Request should succeed' );
done_testing();

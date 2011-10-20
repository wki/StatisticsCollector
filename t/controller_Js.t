use strict;
use warnings;
use Test::More;


use Catalyst::Test 'StatisticsCollector';
use StatisticsCollector::Controller::Js;

ok( request('/js')->is_success, 'Request should succeed' );
done_testing();

use strict;
use warnings;
use Test::More;


use Catalyst::Test 'StatisticsCollector';
use StatisticsCollector::Controller::Admin;

ok( request('/admin')->is_success, 'Request should succeed' );

done_testing();

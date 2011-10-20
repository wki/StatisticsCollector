use strict;
use warnings;
use Test::More;


use Catalyst::Test 'StatisticsCollector';
use StatisticsCollector::Controller::Dashboard;

ok( request('/dashboard')->is_success, 'Request should succeed' );

done_testing();

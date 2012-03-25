use strict;
use warnings;
use Test::More;

BEGIN { $ENV{DSN} = 'dbi:Pg:dbname=statistics_test' }

use Catalyst::Test 'StatisticsCollector';
use ok 'StatisticsCollector::Controller::Admin';

ok( request('/admin')->is_success, 'Request should succeed' );

done_testing();

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'StatisticsCollector';

ok( action_redirect('/', '/ redirects') );

done_testing();

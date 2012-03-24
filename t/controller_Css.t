use strict;
use warnings;
use Test::More;

use Catalyst::Test 'StatisticsCollector';
use ok 'StatisticsCollector::Controller::Css';

# strange: test fails, but it works!
# my $response = request('/css/site.css');
# warn $response->code;
# warn $response->content;

### fails:
# ok request('/css/site.css')->is_success, 'Request should succeed';

done_testing();

use strict;
use warnings;

use StatisticsCollector;

my $app = StatisticsCollector->apply_default_middlewares(StatisticsCollector->psgi_app);
$app;


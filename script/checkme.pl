#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::Schema;
use DateTime;
use POSIX 'strftime';
use Data::Dumper; $Data::Dumper::Maxdepth = 2; $Data::Dumper::Sortkeys = 1;

my $FORMAT = '%Y-%m-%d %H:%M:%S %z (%Z)';

my $schema = StatisticsCollector::Schema->connect('dbi:Pg:dbname=statistics', 'postgres', '');

my $rs = $schema->resultset('TestMe');

$rs->result_source->something('some more thing');

say 'ref($rs) = ' . ref $rs;
say 'isa($rs) = ' . join(', ', @StatisticsCollector::Schema::ResultSet::ISA);
say "ref(${\$rs->result_source}) = " . ref $rs->result_source;
say 'FROM = ' . ${$rs->result_source->from};

my $x = $rs->first;
$x = $schema->resultset('TestMe')->first;
$x = $schema->resultset('TestMe')->first;
# my $x = $rs->search(undef, { bind => ['hour', 24, 33] })->first;

# say Data::Dumper->Dump([$rs->result_source], ['result_source']);

__END__

my $sensor = $schema->resultset('Sensor')->find(26);

my @measures = $sensor->aggregate_measures('week', 20);
say "Nr Measures: ${\scalar @measures}";
say $_->starting_at->strftime($FORMAT), $_->min_value // '-undef-', " (${\$_->nr_values})"  for @measures;


# my @intervals =
#     $schema->resultset('DayInterval')
#            ->search( 
#                undef,
#                { bind => [10] } )
#            ->all();
# say "Nr Intervals: ${\scalar @intervals}";
# say $_->starting_at->strftime($FORMAT) for @intervals;


__END__

my $sensor = $schema->resultset('Sensor')->find(1, {prefetch => 'latest_measure'});
my $latest_measure = $sensor->latest_measure;
say "Latest: ${\$latest_measure->starting_at->hms}, " .
    "min: ${\$latest_measure->min_value}, " .
    "alarm: ${\$latest_measure->has_alarm}, " .
    "age alarm: ${\$latest_measure->measure_age_alarm}, " .
    "severity: ${\$latest_measure->max_severity_level}, " .
    "nr conditions: ${\$latest_measure->nr_matching_alarm_conditions}";

exit;

my @sensors = $schema->resultset('Sensor')
                     ->search(undef,
                              {
                                  prefetch => 'measures',
                                  page => 1,
                                  rows => 3,
                              });
foreach my $s (@sensors) {
    say "Sensor ${\$s->id} = ${\$s->name} (${\scalar($s->measures)}), isa = ${\ref $s}";
}
exit;



say 'Local time: ', strftime($FORMAT, localtime(time));

print_record(DateTime->now(),                                'without time zone');
print_record(DateTime->now( time_zone => 'floating' ),       'with floating time zone');
print_record(DateTime->now( time_zone => 'local' ),          'with local time zone');
print_record(DateTime->now( time_zone => 'Europe/Berlin' ),  'with my time zone');
print_record(DateTime->now( time_zone => 'America/Chicago'), 'with foreign time zone: Chicago');
print_record(DateTime->now( time_zone => 'Asia/Seoul'),      'with foreign time zone: Seoul');

sub print_record {
    my $dt = shift;
    my $description = shift;
    
    say "$description - date entered: ", $dt->strftime($FORMAT),
        ', offset: ', $dt->offset;
    
    my $record = $schema->resultset('DateTest')
                        ->create(
                            {
                                d1 => $dt->clone,
                                d2 => $dt->clone,
                                d3 => $dt->clone,
                                d4 => $dt->clone,
                            })
                        ->discard_changes;
    
    foreach my $column (qw(d1 d2 d3 d4)) {
        say "$column: ", sprintf('%-40s', $record->$column()->strftime($FORMAT)), 
            '- raw: ', $record->get_column($column);
    }
    
    say '---';
}

__END__

# add or find a sensor
my $sensor = $schema->resultset('Sensor')
                    ->find_or_create({name => 'erlangen/keller/temperatur'});

# add a measure (cumulative into last hour)
my $m = $sensor->add_measure(42);
say $m->starting_at->hms, ' offset ', $m->starting_at->offset;
$m->starting_at->set_time_zone('local');
say $m->starting_at->hms, ' offset ', $m->starting_at->offset;
$m->starting_at->set_time_zone('America/Chicago');
say $m->starting_at->hms, ' offset ', $m->starting_at->offset;


# # Query of measures
# $sensor->latest_measure->max_value();
# 
# my @m = $sensor->get_measures(nr);
# my @m = $sensor->get_measures(nr, interval);


# Alarm
# - Mask for sensor(s)
# - Age of latest measure
# - expected min/max value
# - expected min/max avg-value

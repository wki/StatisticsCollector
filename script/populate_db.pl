#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::Schema;
use DateTime;

my $schema = StatisticsCollector::Schema->connect('dbi:Pg:dbname=statistics', 'postgres', '');

$schema->resultset('AlarmCondition')->delete;
$schema->resultset('Measure')->delete;
$schema->resultset('Sensor')->delete;

my $now = DateTime->now(time_zone => 'local');
my $t0  = $now->clone->truncate(to => 'hour')->subtract(hours => 2);
my $t0x = $now->clone->truncate(to => 'hour')->subtract(hours => 2)->add(minutes => 42);
my $t1  = $now->clone->truncate(to => 'hour')->subtract(hours => 1);
my $t1x = $now->clone->truncate(to => 'hour')->subtract(hours => 1)->add(minutes => 34);
my $t2  = $now->clone->truncate(to => 'hour');

$schema->populate(
    AlarmCondition => [
        { sensor_mask => '%/%/temperatur',
          max_measure_age => 2,
          min_value_gt => 5, max_value_lt => 30,
          severity_level => 500 },
    ]);
$schema->populate(
    Sensor => [
        { name => 'erlangen/keller/temperatur',
          measures => [
            { min_value => 10, max_value => 10, sum_value => 10, nr_values => 1,
              starting_at => $t0, updated_at => $t0x, ending_at => $t1 },
          ] },
        { name => 'erlangen/waschkueche/temperatur'  ,
            measures => [
              { min_value => 12, max_value => 14, sum_value => 26, nr_values => 2,
                starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
            ] },
        { name => 'erlangen/heizung/temperatur'    ,
              measures => [
                { min_value => 11, max_value => 11, sum_value => 11, nr_values => 1,
                  starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
              ] },
        { name => 'erlangen/treppenhaus/temperatur'      ,
                measures => [
                  { min_value => 1, max_value => 3, sum_value => 4, nr_values => 2,
                    starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
                ] },
        { name => 'erlangen/hof/temperatur' },
        
        { name => 'trainmeusel/keller/temperatur',
          measures => [
            { min_value => 10, max_value => 10, sum_value => 10, nr_values => 1,
              starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
          ] },
        { name => 'trainmeusel/waschkueche/temperatur'  ,
            measures => [
              { min_value => 10, max_value => 10, sum_value => 10, nr_values => 1,
                starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
            ] },
        { name => 'trainmeusel/heizung/temperatur'    ,
              measures => [
                { min_value => 10, max_value => 10, sum_value => 10, nr_values => 1,
                  starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
              ] },
        { name => 'trainmeusel/treppenhaus/temperatur'      ,
                measures => [
                  { min_value => 10, max_value => 10, sum_value => 10, nr_values => 1,
                    starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
                ] },
        { name => 'trainmeusel/hof/temperatur'        ,
                  measures => [
                    { min_value => 10, max_value => 10, sum_value => 10, nr_values => 1,
                      starting_at => $t1, updated_at => $t1x, ending_at => $t2 },
                  ] },
    ],
);
#!/usr/bin/env perl
use Modern::Perl;
use Parallel::Scoreboard;
use FindBin;

our $TIMEOUT = 120;

my $base_dir = "$FindBin::Bin/../run";
die "base dir ($base_dir) does not exist"
    if !-d $base_dir;

my $status = Parallel::Scoreboard
    ->new(base_dir => $base_dir)
    ->read_all;

foreach my $pid (sort keys %$status) {
    my $now   = time();
    my $mtime = (stat "$base_dir/status_$pid")[9];
    my $age   = '';
    
    if ($status->{$pid} !~ m{\A _}xms) {
        if ($now - $mtime > $TIMEOUT) {
            $age = "> $TIMEOUT";
        } else {
            $age = sprintf('(%d s)', $now-$mtime);
        }
    }
    printf("%05d: %-8s %s\n",
             $pid,
             $age,
             $status->{$pid});
}
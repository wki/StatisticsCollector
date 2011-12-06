#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';
use Getopt::Std;
use IO::Socket::INET;
use Try::Tiny;
use FindBin;
use lib "$FindBin::Bin/../lib";
use StatisticsCollector::Schema;

my %opts;
getopts('vp:d:h', \%opts);
usage() if $opts{h};
my $verbose = $opts{v} || 0;
my $port    = $opts{p} || 8080;
my $dsn     = $opts{d} || 'dbi:Pg:dbname=statistics';


my $schema = StatisticsCollector::Schema->connect($dsn, 'postgres', '');


my $response = IO::Socket::INET->new(
    Proto     => 'udp',
    LocalPort => $port,
    Timeout   => 10)
or die "Can't make UDP server: $@";


say 'UDP Server ready.' if $verbose;
my ($datagram,$flags);
while ($response->recv($datagram, 500, $flags)) {
    say "Got message from ${\$response->peerhost}: $datagram" if $verbose;
    
    my ($sensor_name, $value) = split(/\s+/, $datagram);
    if ($sensor_name !~ m{\A [^/]+ / [^/]+ / [^/]+ \z}xms) {
        warn "Ignoring sensor '$sensor_name' -- not matching required namespace";
        next;
    }
    $value //= 0;
    
    try {
        $schema->resultset('Sensor')
               ->find_or_create( { name => $sensor_name } )
               ->add_measure( $value );
    } catch {
        warn "Error adding a measure, sensor '$sensor_name' ($_)";
    };
}


sub usage {
    print <<EOF;
$0 [options]
    -h        this help
    -v        verbose
    -p port   specify port to listen (default: 8080)
    -d dsn    specify dsn to DB
EOF
    exit;
}

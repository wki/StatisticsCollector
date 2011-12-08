#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Std;

my %opts;
getopts('hs:p:', \%opts);
usage() if $opts{h};
my $server = $opts{s} || '127.0.0.1';
my $port   = $opts{p} || 8080;

die 'nothing to send' if (!@ARGV);

my $sock = IO::Socket::INET->new(
    PeerAddr => $server, 
    PeerPort => $port,
    Proto    => 'udp',
    Timeout  => 1) or die "could not connect: $@";

print $sock join(' ', @ARGV);


sub usage {
    print <<EOF;
send_measure [options] name/of/sensor [measure]
   -h       this help
   -s addr  server (default: 127.0.0.1)
   -p port  port (default: 8080)
   
EOF
    exit;
}

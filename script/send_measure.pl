#!/usr/bin/env perl
#
# IMPORTANT!
# this script schould only use modules shipped with perl.
# This makes it simple to install by simply copying.
#
use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Std;

my $DEFAULT_HOST = '127.0.0.1';
my $DEFAULT_PORT = 8080;

my %opts;
getopts('hs:p:', \%opts);
usage() if $opts{h};
die 'nothing to send' if !@ARGV;

my %socket_options = (
    PeerHost => $opts{s} || $DEFAULT_HOST,
    PeerPort => $opts{p} || $DEFAULT_PORT,
    Proto    => 'udp'
);

my $sock = IO::Socket::INET->new( %socket_options )
    or die "could not connect to socket: $@";

print $sock join(' ', @ARGV);

sub usage {
    print <<EOF;
send_measure [options] name/of/sensor [value]
   -h       this help
   -s addr  server (default: $DEFAULT_HOST)
   -p port  port (default: $DEFAULT_PORT)
   
EOF
    exit;
}


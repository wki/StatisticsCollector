#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket::INET;

die 'nothing to send' if (!@ARGV);

my $sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1', 
    PeerPort => 8080,
    Proto    => 'udp',
    Timeout  => 1) or die "could not connect: $@";

print $sock join(' ', @ARGV);

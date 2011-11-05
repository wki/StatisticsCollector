#!/bin/bash
dstdir=/var/www/StatisticsCollector
PERL5LIB=$dstdir/lib \
    starman --listen=127.0.0.1:5000 \
            --daemonize \
            --pid=/var/www/socket/starman.pid \
    $dstdir/statisticscollector.psgi

#!/bin/bash
DSTDIR=/var/www/StatisticsCollector
PERL5LIB=$DSTDIR/lib \
    starman --listen=127.0.0.1:5000 \
            --daemonize \
            --pid=/var/www/pid/starman.pid \
    $DSTDIR/statisticscollector.psgi

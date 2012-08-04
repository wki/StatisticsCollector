#!/bin/sh

[% FOREACH env_var IN env.keys %]
[%- env_var %]="[% env.$env_var %]"
[% END %]
[% IF perl_libs -%]
PERL5LIB="[% perl_libs %]"
[%- END %]

case "$1" in
    start)
        echo -n "Starting [% label || name %] "
        [% starman || "starman" %] [% starman_opts %] [% psgi_file %]
        echo "[% name %]."
        ;;

    stop)
        echo -n "Stopping [% label || name %]: "
        kill `cat [% pid_file %]`
        echo "[% name %]."
        ;;

    restart)
        echo -n "Restarting [% label || name %]: "
        kill `cat [% pid_file %]`
        sleep 1
        [% starman || "starman" %] [% starman_opts %] [% psgi_file %]
        echo "[% name %]."
        ;;

    status)
        if [ -f [% pid_file %] ] ; then 
            echo "[% name %] is running."
        else
            echo "[% name %] is not running."
        fi
        ;;

    *)
        echo "Usage: [% name %] { start | stop | restart | status }"
        exit 1
        ;;
esac

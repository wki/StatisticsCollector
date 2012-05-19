#
# main configuration for creating an init.d script that manages starman daemon
# Individual settings might get overridden in a secondary config file
#
# interpolation is done after merging config files
#
{
    name         => 'statisticscollector',
    label        => '$name',

    ssh_hostname => 'box',

    user         => 'sites',
    group        => '$user',
    home_dir     => '/home/$user',
    install_dir  => '$home_dir/StatisticsCollector',

    perlbrew_dir => '$home_dir/perl5/perlbrew',
    perlbrew     => '$perlbrew_dir/bin/perlbrew',
    cpanm        => '$perlbrew_dir/bin/cpanm',
    cpanm_local  => '$install_dir/local',

    perl_version => '5.14.2',
    perl_dir     => '$perlbrew_dir/perls/perl-$perl_version',
    perl         => '$perl_dir/bin/perl',
    perl_libs    => '$cpanm_local/lib/perl5:$install_dir/lib',

    nginx_port   => 81,
    nginx_name   => '$name',

    init_d_name  => 'statisticscollector_starman',
    starman      => '$install_dir/local/bin/starman',
    pid_file     => '$home_dir/pid/$name.pid',
    starman_port => '127.0.0.1:5000',
    starman_opts => '--listen $starman_port --pid $pid_file --daemonize --user $user --group $group',
    psgi_file    => '$install_dir/$name.psgi',

    env          => {
        CATALYST_CONFIG => '$install_dir/config',
        CATALYST_CONFIG_LOCAL_SUFFIX => 'live',
    },
}

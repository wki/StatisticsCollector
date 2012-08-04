{
    # just a name, currently not used.
    name           => 'statisticscollector live',
    
    # the file to run on the controlled machine
    provision_file => 'config/provision_live.pl',

    # ssh connection details
    #  - only hostname is mandatory, all others are optional
    #  - options are added to the ssh commandline as-is
    ssh => {
        hostname      => 'box',
        # user          => 'wolfgang',
        # identity_file => 'id_rsa',
        # options     => '--foo 42 --bar zzz',
    },
    
    # resources to get packed into resources/ in a tar archive
    resources => [
        {
            # Web Site: almost everything inside "."
            #    to 'resources/app'
            source      => '.',         # root directory
            destination => 'app',       # subdir inside resources
            exclude     => [
                '._DS_Store', '.git*',
                # 'inc', # initially needed, or Module::Install complains
                'local', 'plist',
                'blib', 'pm_to_blib',
                'script/dbicdh', 'dump',
                'META.yml', 'MYMETA.*', 'Makefile',
                'service',
                'root/_*',
            ],
        },
        {
            source      => 'service',
            destination => 'service',
        }
    ],
    
    # todo:
    # remote_environment => {
    #     PERL_CPANM_OPT => '--mirror http://10.0.2.2:8080 --mirror-only',
    # },
    
    environment => {
        # let a box use the cpan mirror below
        (-d "$ENV{HOME}/minicpan"
            ? (PERL_CPANM_OPT => "--mirror $ENV{HOME}/minicpan --mirror-only")
            : ()),
    },
    
    # setup a mirror for the box
    cpan_mirror => {
        root => "$ENV{HOME}/minicpan",
        port => 8080,
    },
}

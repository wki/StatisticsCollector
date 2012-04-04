package StatisticsCollector::Controller::Css;

use Moose;
use Proc::Class;
use List::Util 'first';

BEGIN { extends 'Catalyst::Controller::Combine' }

# uncomment if desired and do not import namespace::autoclean!
use CSS::Minifier::XS ();

=head1 NAME

StatisticsCollector::Controller::Css - Combine View for StatisticsCollector

=head1 DESCRIPTION

Combine View for StatisticsCollector. 

=cut

__PACKAGE__->config(
    #   optional, defaults to static/<<action_namespace>>
    # dir => 'static/css',
    #
    #   optional, defaults to <<action_namespace>>
    # extension => 'css',
    #
    #   specify dependencies (without file extensions)
    depend => {
        # page    => [ qw(forms table) ],
        site    => [ qw(all tipped form) ],
    },
    #
    #   optionally specify replacements to get done
    replace => {
        # change jQuery UI's links to images
        # assumes that all images for jQuery UI reside under static/images
        # 'jquery-ui' => [ qr'url(images/' => 'url(/static/images/' ],
        '*' => [
            # fix a buggy entry that crashes sass
            qr'rgba[(]0,0,0,33[)]' => 'rgba(0,0,0,.33)',
            
            # now only module/*.css have skin/ references.
            # generally this is really bad
            qr'url[(]skin/' => 'url(/static/css/core/module/skin/',
        ],
    },
    #
    #   execute @import statements during combining
    #   CAUTION: media-types cannot get evaluated, everything is included!
    include => [
        qr{^\s* \@import \s+ (?:url\s*\()? ["']? ([^"')]+) ["']? [)]? .*? ;}xms
    ],
    #
    #   will be guessed from extension
    # mimetype => 'text/css',
    #
    #   if you want a different minifier function name (default: 'minify')
    # minifier => 'my_own_minify',
    #
    #   uncomment if you want to get the 'expire' header set (default:off)
    # expire => 1,
    #
    #   set a different value if wanted
    # expire_in => 60 * 60 * 24 * 365 * 3, # 3 years
);

#
# defined in base class Catalyst::Controller::Combine
# uncomment and modify if you like
#
# sub default :Path {
#     my $self = shift;
#     my $c = shift;
#     
#     $c->forward('do_combine');
# }

#
# optionally, define a minifier routine of your own
#
sub minify :Private {
    my $text = shift;
    
    # my $cmd = first { -f }
    #           qw(/var/lib/gems/1.8/bin/sass /usr/bin/sass);
    # 
    # my $sass = Proc::Class->new(
    #     cmd => $cmd,
    #     argv => [ qw(--stdin --scss) ],
    # );
    # 
    # $sass->print_stdin($text);
    # $sass->close_stdin;
    # 
    # $text = $sass->slurp_stdout;
    # 
    # $sass->waitpid;
    
    return CSS::Minifier::XS::minify($text);
}

# sub minify :Private {
#     my $text = shift;
# 
#     #
#     # let `sass` convert our scss-style into css
#     # borrowed from Tatsuhiko Miyagawa's Plack::Middleware::File::Sass
#     #
#     
#     use IPC::Open3 'open3';
#     
#     my $pid = open3(my $in, my $out, my $err,
#                     '/usr/bin/sass', '--stdin', '--scss');
#     print $in $text;
#     close $in;
#     
#     $text = join '', <$out>;
#     waitpid $pid, 0;
# 
#     return $text;
# }

__PACKAGE__->meta->make_immutable;

1;

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

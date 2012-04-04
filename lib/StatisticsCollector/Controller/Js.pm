package StatisticsCollector::Controller::Js;

use Moose;
BEGIN { extends 'Catalyst::Controller::Combine' }

# uncomment if desired and do not import namespace::autoclean!
# use JavaScript::Minifier::XS qw(minify);

=head1 NAME

StatisticsCollector::Controller::Js - Combine View for StatisticsCollector

=head1 DESCRIPTION

Combine View for StatisticsCollector. 

=cut

__PACKAGE__->config(
    #   optional, defaults to static/<<action_namespace>>
    # dir => 'static/js',
    #
    #   optional, defaults to <<action_namespace>>
    # extension => 'js',
    #
    #   specify dependencies (without file extensions)
    depend => {
    #     'jquery.metadata'     => 'jquery-1.6.2'
    #     'jquery.form-2.36'    => 'jquery-1.6.2'
    #     'jquery.validate-1.6' => [qw(jquery.form-2.36 jquery.metadata)]
        site                  => [ qw(jquery-1.7 tipped) ],
    },
    #
    #   optionally specify replacements to get done
    # replace => {
    # },
    #
    #   will be guessed from extension
    # mimetype => 'application/javascript',
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
# sub minify :Private {
#     my $text = shift;
#
#    usually you will do more :-)
#    $text =~ s{\\s+}{ }xmsg;
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

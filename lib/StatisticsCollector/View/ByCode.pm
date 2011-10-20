package StatisticsCollector::View::ByCode;

use Moose;
BEGIN { extends 'Catalyst::View::ByCode' }

__PACKAGE__->config(
    # # Change default
    # extension => '.pl',
    # 
    # # Set the location for .pl files
    # root_dir => 'root/bycode',
    # 
    # # This is your wrapper template located in the 'root_dir'
    # wrapper => 'wrapper.pl',
    #
    # # specify packages to use in every template
    include => [ qw(StatisticsCollector::TemplateBlocks) ]
);

=head1 NAME

StatisticsCollector::View::ByCode - ByCode View for StatisticsCollector

=head1 DESCRIPTION

ByCode View for StatisticsCollector. 

=head1 METHODS
=cut



=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
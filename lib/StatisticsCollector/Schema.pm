package StatisticsCollector::Schema;

use base 'DBIx::Class::Schema';

our $VERSION = 2;

=head1 NAME

StatisticsCollector::Schema - DBIx::Class Schema

=head1 SYNOPSIS

    use StatisticsCollector::Schema;
    
    my $schema = StatisticsCollector::Schema->new($dsn, $user, $password);

=head1 DESCRIPTION

handles DB connection

=cut

__PACKAGE__->load_namespaces(
    default_resultset_class => 'ResultSet',
);

1;

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

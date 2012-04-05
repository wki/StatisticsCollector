package StatisticsCollector::Schema::ResultSet;
use Modern::Perl;
use DBIx::Class::ResultClass::HashRefInflator;
use base 'DBIx::Class::ResultSet';

=head1 NAME

StatisticsCollector::Schema::ResultSet - ResultSet base class

=head1 SYNOPSIS

    # result is wanted as a hashref
    $rs->as_hashref();
    
    # can be chained
    $schema->resultset(...)->search(...)->as_hashref->all

=head1 DESCRIPTION

methods common to all resultsets are defined here

=head1 METHODS

=cut

=head2 as_hashref

=cut

sub as_hashref {
    my $self = shift;

    $self->result_class('DBIx::Class::ResultClass::HashRefInflator');

    return $self;
}

1;

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

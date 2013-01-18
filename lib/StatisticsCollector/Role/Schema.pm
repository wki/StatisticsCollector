package StatisticsCollector::Role::Schema;

use Moose::Role;
use StatisticsCollector::Schema;
with 'MooseX::Getopt::Strict';

=head1 NAME

StatisticsCollector::Role::Schema - reusable part for DB connections

=head1 SYNOPSIS

    package StatisticsCollector::App::Foo;
    extends 'StatisticsCollector::App';
    with 'StatisticsCollector::Role::Schema';
    
    sub whatever {
        my $self = shift;
        
        # access a resultset via schema
        $self->schema->resultset('SomeTable')->...
        
        # a shortcut
        $self->resultset('AnotherTable')->...
    }

=head1 DESCRIPTION

handles the attributes needed for a DB connection

=head1 ATTRIBUTES

=cut

=head2 dsn

the Data Source Name (dsn) needed to connect to the database

=cut

has dsn => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    default => 'dbi:Pg:dbname=statistics',
    documentation => 'the Data Source Name (dsn) needed to connect to the database',
);

=head2 username

the user name needed to connect to the database

=cut

has username => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    default => 'postgres',
    cmd_aliases => ['U'],
    documentation => 'the user name needed to connect to the database',
);

=head2 password

the password needed to connect to the database

=cut

has password => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    default => '',
    cmd_aliases => ['P'],
    documentation => 'the password needed to connect to the database',
);

=head2 schema

the db schema after a successful connect

=cut

has schema => (
    is => 'ro',
    isa => 'StatisticsCollector::Schema',
    lazy_build => 1,
);

sub _build_schema {
    my $self = shift;
    
    return StatisticsCollector::Schema->connect($self->dsn, $self->username, $self->password);
}

=head1 METHODS

=cut

=head2 resultset ( $resultset_name )

gives back a named result set

=cut

sub resultset {
    my ($self, $resultset_name) = @_;
    
    return $self->schema->resultset($resultset_name);
}

no Moose::Role;

1;

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

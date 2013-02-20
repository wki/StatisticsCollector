package StatisticsCollector::Schema::ResultSource::Foo;
use Moose;
use MooseX::NonMoose;
use SQL::Abstract;

extends 'DBIx::Class::ResultSource::View';

sub BUILDARGS {
    use Data::Dumper;
    warn Data::Dumper->Dump([\@_], ['buildargs']);
    
    {}
}

has something => (
    is      => 'rw',
    isa     => 'Str',
    default => 'xx',
);

has sqla => (
    is => 'ro',
    isa => 'SQL::Abstract',
    lazy_build => 1,
);

sub _build_sqla { SQL::Abstract->new }

sub _sql {
    my $self = shift;
    
    $self->sqla->select(
        sensor => [qw(sensor_id name)],
        # { sensor_id => { '=' => \$self->something } }
    );
}

sub from {
    my $self = shift;
    
    warn "Foo::from, self = $self";
    
    my ($sql, @bind) = $self->_sql;
    
    warn "bind: @bind";
    
    # $self->resultset_attributes( { bind => \@bind } );
    
    return \"($sql)";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

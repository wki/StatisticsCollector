package Monitor;
use Moose;
use namespace::autoclean;
use YAML::XS qw(LoadFile DumpFile);
use Try::Tiny;

has filename => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

sub BUILD {
    my $self = shift;

    # warn "BUILD: " . $self->filename;
}

sub DEMOLISH {
    my $self = shift;

    unlink $self->filename;
    # warn "DEMOLISH: " . $self->filename;
}

sub load {
    my $self = shift;

    # warn "LOAD: " . $self->filename;

    my $data;
    try { 
        $data = LoadFile $self->filename 
    } catch {
        $data = {};
    };
    return $data;
}

sub save {
    my $self = shift;
    my $data = shift;

    # warn "SAVE: " . $self->filename;

    try {
        DumpFile $self->filename, $data;
    };
}

__PACKAGE__->meta->make_immutable;

1;

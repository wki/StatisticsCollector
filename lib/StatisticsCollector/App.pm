package StatisticsCollector::App;
use Moose;
use feature ':5.10';
with 'MooseX::Getopt';

has verbose => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    cmd_aliases   => 'v',
    documentation => 'print what the script is about to do',
);

has debug => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'print (many) debug messages',
);

has dryrun => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    cmd_aliases   => 'n',
    documentation => 'simulate a run',
);

sub verbose_msg {
    my $self = shift;
    $self->_say_if($self->verbose || $self->debug, @_);
}

sub debug_msg {
    my $self = shift;
    $self->_say_if($self->debug, 'DEBUG:', @_);
}

sub dryrun_msg {
    my $self = shift;
    $self->_say_if($self->dryrun, @_);
}

sub _say_if {
    my $self = shift;
    my $condition = shift;

    say @_ if $condition;
    
    return $condition;
}

__PACKAGE__->meta->make_immutable;

1;

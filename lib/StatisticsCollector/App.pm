package StatisticsCollector::App;
use Moose;
use feature ':5.10';
with 'MooseX::Getopt';

=head1 NAME

StatisticsCollector::App - Base class for applications

=head1 SYNOPSIS

    package StatisticsCollector::App::Foo;
    use Moose;
    extends 'StatisticsCollector::App';

=head1 DESCRIPTION

handles the common part of all applications

=head1 ATTRIBUTES

=cut

=head2 verbose

a boolean that decides if verbosity is on or off

=cut

has verbose => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    cmd_aliases   => 'v',
    documentation => 'print what the script is about to do',
);

=head2 debug

a boolean that decides if debug mode is on or off

=cut

has debug => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'print (many) debug messages',
);

=head2 dryrun

a boolean that decides if dryrun mode is on or off

=cut

has dryrun => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    cmd_aliases   => 'n',
    documentation => 'simulate a run',
);

=head1 METHODS

=cut

=head2 verbose_msg(@messages)

if verbose mode is on, @message is printed to STDOUT

returns true of verbose mode is on

=cut

sub verbose_msg {
    my $self = shift;
    $self->_say_if($self->verbose || $self->debug, @_);
}

=head2 debug_msg(@messages)

if debug mode is on, @message is printed to STDOUT

returns true of debug mode is on

=cut

sub debug_msg {
    my $self = shift;
    $self->_say_if($self->debug, 'DEBUG:', @_);
}

=head2 dryrun_msg(@messages)

if dryrun mode is on, @message is printed to STDOUT

returns true of dryrun mode is on

=cut

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

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

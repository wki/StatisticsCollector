package StatisticsCollector::App::UdpServer;
use Moose;
use IO::Socket::INET;
use Try::Tiny;
use feature ':5.10';

extends 'StatisticsCollector::App';
with 'StatisticsCollector::Role::Schema';

=head1 NAME

StatisticsCollector::App::CheckAlarms - Check if sensor alarms are changing

=head1 SYNOPSIS

    StatisticsCollector::App::CheckAlarms->new_with_options->run();

=head1 DESCRIPTION

This is the class behind a shell-executable script to check alarms

=head1 ATTRIBUTES

=cut

=head2 port

the port to listen to (default: 8080)

=cut

has port => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Int',
    default => 8080,
    lazy => 1,
    cmd_aliases => ['p'],
    documentation => 'Port to bind [8080]',
);

=head1 METHODS

=cut

=head2 run

called from L<StatisticsCollector::App> in order to run the script

=cut

sub run {
    my $self = shift;
    
    my $response = IO::Socket::INET->new(
        Proto     => 'udp',
        LocalPort => $self->port,
        Timeout   => 10)
    or die "Can't make UDP server: $@";
    
    $self->verbose_msg('UDP Server ready.');
    my ($datagram,$flags);
    while ($response->recv($datagram, 500, $flags)) {
        $self->verbose_msg("Got message from ${\$response->peerhost}: $datagram");
        
        my ($sensor_name, $value) = split(/\s+/, $datagram);
        if ($sensor_name !~ m{\A [^/]+ / [^/]+ / [^/]+ \z}xms) {
            warn "Ignoring sensor '$sensor_name' -- not matching required namespace";
            next;
        }
        
        try {
            $self->schema->resultset('Sensor')
                         ->find_or_create( { name => $sensor_name } )
                         ->add_measure( $value // 0 );
        } catch {
            warn "Error adding a measure, sensor '$sensor_name' ($_)";
        };
    }
}

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

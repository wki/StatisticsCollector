package StatisticsCollector::App::UdpServer;

use Moose;
use IO::Socket::INET;
use Try::Tiny;
use StatisticsCollector::Schema;

extends 'StatisticsCollector::App';

has port => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Int',
    default => 8080,
    lazy => 1,
    cmd_aliases => ['p'],
    documentation => 'Port to bind [8080]',
);

has dsn => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    default => 'dbi:Pg:dbname=statistics',
    lazy => 1,
    cmd_aliases => ['d'],
    documentation => 'dsn to DB [dbi:Pg:dbname=statistics]',
);

has user => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    default => 'statistics',
    lazy => 1,
    cmd_aliases => ['U'],
    documentation => 'db username',
);

has password => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    default => 'numbers',
    lazy => 1,
    cmd_aliases => ['P'],
    documentation => 'db password',
);

sub run {
    my $self = shift;
    
    my $schema = StatisticsCollector::Schema->connect($self->dsn, $self->user, $self->password);
    
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
        $value //= 0;
        
        try {
            $schema->resultset('Sensor')
                   ->find_or_create( { name => $sensor_name } )
                   ->add_measure( $value );
        } catch {
            warn "Error adding a measure, sensor '$sensor_name' ($_)";
        };
    }
}

__PACKAGE__->meta->make_immutable;

1;

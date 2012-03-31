package StatisticsCollector::App::CheckAlarms;

use Moose;
use IO::Socket::INET;
use Try::Tiny;
use StatisticsCollector::Schema;

extends 'StatisticsCollector::App';

has whatever => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Int',
    default => 8080,
    lazy => 1,
    cmd_aliases => ['w'],
    documentation => 'XXX-fill me',
);


sub run {
    my $self = shift;
    
    ...
    
}

__PACKAGE__->meta->make_immutable;

1;

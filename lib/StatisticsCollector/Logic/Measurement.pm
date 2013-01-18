package StatisticsCollector::Logic::Measurement;
use Moose;
use namespace::autoclean;

has schema => (
    is       => 'ro',
    required => 1,
);

# sub BUILD {
#     my $self = shift;
#     
#     warn "Measurement::BUILD running, schema = ${\$self->schema}";
# }

sub get_latest_measure {
    my ($self, $name) = @_;
    
    my $sensor = 
        $self->schema->resultset('Sensor')
             ->find(
                { name => $name },
                { prefetch => 'latest_measure' })
        or die 'sensor not found';

    return $sensor->latest_measure;
}

sub save_measure {
    my ($self, $name, $value) = @_;
    
    my $sensor = 
        $self->schema->resultset('Sensor')
             ->find_or_create( { name => $name } )
        or die 'Sensor not found';

    return $sensor->add_measure($value // 0);
}

__PACKAGE__->meta->make_immutable;
1;

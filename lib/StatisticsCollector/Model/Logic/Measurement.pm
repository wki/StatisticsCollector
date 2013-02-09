package StatisticsCollector::Model::Logic::Measurement;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'Catalyst::Model::Factory::PerRequest'; # per usage

has class => ( is => 'ro', default => 'StatisticsCollector::Logic::Measurement' );
has model => ( is => 'ro', default => 'DB' );

sub prepare_arguments {
    my ($self, $c) = @_;
    
    warn 'Model::Logic::Measurement::prepare_arguments, ',
         "$$, c=$c, class=${\$self->class}, model=${\$self->model}";
    
    return {
        schema => $c->model($self->model),
    };
}

__PACKAGE__->meta->make_immutable;
1;

package StatisticsCollector::Controller::Sensor;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

StatisticsCollector::Controller::Sensor - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    default => 'application/json',
);

=head2 default

a universal "catch-all" action that dispatches everything

=cut

sub default :Path :Args :ActionClass('REST') {}

=head2 default_GET

http method GET: retrieve the last measure of a sensor

=cut

sub default_GET {
    my ($self, $c, @path) = @_;
    
    if (scalar(@path) != 3) {
        $self->status_bad_request(
            $c,
            message => 'illegal syntax for sensor name',
        );
    } elsif (my $sensor = $c->model('DB::Sensor')
                            ->find({name => join('/', @path)})) {
        my $measure = $sensor->search_related(
            measures => undef,
            { 
                order_by => { -desc => 'starting_at' },
            })->first;
        $self->status_ok(
            $c,
            entity => {
                map { $_ => $measure->$_() }
                qw(latest_value min_value max_value sum_value nr_values)
            },
        );
    } else {
        $self->status_not_found(
            $c,
            message => 'no sensor given',
        );
    }
}

=head2 default_POST

http method POST: deliver a new measurement to a sensor

=cut

sub default_POST {
    my ($self, $c, @path) = @_;
    
    if (scalar(@path) != 3) {
        $self->status_bad_request(
            $c,
            message => 'illegal syntax for sensor name',
        );
    } else {
        my $sensor = $c->model('DB::Sensor')
                       ->find_or_create({name => join('/', @path)});
        if (!$sensor) {
            $self->status_bad_request(
                $c,
                message => 'Sensor not found',
            );
        } else {
            my $measure = $sensor->add_measure($c->req->params->{value});
            $self->status_created(
                $c,
                location => $c->req->uri->as_string,
                entity => {
                    map { $_ => $measure->$_() }
                    qw(sensor_id measure_id min_value max_value latest_value nr_values)
                },
            );
        }
    }
}


=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

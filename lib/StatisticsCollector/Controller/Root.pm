package StatisticsCollector::Controller::Root;
use Moose;
use YAML;
use namespace::autoclean;

use mro 'dfs';

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

StatisticsCollector::Controller::Root - Root Controller for StatisticsCollector

=head1 DESCRIPTION

A simple collector for sensor measures

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->res->redirect( $c->uri_for_action('dashboard/index') );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head2 save_measures

a simple and currently hard coded getter for measures.

Receives all measures of a single arduino board as name/value pairs.
Temperatures of -99 indicate missing values.

=cut

sub save_measures :Global {
    my ( $self, $c ) = @_;
    
    foreach my $name (keys(%{$c->req->params})) {
        my $value = $c->req->params->{$name};
        next if $value < -50;
        
        my $sensor = $c->model('DB::Sensor')
                       ->find_or_create({name => "erlangen/\L$name\E/temperatur"})
            or next;
        
        $sensor->add_measure($value);
    }
    $c->response->body('OK');
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

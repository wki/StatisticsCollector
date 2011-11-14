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

=cut

sub save_measures :Global {
    my ( $self, $c ) = @_;
    
    $c->log->error('save measures: ', Dump($c->req->params));
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

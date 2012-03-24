package StatisticsCollector::Controller::Admin::AlarmCondition;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::HTML::FormFu' }

__PACKAGE__->config(namespace => 'admin/alarm_condition');

=head1 NAME

StatisticsCollector::Controller::Admin::AlarmCondition - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

show a form that allows editing an alarm condition record

=cut

sub index :Path :Args(1) :FormConfig('admin/alarm_condition') {
    my ( $self, $c, $alarm_condition_id ) = @_;

    my $form = $c->stash->{form};
    my $alarm_condition =
        $c->model('DB::AlarmCondition')
          ->find($alarm_condition_id);

    $form->model->default_values($alarm_condition);
}

=head2 save

saves the data entered in the form

=cut

sub save :Local :Args(0) :FormConfig('admin/alarm_condition') {
    my ( $self, $c ) = @_;
    
    my $form = $c->stash->{form};
    if ($form->submitted_and_valid) {
        my $alarm_condition =
            $c->model('DB::AlarmCondition')
              ->find($c->req->params->{alarm_condition_id});
        $form->model->update($alarm_condition);
        
        $c->res->redirect(
            $c->uri_for_action('admin/index', 
                               {-message => 'Saved Alarm Condition'})
        );
    }
    
    $c->stash->{template} = 'admin/alarm_condition/index.pl';
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

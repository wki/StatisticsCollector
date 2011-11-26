package StatisticsCollector::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

StatisticsCollector::Controller::Admin - The entire admin area

=head1 DESCRIPTION

manages all admin responsibilities

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{alarm_conditions} = [
        $c->model('DB::AlarmCondition')
          ->search(
              {
              },
              {
                  order_by => [ {-desc => 'severity_level'}, {-desc => 'specificity'} ],
              })
          ->all
    ];
}


=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

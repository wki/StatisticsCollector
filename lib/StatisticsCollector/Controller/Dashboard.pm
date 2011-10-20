package StatisticsCollector::Controller::Dashboard;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

StatisticsCollector::Controller::Dashboard - Catalyst Controller

=head1 DESCRIPTION

Presents a dashboard page for the regular user

=head1 METHODS

=cut


=head2 index

displays a list of measures, influenced by sort/filter criteria

sort:            name of field to order by ("-" prefix for reverse)
filter_name:     '%/%/whatever'
filter_missing:  0/1 (w/o or w/ missing measures)
filter_severity: 0 (OK) or number or number-number (errors w/severity level range)
filter_age:      num - num
page_nr:         1
page_size:       default 25

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my %search; # to be filled by search-params
    
    my $page_size = $c->req->params->{page_size} || 20;
    
    # testing:
    $search{'me.name'} = { -like => '%/%/temperatur' };
    
    my $search_rs = 
        $c->model('DB::Sensor')
          ->search(
              \%search,
              {
                  prefetch => 'latest_measure',
                  order_by => 'me.name',
                  page => 1,
                  rows => $page_size,
              });
    
    $c->stash(
        sensors => [ $search_rs->all ],
        pager   => $search_rs->pager,
    );
}


=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

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
filter_name1-3:  'whatever' -- part 1-3
filter_missing:  0/1 (w/o or w/ missing measures)
filter_severity: 0 (OK) or number or number-number (errors w/severity level range)
filter_age:      num - num
page_nr:         1
page_size:       default 25

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    
    
    my $page_size = $c->req->params->{page_size};
    $page_size = 25 if $page_size < 10 || $page_size > 100;
    
    my $page_nr   = $c->req->params->{page_nr};
    $page_nr = 1 if $page_nr < 1 || $page_nr > 10000;
    
    my $sort = $c->req->params->{sort} // 'name';
    my %sort_field_for = (
        name   => 'me.name',
        latest => 'latest_measure.updated_at',
        value  => 'latest_measure.latest_value',
    );
    $sort = 'name' if !exists $sort_field_for{$sort};
    $c->req->params->{sort} = $sort;
    
    my @search;
    push @search,
         'me.name' => { -like => $c->req->params->{filter_name1} . '/%/%' }
        if $c->req->params->{filter_name1};
    push @search,
         'me.name' => { -like => '%/' . $c->req->params->{filter_name2} . '/%' }
        if $c->req->params->{filter_name2};
    push @search,
         'me.name' => { -like => '%/%/' . $c->req->params->{filter_name3} }
        if $c->req->params->{filter_name3};
    
    my $search_rs = 
        $c->model('DB::Sensor')
          ->search(
              {
                  (@search ? (-and => \@search) : ()),
              },
              {
                  prefetch => 'latest_measure',
                  order_by => $sort_field_for{$sort},
                  page => $page_nr,
                  rows => $page_size,
              });
    
    my $pager = $search_rs->pager;
    if ($page_nr > $pager->last_page) {
        $c->req->params->{page_nr} = $pager->last_page;
        $search_rs = $search_rs->search( undef, { page => $pager->last_page } );
    }
    
    $c->stash(
        sensors => [ $search_rs->all ],
        pager   => $pager,
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

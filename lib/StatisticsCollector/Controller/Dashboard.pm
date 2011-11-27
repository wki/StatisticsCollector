package StatisticsCollector::Controller::Dashboard;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

StatisticsCollector::Controller::Dashboard - Catalyst Controller

=head1 DESCRIPTION

Presents a dashboard page for the regular user

=head1 METHODS

=cut


=head2 index

displays a list of measures, influenced by sort/filter criteria

sort:            name of field to order by
sort_desc:       0/1
filter_name1-3:  'whatever' -- part 1-3
filter_special:  too_old/missing/range
page_nr:         1
page_size:       default 25

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    
    my ($page_size, $page_nr) = $self->_get_page_size_and_page_nr($c);
    my $order_by              = $self->_determine_order_column($c);
    my @search_criteria       = $self->_compose_search_criteria($c);
    
    my $search_rs = 
        $c->model('DB::Sensor')
          ->search(
              {
                  @search_criteria
              },
              {
                  prefetch => 'latest_measure',
                  order_by => $order_by,
                  page     => $page_nr,
                  rows     => $page_size,
              });
    
    # we must fix our pager and resultset if requested page is over limit
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

sub _get_page_size_and_page_nr {
    my ($self, $c) = @_;
    
    my $page_size = $c->req->params->{page_size};
    $page_size = 25 if !$page_size || $page_size < 10 || $page_size > 100;
    
    my $page_nr   = $c->req->params->{page_nr};
    $page_nr = 1 if !$page_nr || $page_nr < 1 || $page_nr > 10000;
    
    return ($page_size, $page_nr);
}

sub _determine_order_column {
    my ($self, $c) = @_;
    
    my $sort = $c->req->params->{sort} // 'name';
    my $sort_desc = $c->req->params->{sort_desc} ? 1 : 0;
    
    my %sort_field_for = (
        name   => 'me.name',
        latest => 'latest_measure.updated_at',
        value  => 'latest_measure.latest_value',
    );
    $sort = 'name' if !exists $sort_field_for{$sort};
    $c->req->params->{sort} = $sort;
    
    return $sort_desc
        ? { -desc => $sort_field_for{$sort} }
        : $sort_field_for{$sort};
    
}

sub _compose_search_criteria {
    my ($self, $c) = @_;
    
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
    
    if (my $special = $c->req->params->{filter_special}) {
        push @search,
             'latest_measure.measure_id' => undef
            if $special eq 'missing';
        push @search,
             -bool => 'latest_measure.measure_age_alarm',
            if $special eq 'too_old';
        push @search,
             -or => [
                -bool  => 'latest_measure.latest_value_gt_alarm',
                -bool  => 'latest_measure.latest_value_lt_alarm',
                -bool  => 'latest_measure.max_value_lt_alarm',
                -bool  => 'latest_measure.min_value_gt_alarm',
             ]
            if $special eq 'range';
    }
    
    return @search
        ? (-and => \@search)
        : ();
}

=head2 graph_demo

a simple demonstration for generating graphs in HTML instead of PNG

a PNG sized 600 x 400 px is about 37K

the HTML Markup (excluding CSS) is 1-3K

a pure-JS version would even be smaller

=cut

sub graph_demo :Local {
    my ($self, $c) = @_;
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

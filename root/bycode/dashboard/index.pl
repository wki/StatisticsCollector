#
# dashboard / index
#

sub _construct_filter_params {
    my %args = @_;
    
    my %page_params = 
        map { $_ => c->req->params->{$_} }
        grep { m{\A(?:page|filter|sort)}xms }
        keys %{c->req->params};
    
    foreach my $key (keys %args) {
        if (!defined $args{$key}) {
            delete $page_params{$key};
        } else {
            $page_params{$key} = $args{$key};
        }
    }
    
    return \%page_params;
}

sub create_query_params {
    return _construct_filter_params(@_);
}

sub create_hidden_fields {
    my $page_params = _construct_filter_params(@_);
    
    while (my ($name, $value) = each(%{$page_params})) {
        input(type => 'hidden', name => $name, value => $value);
    }
}

sub show_filters {
    my @filters;
    
    foreach my $param (sort grep { m{\A filter_}xms } keys(%{c->req->params})) {
        my $name = $param; $name =~ s{\A filter_}{}xms;
        next if $name eq 'special';
        
        push @filters,
             {
                 name  => $name,
                 param => $param,
                 value => c->req->params->{$param},
                 uri   => c->uri_for_action('dashboard/index',
                                            create_query_params($param => undef)),
             };
    }
    if (@filters) {
        foreach my $filter (@filters) {
            span.mrl {
                print OUT "$filter->{name}: $filter->{value}";
                a.mls(href => $filter->{uri}, title => 'remove filter') { 'X' };
            };
        }
    } else {
        span { 'no filters yet' };
    }
}

sub show_special_filter {
    my %description_for = (
        ''      => '- special filters -',
        missing => 'missing measures',
        too_old => 'too old measures',
        range   => 'values out of range',
    );
    
    form (action => c->uri_for_action('dashboard/index'), method => 'GET') {
        create_hidden_fields(filter_special => undef);
        choice._submit_on_change(name => 'filter_special') {
            foreach my $key (sort keys %description_for) {
                option(value => $key) {
                    attr selected => 1
                        if (c->req->params->{filter_special} // '') eq $key;
                    $description_for{$key};
                };
            }
        };
    }
}

sub show_pager {
    my $pager = stash->{pager};
    # return if $pager->last_page < 2;
    
    form (action => c->uri_for_action('dashboard/index'), method => 'GET') {
        create_hidden_fields(page_nr => undef, page_size => undef);
        choice._submit_on_change(name => 'page_size') {
            foreach my $size (10,25,50,100) {
                option(value => $size) {
                    attr selected => 1 if $size == $pager->entries_per_page;
                    $size;
                };
            }
        };
        choice._submit_on_change(name => 'page_nr') {
            foreach my $i (1 .. $pager->last_page) {
                option(value => $i) {
                    attr selected => 1 if $i == $pager->current_page;
                    "page $i of ${\$pager->last_page}"
                };
            }
        };
    };
}

sub sortable_header {
    my ($field, $name) = @_;
    
    if (c->req->params->{sort} eq $field) {
        my $sort_desc = c->req->params->{sort_desc} ? 1 : 0;
        
        # img(src => "/static/images/bullet_arrow_$dir.png");
        a.sorted(href => c->uri_for_action('dashboard/index',
                                           create_query_params(sort_desc => 1-$sort_desc))) {
            class '+desc' if $sort_desc;
            $name
        };
    } else {
        #img(src => "/static/images/bullet_arrow_up.png");
        a.sortable(href => c->uri_for_action('dashboard/index',
                                             create_query_params(sort => $field, sort_desc => 0))) {
            $name
        };
    }
    return;
}

sub show_sensor_table {
    table.txtL {
        thead {
            trow {
                th(width => '45%') { sortable_header(name => 'Sensor') };
                th(width => '20%') { sortable_header(latest => 'Latest Measure') };
                th(width => '10%') { sortable_header(value => 'value') };
                th(width => '15%') { 'min/avg/max' };
                th(width =>  '5%') { '#' };
                th(width =>  '5%') { '' };
            };
        };
        tbody {
            foreach my $sensor (@{stash->{sensors}}) {
                show_data_row($sensor);
            }
        };
    };
}

sub show_data_row {
    my $sensor = shift;
    my $latest = $sensor->latest_measure;
    
    trow {
        tcol {
            ul.breadcrumb.mvs.mhn {
                my $part_nr = 1;
                foreach my $part (split qr{/}xms, $sensor->name) {
                    li {
                        a(href => c->uri_for_action('dashboard/index', 
                                                    create_query_params("filter_name$part_nr" => $part))) { 
                            $part
                        };
                    };
                    $part_nr++;
                }
            };
        };
        tcol {
            class '+negative' if $latest && $latest->measure_age_alarm;
            
            $latest 
                ? $latest->updated_at->strftime('%Y-%m-%d %H:%M')
                : '-'
        };
        tcol {
            class '+negative'
                if $latest
                   && ($latest->latest_value_gt_alarm || $latest->latest_value_lt_alarm);
            
            $latest 
                ? $latest->latest_value
                : '-'
        };
        tcol { 
            class '+negative'
                if $latest 
                   && ($latest->min_value_gt_alarm || $latest->max_value_lt_alarm);
            
            $latest 
                ? sprintf('%d / %d / %d',
                          $latest->min_value,
                          $latest->sum_value / $latest->nr_values,
                          $latest->max_value)
                : '-'
        };
        tcol {
            $latest
                ? $latest->nr_values
                : '-'
            
        };
        tcol.txtC {
            if (!$latest) {
                img(src => '/static/images/clock_error.png');
            } elsif ($latest->has_alarm) {
                img(src => '/static/images/chart_bar_error.png');
            } else {
                # testing only:
                # img(src => '/static/images/chart_bar_error.png');
            }
            '';
        };
    };
}

template {
    mod.complex.excerpt {
        div.hd.section { 
            h3 { 'Latest Measures' } 
        };
        div.bd {
            div.line.mtm {
                div.unit.size1of2.pll { show_filters() };
                div.unit.size1of4.txtR.prl { show_special_filter() };
                div.unit.size1of4.lastUnit.txtR.prl { show_pager() };
            };
            div.data.simpleTable { show_sensor_table() };
        };
    };
};

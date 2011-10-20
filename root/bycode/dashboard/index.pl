#
# dashboard / index
#

sub show_filters {
    span { 'no filters yet' };
}

sub show_pager {
    my $pager = stash->{pager};
    return if $pager->last_page < 2;
    
    choice(name => 'page_nr') {
        foreach my $i (1 .. $pager->last_page) {
            option(value => $i) {
                attr selected => 1 if $i == $pager->current_page;
                "page $i of ${\$pager->last_page}"
            };
        }
    };
}

sub show_sensor_table {
    table.txtL {
        thead {
            trow {
                th(width => '45%') { 'Sensor' };
                th(width => '25%') { 'Latest Measure' };
                th(width => '20%') { 'min / avg / max' };
                th(width => '5%') { '#' };
                th(width => '5%') { '' };
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
                foreach my $part (split qr{/}xms, $sensor->name) {
                    li { 
                        a(href => '#') { $part };
                    };
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
                div.unit.size3of4.pll { show_filters() };
                div.unit.size1of4.lastUnit.txtR.prl { show_pager() };
            };
            div.data.simpleTable { show_sensor_table() };
        };
    };
};

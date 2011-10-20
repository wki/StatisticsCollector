#
# dashboard / index
#
template {
    mod.complex.excerpt {
        div.hd.section { 
            h3 { 'Latest Measures' } 
        };
        div.bd {
            div.data.simpleTable {
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
                                tcol { $latest 
                                         ? $latest->starting_at->strftime('%Y-%m-%d %H:%M')
                                         : '-'
                                };
                                tcol { $latest 
                                         ? sprintf('%d / %d / %d',
                                                  $latest->min_value,
                                                  $latest->sum_value / $latest->nr_values,
                                                  $latest->max_value)
                                         : '-'
                                };
                                tcol { $latest
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
                    };
                };
            };
        };
    };
};

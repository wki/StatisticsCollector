#
# admin / index
#

sub show_alarm_table {
    table.txtL {
        thead {
            trow {
                th(width => '20%') { 'Alarm Name' };
                th(width => '16%') { 'Sensor Mask' };
                th.txtC(width => '10%') { 'Severity' };
                th.txtC(width => '10%') { 'Age [min]' };
                th.txtC(width => '10%') { 'Latest' };
                th.txtC(width => '10%') { 'Min/Max' };
                th(width =>  '4%') { '' };
            };
        };
        tbody {
            show_data_row($_) for (@{stash->{alarm_conditions}});
        };
    };
}

sub show_data_row {
    my $alarm_condition = shift;

    trow {
        tcol.txtL { $alarm_condition->name };
        tcol.txtL { $alarm_condition->sensor_mask };
        tcol.txtC { $alarm_condition->severity_level };
        tcol.txtC { $alarm_condition->max_measure_age_minutes // '-' };
        tcol.txtC { 
            join(' / ',
                 ($alarm_condition->latest_value_gt // '-'),
                 ($alarm_condition->latest_value_lt // '-') )
        };
        tcol.txtC { 
            join(' / ',
                 ($alarm_condition->min_value_gt // '-'),
                 ($alarm_condition->max_value_lt // '-') )
        };
        tcol.txtL { 'x' };
    };

}

template {
    mod.topic {
        div.hd.section.phm { 
            h3 { 'Admin Area' } 
        };
        div.bd {
            # div.line.mtm {
            #     div.unit.size1of2.pll { show_filters() };
            #     div.unit.size1of4.txtR.prl { show_special_filter() };
            #     div.unit.size1of4.lastUnit.txtR.prl { show_pager() };
            # };
            
            div.data.simpleTable { show_alarm_table() };
        };
    };
};

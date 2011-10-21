#
# top level wrapper
#
template {
    doctype 'html';
    boilerplate {
        head {
            load Css => 'site.css';
            load Js  => 'site.js';
            title { stash->{title} // 'Statistics Collector' };
        };
        body {
            div.page {
                div.head {
                    h1 { stash->{headline} // stash->{title} // 'Statistics Collector' };
                };
                div.body {
                    div.main {
                        yield;
                    };
                };
                div.foot {
                    div.ft.act.phm.pvs.mbl { 
                        div.line {
                            div.unit.size1of3 { "Statistics Collector $StatisticsCollector::VERSION" };
                            div.unit.size1of3.txtC { 'Copyright (C) 2011 WKI' };
                            div.unit.size1of3.lastUnit.txtR {
                                a(href => '#') { 'Info' };
                            };
                        };
                    };
                };
            };
        };
    };
};

#
# top level wrapper
#

block navitem {
    my $namespace = attr('namespace') // '';
    
    li.phl.pvm {
        class '+current' if (c->namespace eq $namespace);
        a(href => c->uri_for_action("$namespace/index")) {
            block_content;
        }
    };
};

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
                        mod.topic.nav {
                            div.hd.topper.phl {
                                ul.navControl {
                                    navitem(namespace => 'dashboard') { 'Dashboard' };
                                    navitem(namespace => 'admin')     { 'Admin' };
                                }
                            };
                            div.bd {
                                yield;
                            };
                        };
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

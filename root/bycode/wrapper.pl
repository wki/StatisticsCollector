#
# top level wrapper
#
template {
    doctype 'html';
    boilerplate {
        head {
            load Css => '/css/site.css';
            title { stash->{title} // 'Statistics Collector' };
        };
        body {
            div.page {
                div.head {
                    h1 { stash->{headline} // stash->{title} // 'Statistics Collector' };
                };
                div.body {
                    # div.leftCol {
                    #     mod.complex.excerpt {
                    #         div.bd {
                    #             ul {
                    #                 li.topper.current { 'select' };
                    #                 li.topper { 'one' };
                    #                 li.topper { 'thing' };
                    #             };
                    #         };
                    #     };
                    # };
                    div.main {
                        yield;
                    };
                };
                div.foot {
                    div.ft.act { 'footer' };
                };
            };
        };
    };
};

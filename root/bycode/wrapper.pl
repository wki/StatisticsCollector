#
# top level wrapper
#
template {
    boilerplate {
        head {
            load Css => '/css/site.css';
        };
        body {
            div page {
                div header {
                };
                div content {
                    yield;
                };
                div footer {
                };
            };
        };
    };
};

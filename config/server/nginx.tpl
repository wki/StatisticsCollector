server {
    listen [% nginx_port %] default;
    server_name [% nginx_name %];
    access_log /var/log/nginx/[% nginx_name %].access.log;
    
    # CSS is served statically
    location /css/ {
        alias [% install_dir %]/root/_static_css/;
    }
    
    # JS is served statically
    location /js/ {
        alias [% install_dir %]/root/_static_js/;
    }
    
    # everything else is passed to Catalyst
    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Port [% nginx_port %]; # important for Catalyst
        proxy_pass http://[% starman_port %];
    }
}
